import Foundation

public struct WitnessMessage: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let role: String // "user", "assistant", "system", "tool"
    public let content: String
    public var toolActionId: String?
    public var toolResult: String?
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), role: String, content: String, toolActionId: String? = nil, toolResult: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.role = role
        self.content = content
        self.toolActionId = toolActionId
        self.toolResult = toolResult
    }
}

public struct ConversationSession: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var messages: [WitnessMessage]
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), title: String, messages: [WitnessMessage] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public final class CoreOrchestrator: @unchecked Sendable {
    public static let shared = CoreOrchestrator()
    
    private let queue = DispatchQueue(label: "com.awitness.orchestrator", attributes: .concurrent)
    private var sessions: [ConversationSession] = []
    private var currentSessionId: UUID?
    private let storageURL: URL
    
    // Dependencies
    private let memoryManager = MemoryManager.shared
    private let permissionEngine = PermissionEngine.shared
    private let modelRouter = ModelRouter.shared
    private let identityLoader = WitnessIdentityLoader.shared
    private let toolRegistry = ToolRegistry.shared
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let witnessDir = appSupport.appendingPathComponent("Witness", isDirectory: true)
        try? FileManager.default.createDirectory(at: witnessDir, withIntermediateDirectories: true)
        self.storageURL = witnessDir.appendingPathComponent("conversations.json")
        loadConversations()
    }
    
    // MARK: - Conversation Management
    
    public func getSessions() -> [ConversationSession] {
        queue.sync { self.sessions }
    }
    
    public func getActiveSession() -> ConversationSession? {
        queue.sync {
            if let id = currentSessionId {
                return sessions.first(where: { $0.id == id })
            }
            return sessions.first
        }
    }
    
    public func selectSession(id: UUID) {
        queue.sync {
            if sessions.contains(where: { $0.id == id }) {
                currentSessionId = id
            }
        }
    }
    
    public func createNewSession(title: String = "New Conversation") -> ConversationSession {
        return queue.sync {
            let session = ConversationSession(title: title)
            sessions.insert(session, at: 0)
            currentSessionId = session.id
            saveConversations()
            return session
        }
    }
    
    public func deleteSession(id: UUID) {
        queue.sync {
            sessions.removeAll { $0.id == id }
            if currentSessionId == id {
                currentSessionId = sessions.first?.id
            }
            if sessions.isEmpty {
                let fallback = ConversationSession(title: "Default Conversation")
                sessions.append(fallback)
                currentSessionId = fallback.id
            }
            saveConversations()
        }
    }
    
    public func searchConversations(query: String) -> [ConversationSession] {
        let q = query.lowercased()
        guard !q.isEmpty else { return getSessions() }
        return queue.sync {
            self.sessions.filter { session in
                if session.title.lowercased().contains(q) { return true }
                return session.messages.contains(where: { $0.content.lowercased().contains(q) })
            }
        }
    }
    
    // MARK: - Message Processing & Governed Tool Pipeline
    
    public func processUserMessage(
        text: String,
        useRuntimeKernel: Bool = true,
        onToken: @escaping @Sendable (String) -> Void,
        onToolActionProposed: (@Sendable (PendingToolAction) -> Void)? = nil,
        onComplete: @escaping @Sendable (Result<String, Error>) -> Void
    ) {
        // Enforce permissions: processing dialogue is ASSIST tier
        guard permissionEngine.evaluate(actionTier: .assist, description: "Process user query and generate response") else {
            let deniedMsg = "Action was prevented by active permission level (\(permissionEngine.currentTier.rawValue))."
            onComplete(.failure(NSError(domain: "Witness", code: 403, userInfo: [NSLocalizedDescriptionKey: deniedMsg])))
            return
        }
        
        let userMsg = WitnessMessage(role: "user", content: text)
        
        // Append user message to active session
        queue.sync {
            if let idx = sessions.firstIndex(where: { $0.id == currentSessionId }) {
                sessions[idx].messages.append(userMsg)
                sessions[idx].updatedAt = Date()
                if sessions[idx].messages.count == 1 {
                    let preview = String(text.prefix(32))
                    sessions[idx].title = preview.isEmpty ? "Conversation" : preview
                }
                saveConversations()
            }
        }
        
        // Record Working Memory (transient, in-session)
        _ = memoryManager.record(tier: .working, content: "Query: \(text)", provenance: .userStatement, importance: 0.5)
        
        // Assemble Prompt Context
        // Use runtime identity kernel for fast inference unless deep prompt is requested
        let systemPrompt = useRuntimeKernel ? identityLoader.getRuntimeKernelPrompt() : identityLoader.getSystemPrompt()
        
        // BM25/Lexical intelligent memory retrieval based on user query
        let memoryContext = memoryManager.retrieveRelevantContext(query: text, maxTokens: 800)
        
        // Tool registry prompt
        let toolPrompt = toolRegistry.generateToolPrompt()
        
        var fullSystemInstruction = systemPrompt
        if !memoryContext.isEmpty {
            fullSystemInstruction += "\n\n" + memoryContext
        }
        if !toolPrompt.isEmpty {
            fullSystemInstruction += "\n\n" + toolPrompt
        }
        
        // History payload with bounded sliding context window (last 10 messages)
        var payloads: [ChatMessagePayload] = [
            ChatMessagePayload(role: "system", content: fullSystemInstruction)
        ]
        
        queue.sync {
            if let active = sessions.first(where: { $0.id == currentSessionId }) {
                let recents = active.messages.suffix(10)
                for m in recents {
                    payloads.append(ChatMessagePayload(role: m.role, content: m.content))
                }
            }
        }
        
        // Stream from Model Router
        Task {
            var fullAssistantReply = ""
            do {
                let stream = modelRouter.streamResponse(messages: payloads)
                for try await token in stream {
                    fullAssistantReply += token
                    onToken(token)
                }
                
                // Inspect for tool invocations formatted in ```tool_call ... ```
                if let toolAction = self.extractToolCall(from: fullAssistantReply) {
                    await self.handleToolCall(
                        action: toolAction,
                        originalReply: fullAssistantReply,
                        onProposed: onToolActionProposed,
                        onComplete: onComplete
                    )
                    return
                }
                
                // Regular response completion
                self.recordAssistantMessage(fullAssistantReply)
                
                // Consolidate episodic memory only if response is meaningful (>25 chars)
                if fullAssistantReply.count > 25 {
                    _ = self.memoryManager.record(
                        tier: .episodic,
                        content: "Witness responded: \"\(fullAssistantReply.prefix(120))...\"",
                        provenance: .modelDerived,
                        importance: 0.4
                    )
                }
                
                onComplete(.success(fullAssistantReply))
            } catch {
                onComplete(.failure(error))
            }
        }
    }
    
    // MARK: - Tool Calling & Governed Execution
    
    private func extractToolCall(from text: String) -> (toolId: String, args: [String: Any])? {
        guard let startRange = text.range(of: "```tool_call"),
              let endRange = text.range(of: "```", range: startRange.upperBound..<text.endIndex) else {
            return nil
        }
        let jsonStr = String(text[startRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = jsonStr.data(using: .utf8),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let toolId = dict["tool"] as? String else {
            return nil
        }
        let params = (dict["parameters"] as? [String: Any]) ?? [:]
        return (toolId, params)
    }
    
    private func handleToolCall(
        action: (toolId: String, args: [String: Any]),
        originalReply: String,
        onProposed: (@Sendable (PendingToolAction) -> Void)?,
        onComplete: @escaping @Sendable (Result<String, Error>) -> Void
    ) async {
        guard let toolDef = toolRegistry.tool(named: action.toolId) else {
            let errMsg = "Tool '\(action.toolId)' not found in registry."
            recordAssistantMessage("\(originalReply)\n\n[Tool Error: \(errMsg)]")
            onComplete(.success(originalReply))
            return
        }
        
        // Parameter schema validation
        if case .failure(let err) = toolRegistry.validateParameters(tool: toolDef, args: action.args) {
            recordAssistantMessage("\(originalReply)\n\n[Schema Validation Error: \(err.localizedDescription)]")
            onComplete(.success(originalReply))
            return
        }
        
        // Check permission boundary
        guard permissionEngine.evaluate(actionTier: toolDef.requiredTier, description: "Invoke tool '\(toolDef.name)'") else {
            let deniedMsg = "\n\n⚠️ Action '\(toolDef.name)' was prevented by permission level (\(permissionEngine.currentTier.rawValue))."
            recordAssistantMessage(originalReply + deniedMsg)
            onComplete(.success(originalReply + deniedMsg))
            return
        }
        
        // If explicit approval required or restricted tier, propose action
        if toolDef.requiresExplicitApproval || permissionEngine.currentTier == .restricted {
            let pending = PendingToolAction(
                toolId: toolDef.id,
                toolName: toolDef.name,
                arguments: action.args,
                requiredTier: toolDef.requiredTier
            )
            onProposed?(pending)
            recordAssistantMessage("\(originalReply)\n\n[Pending Approval: '\(toolDef.name)' requires user authorization.]")
            onComplete(.success(originalReply))
            return
        }
        
        // Authorized: execute tool
        do {
            let res = try await toolDef.handler(action.args)
            let resultBlock = "\n\n[Tool '\(toolDef.name)' Result]:\n\(res.output)"
            recordAssistantMessage(originalReply + resultBlock)
            onComplete(.success(originalReply + resultBlock))
        } catch {
            let errBlock = "\n\n[Tool Execution Failed]: \(error.localizedDescription)"
            recordAssistantMessage(originalReply + errBlock)
            onComplete(.success(originalReply + errBlock))
        }
    }
    
    public func executePendingAction(_ action: PendingToolAction) async -> ToolExecutionResult {
        guard let toolDef = toolRegistry.tool(named: action.toolId) else {
            return ToolExecutionResult(success: false, output: "", error: "Tool not registered")
        }
        
        // Audit log explicit user approval
        _ = permissionEngine.evaluate(actionTier: toolDef.requiredTier, description: "User explicitly approved tool '\(toolDef.name)'")
        
        do {
            let result = try await toolDef.handler(action.arguments)
            let logMsg = "[Approved Tool '\(toolDef.name)' Executed]:\n\(result.output)"
            recordAssistantMessage(logMsg)
            return result
        } catch {
            let errResult = ToolExecutionResult(success: false, output: "", error: error.localizedDescription)
            recordAssistantMessage("[Approved Tool '\(toolDef.name)' Failed]: \(error.localizedDescription)")
            return errResult
        }
    }
    
    private func recordAssistantMessage(_ text: String) {
        let assistantMsg = WitnessMessage(role: "assistant", content: text)
        queue.sync {
            if let idx = self.sessions.firstIndex(where: { $0.id == self.currentSessionId }) {
                self.sessions[idx].messages.append(assistantMsg)
                self.sessions[idx].updatedAt = Date()
                self.saveConversations()
            }
        }
    }
    
    private func loadConversations() {
        guard let data = try? Data(contentsOf: storageURL),
              let list = try? JSONDecoder().decode([ConversationSession].self, from: data),
              !list.isEmpty else {
            let defaultSession = ConversationSession(title: "Initial Session")
            self.sessions = [defaultSession]
            self.currentSessionId = defaultSession.id
            saveConversations()
            return
        }
        self.sessions = list
        self.currentSessionId = list.first?.id
    }
    
    private func saveConversations() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(self.sessions) {
            try? data.write(to: storageURL, options: .atomic)
        }
    }
}

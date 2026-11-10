import Foundation

public struct WitnessMessage: Identifiable, Codable, Sendable {
    public let id: UUID
    public let role: String // "user", "assistant", "system"
    public var content: String
    public let timestamp: Date
    
    public init(id: UUID = UUID(), role: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

public struct ConversationSession: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var createdAt: Date
    public var messages: [WitnessMessage]
    
    public init(id: UUID = UUID(), title: String = "New Conversation", createdAt: Date = Date(), messages: [WitnessMessage] = []) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.messages = messages
    }
}

public final class CoreOrchestrator: @unchecked Sendable {
    public static let shared = CoreOrchestrator()
    
    private let identityLoader: WitnessIdentityLoader
    private let memoryManager: MemoryManager
    private let permissionEngine: PermissionEngine
    private let modelRouter: ModelRouter
    
    private let queue = DispatchQueue(label: "com.awitness.orchestrator")
    private var sessions: [ConversationSession] = []
    private var currentSessionId: UUID?
    private let historyFileURL: URL
    
    public init(
        identityLoader: WitnessIdentityLoader = .shared,
        memoryManager: MemoryManager = .shared,
        permissionEngine: PermissionEngine = .shared,
        modelRouter: ModelRouter = .shared
    ) {
        self.identityLoader = identityLoader
        self.memoryManager = memoryManager
        self.permissionEngine = permissionEngine
        self.modelRouter = modelRouter
        
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let witnessDir = appSupport.appendingPathComponent("Witness", isDirectory: true)
        try? FileManager.default.createDirectory(at: witnessDir, withIntermediateDirectories: true)
        self.historyFileURL = witnessDir.appendingPathComponent("conversations.json")
        
        loadConversations()
        if sessions.isEmpty {
            let initial = ConversationSession(title: "Initial Session")
            sessions.append(initial)
            currentSessionId = initial.id
            saveConversations()
        } else {
            currentSessionId = sessions.first?.id
        }
    }
    
    public func getSessions() -> [ConversationSession] {
        queue.sync { self.sessions }
    }
    
    public func getActiveSession() -> ConversationSession? {
        queue.sync {
            guard let id = currentSessionId else { return sessions.first }
            return sessions.first(where: { $0.id == id })
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
    
    public func processUserMessage(
        text: String,
        onToken: @escaping @Sendable (String) -> Void,
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
                if sessions[idx].messages.count == 1 {
                    // Update title based on first query
                    let preview = String(text.prefix(30))
                    sessions[idx].title = preview.isEmpty ? "Conversation" : preview
                }
                saveConversations()
            }
        }
        
        // Record in Working Memory & Episodic Memory
        _ = memoryManager.record(tier: .working, content: "Query: \(text)", provenance: "user_input", importance: 0.6)
        _ = memoryManager.record(tier: .episodic, content: "User asked: \"\(text)\"", provenance: "dialogue", importance: 0.5)
        
        // Assemble Prompt Context
        let systemPrompt = identityLoader.getSystemPrompt()
        let memoryContext = memoryManager.retrieveRelevantContext(limit: 6)
        
        var fullSystemInstruction = systemPrompt
        if !memoryContext.isEmpty {
            fullSystemInstruction += "\n\n" + memoryContext
        }
        
        // Gather history payload
        var payloads: [ChatMessagePayload] = [
            ChatMessagePayload(role: "system", content: fullSystemInstruction)
        ]
        
        queue.sync {
            if let active = sessions.first(where: { $0.id == currentSessionId }) {
                // Take last 12 messages for conversation context window
                let recents = active.messages.suffix(12)
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
                
                // Save assistant reply to session
                let assistantMsg = WitnessMessage(role: "assistant", content: fullAssistantReply)
                self.queue.sync {
                    if let idx = self.sessions.firstIndex(where: { $0.id == self.currentSessionId }) {
                        self.sessions[idx].messages.append(assistantMsg)
                        self.saveConversations()
                    }
                }
                
                // Consolidate response into memory
                _ = self.memoryManager.record(
                    tier: .episodic,
                    content: "Witness responded: \"\(fullAssistantReply.prefix(120))...\"",
                    provenance: "assistant_response",
                    importance: 0.4
                )
                
                onComplete(.success(fullAssistantReply))
            } catch {
                onComplete(.failure(error))
            }
        }
    }
    
    private func loadConversations() {
        guard let data = try? Data(contentsOf: historyFileURL),
              let list = try? JSONDecoder().decode([ConversationSession].self, from: data) else {
            return
        }
        self.sessions = list
    }
    
    private func saveConversations() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(self.sessions) {
            try? data.write(to: historyFileURL, options: .atomic)
        }
    }
}

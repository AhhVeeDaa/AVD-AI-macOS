import Foundation
import AppKit

public struct ToolParameterSchema: Codable, Sendable {
    public let name: String
    public let type: String // "string", "number", "boolean"
    public let description: String
    public let required: Bool
    
    public init(name: String, type: String, description: String, required: Bool = true) {
        self.name = name
        self.type = type
        self.description = description
        self.required = required
    }
}

public struct ToolDefinition: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let parameters: [ToolParameterSchema]
    public let requiredTier: PermissionTier
    public let requiresExplicitApproval: Bool
    public let handler: @Sendable ([String: Any]) async throws -> ToolExecutionResult
    
    public init(
        id: String,
        name: String,
        description: String,
        parameters: [ToolParameterSchema],
        requiredTier: PermissionTier = .assist,
        requiresExplicitApproval: Bool = false,
        handler: @escaping @Sendable ([String: Any]) async throws -> ToolExecutionResult
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.parameters = parameters
        self.requiredTier = requiredTier
        self.requiresExplicitApproval = requiresExplicitApproval
        self.handler = handler
    }
}

public struct ToolExecutionResult: Codable, Sendable {
    public let success: Bool
    public let output: String
    public let error: String?
    
    public init(success: Bool, output: String, error: String? = nil) {
        self.success = success
        self.output = output
        self.error = error
    }
}

public struct PendingToolAction: Identifiable, @unchecked Sendable {
    public let id: UUID
    public let toolId: String
    public let toolName: String
    public let arguments: [String: Any]
    public let argumentsDisplay: String
    public let requiredTier: PermissionTier
    public let timestamp: Date
    
    public init(toolId: String, toolName: String, arguments: [String: Any], requiredTier: PermissionTier) {
        self.id = UUID()
        self.toolId = toolId
        self.toolName = toolName
        self.arguments = arguments
        self.argumentsDisplay = (try? String(data: JSONSerialization.data(withJSONObject: arguments, options: [.prettyPrinted, .sortedKeys]), encoding: .utf8)) ?? "\(arguments)"
        self.requiredTier = requiredTier
        self.timestamp = Date()
    }
}

public final class ToolRegistry: @unchecked Sendable {
    public static let shared = ToolRegistry()
    
    private let queue = DispatchQueue(label: "com.awitness.toolregistry", attributes: .concurrent)
    private var tools: [String: ToolDefinition] = [:]
    
    // Command allowlist for developer operations
    public static let commandAllowlist: Set<String> = [
        "git", "swift", "uname", "sw_vers", "echo", "pwd", "date", "whoami"
    ]
    
    public init() {
        registerBuiltInTools()
    }
    
    public func register(tool: ToolDefinition) {
        queue.async(flags: .barrier) {
            self.tools[tool.id] = tool
        }
    }
    
    public func allTools() -> [ToolDefinition] {
        queue.sync { Array(self.tools.values).sorted(by: { $0.id < $1.id }) }
    }
    
    public func tool(named id: String) -> ToolDefinition? {
        queue.sync { self.tools[id] }
    }
    
    public func generateToolPrompt() -> String {
        let list = allTools()
        if list.isEmpty { return "" }
        
        var lines = [
            "[AVAILABLE TOOLS & CAPABILITIES]",
            "Witness has access to governed tools. To invoke a tool, respond with a JSON block formatted exactly as:",
            "```tool_call",
            "{\"tool\": \"<tool_id>\", \"parameters\": { ... }}",
            "```",
            "Available tools:"
        ]
        
        for t in list {
            let paramDescriptions = t.parameters.map { "\($0.name) (\($0.type)\($0.required ? ", required" : "")): \($0.description)" }.joined(separator: ", ")
            lines.append("- `\(t.id)` (\(t.name)): \(t.description) [Requires \(t.requiredTier.rawValue)]")
            if !paramDescriptions.isEmpty {
                lines.append("  Parameters: \(paramDescriptions)")
            }
        }
        lines.append("Never attempt to execute actions outside these registered tools.")
        return lines.joined(separator: "\n")
    }
    
    public func validateParameters(tool: ToolDefinition, args: [String: Any]) -> Result<Void, Error> {
        for p in tool.parameters where p.required {
            if args[p.name] == nil {
                let err = NSError(domain: "ToolRegistry", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing required parameter '\(p.name)' for tool '\(tool.id)'"])
                return .failure(err)
            }
        }
        return .success(())
    }
    
    private func registerBuiltInTools() {
        // 1. memory_search
        register(tool: ToolDefinition(
            id: "memory_search",
            name: "Memory Search",
            description: "Search local memory vault by keyword or phrase",
            parameters: [
                ToolParameterSchema(name: "query", type: "string", description: "Search term or concept")
            ],
            requiredTier: .observe,
            requiresExplicitApproval: false,
            handler: { args in
                let query = args["query"] as? String ?? ""
                let result = MemoryManager.shared.retrieveRelevantContext(query: query, maxTokens: 400)
                let text = result.isEmpty ? "No relevant memories found." : result
                return ToolExecutionResult(success: true, output: text)
            }
        ))
        
        // 2. conversation_search
        register(tool: ToolDefinition(
            id: "conversation_search",
            name: "Conversation Search",
            description: "Search previous conversation sessions for matching keywords",
            parameters: [
                ToolParameterSchema(name: "query", type: "string", description: "Keyword or phrase to locate")
            ],
            requiredTier: .observe,
            requiresExplicitApproval: false,
            handler: { args in
                let query = (args["query"] as? String ?? "").lowercased()
                let sessions = CoreOrchestrator.shared.getSessions()
                var matches: [String] = []
                for s in sessions {
                    if s.title.lowercased().contains(query) {
                        matches.append("Session '\(s.title)' (ID: \(s.id.uuidString.prefix(8)))")
                        continue
                    }
                    for m in s.messages {
                        if m.content.lowercased().contains(query) {
                            matches.append("Session '\(s.title)': \"\(m.content.prefix(80))...\"")
                            break
                        }
                    }
                }
                let out = matches.isEmpty ? "No matching conversations found." : matches.joined(separator: "\n")
                return ToolExecutionResult(success: true, output: out)
            }
        ))
        
        // 3. system_status
        register(tool: ToolDefinition(
            id: "system_status",
            name: "System Status",
            description: "Inspect local inference engine, model health, and runtime diagnostic metrics",
            parameters: [],
            requiredTier: .observe,
            requiresExplicitApproval: false,
            handler: { _ in
                let health = await ModelRouter.shared.checkHealth()
                let cfg = ModelRouter.shared.config
                let memCount = MemoryManager.shared.allItems().count
                let sessCount = CoreOrchestrator.shared.getSessions().count
                let tier = PermissionEngine.shared.currentTier.rawValue
                
                var statusStr = "Witness macOS Runtime:\n"
                statusStr += "- Provider: \(cfg.providerType.rawValue) at \(cfg.baseURL.absoluteString)\n"
                statusStr += "- Model: \(cfg.modelName)\n"
                switch health {
                case .success(let msg): statusStr += "- Health: \(msg)\n"
                case .failure(let err): statusStr += "- Health: Offline (\(err.localizedDescription))\n"
                }
                statusStr += "- Memory Records: \(memCount)\n"
                statusStr += "- Saved Conversations: \(sessCount)\n"
                statusStr += "- Active Permission Tier: \(tier)\n"
                statusStr += "- Platform: Apple Silicon macOS (16GB unified memory)"
                return ToolExecutionResult(success: true, output: statusStr)
            }
        ))
        
        // 4. memory_manage
        register(tool: ToolDefinition(
            id: "memory_manage",
            name: "Memory Management",
            description: "Propose or record a durable fact into Semantic or Procedural memory",
            parameters: [
                ToolParameterSchema(name: "tier", type: "string", description: "Target tier: 'SEMANTIC' or 'PROCEDURAL'"),
                ToolParameterSchema(name: "fact", type: "string", description: "The concise factual content to record")
            ],
            requiredTier: .assist,
            requiresExplicitApproval: false,
            handler: { args in
                let fact = args["fact"] as? String ?? ""
                let tierStr = (args["tier"] as? String ?? "SEMANTIC").uppercased()
                let tier: MemoryTier = (tierStr == "PROCEDURAL") ? .procedural : .semantic
                
                if fact.isEmpty {
                    return ToolExecutionResult(success: false, output: "", error: "Fact content cannot be empty")
                }
                
                let item = MemoryManager.shared.record(
                    tier: tier,
                    content: fact,
                    provenance: .modelDerived,
                    importance: 0.7,
                    isConfirmed: false
                )
                return ToolExecutionResult(success: true, output: "Recorded memory in \(tier.rawValue) tier (ID: \(item.id.uuidString.prefix(8))). Marked as MODEL-DERIVED pending user confirmation.")
            }
        ))
        
        // 5. open_url
        register(tool: ToolDefinition(
            id: "open_url",
            name: "Open URL",
            description: "Safely open an external web URL in the default macOS browser",
            parameters: [
                ToolParameterSchema(name: "url", type: "string", description: "Fully-qualified http/https URL")
            ],
            requiredTier: .execute,
            requiresExplicitApproval: true,
            handler: { args in
                guard let urlStr = args["url"] as? String,
                      let url = URL(string: urlStr),
                      url.scheme == "http" || url.scheme == "https" else {
                    return ToolExecutionResult(success: false, output: "", error: "Invalid URL. Only http and https schemes are permitted.")
                }
                
                let opened = await MainActor.run {
                    NSWorkspace.shared.open(url)
                }
                if opened {
                    return ToolExecutionResult(success: true, output: "Successfully opened \(urlStr) in default browser.")
                } else {
                    return ToolExecutionResult(success: false, output: "", error: "macOS workspace failed to open \(urlStr)")
                }
            }
        ))
        
        // 6. local_diagnostics
        register(tool: ToolDefinition(
            id: "local_diagnostics",
            name: "Local Information & Diagnostics",
            description: "Inspect local application data sizes and configuration paths",
            parameters: [],
            requiredTier: .observe,
            requiresExplicitApproval: false,
            handler: { _ in
                let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                let witnessDir = appSupport.appendingPathComponent("Witness", isDirectory: true)
                
                var lines = ["Local Storage Diagnostics:"]
                lines.append("- Path: \(witnessDir.path)")
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: witnessDir.path) {
                    for f in contents {
                        let filePath = witnessDir.appendingPathComponent(f).path
                        if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
                           let size = attrs[.size] as? Int64 {
                            lines.append("  • \(f): \(size) bytes")
                        }
                    }
                }
                return ToolExecutionResult(success: true, output: lines.joined(separator: "\n"))
            }
        ))
        
        // 7. open_application (NEW in v1.5): Device capability interaction
        register(tool: ToolDefinition(
            id: "open_application",
            name: "Open macOS Application",
            description: "Launch an installed application by bundle identifier or name (Requires EXECUTE tier + confirmation)",
            parameters: [
                ToolParameterSchema(name: "bundleIdOrName", type: "string", description: "Application bundle identifier (e.g. com.apple.Terminal) or app name")
            ],
            requiredTier: .execute,
            requiresExplicitApproval: true,
            handler: { args in
                let target = args["bundleIdOrName"] as? String ?? ""
                if target.isEmpty {
                    return ToolExecutionResult(success: false, output: "", error: "Target app name or bundle ID is required.")
                }
                
                let launched = await MainActor.run { () -> Bool in
                    if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: target) {
                        let config = NSWorkspace.OpenConfiguration()
                        NSWorkspace.shared.openApplication(at: appURL, configuration: config, completionHandler: nil)
                        return true
                    }
                    if let appURL = NSWorkspace.shared.urlsForApplications(toOpen: URL(fileURLWithPath: "/Applications/\(target).app")).first {
                        NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                        return true
                    }
                    return false
                }
                
                if launched {
                    return ToolExecutionResult(success: true, output: "Dispatched launch request for application '\(target)'.")
                } else {
                    return ToolExecutionResult(success: false, output: "", error: "Could not locate installed application matching '\(target)'.")
                }
            }
        ))
        
        // 8. read_local_file (NEW in v1.5): Safe approved read-only workspace inspection
        register(tool: ToolDefinition(
            id: "read_local_file",
            name: "Read Local File",
            description: "Read text contents of a file within an approved workspace or user directory",
            parameters: [
                ToolParameterSchema(name: "path", type: "string", description: "Absolute path to the text file")
            ],
            requiredTier: .observe,
            requiresExplicitApproval: false,
            handler: { args in
                let path = args["path"] as? String ?? ""
                guard !path.isEmpty, !path.contains("..") else {
                    return ToolExecutionResult(success: false, output: "", error: "Invalid path specification.")
                }
                // Security guard: disallow reading private keys or credential files
                let forbiddenKeywords = ["id_rsa", ".ssh", "Keychains", "Credentials", "token", ".env"]
                if forbiddenKeywords.contains(where: { path.contains($0) }) {
                    return ToolExecutionResult(success: false, output: "", error: "Access prohibited by local security boundary.")
                }
                guard FileManager.default.fileExists(atPath: path),
                      let content = try? String(contentsOfFile: path, encoding: .utf8) else {
                    return ToolExecutionResult(success: false, output: "", error: "File not readable or does not exist at '\(path)'.")
                }
                let truncated = content.prefix(4000)
                let note = content.count > 4000 ? "\n[Truncated to first 4000 characters]" : ""
                return ToolExecutionResult(success: true, output: String(truncated) + note)
            }
        ))
        
        // 9. run_allowlisted_command (NEW in v1.5): Governed developer CLI execution
        register(tool: ToolDefinition(
            id: "run_allowlisted_command",
            name: "Run Allowlisted Command",
            description: "Execute a pre-approved safe developer command (e.g. git status, swift --version, uname) with arguments",
            parameters: [
                ToolParameterSchema(name: "executable", type: "string", description: "Executable name on the strict allowlist"),
                ToolParameterSchema(name: "arguments", type: "string", description: "Arguments space-separated", required: false)
            ],
            requiredTier: .execute,
            requiresExplicitApproval: true,
            handler: { args in
                let executable = (args["executable"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let rawArgs = (args["arguments"] as? String ?? "").components(separatedBy: " ").filter { !$0.isEmpty }
                
                // Allowlist verification
                guard ToolRegistry.commandAllowlist.contains(executable) else {
                    return ToolExecutionResult(success: false, output: "", error: "Executable '\(executable)' is not on the strict allowlist.")
                }
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/\(executable)")
                if !FileManager.default.fileExists(atPath: process.executableURL!.path) {
                    process.executableURL = URL(fileURLWithPath: "/bin/\(executable)")
                }
                process.arguments = rawArgs
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    return ToolExecutionResult(success: process.terminationStatus == 0, output: output, error: process.terminationStatus != 0 ? "Exited with code \(process.terminationStatus)" : nil)
                } catch {
                    return ToolExecutionResult(success: false, output: "", error: error.localizedDescription)
                }
            }
        ))
    }
}

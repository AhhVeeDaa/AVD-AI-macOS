import Foundation

public enum ModelRole: String, Codable, CaseIterable, Sendable {
    case generalReasoning = "GENERAL_REASONING"
    case coding = "CODING"
    case research = "RESEARCH"
    case fastResponse = "FAST_RESPONSE"
}

public struct ModelRegistryEntry: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let provider: ModelProviderType
    public let endpoint: String
    public var assignedRole: ModelRole
    public var contextWindow: Int
    public var isAvailable: Bool
    public var lastHealthCheck: Date
    
    public init(
        id: String,
        name: String,
        provider: ModelProviderType,
        endpoint: String,
        assignedRole: ModelRole = .generalReasoning,
        contextWindow: Int = 8192,
        isAvailable: Bool = false,
        lastHealthCheck: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.provider = provider
        self.endpoint = endpoint
        self.assignedRole = assignedRole
        self.contextWindow = contextWindow
        self.isAvailable = isAvailable
        self.lastHealthCheck = lastHealthCheck
    }
}

public final class ModelRegistry: @unchecked Sendable {
    public static let shared = ModelRegistry()
    
    private let queue = DispatchQueue(label: "com.awitness.modelregistry", attributes: .concurrent)
    private var entries: [ModelRegistryEntry] = []
    
    public init() {
        registerDefaultEntries()
    }
    
    public func allModels() -> [ModelRegistryEntry] {
        queue.sync { self.entries }
    }
    
    public func model(for role: ModelRole) -> ModelRegistryEntry? {
        queue.sync {
            self.entries.first(where: { $0.assignedRole == role && $0.isAvailable }) ??
            self.entries.first(where: { $0.isAvailable })
        }
    }
    
    public func refreshModelInventory() async -> [ModelRegistryEntry] {
        // 1. Check Ollama Endpoint
        var updated: [ModelRegistryEntry] = []
        if let url = URL(string: "http://127.0.0.1:11434/api/tags") {
            var req = URLRequest(url: url)
            req.timeoutInterval = 2.0
            if let (data, resp) = try? await URLSession.shared.data(for: req),
               let http = resp as? HTTPURLResponse, http.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                for m in models {
                    if let name = m["name"] as? String {
                        let isQwen = name.contains("qwen")
                        updated.append(ModelRegistryEntry(
                            id: "ollama:\(name)",
                            name: name,
                            provider: .ollama,
                            endpoint: "http://127.0.0.1:11434",
                            assignedRole: isQwen ? .generalReasoning : .fastResponse,
                            contextWindow: 8192,
                            isAvailable: true
                        ))
                    }
                }
            }
        }
        
        // 2. Check LM Studio Endpoint
        if let url = URL(string: "http://127.0.0.1:1234/api/v1/models") {
            var req = URLRequest(url: url)
            req.timeoutInterval = 2.0
            if let (data, resp) = try? await URLSession.shared.data(for: req),
               let http = resp as? HTTPURLResponse, http.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                for m in models {
                    let key = m["key"] as? String ?? m["display_name"] as? String ?? "lmstudio-model"
                    updated.append(ModelRegistryEntry(
                        id: "lmstudio:\(key)",
                        name: key,
                        provider: .lmstudio,
                        endpoint: "http://127.0.0.1:1234",
                        assignedRole: .coding,
                        contextWindow: 4096,
                        isAvailable: true
                    ))
                }
            }
        }
        
        queue.async(flags: .barrier) {
            if !updated.isEmpty {
                self.entries = updated
            }
        }
        return queue.sync { self.entries }
    }
    
    private func registerDefaultEntries() {
        entries = [
            ModelRegistryEntry(
                id: "ollama:qwen3.5:4b",
                name: "qwen3.5:4b",
                provider: .ollama,
                endpoint: "http://127.0.0.1:11434",
                assignedRole: .generalReasoning,
                contextWindow: 8192,
                isAvailable: true
            )
        ]
    }
}

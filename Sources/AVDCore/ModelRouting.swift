import Foundation

public enum ModelProviderType: String, Codable, CaseIterable, Sendable {
    case ollama = "OLLAMA"
    case lmstudio = "LM_STUDIO"
    case custom = "CUSTOM_OPENAI_COMPATIBLE"
}

public struct ModelEndpointConfig: Codable, Sendable {
    public var providerType: ModelProviderType
    public var host: String
    public var port: Int
    public var modelName: String
    public var temperature: Double
    public var timeoutSeconds: TimeInterval
    
    public init(
        providerType: ModelProviderType = .ollama,
        host: String = "127.0.0.1",
        port: Int = 11434,
        modelName: String = "qwen3.5:4b",
        temperature: Double = 0.7,
        timeoutSeconds: TimeInterval = 120.0
    ) {
        self.providerType = providerType
        self.host = host
        self.port = port
        self.modelName = modelName
        self.temperature = temperature
        self.timeoutSeconds = timeoutSeconds
    }
    
    public var baseURL: URL {
        URL(string: "http://\(host):\(port)")!
    }
}

public struct ChatMessagePayload: Codable, Sendable {
    public let role: String
    public let content: String
    
    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public protocol ModelProviderProtocol: Sendable {
    func checkHealth(config: ModelEndpointConfig) async -> Result<String, Error>
    func sendChat(messages: [ChatMessagePayload], config: ModelEndpointConfig) async throws -> String
    func streamChat(messages: [ChatMessagePayload], config: ModelEndpointConfig) -> AsyncThrowingStream<String, Error>
}

public final class OllamaProvider: ModelProviderProtocol {
    public init() {}
    
    public func checkHealth(config: ModelEndpointConfig) async -> Result<String, Error> {
        let url = config.baseURL.appendingPathComponent("api/tags")
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .failure(NSError(domain: "OllamaProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "HTTP non-200"]))
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                let names = models.compactMap { $0["name"] as? String }.joined(separator: ", ")
                return .success("Connected. Available models: \(names)")
            }
            return .success("Connected to Ollama.")
        } catch {
            return .failure(error)
        }
    }
    
    public func sendChat(messages: [ChatMessagePayload], config: ModelEndpointConfig) async throws -> String {
        let stream = streamChat(messages: messages, config: config)
        var fullText = ""
        for try await token in stream {
            fullText += token
        }
        return fullText
    }
    
    public func streamChat(messages: [ChatMessagePayload], config: ModelEndpointConfig) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = config.baseURL.appendingPathComponent("api/chat")
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = config.timeoutSeconds
                    
                    let body: [String: Any] = [
                        "model": config.modelName,
                        "messages": messages.map { ["role": $0.role, "content": $0.content] },
                        "stream": true,
                        "options": [
                            "temperature": config.temperature
                        ]
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        throw NSError(domain: "OllamaProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ollama returned error or non-200"])
                    }
                    
                    for try await line in asyncBytes.lines {
                        guard !line.isEmpty else { continue }
                        guard let data = line.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                            continue
                        }
                        
                        if let messageObj = json["message"] as? [String: Any] {
                            // Extract content tokens
                            if let content = messageObj["content"] as? String, !content.isEmpty {
                                continuation.yield(content)
                            }
                        }
                        
                        if let done = json["done"] as? Bool, done {
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

public final class LMStudioProvider: ModelProviderProtocol {
    public init() {}
    
    public func checkHealth(config: ModelEndpointConfig) async -> Result<String, Error> {
        let url = config.baseURL.appendingPathComponent("api/v1/models")
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .failure(NSError(domain: "LMStudioProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "HTTP non-200"]))
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                let names = models.compactMap { $0["display_name"] as? String ?? $0["key"] as? String }.joined(separator: ", ")
                return .success("Connected. Available models: \(names)")
            }
            return .success("Connected to LM Studio.")
        } catch {
            return .failure(error)
        }
    }
    
    public func sendChat(messages: [ChatMessagePayload], config: ModelEndpointConfig) async throws -> String {
        let url = config.baseURL.appendingPathComponent("v1/chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.timeoutSeconds
        
        let body: [String: Any] = [
            "model": config.modelName,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": config.temperature,
            "stream": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "LMStudioProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "LM Studio returned error HTTP status"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw NSError(domain: "LMStudioProvider", code: 3, userInfo: [NSLocalizedDescriptionKey: "Malformed response format"])
    }
    
    public func streamChat(messages: [ChatMessagePayload], config: ModelEndpointConfig) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = config.baseURL.appendingPathComponent("v1/chat/completions")
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = config.timeoutSeconds
                    
                    let body: [String: Any] = [
                        "model": config.modelName,
                        "messages": messages.map { ["role": $0.role, "content": $0.content] },
                        "temperature": config.temperature,
                        "stream": true
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        throw NSError(domain: "LMStudioProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "LM Studio stream failed with non-200"])
                    }
                    
                    for try await line in asyncBytes.lines {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        guard trimmed.hasPrefix("data: ") else { continue }
                        let payload = String(trimmed.dropFirst(6))
                        if payload == "[DONE]" { break }
                        
                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let deltaText = delta["content"] as? String else {
                            continue
                        }
                        continuation.yield(deltaText)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

public final class ModelRouter: @unchecked Sendable {
    public static let shared = ModelRouter()
    
    private let queue = DispatchQueue(label: "com.awitness.modelrouter")
    private var _config: ModelEndpointConfig
    private let configFileURL: URL
    
    private let ollama = OllamaProvider()
    private let lmStudio = LMStudioProvider()
    
    public var config: ModelEndpointConfig {
        get { queue.sync { _config } }
        set {
            queue.sync {
                _config = newValue
                saveConfig()
            }
        }
    }
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let witnessDir = appSupport.appendingPathComponent("Witness", isDirectory: true)
        try? FileManager.default.createDirectory(at: witnessDir, withIntermediateDirectories: true)
        self.configFileURL = witnessDir.appendingPathComponent("model_config.json")
        
        self._config = ModelEndpointConfig(
            providerType: .ollama,
            host: "127.0.0.1",
            port: 11434,
            modelName: "qwen3.5:4b",
            temperature: 0.7,
            timeoutSeconds: 120.0
        )
        loadConfig()
    }
    
    public func getProvider() -> ModelProviderProtocol {
        let current = config
        switch current.providerType {
        case .ollama:
            return ollama
        case .lmstudio, .custom:
            return lmStudio
        }
    }
    
    public func checkHealth() async -> Result<String, Error> {
        let current = config
        return await getProvider().checkHealth(config: current)
    }
    
    public func streamResponse(messages: [ChatMessagePayload]) -> AsyncThrowingStream<String, Error> {
        let current = config
        return getProvider().streamChat(messages: messages, config: current)
    }
    
    private func loadConfig() {
        guard let data = try? Data(contentsOf: configFileURL),
              let saved = try? JSONDecoder().decode(ModelEndpointConfig.self, from: data) else {
            return
        }
        self._config = saved
    }
    
    private func saveConfig() {
        guard let data = try? JSONEncoder().encode(_config) else { return }
        try? data.write(to: configFileURL, options: .atomic)
    }
}

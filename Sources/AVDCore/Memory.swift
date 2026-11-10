import Foundation

public enum MemoryTier: String, Codable, CaseIterable, Sendable {
    case working = "WORKING"       // In-session context, transient thoughts
    case episodic = "EPISODIC"     // Specific user interactions, historical events
    case semantic = "SEMANTIC"     // Durable knowledge, facts about user, rules
    case procedural = "PROCEDURAL" // Habits, workflows, system preferences
}

public struct MemoryItem: Identifiable, Codable, Sendable {
    public let id: UUID
    public let tier: MemoryTier
    public var content: String
    public let provenance: String
    public let timestamp: Date
    public var lastAccessed: Date
    public var importance: Double // 0.0 to 1.0
    
    public init(id: UUID = UUID(), tier: MemoryTier, content: String, provenance: String = "conversation", timestamp: Date = Date(), lastAccessed: Date = Date(), importance: Double = 0.5) {
        self.id = id
        self.tier = tier
        self.content = content
        self.provenance = provenance
        self.timestamp = timestamp
        self.lastAccessed = lastAccessed
        self.importance = importance
    }
}

public final class MemoryManager: @unchecked Sendable {
    public static let shared = MemoryManager()
    
    private let queue = DispatchQueue(label: "com.awitness.memory", attributes: .concurrent)
    private var items: [MemoryItem] = []
    private let storageURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let witnessDir = appSupport.appendingPathComponent("Witness", isDirectory: true)
        try? FileManager.default.createDirectory(at: witnessDir, withIntermediateDirectories: true)
        self.storageURL = witnessDir.appendingPathComponent("memory_store.json")
        loadFromDisk()
    }
    
    public func record(tier: MemoryTier, content: String, provenance: String = "user_input", importance: Double = 0.5) -> MemoryItem {
        let item = MemoryItem(tier: tier, content: content, provenance: provenance, timestamp: Date(), lastAccessed: Date(), importance: importance)
        queue.async(flags: .barrier) {
            self.items.append(item)
            self.saveToDisk()
        }
        return item
    }
    
    public func update(id: UUID, newContent: String) {
        queue.async(flags: .barrier) {
            if let index = self.items.firstIndex(where: { $0.id == id }) {
                self.items[index].content = newContent
                self.items[index].lastAccessed = Date()
                self.saveToDisk()
            }
        }
    }
    
    public func delete(id: UUID) {
        queue.async(flags: .barrier) {
            self.items.removeAll { $0.id == id }
            self.saveToDisk()
        }
    }
    
    public func clearAll() {
        queue.async(flags: .barrier) {
            self.items.removeAll()
            self.saveToDisk()
        }
    }
    
    public func allItems() -> [MemoryItem] {
        queue.sync { self.items }
    }
    
    public func items(for tier: MemoryTier) -> [MemoryItem] {
        queue.sync { self.items.filter { $0.tier == tier } }
    }
    
    public func retrieveRelevantContext(limit: Int = 10) -> String {
        return queue.sync {
            let sorted = self.items.sorted {
                // Weight by tier and importance
                let scoreA = $0.importance + ($0.tier == .semantic ? 0.3 : 0.0)
                let scoreB = $1.importance + ($1.tier == .semantic ? 0.3 : 0.0)
                return scoreA > scoreB
            }
            let slice = sorted.prefix(limit)
            if slice.isEmpty { return "" }
            
            var lines = ["--- RECALLED MEMORY CONTEXT ---"]
            for m in slice {
                lines.append("[\(m.tier.rawValue)] (\(m.provenance)): \(m.content)")
            }
            lines.append("-------------------------------")
            return lines.joined(separator: "\n")
        }
    }
    
    public func exportJSON() -> String {
        queue.sync {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(self.items),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return "[]"
        }
    }
    
    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storageURL),
              let list = try? JSONDecoder().decode([MemoryItem].self, from: data) else {
            // Pre-seed initial semantic memories if completely empty
            seedInitialMemories()
            return
        }
        self.items = list
    }
    
    private func seedInitialMemories() {
        items = [
            MemoryItem(tier: .semantic, content: "Witness is running on macOS on Apple Silicon.", provenance: "system_init", importance: 0.9),
            MemoryItem(tier: .procedural, content: "Default model provider connects to Ollama on 127.0.0.1:11434 with model qwen3.5:4b.", provenance: "hardware_profile", importance: 0.8),
            MemoryItem(tier: .semantic, content: "User values direct, competent assistance without conversational filler.", provenance: "identity_core", importance: 0.9)
        ]
        saveToDisk()
    }
    
    private func saveToDisk() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(self.items) {
            try? data.write(to: storageURL, options: .atomic)
        }
    }
}

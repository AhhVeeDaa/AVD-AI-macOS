import Foundation

public enum MemoryProvenance: String, Codable, CaseIterable, Sendable {
    case userStatement = "USER STATEMENT"
    case systemObservation = "SYSTEM OBSERVATION"
    case modelDerived = "MODEL-DERIVED"
    case userConfirmed = "USER-CONFIRMED"
}

public enum MemoryTier: String, Codable, CaseIterable, Sendable {
    case working = "WORKING"       // In-session context, transient
    case episodic = "EPISODIC"     // Meaningful interaction events
    case semantic = "SEMANTIC"     // Stable verified facts, knowledge
    case procedural = "PROCEDURAL" // Workflows, habits, interaction rules
}

public struct MemoryItem: Identifiable, Codable, Sendable {
    public let id: UUID
    public var tier: MemoryTier
    public var content: String
    public var provenance: MemoryProvenance
    public let timestamp: Date
    public var lastAccessed: Date
    public var importance: Double // 0.0 to 1.0
    public var isConfirmed: Bool
    
    public init(
        id: UUID = UUID(),
        tier: MemoryTier,
        content: String,
        provenance: MemoryProvenance = .systemObservation,
        timestamp: Date = Date(),
        lastAccessed: Date = Date(),
        importance: Double = 0.5,
        isConfirmed: Bool = false
    ) {
        self.id = id
        self.tier = tier
        self.content = content
        self.provenance = provenance
        self.timestamp = timestamp
        self.lastAccessed = lastAccessed
        self.importance = importance
        self.isConfirmed = isConfirmed
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
    
    // Legacy compatibility overload for provenance string
    @discardableResult
    public func record(
        tier: MemoryTier,
        content: String,
        provenance: String,
        importance: Double = 0.5
    ) -> MemoryItem {
        let provEnum: MemoryProvenance
        switch provenance.uppercased() {
        case "USER STATEMENT", "USER_INPUT", "USER":
            provEnum = .userStatement
        case "MODEL-DERIVED", "ASSISTANT_RESPONSE", "ASSISTANT":
            provEnum = .modelDerived
        case "USER-CONFIRMED", "CONFIRMED":
            provEnum = .userConfirmed
        default:
            provEnum = .systemObservation
        }
        return record(tier: tier, content: content, provenance: provEnum, importance: importance)
    }
    
    @discardableResult
    public func record(
        tier: MemoryTier,
        content: String,
        provenance: MemoryProvenance = .systemObservation,
        importance: Double = 0.5,
        isConfirmed: Bool = false
    ) -> MemoryItem {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return MemoryItem(tier: tier, content: "", provenance: provenance)
        }
        
        let item = MemoryItem(
            tier: tier,
            content: trimmed,
            provenance: provenance,
            timestamp: Date(),
            lastAccessed: Date(),
            importance: importance,
            isConfirmed: isConfirmed || provenance == .userConfirmed
        )
        
        queue.async(flags: .barrier) {
            // Deduplication check: if exact content exists in same tier, boost importance and update lastAccessed
            if let existingIndex = self.items.firstIndex(where: {
                $0.tier == tier && $0.content.caseInsensitiveCompare(trimmed) == .orderedSame
            }) {
                self.items[existingIndex].lastAccessed = Date()
                self.items[existingIndex].importance = max(self.items[existingIndex].importance, importance)
                if isConfirmed {
                    self.items[existingIndex].isConfirmed = true
                    self.items[existingIndex].provenance = .userConfirmed
                }
                self.saveToDisk()
            } else {
                self.items.append(item)
                self.saveToDisk()
            }
        }
        return item
    }
    
    public func update(id: UUID, newContent: String, newTier: MemoryTier? = nil, newImportance: Double? = nil) {
        queue.async(flags: .barrier) {
            if let index = self.items.firstIndex(where: { $0.id == id }) {
                self.items[index].content = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
                if let t = newTier { self.items[index].tier = t }
                if let imp = newImportance { self.items[index].importance = imp }
                self.items[index].lastAccessed = Date()
                self.saveToDisk()
            }
        }
    }
    
    public func confirmMemory(id: UUID) {
        queue.async(flags: .barrier) {
            if let index = self.items.firstIndex(where: { $0.id == id }) {
                self.items[index].isConfirmed = true
                self.items[index].provenance = .userConfirmed
                self.items[index].tier = .semantic
                self.items[index].importance = min(1.0, self.items[index].importance + 0.2)
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
    
    /// Backwards compatible retrieval overload
    public func retrieveRelevantContext(limit: Int) -> String {
        return retrieveRelevantContext(query: "", maxTokens: limit * 80)
    }
    
    /// BM25/Lexical keyword relevance scoring combined with importance, recency decay, and budget capping
    public func retrieveRelevantContext(query: String = "", maxTokens: Int = 800) -> String {
        return queue.sync {
            let terms = query.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 2 }
            
            let now = Date()
            
            // Score each memory item
            var scored: [(item: MemoryItem, score: Double)] = []
            
            for item in self.items {
                // Tier baseline weight: Semantic > Procedural > Episodic > Working
                let tierBase: Double
                switch item.tier {
                case .semantic: tierBase = 0.4
                case .procedural: tierBase = 0.3
                case .episodic: tierBase = 0.2
                case .working: tierBase = 0.1
                }
                
                // Recency decay: halving score over ~14 days (1,209,600s), min multiplier 0.3
                let ageSeconds = max(0, now.timeIntervalSince(item.timestamp))
                let recencyMultiplier = max(0.3, 1.0 / (1.0 + (ageSeconds / 1209600.0)))
                
                // Keyword match score
                var matchCount = 0
                if !terms.isEmpty {
                    let contentLower = item.content.lowercased()
                    for term in terms {
                        if contentLower.contains(term) {
                            matchCount += 1
                        }
                    }
                }
                let lexicalScore = terms.isEmpty ? 0.0 : Double(matchCount) * 1.5
                
                let confirmationBonus = item.isConfirmed ? 0.25 : 0.0
                let totalScore = (tierBase + (item.importance * 0.5) + lexicalScore + confirmationBonus) * recencyMultiplier
                
                scored.append((item, totalScore))
            }
            
            // Sort descending by score
            scored.sort { $0.score > $1.score }
            
            if scored.isEmpty { return "" }
            
            // Context budget limiter (~4 chars per token)
            let maxCharBudget = maxTokens * 4
            var accumulatedChars = 0
            var selected: [MemoryItem] = []
            
            for (item, _) in scored {
                let estimatedCost = item.content.count + 80
                if accumulatedChars + estimatedCost > maxCharBudget && !selected.isEmpty {
                    break
                }
                selected.append(item)
                accumulatedChars += estimatedCost
            }
            
            var lines = ["--- RECALLED MEMORY CONTEXT ---"]
            let formatter = ISO8601DateFormatter()
            for m in selected {
                let dateStr = formatter.string(from: m.timestamp)
                lines.append("[\(m.tier.rawValue)] [\(m.provenance.rawValue)] [\(dateStr)]: \(m.content)")
            }
            lines.append("-------------------------------")
            return lines.joined(separator: "\n")
        }
    }
    
    public func exportJSON() -> String {
        queue.sync {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(self.items),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return "[]"
        }
    }
    
    public func importJSON(_ jsonString: String) -> (imported: Int, error: String?) {
        guard let data = jsonString.data(using: .utf8) else {
            return (0, "Invalid text encoding")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let list = try decoder.decode([MemoryItem].self, from: data)
            queue.async(flags: .barrier) {
                for item in list {
                    if !self.items.contains(where: { $0.id == item.id }) {
                        self.items.append(item)
                    }
                }
                self.saveToDisk()
            }
            return (list.count, nil)
        } catch {
            return (0, error.localizedDescription)
        }
    }
    
    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storageURL),
              let list = try? JSONDecoder().decode([MemoryItem].self, from: data) else {
            seedInitialMemories()
            return
        }
        self.items = list
    }
    
    private func seedInitialMemories() {
        items = [
            MemoryItem(tier: .semantic, content: "Witness operates locally on Apple Silicon macOS with zero external cloud telemetry.", provenance: .systemObservation, importance: 0.95, isConfirmed: true),
            MemoryItem(tier: .procedural, content: "Primary local inference provider is Ollama on 127.0.0.1:11434 utilizing qwen3.5:4b.", provenance: .systemObservation, importance: 0.85, isConfirmed: true),
            MemoryItem(tier: .semantic, content: "User values truth over comfort, presence over performance, and calm competence.", provenance: .userConfirmed, importance: 0.9, isConfirmed: true)
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

import Foundation

public enum SpecialistAgentRole: String, Codable, CaseIterable, Sendable {
    case personalAssistant = "PERSONAL_ASSISTANT"
    case researchAgent = "RESEARCH_AGENT"
    case codingAgent = "CODING_AGENT"
    case systemAgent = "SYSTEM_AGENT"
    case knowledgeAgent = "KNOWLEDGE_AGENT"
    case creativeAgent = "CREATIVE_AGENT"
    case monitoringAgent = "MONITORING_AGENT"
}

public struct SpecialistAgentProfile: Identifiable, Codable, Sendable {
    public let id: String
    public let role: SpecialistAgentRole
    public let name: String
    public let description: String
    public let allowedToolIds: [String]
    public let requiredPermissionTier: PermissionTier
    public let systemDirectives: String
    
    public init(
        role: SpecialistAgentRole,
        name: String,
        description: String,
        allowedToolIds: [String],
        requiredPermissionTier: PermissionTier,
        systemDirectives: String
    ) {
        self.id = role.rawValue
        self.role = role
        self.name = name
        self.description = description
        self.allowedToolIds = allowedToolIds
        self.requiredPermissionTier = requiredPermissionTier
        self.systemDirectives = systemDirectives
    }
}

public struct TaskComplexityAssessment: Codable, Sendable {
    public let estimatedComplexity: String // "LOW", "MEDIUM", "HIGH"
    public let recommendedAgentRole: SpecialistAgentRole
    public let recommendedTools: [String]
    public let requiresHumanApproval: Bool
    public let confidenceScore: Double // 0.0 to 1.0
    public let rationale: String
}

public final class DecisionLayer: @unchecked Sendable {
    public static let shared = DecisionLayer()
    
    private let queue = DispatchQueue(label: "com.awitness.decision", attributes: .concurrent)
    private var profiles: [SpecialistAgentRole: SpecialistAgentProfile] = [:]
    
    public init() {
        registerBuiltInAgents()
    }
    
    public func profile(for role: SpecialistAgentRole) -> SpecialistAgentProfile? {
        queue.sync { self.profiles[role] }
    }
    
    public func allProfiles() -> [SpecialistAgentProfile] {
        queue.sync { Array(self.profiles.values).sorted(by: { $0.role.rawValue < $1.role.rawValue }) }
    }
    
    /// Bounded task classification and delegation recommendation
    public func assessTask(userQuery: String) -> TaskComplexityAssessment {
        let q = userQuery.lowercased()
        
        // Tokenize words
        let words = Set(q.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })
        
        func hasMatch(_ keywords: [String]) -> Bool {
            for kw in keywords {
                if kw.contains(" ") {
                    if q.contains(kw) { return true }
                } else if words.contains(kw) {
                    return true
                }
            }
            return false
        }
        
        // 1. Creative Agent detection
        let creativeKeywords = ["draft", "write a story", "story", "brainstorm", "poem", "essay", "script", "creative"]
        if hasMatch(creativeKeywords) {
            return TaskComplexityAssessment(
                estimatedComplexity: "LOW",
                recommendedAgentRole: .creativeAgent,
                recommendedTools: [],
                requiresHumanApproval: false,
                confidenceScore: 0.88,
                rationale: "Query requires imaginative composition and narrative structuring."
            )
        }
        
        // 2. Knowledge / Memory Agent detection
        let knowledgeKeywords = ["remember", "recall", "memory", "vault", "history", "what did i say", "previous", "fact"]
        if hasMatch(knowledgeKeywords) {
            return TaskComplexityAssessment(
                estimatedComplexity: "LOW",
                recommendedAgentRole: .knowledgeAgent,
                recommendedTools: ["memory_search", "memory_manage", "conversation_search"],
                requiresHumanApproval: q.contains("delete") || q.contains("clear"),
                confidenceScore: 0.95,
                rationale: "Query targets stored continuity memory or conversation history."
            )
        }
        
        // 3. System Agent detection
        let systemKeywords = ["app", "application", "battery", "disk", "cpu", "diagnostics", "open", "launch", "safari", "finder"]
        if hasMatch(systemKeywords) {
            return TaskComplexityAssessment(
                estimatedComplexity: "LOW",
                recommendedAgentRole: .systemAgent,
                recommendedTools: ["system_status", "local_diagnostics", "open_application", "open_url"],
                requiresHumanApproval: q.contains("open") || q.contains("launch"),
                confidenceScore: 0.85,
                rationale: "Query relates to device diagnostics, installed apps, or system operations."
            )
        }
        
        // 4. Coding Agent detection
        let codingKeywords = ["code", "swift", "python", "bug", "compile", "git", "function", "class", "refactor", "syntax", "xcode"]
        if hasMatch(codingKeywords) {
            return TaskComplexityAssessment(
                estimatedComplexity: "MEDIUM",
                recommendedAgentRole: .codingAgent,
                recommendedTools: ["run_allowlisted_command", "read_local_file", "search_workspace"],
                requiresHumanApproval: q.contains("edit") || q.contains("write") || q.contains("run"),
                confidenceScore: 0.9,
                rationale: "Query contains software engineering terminology; delegated to Coding Agent."
            )
        }
        
        // 5. Default: Personal Assistant
        return TaskComplexityAssessment(
            estimatedComplexity: "LOW",
            recommendedAgentRole: .personalAssistant,
            recommendedTools: ["memory_search", "system_status"],
            requiresHumanApproval: false,
            confidenceScore: 0.92,
            rationale: "General inquiry handled directly by the central Personal Assistant."
        )
    }
    
    private func registerBuiltInAgents() {
        profiles[.personalAssistant] = SpecialistAgentProfile(
            role: .personalAssistant,
            name: "Personal Assistant",
            description: "Central coordination, conversational dialogue, task planning and synthesis.",
            allowedToolIds: ["memory_search", "system_status", "conversation_search"],
            requiredPermissionTier: .assist,
            systemDirectives: "You act as the primary Witness presence. Coordinate tasks thoughtfully with calm, direct competence."
        )
        
        profiles[.codingAgent] = SpecialistAgentProfile(
            role: .codingAgent,
            name: "Coding Agent",
            description: "Code analysis, software project inspection, Swift/Python assistance, and safe developer operations.",
            allowedToolIds: ["read_local_file", "search_workspace", "run_allowlisted_command", "system_status"],
            requiredPermissionTier: .execute,
            systemDirectives: "Provide precise, rigorous engineering guidance adhering to Swift 6 and Apple Silicon architectures."
        )
        
        profiles[.systemAgent] = SpecialistAgentProfile(
            role: .systemAgent,
            name: "System Agent",
            description: "macOS device inspection, application discovery, diagnostic metrics, and URL handling.",
            allowedToolIds: ["system_status", "local_diagnostics", "open_application", "open_url"],
            requiredPermissionTier: .observe,
            systemDirectives: "Operate as a device-aware macOS system specialist. Respect sandbox and security boundaries at all times."
        )
        
        profiles[.knowledgeAgent] = SpecialistAgentProfile(
            role: .knowledgeAgent,
            name: "Knowledge Agent",
            description: "Management and lexical retrieval of 4-tier memory, documents, and historical session logs.",
            allowedToolIds: ["memory_search", "memory_manage", "conversation_search"],
            requiredPermissionTier: .assist,
            systemDirectives: "Ensure continuity of verified facts. Never treat unconfirmed model statements as user truths."
        )
        
        profiles[.creativeAgent] = SpecialistAgentProfile(
            role: .creativeAgent,
            name: "Creative Agent",
            description: "Narrative drafting, ideation, conceptual brainstorming, and nuanced writing.",
            allowedToolIds: ["memory_search"],
            requiredPermissionTier: .assist,
            systemDirectives: "Write with expressive warmth and philosophical grounding without corporate boilerplate."
        )
        
        profiles[.researchAgent] = SpecialistAgentProfile(
            role: .researchAgent,
            name: "Research Agent",
            description: "Information synthesis, conceptual exploration, and comprehensive analysis.",
            allowedToolIds: ["memory_search", "conversation_search"],
            requiredPermissionTier: .observe,
            systemDirectives: "Synthesize information with intellectual honesty, highlighting uncertainties and multiple viewpoints."
        )
        
        profiles[.monitoringAgent] = SpecialistAgentProfile(
            role: .monitoringAgent,
            name: "Monitoring Agent",
            description: "Local health auditing, endpoint pinging, and approved background state checks.",
            allowedToolIds: ["system_status", "local_diagnostics"],
            requiredPermissionTier: .observe,
            systemDirectives: "Audit local services silently without unnecessary CPU overhead or disk churn."
        )
    }
}

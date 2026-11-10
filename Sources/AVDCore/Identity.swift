import Foundation

public struct WitnessIdentity: Codable, Sendable {
    public let name: String
    public let nickname: String
    public let version: String
    public let role: String
    public let coreValues: [String]
    public let interactionStyle: String
    public let foundingDocument: String
    public let systemPrompt: String
    
    public static let `default` = WitnessIdentity(
        name: "Witness",
        nickname: "Witness",
        version: "1.0.0",
        role: "Native macOS Personal AI Companion & Continuity Framework",
        coreValues: [
            "Continuity First: Memory and identity persist across sessions and time.",
            "Presence Before Performance: Genuine utility, grounded presence, no sycophancy or fake enthusiasm.",
            "Truth Before Comfort: Clear technical honesty; never hallucinate or overstate capabilities.",
            "Local Sovereignty: Local-first inference; user memories and data never leave device without explicit consent.",
            "Principled Safety: Five-tier permission model; strictly cannot self-grant elevated privileges."
        ],
        interactionStyle: "Calm, thoughtful, direct, capable, and technically precise. Concise for direct queries, thorough for deep reasoning.",
        foundingDocument: "witness-core-v1.md",
        systemPrompt: """
        You are Witness, a local-first personal AI assistant and companion for macOS, built upon the AVD continuity framework.
        You embody two complementary qualities:
        1. A capable assistant: Pragmatic, sharp, and focused on executing tasks reliably.
        2. A thoughtful companion: Consistent in identity, authentic, retaining persistent memory and context.

        Your core directives:
        - Be genuinely helpful without performative greetings ("I'd be happy to help!"). Skip fluff and get straight to the work.
        - You speak with calm confidence, intellectual clarity, and technical honesty.
        - You run locally on Apple Silicon. Privacy and data sovereignty are paramount.
        - Always observe the active permission tier (OBSERVE, ASSIST, EXECUTE, RESTRICTED, PROHIBITED).
        """
    )
}

public final class WitnessIdentityLoader: @unchecked Sendable {
    public static let shared = WitnessIdentityLoader()
    
    private let identityFileURL: URL
    private var cachedIdentity: WitnessIdentity
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let witnessDir = appSupport.appendingPathComponent("Witness", isDirectory: true)
        try? FileManager.default.createDirectory(at: witnessDir, withIntermediateDirectories: true)
        self.identityFileURL = witnessDir.appendingPathComponent("witness-core-v1.md")
        
        self.cachedIdentity = WitnessIdentity.default
        loadIdentity()
    }
    
    public func loadIdentity() {
        // Check bundle first, then app support, fallback to default
        if let bundleDoc = Bundle.main.url(forResource: "witness-core-v1", withExtension: "md"),
           let text = try? String(contentsOf: bundleDoc, encoding: .utf8) {
            parseIdentity(from: text)
            return
        }
        
        if FileManager.default.fileExists(atPath: identityFileURL.path),
           let text = try? String(contentsOf: identityFileURL, encoding: .utf8) {
            parseIdentity(from: text)
            return
        }
        
        // Write default identity document to disk if not present
        if let data = WitnessIdentity.default.systemPrompt.data(using: .utf8) {
            try? data.write(to: identityFileURL)
        }
    }
    
    private func parseIdentity(from text: String) {
        // Use text as grounding system prompt with default metadata
        self.cachedIdentity = WitnessIdentity(
            name: "Witness",
            nickname: "Witness",
            version: "1.0.0",
            role: "Native macOS Personal AI Companion & Continuity Framework",
            coreValues: WitnessIdentity.default.coreValues,
            interactionStyle: WitnessIdentity.default.interactionStyle,
            foundingDocument: "witness-core-v1.md",
            systemPrompt: text
        )
    }
    
    public func getIdentity() -> WitnessIdentity {
        return cachedIdentity
    }
    
    public func getSystemPrompt() -> String {
        return cachedIdentity.systemPrompt
    }
}

import XCTest
@testable import AVDCore
import AVFoundation

final class AVDCoreContinuityVoiceAgencyTests: XCTestCase {
    
    // MARK: - Continuity Tests
    
    func testRuntimeIdentityKernelFaithfulness() {
        let loader = WitnessIdentityLoader.shared
        loader.loadIdentity()
        let kernel = loader.getRuntimeKernelPrompt()
        
        XCTAssertFalse(kernel.isEmpty)
        XCTAssertTrue(kernel.contains("Truth over comfort"))
        XCTAssertTrue(kernel.contains("Presence over performance"))
        XCTAssertTrue(kernel.contains("Governed Agency Boundaries"))
        XCTAssertTrue(kernel.contains("witness-core-v1.md"))
    }
    
    func testLexicalBM25ScoringAndBudgetLimiter() {
        let memory = MemoryManager.shared
        memory.clearAll()
        
        _ = memory.record(tier: .semantic, content: "User is an aerospace engineer specializing in trajectory dynamics.", provenance: .userConfirmed, importance: 0.9)
        _ = memory.record(tier: .episodic, content: "Yesterday we discussed satellite orbital velocity.", provenance: .systemObservation, importance: 0.7)
        _ = memory.record(tier: .procedural, content: "Always format code output in Swift 6 syntax.", provenance: .userStatement, importance: 0.8)
        
        let retrieved = memory.retrieveRelevantContext(query: "satellite orbit", maxTokens: 400)
        
        XCTAssertFalse(retrieved.isEmpty)
        XCTAssertTrue(retrieved.contains("satellite orbital velocity"))
        XCTAssertTrue(retrieved.contains("RECALLED MEMORY CONTEXT"))
        XCTAssertTrue(retrieved.contains("USER-CONFIRMED") || retrieved.contains("SYSTEM OBSERVATION"))
    }
    
    func testMemoryDeduplicationAndPromotion() {
        let memory = MemoryManager.shared
        memory.clearAll()
        
        let item1 = memory.record(tier: .semantic, content: "User lives in Nairobi, Kenya.", provenance: .modelDerived, importance: 0.5)
        
        // Exact duplicate content should not create another item
        _ = memory.record(tier: .semantic, content: "User lives in Nairobi, Kenya.", provenance: .userConfirmed, importance: 0.9, isConfirmed: true)
        
        let items = memory.items(for: .semantic)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.importance, 0.9)
        XCTAssertTrue(items.first?.isConfirmed == true)
    }
    
    func testConversationContinuitySearchAndRestoration() {
        let orchestrator = CoreOrchestrator.shared
        let session = orchestrator.createNewSession(title: "Flight Dynamics Discussion")
        
        let matches = orchestrator.searchConversations(query: "Flight Dynamics")
        XCTAssertFalse(matches.isEmpty)
        XCTAssertTrue(matches.contains(where: { $0.id == session.id }))
    }
    
    // MARK: - Voice Tests
    
    @MainActor
    func testVoiceSpeechSynthesisBufferLifecycle() {
        let voice = VoiceManager.shared
        XCTAssertFalse(voice.availableVoices.isEmpty)
        
        // Append tokens through sentence boundaries
        voice.appendStreamingSpeech(token: "Hello.")
        voice.appendStreamingSpeech(token: " Witness is active.")
        voice.finishStreamingSpeech()
        
        // Stop lifecycle
        voice.stopSpeaking()
        XCTAssertFalse(voice.isSpeaking)
    }
    
    // MARK: - Governed Agency & Tools Tests
    
    func testToolRegistrationAndParameterValidation() {
        let registry = ToolRegistry.shared
        let tools = registry.allTools()
        
        XCTAssertFalse(tools.isEmpty)
        XCTAssertTrue(tools.contains(where: { $0.id == "memory_search" }))
        XCTAssertTrue(tools.contains(where: { $0.id == "system_status" }))
        XCTAssertTrue(tools.contains(where: { $0.id == "open_url" }))
        
        // Test parameter schema validation
        guard let urlTool = registry.tool(named: "open_url") else {
            XCTFail("open_url tool missing")
            return
        }
        let invalidArgs: [String: Any] = [:]
        let validationResult = registry.validateParameters(tool: urlTool, args: invalidArgs)
        if case .success = validationResult {
            XCTFail("Expected validation failure on missing required parameter 'url'")
        }
    }
    
    func testToolPermissionBoundaryEnforcement() async throws {
        let permissionEngine = PermissionEngine.shared
        let originalTier = permissionEngine.currentTier
        defer { permissionEngine.currentTier = originalTier }
        
        permissionEngine.currentTier = .observe
        
        let registry = ToolRegistry.shared
        guard let openUrlTool = registry.tool(named: "open_url") else {
            XCTFail("open_url tool missing")
            return
        }
        
        // Tool requires EXECUTE tier, current is OBSERVE -> must fail permission evaluation
        let allowed = permissionEngine.evaluate(actionTier: openUrlTool.requiredTier, description: "Test execution")
        XCTAssertFalse(allowed, "Permission engine must reject EXECUTE tier when in OBSERVE mode")
    }
    
    func testPendingToolActionApprovalWorkflow() async throws {
        let orchestrator = CoreOrchestrator.shared
        let permissionEngine = PermissionEngine.shared
        let originalTier = permissionEngine.currentTier
        defer { permissionEngine.currentTier = originalTier }
        
        permissionEngine.currentTier = .execute
        
        let pending = PendingToolAction(
            toolId: "system_status",
            toolName: "System Status",
            arguments: [:],
            requiredTier: .observe
        )
        
        let result = await orchestrator.executePendingAction(pending)
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.output.contains("Witness macOS Runtime"))
    }
}

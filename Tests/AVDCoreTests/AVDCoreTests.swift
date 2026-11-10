import XCTest
@testable import AVDCore

final class AVDCoreTests: XCTestCase {
    
    func testIdentityPersistence() {
        let loader = WitnessIdentityLoader()
        let identity = loader.getIdentity()
        XCTAssertEqual(identity.name, "Witness")
        XCTAssertFalse(identity.coreValues.isEmpty)
        XCTAssertFalse(identity.systemPrompt.isEmpty)
    }
    
    func testPermissionEnforcement() {
        let engine = PermissionEngine()
        
        // Test lockdown
        engine.currentTier = .prohibited
        XCTAssertFalse(engine.evaluate(actionTier: .assist, description: "Should fail in prohibited"))
        
        // Test Observe tier
        engine.currentTier = .observe
        XCTAssertTrue(engine.evaluate(actionTier: .observe, description: "Read-only inspection"))
        XCTAssertFalse(engine.evaluate(actionTier: .execute, description: "Cannot execute in observe tier"))
        
        // Test Assist tier
        engine.currentTier = .assist
        XCTAssertTrue(engine.evaluate(actionTier: .assist, description: "Assist operation"))
        XCTAssertFalse(engine.evaluate(actionTier: .restricted, description: "Restricted operation not permitted"))
    }
    
    func testMemoryTierSeparationAndPersistence() {
        let manager = MemoryManager()
        
        let initialCount = manager.allItems().count
        let working = manager.record(tier: .working, content: "Temporary scratchpad note")
        let semantic = manager.record(tier: .semantic, content: "Permanent fact: User prefers Swift")
        
        XCTAssertEqual(working.tier, .working)
        XCTAssertEqual(semantic.tier, .semantic)
        
        let items = manager.allItems()
        XCTAssertEqual(items.count, initialCount + 2)
        
        let context = manager.retrieveRelevantContext(limit: 5)
        XCTAssertTrue(context.contains("Permanent fact: User prefers Swift"))
    }
    
    func testModelRouterHealthAndOllamaIntegration() async {
        let router = ModelRouter.shared
        let healthResult = await router.checkHealth()
        
        switch healthResult {
        case .success(let info):
            print("Model Router Health Success: \(info)")
            XCTAssertFalse(info.isEmpty)
        case .failure(let err):
            XCTFail("Model Router should be reachable on localhost:11434: \(err)")
        }
    }
}

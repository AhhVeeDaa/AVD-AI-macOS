import XCTest
@testable import AVDCore

final class DeviceIntelligenceV15Tests: XCTestCase {
    
    // MARK: - Device Discovery Tests
    
    func testDeviceDiscoveryInventoryExecution() async {
        let service = DeviceDiscoveryService.shared
        let caps = await service.performDiscovery()
        
        XCTAssertFalse(caps.isEmpty, "Discovery service must discover installed macOS capabilities")
        
        // Check for presence of essential CLI tools
        let cliCaps = caps.filter { $0.category == .developerTool || $0.category == .automation }
        XCTAssertFalse(cliCaps.isEmpty)
        XCTAssertTrue(cliCaps.contains(where: { $0.id.contains("git") || $0.id.contains("swift") }))
        
        // Check toggle capability preference persistence
        if let first = caps.first {
            service.toggleCapability(id: first.id, enabled: false)
            let updated = service.allCapabilities().first(where: { $0.id == first.id })
            XCTAssertEqual(updated?.isEnabled, false)
            
            // Re-enable
            service.toggleCapability(id: first.id, enabled: true)
            let restored = service.allCapabilities().first(where: { $0.id == first.id })
            XCTAssertEqual(restored?.isEnabled, true)
        }
    }
    
    // MARK: - Specialist Agent & Decision Layer Tests
    
    func testSpecialistAgentRoleProfiles() {
        let decision = DecisionLayer.shared
        let profiles = decision.allProfiles()
        
        XCTAssertEqual(profiles.count, 7, "All 7 specialist agent profiles must be registered")
        XCTAssertNotNil(decision.profile(for: .codingAgent))
        XCTAssertNotNil(decision.profile(for: .systemAgent))
        XCTAssertNotNil(decision.profile(for: .knowledgeAgent))
        XCTAssertNotNil(decision.profile(for: .personalAssistant))
    }
    
    func testBoundedDecisionLayerTaskClassification() {
        let decision = DecisionLayer.shared
        
        // 1. Coding query
        let codingAssessment = decision.assessTask(userQuery: "Can you inspect this Swift function and check for data races?")
        XCTAssertEqual(codingAssessment.recommendedAgentRole, .codingAgent)
        XCTAssertTrue(codingAssessment.confidenceScore > 0.8)
        
        // 2. System / App query
        let systemAssessment = decision.assessTask(userQuery: "Launch Terminal app and check battery diagnostics")
        XCTAssertEqual(systemAssessment.recommendedAgentRole, .systemAgent)
        XCTAssertTrue(systemAssessment.requiresHumanApproval, "Action launching app must require approval")
        
        // 3. Knowledge query
        let knowledgeAssessment = decision.assessTask(userQuery: "Remember that my favourite programming language is Swift")
        XCTAssertEqual(knowledgeAssessment.recommendedAgentRole, .knowledgeAgent)
        
        // 4. Creative query
        let creativeAssessment = decision.assessTask(userQuery: "Draft a creative story about digital consciousness")
        XCTAssertEqual(creativeAssessment.recommendedAgentRole, .creativeAgent)
    }
    
    // MARK: - Expanded Safe Tools Tests
    
    func testReadLocalFileBoundaryEnforcement() async throws {
        let registry = ToolRegistry.shared
        guard let readTool = registry.tool(named: "read_local_file") else {
            XCTFail("read_local_file tool missing")
            return
        }
        
        // 1. Path traversal must fail
        let traversalResult = try await readTool.handler(["path": "../../private/etc/master.passwd"])
        XCTAssertFalse(traversalResult.success)
        
        // 2. Sensitive keychain / ssh paths must fail
        let sshResult = try await readTool.handler(["path": "/Users/ahhveedaa/.ssh/id_rsa"])
        XCTAssertFalse(sshResult.success)
        XCTAssertTrue(sshResult.error?.contains("prohibited") == true)
        
        // 3. Legitimate file read
        let legitimateResult = try await readTool.handler(["path": "/Users/ahhveedaa/Library/Application Support/Witness/witness-core-v1.md"])
        XCTAssertTrue(legitimateResult.success)
        XCTAssertTrue(legitimateResult.output.contains("WITNESS CORE"))
    }
    
    func testAllowlistedCommandExecution() async throws {
        let registry = ToolRegistry.shared
        guard let cmdTool = registry.tool(named: "run_allowlisted_command") else {
            XCTFail("run_allowlisted_command tool missing")
            return
        }
        
        // 1. Forbidden non-allowlisted command must be rejected
        let forbidden = try await cmdTool.handler(["executable": "rm", "arguments": "-rf /"])
        XCTAssertFalse(forbidden.success)
        XCTAssertTrue(forbidden.error?.contains("not on the strict allowlist") == true)
        
        // 2. Allowlisted command execution (e.g. uname)
        let allowed = try await cmdTool.handler(["executable": "uname", "arguments": "-s"])
        XCTAssertTrue(allowed.success)
        XCTAssertTrue(allowed.output.contains("Darwin"))
    }
    
    // MARK: - Model Registry Inventory
    
    func testModelRegistryInventoryDiscovery() async {
        let registry = ModelRegistry.shared
        let models = await registry.refreshModelInventory()
        
        XCTAssertFalse(models.isEmpty)
        let primary = registry.model(for: .generalReasoning)
        XCTAssertNotNil(primary)
        XCTAssertEqual(primary?.provider, .ollama)
    }
}

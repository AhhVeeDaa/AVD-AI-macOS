import XCTest
@testable import AVDCore

final class EndToEndOrchestratorTests: XCTestCase {
    
    final class TokenCollector: @unchecked Sendable {
        private let lock = NSLock()
        private var tokens: String = ""
        
        func append(_ str: String) {
            lock.lock()
            defer { lock.unlock() }
            tokens += str
        }
        
        func get() -> String {
            lock.lock()
            defer { lock.unlock() }
            return tokens
        }
    }
    
    func testEndToEndStreamingConversationAndMemory() async throws {
        let orchestrator = CoreOrchestrator.shared
        let memory = MemoryManager.shared
        
        let initialMemCount = memory.allItems().count
        let collector = TokenCollector()
        let expectation = XCTestExpectation(description: "Streaming response received")
        
        orchestrator.processUserMessage(
            text: "Hello Witness! Respond with just the word 'ACK'.",
            onToken: { token in
                collector.append(token)
            },
            onComplete: { result in
                switch result {
                case .success(let full):
                    print("Received response successfully: \(full)")
                    XCTAssertFalse(full.isEmpty)
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Orchestrator failed with error: \(error)")
                }
            }
        )
        
        await fulfillment(of: [expectation], timeout: 200.0)
        
        let collected = collector.get()
        XCTAssertFalse(collected.isEmpty)
        print("Live streamed response: \(collected)")
        
        // Verify conversation and memory recorded
        let postMemCount = memory.allItems().count
        XCTAssertGreaterThan(postMemCount, initialMemCount)
        
        let sessions = orchestrator.getSessions()
        XCTAssertFalse(sessions.isEmpty)
        let active = orchestrator.getActiveSession()
        XCTAssertNotNil(active)
        XCTAssertFalse(active!.messages.isEmpty)
    }
}

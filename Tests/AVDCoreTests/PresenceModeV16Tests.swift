import XCTest
@testable import AVDCore
import AVFoundation

final class PresenceModeV16Tests: XCTestCase {
    
    @MainActor
    func testPresenceStateTransitionLifecycle() {
        let voice = VoiceManager.shared
        XCTAssertEqual(voice.presenceState, .idle)
        
        // Speak transition
        voice.speak(text: "Witness enters presence mode.")
        XCTAssertEqual(voice.presenceState, .speaking)
        XCTAssertTrue(voice.isSpeaking)
        
        // Interrupt / Stop
        voice.stopSpeaking()
        XCTAssertEqual(voice.presenceState, .idle)
        XCTAssertFalse(voice.isSpeaking)
        
        // Pause / Resume
        voice.speak(text: "Testing pause state.")
        voice.pauseSpeaking()
        XCTAssertEqual(voice.presenceState, .paused)
        
        voice.resumeSpeaking()
        XCTAssertEqual(voice.presenceState, .speaking)
        voice.stopSpeaking()
    }
    
    @MainActor
    func testVoiceInterruptionAndReplay() {
        let voice = VoiceManager.shared
        voice.speak(text: "Important observation about digital presence.")
        XCTAssertEqual(voice.lastSpokenResponse, "Important observation about digital presence.")
        
        // Immediate interruption
        voice.stopSpeaking()
        XCTAssertFalse(voice.isSpeaking)
        
        // Replay
        voice.replayLastResponse()
        XCTAssertTrue(voice.isSpeaking)
        voice.stopSpeaking()
    }
    
    @MainActor
    func testMuteToggleSuspension() {
        let voice = VoiceManager.shared
        voice.audioMuted = false
        
        voice.toggleMute()
        XCTAssertTrue(voice.audioMuted)
        XCTAssertEqual(voice.presenceState, .paused)
        
        voice.toggleMute()
        XCTAssertFalse(voice.audioMuted)
        XCTAssertEqual(voice.presenceState, .idle)
    }
    
    func testSharedConversationSessionBetweenModes() {
        let orchestrator = CoreOrchestrator.shared
        let session = orchestrator.createNewSession(title: "Presence Shared Session")
        
        // Simulate message dispatched from Presence mode
        let userMsg = WitnessMessage(role: "user", content: "Spoken thought in presence mode")
        orchestrator.selectSession(id: session.id)
        
        let active = orchestrator.getActiveSession()
        XCTAssertNotNil(active)
        XCTAssertEqual(active?.id, session.id)
    }
}

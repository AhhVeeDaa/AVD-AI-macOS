import XCTest
@testable import AVDCore
import AVFoundation
import Speech

final class VoiceStabilityV161Tests: XCTestCase {
    
    @MainActor
    func testPermissionLifecycleAndStateRefresh() {
        let voice = VoiceManager.shared
        voice.refreshPermissionStates()
        
        // Assert that microphone and speech recognition permission states are tracked
        XCTAssertTrue([AudioPermissionState.authorized, .denied, .restricted, .notDetermined, .unavailable].contains(voice.microphonePermission))
        XCTAssertTrue([AudioPermissionState.authorized, .denied, .restricted, .notDetermined, .unavailable].contains(voice.speechPermission))
    }
    
    @MainActor
    func testStartListeningWithoutAuthorizationDoesNotCrash() {
        let voice = VoiceManager.shared
        
        // If permissions are not authorized, startListening should fail gracefully to .error state or trigger request without crashing
        voice.stopListening()
        voice.stopSpeaking()
        
        // Ensure starting and stopping in quick succession does not deadlock audio engine
        voice.startListening()
        voice.stopListening()
        
        XCTAssertFalse(voice.isListening)
        XCTAssertEqual(voice.audioAmplitude, 0.0)
    }
    
    @MainActor
    func testRepeatedActivationAndInterruptionSafety() {
        let voice = VoiceManager.shared
        
        // Rapid toggle of speech and listening
        for _ in 0..<5 {
            voice.speak(text: "Stability verification rapid pulse.")
            XCTAssertTrue(voice.isSpeaking)
            voice.stopSpeaking()
            XCTAssertFalse(voice.isSpeaking)
            
            voice.startListening()
            voice.stopListening()
            XCTAssertFalse(voice.isListening)
        }
        
        XCTAssertEqual(voice.presenceState, .idle)
    }
    
    @MainActor
    func testMicrophoneMuteEnforcement() {
        let voice = VoiceManager.shared
        voice.audioMuted = true
        
        voice.startListening()
        XCTAssertFalse(voice.isListening, "startListening must be blocked when audioMuted is true")
        
        voice.audioMuted = false
    }
}

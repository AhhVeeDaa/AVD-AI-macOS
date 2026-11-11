import Foundation
import AVFoundation
import Speech

public enum PresenceState: String, CaseIterable, Sendable {
    case idle = "PRESENT"
    case listening = "LISTENING"
    case contemplating = "CONTEMPLATING"
    case speaking = "SPEAKING"
    case error = "ERROR"
    case paused = "PAUSED"
}

public enum AudioPermissionState: String, CaseIterable, Sendable {
    case notDetermined = "Not Determined"
    case authorized = "Authorized"
    case denied = "Denied"
    case restricted = "Restricted"
    case unavailable = "Unavailable"
}

@MainActor
public final class VoiceManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    public static let shared = VoiceManager()
    
    // Presence Interaction State
    @Published public var presenceState: PresenceState = .idle
    @Published public var audioAmplitude: CGFloat = 0.0 // 0.0 to 1.0 real RMS amplitude
    @Published public var audioMuted: Bool = false
    
    // Synthesizer (Text-To-Speech)
    private let synthesizer = AVSpeechSynthesizer()
    @Published public var isSpeaking: Bool = false
    @Published public var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate
    @Published public var speechVolume: Float = 1.0
    @Published public var selectedVoiceIdentifier: String = ""
    @Published public var availableVoices: [AVSpeechSynthesisVoice] = []
    @Published public var lastSpokenResponse: String = ""
    
    // Speech Recognition & Microphone Permissions
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isAudioEngineRunning: Bool = false
    
    @Published public var isListening: Bool = false
    @Published public var transcribedText: String = ""
    @Published public var recognitionAvailable: Bool = false
    @Published public var microphonePermission: AudioPermissionState = .notDetermined
    @Published public var speechPermission: AudioPermissionState = .notDetermined
    @Published public var permissionStatus: String = "Not Determined"
    @Published public var permissionGuidanceMessage: String = ""
    
    // Sentence buffer for streaming speech
    private var pendingSpeechBuffer: String = ""
    
    override private init() {
        super.init()
        synthesizer.delegate = self
        self.availableVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.starts(with: "en") }
        if let defaultVoice = AVSpeechSynthesisVoice(language: "en-US") {
            self.selectedVoiceIdentifier = defaultVoice.identifier
        }
        self.recognitionAvailable = speechRecognizer?.isAvailable ?? false
        refreshPermissionStates()
    }
    
    public func refreshPermissionStates() {
        // 1. Check Speech Recognition Authorization
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechPermission = .authorized
        case .denied:
            speechPermission = .denied
        case .restricted:
            speechPermission = .restricted
        case .notDetermined:
            speechPermission = .notDetermined
        @unknown default:
            speechPermission = .unavailable
        }
        
        // 2. Check Microphone Authorization via AVCaptureDevice
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphonePermission = .authorized
        case .denied:
            microphonePermission = .denied
        case .restricted:
            microphonePermission = .restricted
        case .notDetermined:
            microphonePermission = .notDetermined
        @unknown default:
            microphonePermission = .unavailable
        }
        
        updatePermissionGuidance()
    }
    
    private func updatePermissionGuidance() {
        if microphonePermission == .authorized && speechPermission == .authorized {
            permissionStatus = "Authorized"
            permissionGuidanceMessage = ""
            recognitionAvailable = speechRecognizer?.isAvailable ?? false
        } else if microphonePermission == .denied || speechPermission == .denied {
            permissionStatus = "Denied"
            permissionGuidanceMessage = "Microphone or Speech Recognition was denied. Open System Settings → Privacy & Security → Microphone / Speech Recognition to enable Witness."
            recognitionAvailable = false
        } else if microphonePermission == .restricted || speechPermission == .restricted {
            permissionStatus = "Restricted"
            permissionGuidanceMessage = "Audio permissions are restricted by parental controls or device management."
            recognitionAvailable = false
        } else {
            permissionStatus = "Not Determined"
            permissionGuidanceMessage = "Click 'Enable Microphone & Speech' to grant local audio authorization."
            recognitionAvailable = false
        }
    }
    
    // MARK: - Speech Synthesis (Speaking)
    
    public func speak(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        stopSpeaking()
        
        lastSpokenResponse = text
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.volume = speechVolume
        if let voice = availableVoices.first(where: { $0.identifier == selectedVoiceIdentifier }) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        isSpeaking = true
        presenceState = .speaking
        synthesizer.speak(utterance)
    }
    
    public func replayLastResponse() {
        if !lastSpokenResponse.isEmpty {
            speak(text: lastSpokenResponse)
        }
    }
    
    public func appendStreamingSpeech(token: String) {
        pendingSpeechBuffer += token
        
        let sentenceDelimiters = CharacterSet(charactersIn: ".!?\n")
        if let range = pendingSpeechBuffer.rangeOfCharacter(from: sentenceDelimiters) {
            let sentence = String(pendingSpeechBuffer[...range.lowerBound])
            pendingSpeechBuffer = String(pendingSpeechBuffer[range.upperBound...])
            
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                lastSpokenResponse += (lastSpokenResponse.isEmpty ? "" : " ") + trimmed
                let utterance = AVSpeechUtterance(string: trimmed)
                utterance.rate = speechRate
                utterance.volume = speechVolume
                if let voice = availableVoices.first(where: { $0.identifier == selectedVoiceIdentifier }) {
                    utterance.voice = voice
                }
                isSpeaking = true
                presenceState = .speaking
                synthesizer.speak(utterance)
            }
        }
    }
    
    public func finishStreamingSpeech() {
        let remainder = pendingSpeechBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingSpeechBuffer = ""
        if !remainder.isEmpty {
            lastSpokenResponse += (lastSpokenResponse.isEmpty ? "" : " ") + remainder
            let utterance = AVSpeechUtterance(string: remainder)
            utterance.rate = speechRate
            utterance.volume = speechVolume
            if let voice = availableVoices.first(where: { $0.identifier == selectedVoiceIdentifier }) {
                utterance.voice = voice
            }
            synthesizer.speak(utterance)
        }
    }
    
    public func stopSpeaking() {
        pendingSpeechBuffer = ""
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        if presenceState == .speaking {
            presenceState = .idle
        }
        audioAmplitude = 0.0
    }
    
    public func pauseSpeaking() {
        if isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
            presenceState = .paused
        }
    }
    
    public func resumeSpeaking() {
        if presenceState == .paused {
            synthesizer.continueSpeaking()
            presenceState = .speaking
        }
    }
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            if self.presenceState == .speaking {
                self.presenceState = .idle
            }
            self.audioAmplitude = 0.0
        }
    }
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            if self.presenceState == .speaking {
                self.presenceState = .idle
            }
            self.audioAmplitude = 0.0
        }
    }
    
    // MARK: - Safe Permission Request Lifecycle
    
    public func requestPermissions(completion: (@Sendable @MainActor (Bool) -> Void)? = nil) {
        // Step 1: Request Microphone Access via AVCaptureDevice
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] micGranted in
            Task { @MainActor in
                guard let self = self else { return }
                self.microphonePermission = micGranted ? .authorized : .denied
                
                guard micGranted else {
                    self.updatePermissionGuidance()
                    completion?(false)
                    return
                }
                
                // Step 2: Request Speech Recognition Access
                SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
                    Task { @MainActor in
                        guard let self = self else { return }
                        switch authStatus {
                        case .authorized:
                            self.speechPermission = .authorized
                        case .denied:
                            self.speechPermission = .denied
                        case .restricted:
                            self.speechPermission = .restricted
                        case .notDetermined:
                            self.speechPermission = .notDetermined
                        @unknown default:
                            self.speechPermission = .unavailable
                        }
                        self.updatePermissionGuidance()
                        let fullyAuthorized = (self.microphonePermission == .authorized && self.speechPermission == .authorized)
                        completion?(fullyAuthorized)
                    }
                }
            }
        }
    }
    
    // MARK: - Speech Recognition (Listening & Safe Audio Engine Lifecycle)
    
    public func startListening() {
        // Prevent overlapping listening sessions or execution when muted
        guard !isListening, !audioMuted else { return }
        
        // Immediately halt any speaking before attempting to access audio input
        stopSpeaking()
        
        // Verify permissions before touching hardware to prevent TCC termination
        refreshPermissionStates()
        guard microphonePermission == .authorized && speechPermission == .authorized else {
            if microphonePermission == .notDetermined || speechPermission == .notDetermined {
                requestPermissions { [weak self] granted in
                    if granted {
                        self?.startListening()
                    }
                }
            } else {
                self.presenceState = .error
            }
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            self.permissionStatus = "Speech recognizer offline or unavailable"
            self.presenceState = .error
            return
        }
        
        cleanupAudioEngine()
        
        do {
            let node = audioEngine.inputNode
            let recordingFormat = node.outputFormat(forBus: 0)
            guard recordingFormat.sampleRate > 0 else {
                self.presenceState = .error
                return
            }
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            
            if speechRecognizer.supportsOnDeviceRecognition {
                recognitionRequest.requiresOnDeviceRecognition = true
            }
            recognitionRequest.shouldReportPartialResults = true
            
            transcribedText = ""
            isListening = true
            presenceState = .listening
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                Task { @MainActor in
                    if let result = result {
                        self.transcribedText = result.bestTranscription.formattedString
                    }
                    if error != nil || result?.isFinal == true {
                        self.stopListening()
                    }
                }
            }
            
            node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                guard let self = self else { return }
                self.recognitionRequest?.append(buffer)
                
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameLength = Int(buffer.frameLength)
                var sum: Float = 0.0
                for i in 0..<frameLength {
                    let sample = channelData[i]
                    sum += sample * sample
                }
                let rms = sqrt(sum / Float(max(1, frameLength)))
                let normalized = CGFloat(min(1.0, max(0.0, rms * 8.0)))
                
                Task { @MainActor in
                    self.audioAmplitude = normalized
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            isAudioEngineRunning = true
        } catch {
            cleanupAudioEngine()
            self.permissionStatus = "Audio engine error: \(error.localizedDescription)"
            self.presenceState = .error
        }
    }
    
    public func stopListening() {
        guard isListening else { return }
        cleanupAudioEngine()
        isListening = false
        audioAmplitude = 0.0
        if presenceState == .listening {
            presenceState = .idle
        }
    }
    
    private func cleanupAudioEngine() {
        if isAudioEngineRunning {
            audioEngine.stop()
            isAudioEngineRunning = false
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    public func toggleMute() {
        audioMuted.toggle()
        if audioMuted {
            stopListening()
            stopSpeaking()
            presenceState = .paused
        } else {
            if presenceState == .paused {
                presenceState = .idle
            }
        }
    }
}

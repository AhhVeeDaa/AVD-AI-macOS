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
    
    // Speech Recognition (Speech-To-Text)
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published public var isListening: Bool = false
    @Published public var transcribedText: String = ""
    @Published public var recognitionAvailable: Bool = false
    @Published public var permissionStatus: String = "Not Requested"
    
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
    
    /// Buffers streaming text and speaks completed sentences progressively
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
    
    // MARK: - Speech Recognition (Listening & Real Amplitude Tracking)
    
    public func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            Task { @MainActor in
                switch authStatus {
                case .authorized:
                    self.permissionStatus = "Authorized"
                    self.recognitionAvailable = true
                case .denied:
                    self.permissionStatus = "Microphone / Speech Denied"
                    self.recognitionAvailable = false
                    self.presenceState = .error
                case .restricted:
                    self.permissionStatus = "Restricted on this Mac"
                    self.recognitionAvailable = false
                    self.presenceState = .error
                case .notDetermined:
                    self.permissionStatus = "Not Determined"
                    self.recognitionAvailable = false
                @unknown default:
                    self.permissionStatus = "Unknown"
                }
            }
        }
    }
    
    public func startListening() {
        guard !isListening, !audioMuted else { return }
        stopSpeaking()
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            self.permissionStatus = "Speech recognizer offline or unavailable"
            self.presenceState = .error
            return
        }
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
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
        
        // Audio tap calculates real RMS amplitude for fluid visualizer reaction
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.recognitionRequest?.append(buffer)
            
            // Calculate Root Mean Square (RMS) amplitude
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            var sum: Float = 0.0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(max(1, frameLength)))
            // Scale and clamp between 0.0 and 1.0 with natural logarithmic curve
            let normalized = CGFloat(min(1.0, max(0.0, rms * 8.0)))
            
            Task { @MainActor in
                self.audioAmplitude = normalized
            }
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            stopListening()
            self.permissionStatus = "Audio engine error: \(error.localizedDescription)"
            self.presenceState = .error
        }
    }
    
    public func stopListening() {
        guard isListening else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
        audioAmplitude = 0.0
        if presenceState == .listening {
            presenceState = .idle
        }
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

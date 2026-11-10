import Foundation
import AVFoundation
import Speech

@MainActor
public final class VoiceManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    public static let shared = VoiceManager()
    
    // Synthesizer (Text-To-Speech)
    private let synthesizer = AVSpeechSynthesizer()
    @Published public var isSpeaking: Bool = false
    @Published public var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate
    @Published public var selectedVoiceIdentifier: String = ""
    @Published public var availableVoices: [AVSpeechSynthesisVoice] = []
    
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
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        if let voice = availableVoices.first(where: { $0.identifier == selectedVoiceIdentifier }) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    /// Buffers streaming text and speaks completed sentences progressively
    public func appendStreamingSpeech(token: String) {
        pendingSpeechBuffer += token
        
        // Check for natural sentence boundaries (. , ! ? \n)
        let sentenceDelimiters = CharacterSet(charactersIn: ".!?\n")
        if let range = pendingSpeechBuffer.rangeOfCharacter(from: sentenceDelimiters) {
            let sentence = String(pendingSpeechBuffer[...range.lowerBound])
            pendingSpeechBuffer = String(pendingSpeechBuffer[range.upperBound...])
            
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let utterance = AVSpeechUtterance(string: trimmed)
                utterance.rate = speechRate
                if let voice = availableVoices.first(where: { $0.identifier == selectedVoiceIdentifier }) {
                    utterance.voice = voice
                }
                isSpeaking = true
                synthesizer.speak(utterance)
            }
        }
    }
    
    public func finishStreamingSpeech() {
        let remainder = pendingSpeechBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingSpeechBuffer = ""
        if !remainder.isEmpty {
            let utterance = AVSpeechUtterance(string: remainder)
            utterance.rate = speechRate
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
    }
    
    public func pauseSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
        }
    }
    
    public func resumeSpeaking() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
    
    // MARK: - Speech Recognition (Listening & Push-To-Talk)
    
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
                case .restricted:
                    self.permissionStatus = "Restricted on this Mac"
                    self.recognitionAvailable = false
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
        guard !isListening else { return }
        stopSpeaking()
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            self.permissionStatus = "Speech recognizer offline or unavailable"
            return
        }
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        // Request on-device recognition if available
        if speechRecognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        recognitionRequest.shouldReportPartialResults = true
        
        transcribedText = ""
        isListening = true
        
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
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            stopListening()
            self.permissionStatus = "Audio engine error: \(error.localizedDescription)"
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
    }
}

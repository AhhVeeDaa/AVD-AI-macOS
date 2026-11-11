import SwiftUI
import AVDCore
import AVFoundation

struct PresenceView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.accessibilityReduceMotion) var isReduceMotion
    
    @State private var showTranscript: Bool = true
    @State private var isMuted: Bool = false
    
    var body: some View {
        ZStack {
            // Background Canvas
            WitnessTheme.bgDeep
                .ignoresSafeArea()
            
            // Atmospheric Ambient Radial Glow
            RadialGradient(
                colors: [
                    ambientAuraColor.opacity(0.12),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 550
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Top Bar
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(stateIndicatorColor)
                            .frame(width: 7, height: 7)
                        
                        Text(vm.voiceManager.presenceState.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(stateIndicatorColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(WitnessTheme.bgSurface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    // System Resource Health Pill
                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                            .font(.system(size: 10))
                        Text(vm.modelName)
                            .font(.system(size: 10, design: .monospaced))
                        Text("• 16GB Apple Silicon")
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(WitnessTheme.textMuted)
                    }
                    .foregroundColor(WitnessTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WitnessTheme.bgSurface)
                    .cornerRadius(8)
                    
                    // Return to Workspace Button
                    Button(action: {
                        vm.activeInteractionMode = .text
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "text.bubble.fill")
                            Text("TEXT WORKSPACE")
                        }
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(WitnessTheme.bgElevated)
                        .foregroundColor(WitnessTheme.textPrimary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("t", modifiers: [.command])
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                
                Spacer()
                
                // Central Luminous Geometric Core
                GeometricEnergyCoreView(
                    state: vm.voiceManager.presenceState,
                    amplitude: vm.voiceManager.audioAmplitude,
                    isReducedMotion: isReduceMotion
                )
                .frame(width: 320, height: 320)
                
                // State Subtitle & Invitation
                VStack(spacing: 6) {
                    Text(stateTitle)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundColor(WitnessTheme.textPrimary)
                    
                    Text(statePrompt)
                        .font(.system(size: 12.5))
                        .foregroundColor(WitnessTheme.textSecondary)
                }
                
                // Live Spoken Response / Transcription Window
                if showTranscript {
                    VStack(alignment: .leading, spacing: 6) {
                        if vm.voiceManager.isListening && !vm.voiceManager.transcribedText.isEmpty {
                            Text("YOU: \(vm.voiceManager.transcribedText)")
                                .font(.system(size: 12.5, design: .monospaced))
                                .foregroundColor(WitnessTheme.amberAccent)
                                .lineLimit(3)
                        } else if !vm.voiceManager.lastSpokenResponse.isEmpty {
                            Text("WITNESS: \(vm.voiceManager.lastSpokenResponse)")
                                .font(.system(size: 12.5))
                                .foregroundColor(WitnessTheme.textSecondary)
                                .lineSpacing(3)
                                .lineLimit(4)
                        } else if let lastMsg = vm.activeSession?.messages.last {
                            Text("\(lastMsg.role == "user" ? "YOU" : "WITNESS"): \(lastMsg.content)")
                                .font(.system(size: 12))
                                .foregroundColor(WitnessTheme.textMuted)
                                .lineLimit(3)
                        }
                    }
                    .frame(maxWidth: 580)
                    .padding(14)
                    .background(WitnessTheme.bgSurface.opacity(0.85))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                    )
                }
                
                Spacer()
                
                // Primary Voice Controls Surface
                HStack(spacing: 20) {
                    // Mute / Unmute
                    Button(action: {
                        vm.voiceManager.toggleMute()
                    }) {
                        Image(systemName: vm.voiceManager.audioMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 15))
                            .foregroundColor(vm.voiceManager.audioMuted ? WitnessTheme.redAlert : WitnessTheme.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(WitnessTheme.bgSurface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(WitnessTheme.borderSubtle, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .help("Mute Audio")
                    
                    // Main Push-To-Talk / Interrupt Trigger
                    Button(action: handlePrimaryVoiceAction) {
                        ZStack {
                            Circle()
                                .fill(primaryButtonColor)
                                .frame(width: 64, height: 64)
                                .shadow(color: primaryButtonColor.opacity(0.4), radius: 14)
                            
                            Image(systemName: primaryButtonIcon)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(WitnessTheme.bgDeep)
                        }
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.space, modifiers: [])
                    
                    // Replay Last Response
                    Button(action: {
                        vm.voiceManager.replayLastResponse()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 15))
                            .foregroundColor(WitnessTheme.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(WitnessTheme.bgSurface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(WitnessTheme.borderSubtle, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.voiceManager.lastSpokenResponse.isEmpty)
                    .help("Replay Last Response")
                }
                .padding(.bottom, 28)
            }
        }
    }
    
    private func handlePrimaryVoiceAction() {
        if vm.voiceManager.isSpeaking {
            // Interrupt speech immediately
            vm.voiceManager.stopSpeaking()
        } else if vm.voiceManager.isListening {
            // Finish listening and dispatch query to shared conversation
            let transcribed = vm.voiceManager.transcribedText
            vm.voiceManager.stopListening()
            if !transcribed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                vm.voiceManager.presenceState = .contemplating
                vm.sendMessage(transcribed)
            }
        } else {
            // Start listening
            vm.voiceManager.requestPermissions()
            vm.voiceManager.startListening()
        }
    }
    
    private var primaryButtonIcon: String {
        if vm.voiceManager.isSpeaking {
            return "hand.raised.fill"
        } else if vm.voiceManager.isListening {
            return "stop.fill"
        } else {
            return "waveform"
        }
    }
    
    private var primaryButtonColor: Color {
        if vm.voiceManager.isSpeaking {
            return WitnessTheme.amberAccent
        } else if vm.voiceManager.isListening {
            return WitnessTheme.redAlert
        } else {
            return WitnessTheme.cyanAccent
        }
    }
    
    private var stateTitle: String {
        switch vm.voiceManager.presenceState {
        case .idle: return "Witness is Present"
        case .listening: return "Listening..."
        case .contemplating: return "Witness is Contemplating"
        case .speaking: return "Speaking..."
        case .error: return "Connection or Audio Interrupted"
        case .paused: return "Presence Suspended"
        }
    }
    
    private var statePrompt: String {
        switch vm.voiceManager.presenceState {
        case .idle: return "Tap the wave button or press Space to speak"
        case .listening: return "Speak clearly into your microphone"
        case .contemplating: return "Formulating thoughtful response locally"
        case .speaking: return "Tap the raised hand button to interrupt"
        case .error: return "Check microphone permissions or local Ollama status"
        case .paused: return "Microphone is muted"
        }
    }
    
    private var stateIndicatorColor: Color {
        switch vm.voiceManager.presenceState {
        case .idle: return WitnessTheme.cyanAccent
        case .listening: return WitnessTheme.amberAccent
        case .contemplating: return WitnessTheme.purpleMemory
        case .speaking: return WitnessTheme.cyanAccent
        case .error: return WitnessTheme.redAlert
        case .paused: return WitnessTheme.textMuted
        }
    }
    
    private var ambientAuraColor: Color {
        stateIndicatorColor
    }
}

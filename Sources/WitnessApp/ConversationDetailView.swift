import SwiftUI
import AVDCore

struct ConversationDetailView: View {
    @ObservedObject var vm: AppViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Refined Top Bar
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.activeSession?.title ?? "Continuity Session")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(WitnessTheme.textPrimary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(WitnessTheme.cyanAccent)
                            .frame(width: 5, height: 5)
                        Text("LOCAL ACTIVE")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(WitnessTheme.cyanAccent)
                        
                        Text("•")
                            .foregroundColor(WitnessTheme.textMuted)
                        
                        Text("OFFLINE ONLY")
                            .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                            .foregroundColor(WitnessTheme.textMuted)
                    }
                }
                
                Spacer()
                
                // Voice Readback Toggle
                Button(action: {
                    vm.voiceEnabled.toggle()
                    if !vm.voiceEnabled {
                        vm.voiceManager.stopSpeaking()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: vm.voiceEnabled ? "speaker.wave.2.fill" : "speaker.slash")
                            .font(.system(size: 11))
                        Text(vm.voiceEnabled ? "VOICE ON" : "VOICE OFF")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(vm.voiceEnabled ? WitnessTheme.cyanAccent.opacity(0.15) : WitnessTheme.bgSurface)
                    .foregroundColor(vm.voiceEnabled ? WitnessTheme.cyanAccent : WitnessTheme.textMuted)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(vm.voiceEnabled ? WitnessTheme.cyanAccent.opacity(0.3) : WitnessTheme.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Immersive Voice & Energy Orb Mode Button
                Button(action: {
                    vm.activeInteractionMode = .presence
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("VOICE ORB MODE")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [WitnessTheme.cyanAccent.opacity(0.25), WitnessTheme.cyanAccent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(WitnessTheme.cyanAccent)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(WitnessTheme.cyanAccent.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: WitnessTheme.cyanAccent.opacity(0.2), radius: 4, x: 0, y: 0)
                }
                .buttonStyle(.plain)
                .help("Switch to Immersive Voice & Energy Core Orb Mode (Cmd+P)")
                
                // Clear / New Session
                Button(action: { vm.createNewSession() }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 13))
                        .foregroundColor(WitnessTheme.textSecondary)
                        .padding(6)
                        .background(WitnessTheme.bgSurface)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("New Conversation (Cmd+N)")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(WitnessTheme.bgDeep)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(WitnessTheme.borderSubtle),
                alignment: .bottom
            )
            
            // Governed Agency Approval Card (if tool action pending)
            if let pending = vm.pendingToolAction {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundColor(WitnessTheme.amberAccent)
                        Text("TOOL AUTHORIZATION REQUIRED")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(WitnessTheme.amberAccent)
                        Spacer()
                        Text("TIER: \(pending.requiredTier.rawValue)")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(WitnessTheme.amberAccent.opacity(0.2))
                            .foregroundColor(WitnessTheme.amberAccent)
                            .cornerRadius(4)
                    }
                    
                    Text("Witness proposes invoking tool: **\(pending.toolName)** (`\(pending.toolId)`)")
                        .font(.system(size: 12))
                        .foregroundColor(WitnessTheme.textPrimary)
                    
                    Text(pending.argumentsDisplay)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(WitnessTheme.textSecondary)
                        .padding(8)
                        .background(WitnessTheme.bgDeep)
                        .cornerRadius(6)
                    
                    HStack(spacing: 12) {
                        Button("Approve Action") {
                            vm.approvePendingAction()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(WitnessTheme.emeraldSignal)
                        
                        Button("Reject") {
                            vm.rejectPendingAction()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(14)
                .background(WitnessTheme.bgSurface)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(WitnessTheme.amberAccent.opacity(0.4), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            
            // Message Scroll Surface
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if let session = vm.activeSession, session.messages.isEmpty && !vm.isStreaming {
                            emptyAwakeningState
                        } else {
                            ForEach(vm.activeSession?.messages ?? []) { msg in
                                MessageBubbleView(message: msg)
                                    .id(msg.id)
                            }
                            
                            // Live Streaming Bubble
                            if vm.isStreaming {
                                StreamingBubbleView(
                                    currentText: vm.currentStreamingText,
                                    status: vm.statusMessage
                                )
                                .id("streaming_indicator")
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .onChange(of: vm.currentStreamingText) { _ in
                    proxy.scrollTo("streaming_indicator", anchor: .bottom)
                }
                .onChange(of: vm.activeSession?.messages.count) { _ in
                    if let lastId = vm.activeSession?.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .background(WitnessTheme.bgDeep)
            
            // Microphone Voice Bar (if listening)
            if vm.voiceManager.isListening {
                HStack(spacing: 10) {
                    Circle()
                        .fill(WitnessTheme.redAlert)
                        .frame(width: 8, height: 8)
                    Text("Listening... (Speak naturally into microphone)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(WitnessTheme.textPrimary)
                    
                    Spacer()
                    
                    Button("Done Listening") {
                        inputText = vm.voiceManager.transcribedText
                        vm.voiceManager.stopListening()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(WitnessTheme.redAlert.opacity(0.12))
            }
            
            // Bottom Command Surface
            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: 10) {
                    // Push-to-Talk Mic Button
                    Button(action: {
                        if vm.voiceManager.isListening {
                            inputText = vm.voiceManager.transcribedText
                            vm.voiceManager.stopListening()
                        } else {
                            vm.voiceManager.requestPermissions()
                            vm.voiceManager.startListening()
                        }
                    }) {
                        Image(systemName: vm.voiceManager.isListening ? "mic.fill" : "mic")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(vm.voiceManager.isListening ? WitnessTheme.redAlert : WitnessTheme.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(vm.voiceManager.isListening ? WitnessTheme.redAlert.opacity(0.15) : WitnessTheme.bgElevated)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Push-to-Talk Voice Input")
                    
                    // Input Text Editor
                    ZStack(alignment: .topLeading) {
                        if inputText.isEmpty {
                            Text("Witness awaits your instruction...")
                                .font(.system(size: 13))
                                .foregroundColor(WitnessTheme.textMuted)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        
                        TextEditor(text: $inputText)
                            .font(.system(size: 13))
                            .foregroundColor(WitnessTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .focused($isInputFocused)
                            .frame(minHeight: 36, maxHeight: 110)
                    }
                    
                    // Send Button
                    Button(action: triggerSend) {
                        ZStack {
                            Circle()
                                .fill(canSend ? WitnessTheme.cyanAccent : WitnessTheme.bgElevated)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(canSend ? WitnessTheme.bgDeep : WitnessTheme.textMuted)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend)
                    .keyboardShortcut(.return, modifiers: [.command])
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(WitnessTheme.bgCommand)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isInputFocused ? WitnessTheme.borderFocus : WitnessTheme.borderSubtle, lineWidth: 1)
                )
                
                HStack {
                    Text("⌘ + Return to dispatch")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(WitnessTheme.textMuted)
                    Spacer()
                    if vm.voiceManager.isSpeaking {
                        Button("Stop Voice") {
                            vm.voiceManager.stopSpeaking()
                        }
                        .font(.system(size: 10))
                        .foregroundColor(WitnessTheme.amberAccent)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 6)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(WitnessTheme.bgDeep)
        }
    }
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !vm.isStreaming
    }
    
    private func triggerSend() {
        guard canSend else { return }
        let text = inputText
        inputText = ""
        vm.sendMessage(text)
    }
    
    private var emptyAwakeningState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 30)
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [WitnessTheme.cyanAccent.opacity(0.18), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "hexagon.fill")
                    .font(.system(size: 42))
                    .foregroundColor(WitnessTheme.cyanAccent)
            }
            
            VStack(spacing: 6) {
                Text("Witness Awakened")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(WitnessTheme.textPrimary)
                
                Text("Continuity • Memory • Voice • Governed Agency")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(WitnessTheme.textSecondary)
            }
            
            // Suggestion Chips
            HStack(spacing: 10) {
                promptChip(title: "Witness, wake up")
                promptChip(title: "Check system status")
                promptChip(title: "Search stored memories")
            }
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    private func promptChip(title: String) -> some View {
        Button(action: {
            inputText = title
            triggerSend()
        }) {
            Text(title)
                .font(.system(size: 11.5, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(WitnessTheme.bgSurface)
                .foregroundColor(WitnessTheme.textPrimary)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct MessageBubbleView: View {
    let message: WitnessMessage
    
    private var isUser: Bool { message.role == "user" }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isUser { Spacer(minLength: 60) }
            
            if !isUser {
                ZStack {
                    Circle()
                        .fill(WitnessTheme.cyanAccent.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 12))
                        .foregroundColor(WitnessTheme.cyanAccent)
                }
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(isUser ? "YOU" : "WITNESS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isUser ? WitnessTheme.amberAccent : WitnessTheme.cyanAccent)
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 9.5))
                        .foregroundColor(WitnessTheme.textMuted)
                }
                
                Text(message.content)
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .foregroundColor(WitnessTheme.textPrimary)
                    .textSelection(.enabled)
                    .padding(14)
                    .background(isUser ? WitnessTheme.bgElevated : WitnessTheme.bgSurface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isUser ? WitnessTheme.amberAccent.opacity(0.2) : WitnessTheme.borderSubtle, lineWidth: 1)
                    )
            }
            
            if isUser {
                ZStack {
                    Circle()
                        .fill(WitnessTheme.amberAccent.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "person.fill")
                        .font(.system(size: 12))
                        .foregroundColor(WitnessTheme.amberAccent)
                }
            }
            
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

struct StreamingBubbleView: View {
    let currentText: String
    let status: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(WitnessTheme.cyanAccent.opacity(0.2))
                    .frame(width: 28, height: 28)
                ProgressView()
                    .scaleEffect(0.6)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("WITNESS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(WitnessTheme.cyanAccent)
                    
                    Text(status.isEmpty ? "contemplating..." : status)
                        .font(.system(size: 10))
                        .foregroundColor(WitnessTheme.textMuted)
                }
                
                if !currentText.isEmpty {
                    Text(currentText)
                        .font(.system(size: 13))
                        .lineSpacing(4)
                        .foregroundColor(WitnessTheme.textPrimary)
                        .textSelection(.enabled)
                        .padding(14)
                        .background(WitnessTheme.bgSurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(WitnessTheme.cyanAccent.opacity(0.4), lineWidth: 1)
                        )
                }
            }
            
            Spacer(minLength: 60)
        }
    }
}

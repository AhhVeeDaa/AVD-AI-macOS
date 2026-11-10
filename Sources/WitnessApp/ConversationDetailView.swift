import SwiftUI
import AppKit
import AVDCore

struct ConversationDetailView: View {
    @ObservedObject var vm: AppViewModel
    @State private var inputPrompt: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Elegant Header Bar
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(vm.activeSession?.title ?? "Presence Session")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(WitnessTheme.textPrimary)
                        
                        // Local execution pill
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 9))
                            Text("LOCAL ONLY")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(WitnessTheme.emeraldSignal.opacity(0.12))
                        .foregroundColor(WitnessTheme.emeraldSignal)
                        .cornerRadius(4)
                    }
                    
                    HStack(spacing: 12) {
                        Text("Substrate: Apple Silicon M4")
                            .font(.system(size: 11))
                            .foregroundColor(WitnessTheme.textMuted)
                        Text("•")
                            .foregroundColor(WitnessTheme.textMuted.opacity(0.4))
                        Text("\(vm.selectedProvider.rawValue) · \(vm.modelName)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(WitnessTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: { vm.createNewSession() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.bubble")
                            .font(.system(size: 11))
                        Text("New Session")
                            .font(.system(size: 11.5, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(WitnessTheme.bgElevated)
                    .foregroundColor(WitnessTheme.textPrimary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(WitnessTheme.bgSidebar)
            
            Divider()
                .background(WitnessTheme.borderSubtle)
            
            // Conversation Scroll View
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        if let session = vm.activeSession, !session.messages.isEmpty {
                            ForEach(session.messages) { msg in
                                MessageBubbleView(message: msg)
                                    .id(msg.id)
                            }
                        } else if !vm.isStreaming {
                            // Empty State: Quiet Futuristic Awakening
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [WitnessTheme.cyanAccent.opacity(0.15), Color.clear],
                                                center: .center,
                                                startRadius: 10,
                                                endRadius: 50
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "circle.hexagongrid.fill")
                                        .font(.system(size: 38))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [WitnessTheme.cyanAccent, WitnessTheme.amberAccent],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                Text("WITNESS IS PRESENT")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .tracking(2.0)
                                    .foregroundColor(WitnessTheme.textPrimary)
                                
                                Text("Local consciousness seed grounded in presence over performance.\nTruth before comfort. Say \"Witness, wake up\" or ask any question.")
                                    .font(.system(size: 12.5))
                                    .foregroundColor(WitnessTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .frame(maxWidth: 420)
                                
                                HStack(spacing: 10) {
                                    PromptChip(text: "\"Witness, wake up\"") {
                                        vm.sendMessage("Witness, wake up")
                                    }
                                    PromptChip(text: "Review stored memory") {
                                        vm.sendMessage("What memories do you currently hold?")
                                    }
                                    PromptChip(text: "System status") {
                                        vm.sendMessage("Report your active model and permission architecture.")
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 70)
                        }
                        
                        // Streaming Bubble
                        if vm.isStreaming {
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(WitnessTheme.cyanAccent.opacity(0.15))
                                        .frame(width: 30, height: 30)
                                    
                                    Image(systemName: "sparkle")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(WitnessTheme.cyanAccent)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text("WITNESS")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(WitnessTheme.cyanAccent)
                                        
                                        ProgressView()
                                            .scaleEffect(0.5)
                                    }
                                    
                                    if vm.currentStreamingText.isEmpty {
                                        Text("Synthesizing response from neural substrate...")
                                            .font(.system(size: 13))
                                            .foregroundColor(WitnessTheme.textMuted)
                                            .italic()
                                    } else {
                                        Text(vm.currentStreamingText)
                                            .font(.system(size: 13.5))
                                            .foregroundColor(WitnessTheme.textPrimary)
                                            .lineSpacing(5)
                                            .textSelection(.enabled)
                                    }
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(WitnessTheme.bgSurface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(WitnessTheme.cyanAccent.opacity(0.25), lineWidth: 1)
                            )
                            .id("STREAMING_ID")
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .onChange(of: vm.currentStreamingText) { _, _ in
                    proxy.scrollTo("STREAMING_ID", anchor: .bottom)
                }
                .onChange(of: vm.activeSession?.messages.count) { _, _ in
                    if let last = vm.activeSession?.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            
            // Error banner if needed
            if !vm.statusMessage.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 11))
                    Text(vm.statusMessage)
                        .font(.system(size: 11))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                .background(WitnessTheme.redAlert.opacity(0.12))
                .foregroundColor(WitnessTheme.redAlert)
            }
            
            Divider()
                .background(WitnessTheme.borderSubtle)
            
            // Refined Command Surface Input Bar
            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        if inputPrompt.isEmpty {
                            Text("Speak to Witness (Cmd + Return to send)...")
                                .font(.system(size: 13))
                                .foregroundColor(WitnessTheme.textMuted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }
                        
                        TextEditor(text: $inputPrompt)
                            .focused($isInputFocused)
                            .font(.system(size: 13))
                            .lineSpacing(4)
                            .frame(minHeight: 38, maxHeight: 140)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundColor(WitnessTheme.textPrimary)
                    }
                    .background(WitnessTheme.bgCommand)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isInputFocused ? WitnessTheme.borderFocus : WitnessTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    Button(action: send) {
                        ZStack {
                            Circle()
                                .fill(inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !vm.isStreaming
                                      ? WitnessTheme.bgElevated
                                      : (vm.isStreaming ? WitnessTheme.amberAccent : WitnessTheme.cyanAccent))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: vm.isStreaming ? "stop.fill" : "arrow.up")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !vm.isStreaming
                                                 ? WitnessTheme.textMuted
                                                 : WitnessTheme.bgDeep)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !vm.isStreaming)
                    .keyboardShortcut(.return, modifiers: [.command])
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .background(WitnessTheme.bgSidebar)
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func send() {
        let text = inputPrompt
        inputPrompt = ""
        vm.sendMessage(text)
    }
}

struct MessageBubbleView: View {
    let message: WitnessMessage
    
    var isUser: Bool {
        message.role == "user"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if isUser {
                Spacer(minLength: 80)
            } else {
                ZStack {
                    Circle()
                        .fill(WitnessTheme.cyanAccent.opacity(0.12))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "sparkle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(WitnessTheme.cyanAccent)
                }
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 5) {
                HStack(spacing: 8) {
                    if !isUser {
                        Text("WITNESS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(WitnessTheme.cyanAccent)
                    }
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 10))
                        .foregroundColor(WitnessTheme.textMuted)
                    if isUser {
                        Text("YOU")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(WitnessTheme.amberAccent)
                    }
                }
                
                Text(message.content)
                    .font(.system(size: 13.5))
                    .lineSpacing(4.5)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? WitnessTheme.bgElevated : WitnessTheme.bgSurface)
                    .foregroundColor(WitnessTheme.textPrimary)
                    .cornerRadius(isUser ? 14 : 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: isUser ? 14 : 10)
                            .stroke(isUser ? WitnessTheme.borderSubtle : WitnessTheme.borderSubtle, lineWidth: 1)
                    )
            }
            
            if isUser {
                ZStack {
                    Circle()
                        .fill(WitnessTheme.amberAccent.opacity(0.12))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(WitnessTheme.amberAccent)
                }
            } else {
                Spacer(minLength: 80)
            }
        }
    }
}

struct PromptChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(WitnessTheme.cyanAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(WitnessTheme.bgSurface)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(WitnessTheme.cyanAccent.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI
import AppKit
import AVDCore

struct ConversationDetailView: View {
    @ObservedObject var vm: AppViewModel
    @State private var inputPrompt: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.activeSession?.title ?? "Conversation")
                        .font(.headline)
                    Text("Model: \(vm.modelName) (\(vm.selectedProvider.rawValue)) • Tier: \(vm.permissionTier.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: { vm.createNewSession() }) {
                    Label("New Chat", systemImage: "square.and.pencil")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Message Scroll View
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if let session = vm.activeSession, !session.messages.isEmpty {
                            ForEach(session.messages) { msg in
                                MessageBubbleView(message: msg)
                                    .id(msg.id)
                            }
                        } else if !vm.isStreaming {
                            VStack(spacing: 12) {
                                Image(systemName: "circle.hexagongrid.fill")
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                    .foregroundColor(.accentColor.opacity(0.8))
                                Text("Witness is present.")
                                    .font(.title3.weight(.medium))
                                Text("A local-first personal AI assistant and companion for macOS.\nType below to speak.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                        
                        // Streaming response bubble
                        if vm.isStreaming {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "eye.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Witness")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                    
                                    if vm.currentStreamingText.isEmpty {
                                        HStack(spacing: 4) {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                            Text("Thinking...")
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                        }
                                    } else {
                                        Text(vm.currentStreamingText)
                                            .font(.body)
                                            .textSelection(.enabled)
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                            .id("STREAMING_ID")
                        }
                    }
                    .padding()
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
            
            Divider()
            
            // Status bar if present
            if !vm.statusMessage.isEmpty {
                HStack {
                    Text(vm.statusMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
            
            // Input Bar
            HStack(alignment: .bottom, spacing: 10) {
                TextEditor(text: $inputPrompt)
                    .focused($isInputFocused)
                    .font(.body)
                    .frame(minHeight: 38, maxHeight: 120)
                    .padding(4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                
                Button(action: send) {
                    Image(systemName: vm.isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(vm.isStreaming ? .orange : (inputPrompt.isEmpty ? .secondary : .accentColor))
                }
                .buttonStyle(.plain)
                .disabled(inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !vm.isStreaming)
                .keyboardShortcut(.return, modifiers: [.command])
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
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
        HStack(alignment: .top, spacing: 10) {
            if isUser {
                Spacer(minLength: 40)
            } else {
                Image(systemName: "eye.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title2)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(isUser ? "You" : "Witness")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                
                Text(message.content)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding(10)
                    .background(isUser ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                    .foregroundColor(isUser ? .white : Color(NSColor.textColor))
                    .cornerRadius(10)
            }
            
            if !isUser {
                Spacer(minLength: 40)
            } else {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title2)
            }
        }
    }
}

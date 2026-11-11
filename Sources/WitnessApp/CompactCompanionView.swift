import SwiftUI
import AppKit
import AVDCore

struct CompactCompanionView: View {
    @ObservedObject var vm: AppViewModel
    @State private var quickPrompt: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            // Header Bar
            HStack(spacing: 8) {
                WitnessKanjiMark(size: 16, glowColor: WitnessTheme.cyanAccent)
                
                ZStack {
                    Circle()
                        .fill(vm.isConnected ? WitnessTheme.emeraldSignal.opacity(0.2) : WitnessTheme.amberAccent.opacity(0.2))
                        .frame(width: 14, height: 14)
                    
                    Circle()
                        .fill(vm.isConnected ? WitnessTheme.emeraldSignal : WitnessTheme.amberAccent)
                        .frame(width: 6, height: 6)
                }
                
                Text("WITNESS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(WitnessTheme.textPrimary)
                
                Spacer()
                
                Text(vm.permissionTier.rawValue)
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(WitnessTheme.bgElevated)
                    .foregroundColor(WitnessTheme.amberAccent)
                    .cornerRadius(4)
            }
            
            // Streaming response or last message
            if vm.isStreaming {
                ScrollView {
                    Text(vm.currentStreamingText.isEmpty ? "Witness is contemplating..." : vm.currentStreamingText)
                        .font(.system(size: 11.5))
                        .foregroundColor(WitnessTheme.textPrimary)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 80)
                .padding(8)
                .background(WitnessTheme.bgDeep)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(WitnessTheme.cyanAccent.opacity(0.3), lineWidth: 1)
                )
            } else if let last = vm.activeSession?.messages.last {
                VStack(alignment: .leading, spacing: 3) {
                    Text(last.role == "user" ? "YOU:" : "WITNESS:")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(last.role == "user" ? WitnessTheme.amberAccent : WitnessTheme.cyanAccent)
                    Text(last.content)
                        .font(.system(size: 11.5))
                        .foregroundColor(WitnessTheme.textSecondary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(WitnessTheme.bgDeep)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                )
            } else {
                Text("Presence active. Ask Witness anything.")
                    .font(.system(size: 11))
                    .foregroundColor(WitnessTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            
            // Quick Command Surface
            HStack(spacing: 8) {
                TextField("Speak to Witness...", text: $quickPrompt)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(7)
                    .background(WitnessTheme.bgDeep)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                    )
                    .onSubmit {
                        submit()
                    }
                
                Button(action: submit) {
                    Image(systemName: vm.isStreaming ? "stop.fill" : "arrow.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(WitnessTheme.bgDeep)
                        .frame(width: 26, height: 26)
                        .background(quickPrompt.isEmpty && !vm.isStreaming ? WitnessTheme.textMuted : WitnessTheme.cyanAccent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(quickPrompt.isEmpty && !vm.isStreaming)
            }
        }
        .padding(14)
        .frame(width: 320)
        .background(WitnessTheme.bgSurface)
    }
    
    private func submit() {
        let text = quickPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        quickPrompt = ""
        vm.sendMessage(text)
    }
}

import SwiftUI
import AppKit
import AVDCore

struct CompactCompanionView: View {
    @ObservedObject var vm: AppViewModel
    @State private var quickPrompt: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Circle()
                    .fill(vm.isConnected ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text("Witness Companion")
                    .font(.caption.bold())
                Spacer()
                Text(vm.permissionTier.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            
            // Recent Exchange or Streaming status
            if vm.isStreaming {
                ScrollView {
                    Text(vm.currentStreamingText.isEmpty ? "Witness is thinking..." : vm.currentStreamingText)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 70)
                .padding(6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            } else if let last = vm.activeSession?.messages.last {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(last.role.capitalized):")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                    Text(last.content)
                        .font(.caption)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            
            // Quick input
            HStack(spacing: 6) {
                TextField("Ask Witness...", text: $quickPrompt)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        submit()
                    }
                
                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill")
                }
                .buttonStyle(.plain)
                .disabled(quickPrompt.isEmpty || vm.isStreaming)
            }
        }
        .padding(10)
        .frame(width: 320)
    }
    
    private func submit() {
        let text = quickPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        quickPrompt = ""
        vm.sendMessage(text)
    }
}

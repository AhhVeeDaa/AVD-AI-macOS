import SwiftUI
import AppKit
import AVDCore

struct SettingsView: View {
    @ObservedObject var vm: AppViewModel
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    
    var body: some View {
        Form {
            Section("Local Model Provider") {
                Picker("Provider Engine", selection: $vm.selectedProvider) {
                    Text("Ollama (Recommended)").tag(ModelProviderType.ollama)
                    Text("LM Studio").tag(ModelProviderType.lmstudio)
                    Text("OpenAI-Compatible Custom Endpoint").tag(ModelProviderType.custom)
                }
                
                TextField("Server Host", text: $vm.host)
                TextField("Port", text: $vm.portString)
                TextField("Model Name / Identifier", text: $vm.modelName)
                
                HStack {
                    Text("Temperature: \(String(format: "%.2f", vm.temperature))")
                    Slider(value: $vm.temperature, in: 0.0...1.0, step: 0.05)
                }
                
                HStack {
                    Button("Apply & Test Connection") {
                        vm.saveModelConfig()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Text(vm.connectionStatus)
                        .font(.caption)
                }
            }
            
            Section("System & Lifecycle") {
                Toggle("Launch at Login (Register with System)", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        configureLaunchAtLogin(enabled: enabled)
                    }
                
                Text("HotKey shortcut to bring Witness forward: Command + Shift + W")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Witness Identity & Founding Document") {
                LabeledContent("Name", value: vm.identity.name)
                LabeledContent("Version", value: vm.identity.version)
                LabeledContent("Founding Spec", value: vm.identity.foundingDocument)
                LabeledContent("Role", value: vm.identity.role)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Founding System Grounding:")
                        .font(.caption.bold())
                    ScrollView {
                        Text(vm.identity.systemPrompt)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .frame(height: 120)
                }
            }
        }
        .padding()
    }
    
    private func configureLaunchAtLogin(enabled: Bool) {
        // macOS standard safe login item configuration
        let bundleId = Bundle.main.bundleIdentifier ?? "com.awitness.Witness"
        print("[Lifecycle] Launch at login toggled to \(enabled) for \(bundleId)")
    }
}

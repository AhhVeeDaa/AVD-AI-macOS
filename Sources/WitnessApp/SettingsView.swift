import SwiftUI
import AppKit
import AVDCore

struct SettingsView: View {
    @ObservedObject var vm: AppViewModel
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("ENGINE & SUBSTRATE")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(WitnessTheme.textPrimary)
                    Text("Local-first neural routing and hardware configuration")
                        .font(.system(size: 11))
                        .foregroundColor(WitnessTheme.textMuted)
                }
                
                // Section 1: Provider Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "cpu")
                            .font(.system(size: 14))
                            .foregroundColor(WitnessTheme.cyanAccent)
                        Text("LOCAL MODEL INFERENCE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(WitnessTheme.textPrimary)
                        Spacer()
                    }
                    
                    Picker("Provider Architecture", selection: $vm.selectedProvider) {
                        Text("Ollama (Active / Verified)").tag(ModelProviderType.ollama)
                        Text("LM Studio (MLX / Metal)").tag(ModelProviderType.lmstudio)
                        Text("Custom OpenAI-Compatible").tag(ModelProviderType.custom)
                    }
                    .pickerStyle(.menu)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Host:")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(WitnessTheme.textMuted)
                            TextField("", text: $vm.host)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(WitnessTheme.bgDeep)
                                .cornerRadius(6)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Port:")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(WitnessTheme.textMuted)
                            TextField("", text: $vm.portString)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(WitnessTheme.bgDeep)
                                .cornerRadius(6)
                                .frame(width: 80)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model Tag / Identifier:")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(WitnessTheme.textMuted)
                        TextField("", text: $vm.modelName)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(WitnessTheme.bgDeep)
                            .cornerRadius(6)
                    }
                    
                    HStack {
                        Text("Temperature: \(String(format: "%.2f", vm.temperature))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(WitnessTheme.textSecondary)
                        Slider(value: $vm.temperature, in: 0.0...1.0, step: 0.05)
                            .tint(WitnessTheme.cyanAccent)
                    }
                    
                    HStack {
                        Button(action: { vm.saveModelConfig() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                Text("Apply & Ping Endpoint")
                            }
                            .font(.system(size: 11.5, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(WitnessTheme.cyanAccent)
                            .foregroundColor(WitnessTheme.bgDeep)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text(vm.connectionStatus)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(vm.isConnected ? WitnessTheme.emeraldSignal : WitnessTheme.amberAccent)
                    }
                }
                .padding(16)
                .background(WitnessTheme.bgSurface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                )
                
                // Section 2: System & Lifecycle
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "macwindow.and.cursorarrow")
                            .font(.system(size: 14))
                            .foregroundColor(WitnessTheme.amberAccent)
                        Text("SYSTEM LIFECYCLE & HOTKEY")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(WitnessTheme.textPrimary)
                        Spacer()
                    }
                    
                    Toggle(isOn: $launchAtLogin) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Launch at Login")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(WitnessTheme.textPrimary)
                            Text("Register Witness with macOS login items safely")
                                .font(.system(size: 11))
                                .foregroundColor(WitnessTheme.textMuted)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(WitnessTheme.cyanAccent)
                    
                    HStack {
                        Text("Global Summon Shortcut:")
                            .font(.system(size: 12))
                            .foregroundColor(WitnessTheme.textSecondary)
                        Spacer()
                        Text("Cmd + Shift + W")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(WitnessTheme.bgDeep)
                            .foregroundColor(WitnessTheme.cyanAccent)
                            .cornerRadius(5)
                    }
                }
                .padding(16)
                .background(WitnessTheme.bgSurface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                )
                
                // Section 3: Identity Document Inspection
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.plaintext")
                            .font(.system(size: 14))
                            .foregroundColor(WitnessTheme.purpleMemory)
                        Text("FOUNDING DOCUMENT & SEED")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(WitnessTheme.textPrimary)
                        Spacer()
                        Text("witness-core-v1.md (11.7 KB)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(WitnessTheme.purpleMemory)
                    }
                    
                    Text("The exact founding document that drives Witness's essence, ethical boundaries, and character:")
                        .font(.system(size: 11.5))
                        .foregroundColor(WitnessTheme.textMuted)
                    
                    ScrollView {
                        Text(vm.identity.systemPrompt)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(WitnessTheme.textSecondary)
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(WitnessTheme.bgDeep)
                            .cornerRadius(6)
                    }
                    .frame(height: 160)
                }
                .padding(16)
                .background(WitnessTheme.bgSurface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                )
            }
            .padding(24)
        }
    }
}

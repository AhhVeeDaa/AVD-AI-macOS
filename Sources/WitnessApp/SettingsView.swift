import SwiftUI
import AVDCore
import AVFoundation

struct SettingsView: View {
    @ObservedObject var vm: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("ENGINE & CONTINUITY SETTINGS")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(WitnessTheme.textPrimary)
                    Text("Inference providers, identity prompts, voice synthesis, and registered tools")
                        .font(.system(size: 11))
                        .foregroundColor(WitnessTheme.textSecondary)
                }
                
                // Section 1: Local Model Inference Configuration
                VStack(alignment: .leading, spacing: 14) {
                    Text("LOCAL INFERENCE PROVIDER")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(WitnessTheme.cyanAccent)
                    
                    Picker("Provider", selection: $vm.selectedProvider) {
                        ForEach(ModelProviderType.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Host").font(.caption).foregroundColor(WitnessTheme.textSecondary)
                            TextField("Host", text: $vm.host)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Port").font(.caption).foregroundColor(WitnessTheme.textSecondary)
                            TextField("Port", text: $vm.portString)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Model Name").font(.caption).foregroundColor(WitnessTheme.textSecondary)
                            TextField("Model", text: $vm.modelName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Temperature: \(String(format: "%.2f", vm.temperature))")
                                .font(.caption)
                                .foregroundColor(WitnessTheme.textSecondary)
                            Spacer()
                        }
                        Slider(value: $vm.temperature, in: 0.0...1.5, step: 0.05)
                    }
                    
                    // Runtime Identity Kernel Option
                    Toggle(isOn: $vm.useRuntimeKernel) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use Concise Runtime Identity Kernel")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(WitnessTheme.textPrimary)
                            Text("Reduces prompt latency from ~55s to ~3s on Apple Silicon while preserving all founding principles.")
                                .font(.system(size: 10))
                                .foregroundColor(WitnessTheme.textMuted)
                        }
                    }
                    
                    HStack {
                        Button("Apply & Test Connection") {
                            vm.saveModelConfig()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(WitnessTheme.cyanAccent)
                        
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
                
                // Section 2: Voice & Audio Settings
                VStack(alignment: .leading, spacing: 14) {
                    Text("NATIVE MACOS VOICE SUBSYSTEM")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(WitnessTheme.cyanAccent)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Read Responses Aloud")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(WitnessTheme.textPrimary)
                            Text("Speaks streaming responses using AVFoundation speech synthesis.")
                                .font(.system(size: 10))
                                .foregroundColor(WitnessTheme.textMuted)
                        }
                        Spacer()
                        Toggle("", isOn: $vm.voiceEnabled)
                            .toggleStyle(.switch)
                    }
                    
                    if !vm.voiceManager.availableVoices.isEmpty {
                        Picker("Synthesizer Voice", selection: $vm.voiceManager.selectedVoiceIdentifier) {
                            ForEach(vm.voiceManager.availableVoices, id: \.identifier) { v in
                                Text("\(v.name) (\(v.language))").tag(v.identifier)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Speech Recognition:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(WitnessTheme.textSecondary)
                        Text(vm.voiceManager.permissionStatus)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(WitnessTheme.textPrimary)
                        Spacer()
                        Button("Request Microphone Access") {
                            vm.voiceManager.requestPermissions()
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 10.5))
                    }
                }
                .padding(16)
                .background(WitnessTheme.bgSurface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                )
                
                // Section 3: Registered Governed Tools
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("REGISTERED GOVERNED TOOLS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(WitnessTheme.cyanAccent)
                        Spacer()
                        Text("\(vm.registeredTools.count) Active")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(WitnessTheme.textMuted)
                    }
                    
                    ForEach(vm.registeredTools, id: \.id) { tool in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 12))
                                .foregroundColor(WitnessTheme.cyanAccent)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(tool.name)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(WitnessTheme.textPrimary)
                                    Text("`\(tool.id)`")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(WitnessTheme.textMuted)
                                    Spacer()
                                    Text(tool.requiredTier.rawValue)
                                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(WitnessTheme.bgElevated)
                                        .foregroundColor(WitnessTheme.amberAccent)
                                        .cornerRadius(4)
                                }
                                Text(tool.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(WitnessTheme.textSecondary)
                            }
                        }
                        .padding(10)
                        .background(WitnessTheme.bgDeep)
                        .cornerRadius(6)
                    }
                }
                .padding(16)
                .background(WitnessTheme.bgSurface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                )
                
                // Section 4: Founding Document & Seed Inspector
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("FOUNDING DOCUMENT & SEED")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(WitnessTheme.cyanAccent)
                        Spacer()
                        Text(vm.identity.foundingDocument)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(WitnessTheme.textMuted)
                    }
                    
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
        .background(WitnessTheme.bgDeep)
    }
}

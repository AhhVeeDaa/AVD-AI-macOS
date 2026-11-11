import SwiftUI
import AVDCore

struct MainWindowView: View {
    @ObservedObject var vm: AppViewModel
    @State private var selectedTab: NavigationTab = .chat
    
    enum NavigationTab: String, CaseIterable, Identifiable {
        case chat = "Presence"
        case capabilities = "Capabilities"
        case memory = "Memory Vault"
        case permissions = "Permissions"
        case settings = "Engine & Models"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .chat: return "bubble.left.and.bubble.right.fill"
            case .capabilities: return "sparkles.rectangle.stack.fill"
            case .memory: return "externaldrive.fill"
            case .permissions: return "shield.lefthalf.filled"
            case .settings: return "cpu"
            }
        }
    }
    
    var body: some View {
        Group {
            if vm.activeInteractionMode == .presence {
                PresenceView(vm: vm)
            } else {
                NavigationSplitView {
                    sidebarContent
                        .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 320)
                } detail: {
                    detailContent
                }
            }
        }
        .frame(minWidth: 860, minHeight: 580)
        .background(WitnessTheme.bgDeep)
    }
    
    // MARK: - Sidebar
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // Branded Top Header with Kanji Artwork
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(WitnessTheme.cyanAccent.opacity(0.12))
                        .frame(width: 34, height: 34)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(WitnessTheme.cyanAccent.opacity(0.35), lineWidth: 1)
                        )
                    WitnessKanjiMark(size: 24, glowColor: WitnessTheme.cyanAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("WITNESS")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(WitnessTheme.textPrimary)
                        Text("見")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(WitnessTheme.cyanAccent.opacity(0.75))
                    }
                    Text("AVD CONTINUITY v1.6")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(WitnessTheme.cyanAccent)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // ── Mode Toggle (prominent, always visible) ──────────────────
            HStack(spacing: 0) {
                modeToggleButton(
                    label: "TEXT",
                    icon: "text.bubble.fill",
                    isActive: vm.activeInteractionMode == .text,
                    action: { vm.activeInteractionMode = .text }
                )
                modeToggleButton(
                    label: "PRESENCE",
                    icon: "waveform.circle.fill",
                    isActive: vm.activeInteractionMode == .presence,
                    action: { vm.activeInteractionMode = .presence }
                )
            }
            .background(WitnessTheme.bgDeep)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(WitnessTheme.borderSubtle, lineWidth: 1))
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            
            // Navigation Section
            VStack(spacing: 2) {
                ForEach(NavigationTab.allCases) { tab in
                    Button(action: { selectedTab = tab }) {
                        HStack(spacing: 10) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13))
                                .frame(width: 18)
                            
                            Text(tab.rawValue)
                                .font(.system(size: 12.5, weight: selectedTab == tab ? .semibold : .regular))
                            
                            Spacer()
                        }
                        .foregroundColor(selectedTab == tab ? WitnessTheme.cyanAccent : WitnessTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedTab == tab ? WitnessTheme.cyanAccent.opacity(0.12) : Color.clear
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            
            Divider()
                .background(WitnessTheme.borderSubtle)
                .padding(.vertical, 6)
            
            // Continuity Sessions Header & Search
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("CONTINUITY SESSIONS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(WitnessTheme.textMuted)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedTab = .chat
                        vm.createNewSession()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(WitnessTheme.textSecondary)
                            .padding(4)
                            .background(WitnessTheme.bgElevated)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Search Field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundColor(WitnessTheme.textMuted)
                    TextField("Search sessions...", text: $vm.conversationSearchQuery)
                        .font(.system(size: 11))
                        .textFieldStyle(.plain)
                        .onChange(of: vm.conversationSearchQuery) {
                            vm.refreshState()
                        }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(WitnessTheme.bgDeep)
                .cornerRadius(6)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
            
            // Session List
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(vm.sessions) { session in
                        let isSelected = vm.activeSession?.id == session.id && selectedTab == .chat
                        
                        Button(action: {
                            selectedTab = .chat
                            vm.selectSession(session)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 11))
                                    .foregroundColor(isSelected ? WitnessTheme.cyanAccent : WitnessTheme.textMuted)
                                
                                Text(session.title)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                    .foregroundColor(isSelected ? WitnessTheme.textPrimary : WitnessTheme.textSecondary)
                                
                                Spacer()
                                
                                Text("\(session.messages.count)")
                                    .font(.system(size: 9.5, design: .monospaced))
                                    .foregroundColor(WitnessTheme.textMuted)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(isSelected ? WitnessTheme.bgElevated : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Delete Session", role: .destructive) {
                                vm.deleteSession(session)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer()
            
            Divider()
                .background(WitnessTheme.borderSubtle)
            
            // Mini Geometric Energy Core Orb & Voice Presence Widget in Sidebar
            VStack(spacing: 6) {
                Button(action: {
                    vm.activeInteractionMode = .presence
                }) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(WitnessTheme.cyanAccent.opacity(0.15))
                                .frame(width: 38, height: 38)
                            
                            GeometricEnergyCoreView(
                                state: vm.voiceManager.presenceState,
                                amplitude: vm.voiceManager.audioAmplitude,
                                isReducedMotion: false
                            )
                            .frame(width: 32, height: 32)
                            .scaleEffect(0.18)
                        }
                        .frame(width: 38, height: 38)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("ENERGY CORE")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(WitnessTheme.cyanAccent)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 8.5))
                                    .foregroundColor(WitnessTheme.cyanAccent.opacity(0.8))
                            }
                            Text(vm.voiceManager.presenceState.rawValue.uppercased())
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(WitnessTheme.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(WitnessTheme.bgElevated.opacity(0.7))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(WitnessTheme.cyanAccent.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Open Fullscreen Presence Orb (Cmd+P)")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()
                .background(WitnessTheme.borderSubtle)

            // Bottom System Status Pill
            HStack(spacing: 8) {
                Circle()
                    .fill(vm.isConnected ? WitnessTheme.emeraldSignal : WitnessTheme.amberAccent)
                    .frame(width: 7, height: 7)
                
                Text(vm.modelName)
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundColor(WitnessTheme.textSecondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(vm.permissionTier.rawValue)
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(WitnessTheme.bgElevated)
                    .foregroundColor(WitnessTheme.cyanAccent)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(WitnessTheme.bgSidebar)
        }
        .background(WitnessTheme.bgSidebar)
    }
    
    // MARK: - Detail
    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .chat:
            ConversationDetailView(vm: vm)
        case .capabilities:
            CapabilitiesView(vm: vm)
        case .memory:
            MemoryManagerView(vm: vm)
        case .permissions:
            PermissionsView(vm: vm)
        case .settings:
            SettingsView(vm: vm)
        }
    }

    // MARK: - Mode Toggle Helper
    @ViewBuilder
    private func modeToggleButton(label: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(isActive ? WitnessTheme.cyanAccent.opacity(0.18) : Color.clear)
            .foregroundColor(isActive ? WitnessTheme.cyanAccent : WitnessTheme.textMuted)
            .overlay(
                // Active underline indicator
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(isActive ? WitnessTheme.cyanAccent : Color.clear)
                        .frame(height: 2)
                }
            )
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI
import AppKit
import AVDCore

enum NavigationTab: String, CaseIterable, Identifiable {
    case chat = "Presence"
    case memories = "Memory Vault"
    case permissions = "Permissions"
    case settings = "Engine & Models"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .chat: return "sparkle"
        case .memories: return "brain"
        case .permissions: return "shield.checkered"
        case .settings: return "cpu"
        }
    }
}

struct MainWindowView: View {
    @ObservedObject var vm: AppViewModel
    @State private var selectedTab: NavigationTab = .chat
    
    var body: some View {
        NavigationSplitView {
            // Sidebar Surface
            VStack(alignment: .leading, spacing: 0) {
                // Brand Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [WitnessTheme.cyanAccent.opacity(0.3), WitnessTheme.bgSurface],
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: 18
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "circle.hexagongrid.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(WitnessTheme.cyanAccent)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text("WITNESS")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(WitnessTheme.textPrimary)
                            Text("v1.1")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(WitnessTheme.cyanAccent.opacity(0.15))
                                .foregroundColor(WitnessTheme.cyanAccent)
                                .cornerRadius(3)
                        }
                        Text("AVD Local Core")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(WitnessTheme.textMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                
                Divider()
                    .background(WitnessTheme.borderSubtle)
                
                // Primary Navigation
                VStack(spacing: 4) {
                    ForEach(NavigationTab.allCases) { tab in
                        Button(action: { selectedTab = tab }) {
                            HStack(spacing: 10) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedTab == tab ? WitnessTheme.cyanAccent : WitnessTheme.textSecondary)
                                    .frame(width: 20)
                                
                                Text(tab.rawValue)
                                    .font(.system(size: 12.5, weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundColor(selectedTab == tab ? WitnessTheme.textPrimary : WitnessTheme.textSecondary)
                                
                                Spacer()
                                
                                if tab == .memories {
                                    Text("\(vm.memoryItems.count)")
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundColor(WitnessTheme.purpleMemory)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(WitnessTheme.purpleMemory.opacity(0.12))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? WitnessTheme.bgElevated : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
                
                // Conversations Sub-Section when in Presence mode
                if selectedTab == .chat {
                    HStack {
                        Text("CONTINUITY SESSIONS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.0)
                            .foregroundColor(WitnessTheme.textMuted)
                        Spacer()
                        Button(action: { vm.createNewSession() }) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(WitnessTheme.cyanAccent)
                                .padding(4)
                                .background(WitnessTheme.cyanAccent.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help("New Conversation (Cmd+N)")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    
                    ScrollView {
                        LazyVStack(spacing: 3) {
                            ForEach(vm.sessions) { session in
                                let isSelected = session.id == vm.activeSession?.id
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(isSelected ? WitnessTheme.cyanAccent : Color.clear)
                                        .frame(width: 4, height: 4)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.title)
                                            .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                                            .foregroundColor(isSelected ? WitnessTheme.textPrimary : WitnessTheme.textSecondary)
                                            .lineLimit(1)
                                        
                                        Text("\(session.messages.count) exchanges")
                                            .font(.system(size: 10, weight: .regular))
                                            .foregroundColor(WitnessTheme.textMuted)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(isSelected ? WitnessTheme.bgElevated.opacity(0.8) : Color.clear)
                                .cornerRadius(7)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    vm.selectSession(session)
                                }
                                .contextMenu {
                                    Button("Delete Session", role: .destructive) {
                                        vm.deleteSession(session)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                } else {
                    Spacer()
                }
                
                Divider()
                    .background(WitnessTheme.borderSubtle)
                
                // Footer Status Pill
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(vm.isConnected ? WitnessTheme.emeraldSignal : WitnessTheme.amberAccent)
                            .frame(width: 7, height: 7)
                            .shadow(color: (vm.isConnected ? WitnessTheme.emeraldSignal : WitnessTheme.amberAccent).opacity(0.5), radius: 3)
                        
                        Text(vm.modelName)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(WitnessTheme.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("POLICY:")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(WitnessTheme.textMuted)
                        Text(vm.permissionTier.rawValue)
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(vm.permissionTier == .prohibited ? WitnessTheme.redAlert : WitnessTheme.amberAccent)
                        Spacer()
                    }
                }
                .padding(12)
                .background(WitnessTheme.bgDeep)
            }
            .background(WitnessTheme.bgSidebar)
            .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            ZStack {
                WitnessTheme.bgDeep.ignoresSafeArea()
                
                switch selectedTab {
                case .chat:
                    ConversationDetailView(vm: vm)
                case .memories:
                    MemoryManagerView(vm: vm)
                case .permissions:
                    PermissionsView(vm: vm)
                case .settings:
                    SettingsView(vm: vm)
                }
            }
        }
        .frame(minWidth: 860, minHeight: 560)
    }
}

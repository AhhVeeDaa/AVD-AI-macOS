import SwiftUI
import AVDCore

struct MainWindowView: View {
    @ObservedObject var vm: AppViewModel
    @State private var selectedTab: NavigationTab = .chat
    
    enum NavigationTab: String, CaseIterable, Identifiable {
        case chat = "Presence"
        case memory = "Memory Vault"
        case permissions = "Permissions"
        case settings = "Engine & Models"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .chat: return "bubble.left.and.bubble.right.fill"
            case .memory: return "externaldrive.fill"
            case .permissions: return "shield.lefthalf.filled"
            case .settings: return "cpu"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 320)
        } detail: {
            detailContent
        }
        .frame(minWidth: 840, minHeight: 560)
        .background(WitnessTheme.bgDeep)
    }
    
    // MARK: - Sidebar
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // Branded Top Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(WitnessTheme.cyanAccent.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 15))
                        .foregroundColor(WitnessTheme.cyanAccent)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("WITNESS")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(WitnessTheme.textPrimary)
                    
                    Text("AVD CONTINUITY v1.4")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(WitnessTheme.cyanAccent)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
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
            .padding(.vertical, 8)
            
            Divider()
                .background(WitnessTheme.borderSubtle)
                .padding(.vertical, 8)
            
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
                        .onChange(of: vm.conversationSearchQuery) { _ in
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
        case .memory:
            MemoryManagerView(vm: vm)
        case .permissions:
            PermissionsView(vm: vm)
        case .settings:
            SettingsView(vm: vm)
        }
    }
}

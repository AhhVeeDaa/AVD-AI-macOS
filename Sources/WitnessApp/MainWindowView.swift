import SwiftUI
import AppKit
import AVDCore

enum NavigationTab: String, CaseIterable, Identifiable {
    case chat = "Chat"
    case memories = "Memory"
    case permissions = "Permissions"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .memories: return "brain.head.profile"
        case .permissions: return "shield.lefthalf.filled"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainWindowView: View {
    @ObservedObject var vm: AppViewModel
    @State private var selectedTab: NavigationTab = .chat
    
    var body: some View {
        NavigationSplitView {
            // Sidebar: Conversations & Navigation
            VStack(alignment: .leading, spacing: 0) {
                // Top Tab Selector
                List(selection: $selectedTab) {
                    Section("Navigation") {
                        ForEach(NavigationTab.allCases) { tab in
                            NavigationLink(value: tab) {
                                Label(tab.rawValue, systemImage: tab.icon)
                            }
                        }
                    }
                    
                    if selectedTab == .chat {
                        Section("Conversations") {
                            ForEach(vm.sessions) { session in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.title)
                                            .font(.body)
                                            .lineLimit(1)
                                        Text("\(session.messages.count) messages")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if session.id == vm.activeSession?.id {
                                        Circle()
                                            .fill(Color.accentColor)
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    vm.selectSession(session)
                                }
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        vm.deleteSession(session)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                
                Divider()
                
                // Footer Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(vm.isConnected ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(vm.modelName)
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer()
                    Text(vm.permissionTier.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(Color(NSColor.windowBackgroundColor))
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } detail: {
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
        .frame(minWidth: 800, minHeight: 520)
    }
}

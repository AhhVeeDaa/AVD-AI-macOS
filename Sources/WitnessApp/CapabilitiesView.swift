import SwiftUI
import AVDCore

struct CapabilitiesView: View {
    @ObservedObject var vm: AppViewModel
    @State private var searchFilter: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("DEVICE INTELLIGENCE & CAPABILITIES")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(WitnessTheme.textPrimary)
                    Text("Inventory of macOS applications, developer CLI tools, automation scripts, and AI runtimes")
                        .font(.system(size: 11))
                        .foregroundColor(WitnessTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    vm.triggerDeviceDiscovery()
                }) {
                    HStack(spacing: 6) {
                        if vm.isDiscoveringDevices {
                            ProgressView().scaleEffect(0.5)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(vm.isDiscoveringDevices ? "Scanning..." : "Rescan Device")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(WitnessTheme.bgElevated)
                    .foregroundColor(WitnessTheme.cyanAccent)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(vm.isDiscoveringDevices)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(WitnessTheme.bgDeep)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(WitnessTheme.borderSubtle),
                alignment: .bottom
            )
            
            // Category Filter Pills
            HStack(spacing: 8) {
                filterPill(title: "ALL", category: nil, count: vm.discoveredCapabilities.count)
                
                ForEach(DeviceItemCategory.allCases, id: \.self) { cat in
                    let count = vm.discoveredCapabilities.filter { $0.category == cat }.count
                    filterPill(title: cat.rawValue, category: cat, count: count)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(WitnessTheme.bgSidebar)
            
            // Search Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(WitnessTheme.textMuted)
                TextField("Filter discovered capabilities...", text: $searchFilter)
                    .font(.system(size: 11.5))
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(WitnessTheme.bgDeep)
            .cornerRadius(8)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            
            // Capability Cards List
            ScrollView {
                LazyVStack(spacing: 10) {
                    let items = filteredCapabilities
                    if items.isEmpty {
                        VStack(spacing: 8) {
                            Spacer().frame(height: 40)
                            Image(systemName: "laptopcomputer.trianglebadge.exclamationmark")
                                .font(.system(size: 32))
                                .foregroundColor(WitnessTheme.textMuted)
                            Text("No capabilities matching filter.")
                                .font(.system(size: 12))
                                .foregroundColor(WitnessTheme.textSecondary)
                        }
                    } else {
                        ForEach(items) { item in
                            CapabilityCardView(item: item, onToggle: {
                                vm.toggleCapability(item)
                            })
                        }
                    }
                }
                .padding(24)
            }
            .background(WitnessTheme.bgDeep)
        }
    }
    
    private var filteredCapabilities: [DiscoveredCapability] {
        var list = vm.discoveredCapabilities
        if let cat = vm.selectedCapabilityCategory {
            list = list.filter { $0.category == cat }
        }
        if !searchFilter.isEmpty {
            let q = searchFilter.lowercased()
            list = list.filter { $0.name.lowercased().contains(q) || $0.pathOrEndpoint.lowercased().contains(q) }
        }
        return list
    }
    
    private func filterPill(title: String, category: DeviceItemCategory?, count: Int) -> some View {
        let isSelected = vm.selectedCapabilityCategory == category
        return Button(action: { vm.selectedCapabilityCategory = category }) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                
                Text("\(count)")
                    .font(.system(size: 9, weight: .semibold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(isSelected ? WitnessTheme.cyanAccent.opacity(0.3) : Color.white.opacity(0.08))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? WitnessTheme.cyanAccent.opacity(0.18) : WitnessTheme.bgSurface)
            .foregroundColor(isSelected ? WitnessTheme.cyanAccent : WitnessTheme.textSecondary)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? WitnessTheme.cyanAccent.opacity(0.4) : WitnessTheme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CapabilityCardView: View {
    let item: DiscoveredCapability
    let onToggle: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: categoryIcon)
                    .font(.system(size: 13))
                    .foregroundColor(categoryColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(WitnessTheme.textPrimary)
                    
                    Text(item.category.rawValue)
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(categoryColor.opacity(0.15))
                        .foregroundColor(categoryColor)
                        .cornerRadius(4)
                    
                    if let v = item.version {
                        Text("v\(v)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(WitnessTheme.textMuted)
                    }
                }
                
                Text(item.pathOrEndpoint)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(WitnessTheme.textMuted)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Enable / Disable Toggle
            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(12)
        .background(WitnessTheme.bgSurface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    private var categoryColor: Color {
        switch item.category {
        case .application: return WitnessTheme.cyanAccent
        case .developerTool: return WitnessTheme.amberAccent
        case .automation: return WitnessTheme.purpleMemory
        case .aiIntegration: return WitnessTheme.emeraldSignal
        case .modelRuntime: return Color.orange
        case .workspace: return Color.blue
        }
    }
    
    private var categoryIcon: String {
        switch item.category {
        case .application: return "app.badge.fill"
        case .developerTool: return "terminal.fill"
        case .automation: return "bolt.fill"
        case .aiIntegration: return "network"
        case .modelRuntime: return "cpu"
        case .workspace: return "folder.fill"
        }
    }
}

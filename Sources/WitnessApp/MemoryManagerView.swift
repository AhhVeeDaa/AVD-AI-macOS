import SwiftUI
import AppKit
import AVDCore

struct MemoryManagerView: View {
    @ObservedObject var vm: AppViewModel
    @State private var filterTier: MemoryTier? = nil
    @State private var newContent: String = ""
    @State private var newTier: MemoryTier = .semantic
    @State private var newImportance: Double = 0.7
    @State private var showAddSheet: Bool = false
    @State private var showExportAlert: Bool = false
    
    var filteredItems: [MemoryItem] {
        if let filter = filterTier {
            return vm.memoryItems.filter { $0.tier == filter }
        }
        return vm.memoryItems
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header & Tier Filter Bar
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MEMORY VAULT")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(WitnessTheme.textPrimary)
                    Text("Four-tier persistent substrate across sessions and reboots")
                        .font(.system(size: 11))
                        .foregroundColor(WitnessTheme.textMuted)
                }
                
                Spacer()
                
                Button(action: { showAddSheet = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                        Text("Add Memory")
                    }
                    .font(.system(size: 11.5, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(WitnessTheme.bgElevated)
                    .foregroundColor(WitnessTheme.cyanAccent)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: exportAction) {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export JSON")
                    }
                    .font(.system(size: 11.5, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(WitnessTheme.bgElevated)
                    .foregroundColor(WitnessTheme.textPrimary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: { vm.clearAllMemories() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(WitnessTheme.redAlert)
                        .padding(7)
                        .background(WitnessTheme.bgElevated)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Clear All Memories")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(WitnessTheme.bgSidebar)
            
            Divider()
                .background(WitnessTheme.borderSubtle)
            
            // Tier Filter Buttons
            HStack(spacing: 8) {
                TierFilterPill(title: "ALL TIERS", count: vm.memoryItems.count, isSelected: filterTier == nil, color: WitnessTheme.cyanAccent) {
                    filterTier = nil
                }
                
                ForEach(MemoryTier.allCases, id: \.self) { tier in
                    let count = vm.memoryItems.filter { $0.tier == tier }.count
                    TierFilterPill(title: tier.rawValue, count: count, isSelected: filterTier == tier, color: tierColor(tier)) {
                        filterTier = tier
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(WitnessTheme.bgDeep)
            
            Divider()
                .background(WitnessTheme.borderSubtle)
            
            // List of Memories
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(WitnessTheme.textMuted.opacity(0.5))
                    Text("No memory traces in this tier.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(WitnessTheme.textSecondary)
                    Text("Dialogue exchanges and learned facts automatically consolidate here.")
                        .font(.system(size: 11))
                        .foregroundColor(WitnessTheme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredItems) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .center, spacing: 8) {
                                    Text(item.tier.rawValue)
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2.5)
                                        .background(tierColor(item.tier).opacity(0.15))
                                        .foregroundColor(tierColor(item.tier))
                                        .cornerRadius(4)
                                    
                                    Text("Provenance: \(item.provenance)")
                                        .font(.system(size: 10.5))
                                        .foregroundColor(WitnessTheme.textMuted)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "gauge.with.needle")
                                            .font(.system(size: 9))
                                        Text(String(format: "%.1f", item.importance))
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    }
                                    .foregroundColor(WitnessTheme.textSecondary)
                                    
                                    Text("•")
                                        .foregroundColor(WitnessTheme.textMuted.opacity(0.4))
                                    
                                    Text(item.timestamp, style: .date)
                                        .font(.system(size: 10))
                                        .foregroundColor(WitnessTheme.textMuted)
                                    
                                    Button(action: { vm.deleteMemory(id: item.id) }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(WitnessTheme.textMuted)
                                            .padding(4)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Text(item.content)
                                    .font(.system(size: 13))
                                    .foregroundColor(WitnessTheme.textPrimary)
                                    .lineSpacing(3)
                                    .textSelection(.enabled)
                            }
                            .padding(14)
                            .background(WitnessTheme.bgSurface)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            VStack(alignment: .leading, spacing: 16) {
                Text("ENCODE MEMORY RECORD")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(WitnessTheme.textPrimary)
                
                Picker("Target Tier", selection: $newTier) {
                    ForEach(MemoryTier.allCases, id: \.self) { tier in
                        Text(tier.rawValue).tag(tier)
                    }
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memory Content:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(WitnessTheme.textSecondary)
                    TextEditor(text: $newContent)
                        .font(.system(size: 12.5))
                        .frame(height: 90)
                        .padding(6)
                        .background(WitnessTheme.bgDeep)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                        )
                }
                
                HStack {
                    Text("Importance Weight: \(String(format: "%.1f", newImportance))")
                        .font(.system(size: 11))
                        .foregroundColor(WitnessTheme.textSecondary)
                    Slider(value: $newImportance, in: 0.1...1.0, step: 0.1)
                        .tint(WitnessTheme.cyanAccent)
                }
                
                HStack {
                    Spacer()
                    Button("Cancel") { showAddSheet = false }
                        .buttonStyle(.plain)
                        .foregroundColor(WitnessTheme.textMuted)
                        .padding(.horizontal, 10)
                    
                    Button("Save to Vault") {
                        if !newContent.isEmpty {
                            vm.addMemory(tier: newTier, content: newContent, importance: newImportance)
                            newContent = ""
                            showAddSheet = false
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(WitnessTheme.cyanAccent)
                    .foregroundColor(WitnessTheme.bgDeep)
                    .cornerRadius(6)
                }
            }
            .padding(20)
            .frame(width: 460)
            .background(WitnessTheme.bgSurface)
        }
        .alert("Vault Exported to Clipboard", isPresented: $showExportAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func exportAction() {
        let json = vm.exportMemories()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(json, forType: .string)
        showExportAlert = true
    }
    
    private func tierColor(_ tier: MemoryTier) -> Color {
        switch tier {
        case .working: return WitnessTheme.cyanAccent
        case .episodic: return WitnessTheme.emeraldSignal
        case .semantic: return WitnessTheme.purpleMemory
        case .procedural: return WitnessTheme.amberAccent
        }
    }
}

struct TierFilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                Text("(\(count))")
                    .font(.system(size: 9.5, weight: .regular))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? color.opacity(0.18) : WitnessTheme.bgSurface)
            .foregroundColor(isSelected ? color : WitnessTheme.textSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color.opacity(0.4) : WitnessTheme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

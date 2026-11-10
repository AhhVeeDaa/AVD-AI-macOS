import SwiftUI
import AVDCore

struct MemoryManagerView: View {
    @ObservedObject var vm: AppViewModel
    @State private var showingExportSheet: Bool = false
    @State private var exportPayload: String = ""
    @State private var newFactText: String = ""
    @State private var newFactTier: MemoryTier = .semantic
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MEMORY VAULT")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(WitnessTheme.textPrimary)
                    Text("Four-tier local continuity store: Working, Episodic, Semantic, Procedural")
                        .font(.system(size: 11))
                        .foregroundColor(WitnessTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    exportPayload = vm.exportMemories()
                    showingExportSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export JSON")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(WitnessTheme.bgElevated)
                    .foregroundColor(WitnessTheme.textPrimary)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
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
            
            // Tier Filter Bar
            HStack(spacing: 8) {
                filterPill(title: "ALL", tier: nil, count: vm.memoryItems.count)
                
                ForEach(MemoryTier.allCases, id: \.self) { tier in
                    let count = vm.memoryItems.filter { $0.tier == tier }.count
                    filterPill(title: tier.rawValue, tier: tier, count: count)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(WitnessTheme.bgSidebar)
            
            // Memory Records List
            ScrollView {
                LazyVStack(spacing: 12) {
                    let displayed = filteredItems
                    if displayed.isEmpty {
                        VStack(spacing: 8) {
                            Spacer().frame(height: 40)
                            Image(systemName: "tray")
                                .font(.system(size: 32))
                                .foregroundColor(WitnessTheme.textMuted)
                            Text("No memories found in selected tier.")
                                .font(.system(size: 12))
                                .foregroundColor(WitnessTheme.textSecondary)
                        }
                    } else {
                        ForEach(displayed) { item in
                            MemoryCardView(item: item, onConfirm: {
                                vm.confirmMemory(item)
                            }, onDelete: {
                                vm.deleteMemory(item)
                            })
                        }
                    }
                }
                .padding(24)
            }
            .background(WitnessTheme.bgDeep)
        }
        .sheet(isPresented: $showingExportSheet) {
            VStack(spacing: 14) {
                HStack {
                    Text("Exported Memory Vault JSON")
                        .font(.headline)
                    Spacer()
                    Button("Done") { showingExportSheet = false }
                }
                TextEditor(text: .constant(exportPayload))
                    .font(.system(size: 10, design: .monospaced))
                    .frame(width: 480, height: 320)
            }
            .padding()
        }
    }
    
    private var filteredItems: [MemoryItem] {
        if let tier = vm.selectedMemoryTier {
            return vm.memoryItems.filter { $0.tier == tier }
        }
        return vm.memoryItems
    }
    
    private func filterPill(title: String, tier: MemoryTier?, count: Int) -> some View {
        let isSelected = vm.selectedMemoryTier == tier
        return Button(action: { vm.selectedMemoryTier = tier }) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                
                Text("\(count)")
                    .font(.system(size: 9.5, weight: .semibold))
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

struct MemoryCardView: View {
    let item: MemoryItem
    let onConfirm: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Tier Badge
                Text(item.tier.rawValue)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tierColor.opacity(0.18))
                    .foregroundColor(tierColor)
                    .cornerRadius(4)
                
                // Provenance Tag
                Text(item.provenance.rawValue)
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundColor(WitnessTheme.textMuted)
                
                if item.isConfirmed {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundColor(WitnessTheme.emeraldSignal)
                        .help("Confirmed Fact")
                }
                
                Spacer()
                
                // Confirm action for model-derived unconfirmed memories
                if !item.isConfirmed && item.provenance == .modelDerived {
                    Button(action: onConfirm) {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark")
                            Text("Confirm")
                        }
                        .font(.system(size: 9.5, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(WitnessTheme.emeraldSignal.opacity(0.2))
                        .foregroundColor(WitnessTheme.emeraldSignal)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help("Confirm into Permanent Semantic Memory")
                }
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(WitnessTheme.textMuted)
                }
                .buttonStyle(.plain)
                .help("Delete Memory")
            }
            
            Text(item.content)
                .font(.system(size: 12.5))
                .foregroundColor(WitnessTheme.textPrimary)
                .lineSpacing(3)
            
            HStack(spacing: 12) {
                Text(item.timestamp, style: .date)
                    .font(.system(size: 9.5))
                    .foregroundColor(WitnessTheme.textMuted)
                
                Text("Importance: \(String(format: "%.1f", item.importance))")
                    .font(.system(size: 9.5))
                    .foregroundColor(WitnessTheme.textMuted)
            }
        }
        .padding(14)
        .background(WitnessTheme.bgSurface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    private var tierColor: Color {
        switch item.tier {
        case .working: return WitnessTheme.cyanAccent
        case .episodic: return WitnessTheme.emeraldSignal
        case .semantic: return WitnessTheme.purpleMemory
        case .procedural: return WitnessTheme.amberAccent
        }
    }
}

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
    @State private var exportedJSON: String = ""
    @State private var showExportAlert: Bool = false
    
    var filteredItems: [MemoryItem] {
        if let filter = filterTier {
            return vm.memoryItems.filter { $0.tier == filter }
        }
        return vm.memoryItems
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Picker("Tier Filter", selection: $filterTier) {
                    Text("All Tiers (\(vm.memoryItems.count))").tag(MemoryTier?.none)
                    ForEach(MemoryTier.allCases, id: \.self) { tier in
                        Text("\(tier.rawValue) (\(vm.memoryItems.filter { $0.tier == tier }.count))").tag(MemoryTier?.some(tier))
                    }
                }
                .pickerStyle(.segmented)
                
                Spacer()
                
                Button(action: { showAddSheet = true }) {
                    Label("Add Memory", systemImage: "plus")
                }
                
                Button(action: exportAction) {
                    Label("Export JSON", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive, action: { vm.clearAllMemories() }) {
                    Label("Clear All", systemImage: "trash")
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.secondary)
                    Text("No memory records found.")
                        .font(.headline)
                    Text("Memories recorded during conversations will persist here locally.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredItems) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.tier.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(tierColor(item.tier).opacity(0.2))
                                    .foregroundColor(tierColor(item.tier))
                                    .cornerRadius(4)
                                
                                Text("Provenance: \(item.provenance)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(item.timestamp, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Button(action: { vm.deleteMemory(id: item.id) }) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text(item.content)
                                .font(.body)
                                .textSelection(.enabled)
                            
                            HStack {
                                Text("Importance: \(String(format: "%.1f", item.importance))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add Memory Record")
                    .font(.headline)
                
                Picker("Memory Tier", selection: $newTier) {
                    ForEach(MemoryTier.allCases, id: \.self) { tier in
                        Text(tier.rawValue).tag(tier)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Content:")
                        .font(.caption)
                    TextEditor(text: $newContent)
                        .frame(height: 80)
                        .border(Color.secondary.opacity(0.3))
                }
                
                HStack {
                    Text("Importance: \(String(format: "%.1f", newImportance))")
                    Slider(value: $newImportance, in: 0.1...1.0, step: 0.1)
                }
                
                HStack {
                    Spacer()
                    Button("Cancel") { showAddSheet = false }
                    Button("Save") {
                        if !newContent.isEmpty {
                            vm.addMemory(tier: newTier, content: newContent, importance: newImportance)
                            newContent = ""
                            showAddSheet = false
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
            .frame(width: 440)
        }
        .alert("Memories Exported to Clipboard", isPresented: $showExportAlert) {
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
        case .working: return .blue
        case .episodic: return .green
        case .semantic: return .purple
        case .procedural: return .orange
        }
    }
}

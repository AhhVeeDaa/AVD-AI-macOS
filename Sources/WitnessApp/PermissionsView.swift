import SwiftUI
import AppKit
import AVDCore

struct PermissionsView: View {
    @ObservedObject var vm: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header / Active Tier Setting
            VStack(alignment: .leading, spacing: 12) {
                Text("Permission & Policy Enforcement")
                    .font(.headline)
                
                Text("Witness strictly enforces a five-tier permission architecture. The core cannot self-grant elevated privileges without explicit user authorization.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Text("Active Policy Tier:")
                        .font(.body.bold())
                    
                    Picker("", selection: Binding(
                        get: { vm.permissionTier },
                        set: { vm.updatePermissionTier($0) }
                    )) {
                        ForEach(PermissionTier.allCases, id: \.self) { tier in
                            Text(tier.rawValue).tag(tier)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 160)
                }
                
                Text(vm.permissionTier.description)
                    .font(.caption)
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Audit Log
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Permission Audit Trail (\(vm.auditRecords.count))")
                        .font(.headline)
                    Spacer()
                    Button("Clear Audit Log") {
                        PermissionEngine.shared.clearAuditLog()
                        vm.refreshState()
                    }
                    .buttonStyle(.bordered)
                }
                .padding([.top, .horizontal])
                
                if vm.auditRecords.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.shield")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No audit events recorded yet.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.auditRecords.reversed()) { rec in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: rec.approved ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                    .foregroundColor(rec.approved ? .green : .red)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(rec.requestedTier.rawValue)
                                            .font(.caption.bold())
                                            .foregroundColor(rec.approved ? .primary : .red)
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        Text(rec.actionDescription)
                                            .font(.subheadline)
                                        Spacer()
                                        Text(rec.timestamp, style: .time)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if !rec.notes.isEmpty {
                                        Text(rec.notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
}

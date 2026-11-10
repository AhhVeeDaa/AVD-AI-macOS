import SwiftUI
import AppKit
import AVDCore

struct PermissionsView: View {
    @ObservedObject var vm: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header & Active Policy Box
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("POLICY & PERMISSION TIERS")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(WitnessTheme.textPrimary)
                        Text("Strict non-escalation sandbox. The model cannot grant itself elevated permissions.")
                            .font(.system(size: 11))
                            .foregroundColor(WitnessTheme.textMuted)
                    }
                    Spacer()
                }
                
                // Tier Cards Grid
                HStack(spacing: 8) {
                    ForEach(PermissionTier.allCases, id: \.self) { tier in
                        let isActive = vm.permissionTier == tier
                        Button(action: { vm.updatePermissionTier(tier) }) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(tier.rawValue)
                                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(isActive ? tierColor(tier) : WitnessTheme.textSecondary)
                                    Spacer()
                                    if isActive {
                                        Circle()
                                            .fill(tierColor(tier))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                
                                Text(shortDescription(tier))
                                    .font(.system(size: 9.5))
                                    .foregroundColor(WitnessTheme.textMuted)
                                    .lineLimit(2)
                                    .frame(minHeight: 24, alignment: .topLeading)
                            }
                            .padding(10)
                            .background(isActive ? tierColor(tier).opacity(0.12) : WitnessTheme.bgSurface)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isActive ? tierColor(tier).opacity(0.5) : WitnessTheme.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .background(WitnessTheme.bgSidebar)
            
            Divider()
                .background(WitnessTheme.borderSubtle)
            
            // Audit Log Stream
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("ACTIVITY & AUDIT TRAIL")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.0)
                        .foregroundColor(WitnessTheme.textMuted)
                    
                    Spacer()
                    
                    Button(action: {
                        PermissionEngine.shared.clearAuditLog()
                        vm.refreshState()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Clear Audit Log")
                        }
                        .font(.system(size: 10.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(WitnessTheme.bgElevated)
                        .foregroundColor(WitnessTheme.textSecondary)
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                
                if vm.auditRecords.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 32))
                            .foregroundColor(WitnessTheme.textMuted.opacity(0.5))
                        Text("No policy boundary evaluations logged yet.")
                            .font(.system(size: 12))
                            .foregroundColor(WitnessTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(vm.auditRecords.reversed()) { rec in
                                HStack(alignment: .top, spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill((rec.approved ? WitnessTheme.emeraldSignal : WitnessTheme.redAlert).opacity(0.15))
                                            .frame(width: 24, height: 24)
                                        
                                        Image(systemName: rec.approved ? "checkmark" : "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(rec.approved ? WitnessTheme.emeraldSignal : WitnessTheme.redAlert)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(rec.requestedTier.rawValue)
                                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                                .foregroundColor(tierColor(rec.requestedTier))
                                            Text("•")
                                                .foregroundColor(WitnessTheme.textMuted.opacity(0.4))
                                            Text(rec.actionDescription)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(WitnessTheme.textPrimary)
                                            Spacer()
                                            Text(rec.timestamp, style: .time)
                                                .font(.system(size: 9.5))
                                                .foregroundColor(WitnessTheme.textMuted)
                                        }
                                        
                                        if !rec.notes.isEmpty {
                                            Text(rec.notes)
                                                .font(.system(size: 11))
                                                .foregroundColor(WitnessTheme.textSecondary)
                                        }
                                    }
                                }
                                .padding(10)
                                .background(WitnessTheme.bgSurface)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(WitnessTheme.borderSubtle, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
    }
    
    private func tierColor(_ tier: PermissionTier) -> Color {
        switch tier {
        case .observe: return WitnessTheme.cyanAccent
        case .assist: return WitnessTheme.emeraldSignal
        case .execute: return WitnessTheme.amberAccent
        case .restricted: return Color(red: 0.95, green: 0.50, blue: 0.30)
        case .prohibited: return WitnessTheme.redAlert
        }
    }
    
    private func shortDescription(_ tier: PermissionTier) -> String {
        switch tier {
        case .observe: return "Read-only system inspection"
        case .assist: return "Dialogue & non-destructive help"
        case .execute: return "Run shell & approved actions"
        case .restricted: return "Elevated per-call prompts"
        case .prohibited: return "Full security lockdown"
        }
    }
}

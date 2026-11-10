import Foundation

public enum PermissionTier: String, Codable, CaseIterable, Comparable, Sendable {
    case observe = "OBSERVE"
    case assist = "ASSIST"
    case execute = "EXECUTE"
    case restricted = "RESTRICTED"
    case prohibited = "PROHIBITED"
    
    public var rank: Int {
        switch self {
        case .observe: return 1
        case .assist: return 2
        case .execute: return 3
        case .restricted: return 4
        case .prohibited: return 5
        }
    }
    
    public static func < (lhs: PermissionTier, rhs: PermissionTier) -> Bool {
        return lhs.rank < rhs.rank
    }
    
    public var description: String {
        switch self {
        case .observe:
            return "Read-only system & memory inspection. Cannot write or run commands."
        case .assist:
            return "Generate recommendations, draft actions, write non-destructive user files."
        case .execute:
            return "Run user-approved shell commands and localized automations."
        case .restricted:
            return "Execute privileged or security-sensitive actions requiring explicit per-call authorization."
        case .prohibited:
            return "Strict lockdown. All action execution is disabled."
        }
    }
}

public struct PermissionAuditRecord: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let requestedTier: PermissionTier
    public let actionDescription: String
    public let approved: Bool
    public let notes: String
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), requestedTier: PermissionTier, actionDescription: String, approved: Bool, notes: String = "") {
        self.id = id
        self.timestamp = timestamp
        self.requestedTier = requestedTier
        self.actionDescription = actionDescription
        self.approved = approved
        self.notes = notes
    }
}

public final class PermissionEngine: @unchecked Sendable {
    public static let shared = PermissionEngine()
    
    private let queue = DispatchQueue(label: "com.awitness.permissions")
    private var _currentTier: PermissionTier = .assist
    private var _auditLog: [PermissionAuditRecord] = []
    private let auditLogURL: URL
    
    public var currentTier: PermissionTier {
        get { queue.sync { _currentTier } }
        set { 
            queue.sync { 
                _currentTier = newValue 
                persistAuditLog()
            } 
        }
    }
    
    public var auditLog: [PermissionAuditRecord] {
        queue.sync { _auditLog }
    }
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let witnessDir = appSupport.appendingPathComponent("Witness", isDirectory: true)
        try? FileManager.default.createDirectory(at: witnessDir, withIntermediateDirectories: true)
        self.auditLogURL = witnessDir.appendingPathComponent("permission_audit.json")
        loadAuditLog()
    }
    
    public func evaluate(actionTier: PermissionTier, description: String) -> Bool {
        return queue.sync {
            // PROHIBITED denies everything except passive read
            if _currentTier == .prohibited {
                let rec = PermissionAuditRecord(
                    requestedTier: actionTier,
                    actionDescription: description,
                    approved: false,
                    notes: "Denied: Engine is in PROHIBITED lockdown mode."
                )
                _auditLog.append(rec)
                persistAuditLog()
                return false
            }
            
            // Cannot self-grant higher privileges
            let approved = actionTier.rank <= _currentTier.rank
            let rec = PermissionAuditRecord(
                requestedTier: actionTier,
                actionDescription: description,
                approved: approved,
                notes: approved ? "Approved under tier \(_currentTier.rawValue)" : "Denied: Requires \(actionTier.rawValue) while active tier is \(_currentTier.rawValue)"
            )
            _auditLog.append(rec)
            persistAuditLog()
            return approved
        }
    }
    
    public func clearAuditLog() {
        queue.sync {
            _auditLog.removeAll()
            persistAuditLog()
        }
    }
    
    private func loadAuditLog() {
        guard let data = try? Data(contentsOf: auditLogURL),
              let list = try? JSONDecoder().decode([PermissionAuditRecord].self, from: data) else {
            return
        }
        self._auditLog = list
    }
    
    private func persistAuditLog() {
        guard let data = try? JSONEncoder().encode(_auditLog) else { return }
        try? data.write(to: auditLogURL, options: .atomic)
    }
}

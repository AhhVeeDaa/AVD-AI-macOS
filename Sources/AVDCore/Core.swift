import Foundation

public struct AVDCoreInfo {
    public static let version = "1.0.0"
    public static let framework = "AVD-Core-Native-macOS"
    
    public static func statusSummary() -> String {
        let identity = WitnessIdentityLoader.shared.getIdentity()
        let perm = PermissionEngine.shared.currentTier
        let memCount = MemoryManager.shared.allItems().count
        let cfg = ModelRouter.shared.config
        return """
        AVD Core v\(version)
        Identity: \(identity.name) (\(identity.version))
        Active Permission: \(perm.rawValue)
        Memories Stored: \(memCount)
        Configured Model: \(cfg.providerType.rawValue) - \(cfg.modelName) @ \(cfg.baseURL.absoluteString)
        """
    }
}

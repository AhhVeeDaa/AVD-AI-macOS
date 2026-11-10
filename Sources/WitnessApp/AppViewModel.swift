import SwiftUI
import AppKit
import AVDCore

@MainActor
final class AppViewModel: ObservableObject {
    @Published var sessions: [ConversationSession] = []
    @Published var activeSession: ConversationSession?
    @Published var currentStreamingText: String = ""
    @Published var isStreaming: Bool = false
    @Published var statusMessage: String = ""
    @Published var connectionStatus: String = "Checking..."
    @Published var isConnected: Bool = false
    
    // Model configuration
    @Published var selectedProvider: ModelProviderType = .ollama
    @Published var host: String = "127.0.0.1"
    @Published var portString: String = "11434"
    @Published var modelName: String = "qwen3.5:4b"
    @Published var temperature: Double = 0.7
    
    // Permission tier
    @Published var permissionTier: PermissionTier = .assist
    @Published var auditRecords: [PermissionAuditRecord] = []
    
    // Memory
    @Published var memoryItems: [MemoryItem] = []
    @Published var selectedMemoryTier: MemoryTier? = nil
    
    // Identity
    @Published var identity: WitnessIdentity = WitnessIdentity.default
    
    private let orchestrator = CoreOrchestrator.shared
    private let memoryManager = MemoryManager.shared
    private let permissionEngine = PermissionEngine.shared
    private let modelRouter = ModelRouter.shared
    private let identityLoader = WitnessIdentityLoader.shared
    
    init() {
        refreshState()
        checkConnection()
    }
    
    func refreshState() {
        self.sessions = orchestrator.getSessions()
        self.activeSession = orchestrator.getActiveSession()
        self.permissionTier = permissionEngine.currentTier
        self.auditRecords = permissionEngine.auditLog
        self.memoryItems = memoryManager.allItems()
        self.identity = identityLoader.getIdentity()
        
        let cfg = modelRouter.config
        self.selectedProvider = cfg.providerType
        self.host = cfg.host
        self.portString = "\(cfg.port)"
        self.modelName = cfg.modelName
        self.temperature = cfg.temperature
    }
    
    func checkConnection() {
        connectionStatus = "Testing connection to \(host):\(portString)..."
        isConnected = false
        Task {
            let res = await modelRouter.checkHealth()
            await MainActor.run {
                switch res {
                case .success(let info):
                    self.connectionStatus = "🟢 \(info)"
                    self.isConnected = true
                case .failure(let err):
                    self.connectionStatus = "🔴 Disconnected: \(err.localizedDescription)"
                    self.isConnected = false
                }
            }
        }
    }
    
    func saveModelConfig() {
        let portInt = Int(portString) ?? 11434
        var cfg = modelRouter.config
        cfg.providerType = selectedProvider
        cfg.host = host
        cfg.port = portInt
        cfg.modelName = modelName
        cfg.temperature = temperature
        modelRouter.config = cfg
        checkConnection()
    }
    
    func updatePermissionTier(_ newTier: PermissionTier) {
        permissionEngine.currentTier = newTier
        self.permissionTier = newTier
        self.auditRecords = permissionEngine.auditLog
    }
    
    func createNewSession() {
        let newSession = orchestrator.createNewSession(title: "New Conversation")
        self.sessions = orchestrator.getSessions()
        self.activeSession = newSession
    }
    
    func selectSession(_ session: ConversationSession) {
        orchestrator.selectSession(id: session.id)
        self.activeSession = orchestrator.getActiveSession()
    }
    
    func deleteSession(_ session: ConversationSession) {
        orchestrator.deleteSession(id: session.id)
        refreshState()
    }
    
    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }
        
        isStreaming = true
        currentStreamingText = ""
        statusMessage = "Witness is thinking..."
        
        orchestrator.processUserMessage(
            text: trimmed,
            onToken: { [weak self] token in
                Task { @MainActor [weak self] in
                    self?.currentStreamingText += token
                }
            },
            onComplete: { [weak self] result in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.isStreaming = false
                    self.currentStreamingText = ""
                    switch result {
                    case .success:
                        self.statusMessage = ""
                    case .failure(let err):
                        self.statusMessage = "Error: \(err.localizedDescription)"
                    }
                    self.refreshState()
                }
            }
        )
    }
    
    func addMemory(tier: MemoryTier, content: String, importance: Double) {
        _ = memoryManager.record(tier: tier, content: content, provenance: "manual_entry", importance: importance)
        self.memoryItems = memoryManager.allItems()
    }
    
    func deleteMemory(id: UUID) {
        memoryManager.delete(id: id)
        self.memoryItems = memoryManager.allItems()
    }
    
    func clearAllMemories() {
        memoryManager.clearAll()
        self.memoryItems = memoryManager.allItems()
    }
    
    func exportMemories() -> String {
        return memoryManager.exportJSON()
    }
}

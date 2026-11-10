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
    @Published var conversationSearchQuery: String = ""
    
    // Model configuration
    @Published var selectedProvider: ModelProviderType = .ollama
    @Published var host: String = "127.0.0.1"
    @Published var portString: String = "11434"
    @Published var modelName: String = "qwen3.5:4b"
    @Published var temperature: Double = 0.7
    @Published var useRuntimeKernel: Bool = true
    
    // Permission tier
    @Published var permissionTier: PermissionTier = .assist
    @Published var auditRecords: [PermissionAuditRecord] = []
    
    // Governed Agency & Tools
    @Published var registeredTools: [ToolDefinition] = []
    @Published var pendingToolAction: PendingToolAction? = nil
    
    // Memory
    @Published var memoryItems: [MemoryItem] = []
    @Published var selectedMemoryTier: MemoryTier? = nil
    @Published var memorySearchQuery: String = ""
    
    // Identity
    @Published var identity: WitnessIdentity = WitnessIdentity.default
    
    // Voice Subsystem
    @ObservedObject var voiceManager = VoiceManager.shared
    @Published var voiceEnabled: Bool = false
    
    private let orchestrator = CoreOrchestrator.shared
    private let memoryManager = MemoryManager.shared
    private let permissionEngine = PermissionEngine.shared
    private let modelRouter = ModelRouter.shared
    private let identityLoader = WitnessIdentityLoader.shared
    private let toolRegistry = ToolRegistry.shared
    
    init() {
        refreshState()
        checkConnection()
    }
    
    func refreshState() {
        if conversationSearchQuery.isEmpty {
            self.sessions = orchestrator.getSessions()
        } else {
            self.sessions = orchestrator.searchConversations(query: conversationSearchQuery)
        }
        self.activeSession = orchestrator.getActiveSession()
        self.permissionTier = permissionEngine.currentTier
        self.auditRecords = permissionEngine.auditLog
        self.memoryItems = memoryManager.allItems()
        self.identity = identityLoader.getIdentity()
        self.registeredTools = toolRegistry.allTools()
        
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
    
    // MARK: - Conversations
    
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
        statusMessage = "Witness is contemplating..."
        
        orchestrator.processUserMessage(
            text: trimmed,
            useRuntimeKernel: self.useRuntimeKernel,
            onToken: { [weak self] token in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.currentStreamingText += token
                    if self.voiceEnabled {
                        self.voiceManager.appendStreamingSpeech(token: token)
                    }
                }
            },
            onToolActionProposed: { [weak self] action in
                Task { @MainActor [weak self] in
                    self?.pendingToolAction = action
                }
            },
            onComplete: { [weak self] result in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.isStreaming = false
                    self.currentStreamingText = ""
                    if self.voiceEnabled {
                        self.voiceManager.finishStreamingSpeech()
                    }
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
    
    // MARK: - Tool Approvals
    
    func approvePendingAction() {
        guard let action = pendingToolAction else { return }
        self.pendingToolAction = nil
        Task {
            _ = await orchestrator.executePendingAction(action)
            await MainActor.run {
                self.refreshState()
            }
        }
    }
    
    func rejectPendingAction() {
        guard let action = pendingToolAction else { return }
        self.pendingToolAction = nil
        // Log rejection in audit trail
        _ = permissionEngine.evaluate(actionTier: .prohibited, description: "User declined tool proposal: \(action.toolName)")
        refreshState()
    }
    
    // MARK: - Memory Vault Actions
    
    func confirmMemory(_ item: MemoryItem) {
        memoryManager.confirmMemory(id: item.id)
        refreshState()
    }
    
    func deleteMemory(_ item: MemoryItem) {
        memoryManager.delete(id: item.id)
        refreshState()
    }
    
    func exportMemories() -> String {
        return memoryManager.exportJSON()
    }
    
    func importMemories(_ json: String) -> (Int, String?) {
        let result = memoryManager.importJSON(json)
        refreshState()
        return result
    }
}

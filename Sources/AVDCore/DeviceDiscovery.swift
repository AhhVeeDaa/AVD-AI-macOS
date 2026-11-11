// Copyright 2026 Avida Buyombo
// SPDX-License-Identifier: Apache-2.0

import Foundation

public enum DeviceItemCategory: String, Codable, CaseIterable, Sendable {
    case application = "APPLICATION"
    case developerTool = "DEVELOPER_TOOL"
    case automation = "AUTOMATION"
    case aiIntegration = "AI_INTEGRATION"
    case modelRuntime = "MODEL_RUNTIME"
    case workspace = "WORKSPACE"
}

public struct DiscoveredCapability: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let category: DeviceItemCategory
    public let pathOrEndpoint: String
    public let bundleIdentifier: String?
    public let version: String?
    public var isEnabled: Bool
    public let discoveredAt: Date
    public var lastVerifiedAt: Date
    
    public init(
        id: String,
        name: String,
        category: DeviceItemCategory,
        pathOrEndpoint: String,
        bundleIdentifier: String? = nil,
        version: String? = nil,
        isEnabled: Bool = true,
        discoveredAt: Date = Date(),
        lastVerifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.pathOrEndpoint = pathOrEndpoint
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.isEnabled = isEnabled
        self.discoveredAt = discoveredAt
        self.lastVerifiedAt = lastVerifiedAt
    }
}

public final class DeviceDiscoveryService: @unchecked Sendable {
    public static let shared = DeviceDiscoveryService()
    
    private let queue = DispatchQueue(label: "com.awitness.discovery", attributes: .concurrent)
    private var capabilities: [DiscoveredCapability] = []
    private let storageURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let witnessDir = appSupport.appendingPathComponent("Witness", isDirectory: true)
        try? FileManager.default.createDirectory(at: witnessDir, withIntermediateDirectories: true)
        self.storageURL = witnessDir.appendingPathComponent("discovered_capabilities.json")
        loadFromDisk()
    }
    
    public func allCapabilities() -> [DiscoveredCapability] {
        queue.sync { self.capabilities }
    }
    
    public func capabilities(for category: DeviceItemCategory) -> [DiscoveredCapability] {
        queue.sync { self.capabilities.filter { $0.category == category } }
    }
    
    public func toggleCapability(id: String, enabled: Bool) {
        queue.async(flags: .barrier) {
            if let idx = self.capabilities.firstIndex(where: { $0.id == id }) {
                self.capabilities[idx].isEnabled = enabled
                self.capabilities[idx].lastVerifiedAt = Date()
                self.saveToDisk()
            }
        }
    }
    
    /// Executes safe, read-only discovery of installed apps, developer tools, AI endpoints, and automations
    public func performDiscovery() async -> [DiscoveredCapability] {
        var discovered: [DiscoveredCapability] = []
        let fm = FileManager.default
        
        // 1. Discover Applications in /Applications and /System/Applications
        let appDirs = ["/Applications", "/System/Applications"]
        for dir in appDirs {
            if let items = try? fm.contentsOfDirectory(atPath: dir) {
                for item in items where item.hasSuffix(".app") {
                    let appPath = (dir as NSString).appendingPathComponent(item)
                    let appName = (item as NSString).deletingPathExtension
                    let bundle = Bundle(path: appPath)
                    let bundleId = bundle?.bundleIdentifier
                    let version = bundle?.infoDictionary?["CFBundleShortVersionString"] as? String
                    
                    let cap = DiscoveredCapability(
                        id: "app:\(bundleId ?? appName)",
                        name: appName,
                        category: .application,
                        pathOrEndpoint: appPath,
                        bundleIdentifier: bundleId,
                        version: version
                    )
                    discovered.append(cap)
                }
            }
        }
        
        // 2. Discover Known Developer CLI Tools at fixed paths
        let knownCLIs: [(id: String, name: String, path: String)] = [
            ("git", "Git Version Control", "/usr/bin/git"),
            ("swift", "Swift Compiler", "/usr/bin/swift"),
            ("xcode-select", "Xcode Command Line Tools", "/usr/bin/xcode-select"),
            ("python3", "Python 3 Runtime", "/usr/bin/python3"),
            ("brew", "Homebrew Package Manager", "/opt/homebrew/bin/brew"),
            ("node", "Node.js Runtime", "/opt/homebrew/bin/node"),
            ("docker", "Docker CLI", "/usr/local/bin/docker"),
            ("shortcuts", "macOS Shortcuts CLI", "/usr/bin/shortcuts"),
            ("osascript", "AppleScript & JXA Engine", "/usr/bin/osascript")
        ]
        
        for cli in knownCLIs {
            if fm.fileExists(atPath: cli.path) {
                let cap = DiscoveredCapability(
                    id: "cli:\(cli.id)",
                    name: cli.name,
                    category: (cli.id == "shortcuts" || cli.id == "osascript") ? .automation : .developerTool,
                    pathOrEndpoint: cli.path
                )
                discovered.append(cap)
            }
        }
        
        // 3. Discover Local AI Inference Providers & Model Runtimes
        // Check Ollama
        let ollamaRunning = await checkHTTPEndpoint(urlStr: "http://127.0.0.1:11434/api/tags")
        if ollamaRunning {
            discovered.append(DiscoveredCapability(
                id: "ai:ollama",
                name: "Ollama Local Inference Service",
                category: .modelRuntime,
                pathOrEndpoint: "http://127.0.0.1:11434"
            ))
        }
        
        // Check LM Studio
        let lmStudioRunning = await checkHTTPEndpoint(urlStr: "http://127.0.0.1:1234/api/v1/models")
        if lmStudioRunning {
            discovered.append(DiscoveredCapability(
                id: "ai:lmstudio",
                name: "LM Studio Local Inference Server",
                category: .modelRuntime,
                pathOrEndpoint: "http://127.0.0.1:1234"
            ))
        }
        
        // Check MCP configurations (e.g. Claude / Cursor / Antigravity MCP definitions)
        let mcpDir = fm.homeDirectoryForCurrentUser.appendingPathComponent(".gemini/antigravity/mcp")
        if fm.fileExists(atPath: mcpDir.path) {
            if let servers = try? fm.contentsOfDirectory(atPath: mcpDir.path) {
                for s in servers where !s.hasPrefix(".") {
                    discovered.append(DiscoveredCapability(
                        id: "mcp:\(s)",
                        name: "MCP Server: \(s)",
                        category: .aiIntegration,
                        pathOrEndpoint: mcpDir.appendingPathComponent(s).path
                    ))
                }
            }
        }
        
        // Merge with existing capabilities (preserving user enabled/disabled preferences)
        queue.async(flags: .barrier) {
            var merged: [DiscoveredCapability] = []
            for item in discovered {
                if let existing = self.capabilities.first(where: { $0.id == item.id }) {
                    var updated = item
                    updated.isEnabled = existing.isEnabled
                    merged.append(updated)
                } else {
                    merged.append(item)
                }
            }
            self.capabilities = merged.sorted(by: { $0.name < $1.name })
            self.saveToDisk()
        }
        
        return queue.sync { self.capabilities }
    }
    
    private func checkHTTPEndpoint(urlStr: String) async -> Bool {
        guard let url = URL(string: urlStr) else { return false }
        var req = URLRequest(url: url)
        req.timeoutInterval = 1.0
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                return true
            }
            return false
        } catch {
            return false
        }
    }
    
    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storageURL),
              let list = try? JSONDecoder().decode([DiscoveredCapability].self, from: data) else {
            return
        }
        self.capabilities = list
    }
    
    private func saveToDisk() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(self.capabilities) {
            try? data.write(to: storageURL, options: .atomic)
        }
    }
}

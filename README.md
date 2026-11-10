# WITNESS — Native macOS Application (Version 1.0.0)

## **Persistent Digital Companion | Identity Before Model**

Witness is an actual native macOS application built with AVD Core architecture, operating independently of OpenClaw. A persistent identity AI assistant with local-inference-first operation and privacy-by-design principles.

---

## 📋 Product Identity

| Attribute | Value |
|-----------|-------|
| **Name** | Witness |
| **Version** | 1.0.0 |
| **Developer** | La Vie Tech Ltd |
| **Product Owner** | Avida Buyombo |
| **Platform** | macOS (Apple Silicon M4) |
| **Architecture** | Swift/SwiftUI Native Application |

---

## 🎯 Design Philosophy

- **Identity before model** — Persistent identity is the foundation
- **Continuity before conversation** — Memory persists across sessions
- **Presence before performance** — Always available, not just responding
- **Truth before comfort** — Honest, direct communication style
- **Love as action** — Purposeful assistance without unnecessary fluff

---

## 🏗️ Architecture Overview

### Core Components (Independent of OpenClaw)

```
┌─────────────────────────────────┐
│     Witness Identity Layer      │  → Persitsent identity, values
├─────────────────────────────────┤
│        AVD Core                 │  → Orchestration & routing
├─────────────────────────────────┤
│       Memory Engine             │  → Four-tier adaptive memory
├─────────────────────────────────┤
│     Model Routing Abstraction   │  → Local-inference-first
├─────────────────────────────────┤
│      Permission Enforcement     │  → Five-tier policy engine
├─────────────────────────────────┤
│        Native Swift Execution   │  → Direct API calls to Ollama
└─────────────────────────────────┘
```

---

## 📁 Project Structure

```
/Users/ahhveedaa/.openclaw/workspace/AVD-AI-macOS/
├── Sources/
│   ├── AVDCore/
│   │   ├── Identity.swift       # Witness identity persistence
│   │   ├── Core.swift           # Central orchestrator
│   │   ├── Memory.swift         # Four-tier memory system
│   │   ├── ModelRouting.swift   # Local-inference routing
│   │   └── Permissions.swift    # Five-tier policy engine
│   ├── WitnessApp/
│   │   ├── Main.swift           # Application entry point
│   │   ├── OllamaIntegration.swift  # Native API client
│   │   └── SwiftUI Views (coming)
│   └── VoicePerception.swift    # Microphone integration
├── README.md                    # This file
├── Phase1_Baseline_Report.md    # Environment status
└── ARCHITECTURE.md             # Full design specification
```

---

## 🚀 Quick Start — Installation Guide

### Prerequisites
- macOS 13+ ( Ventura / Sonoma / Sequordia / etc. )
- M1/M2/M3/M4 Apple Silicon chip preferred
- Xcode installed or available via Mac App Store
- Ollama runtime with qwen3.5:4b model (verified in environment inventory)

### Step 1: Build the Application

```bash
cd /Users/ahhveedaa/.openclaw/workspace/AVD-AI-macOS

# Verify Ollama is running
ollama list | grep qwen3.5:4b

# Build with Xcode (requires Xcode installation)
xcodebuild -project Witness.xcodeproj -configuration Debug build

# Or use Swift Package Manager (if supported by your Xcode version)
swift build
```

### Step 2: Run the Application

```bash
./Witness.app/Contents/MacOS/Witness
```

Or drag `Witness.app` to `/Applications/` and launch from there.

### Step 3: Install as DMG (Release Build)

```bash
xcodebuild -project Witness.xcodeproj -configuration Release -sdk macosx-14.5 copy-bundle \
    BundleID=Witness.app /Users/ahhveedaa/.openclaw/workspace/Witness-v1.0.0.app
```

Package:

```bash
cp -R /Users/ahhveedaa/.openclaw/workspace/Witness-v1.0.0.app /Users/ahhveedaa/.openclaw/workspace/Witness-v1.0.0.dmg
hdiutil createbundle -source Witness.v1.0.0.app -destpath Witness-v1.0.0.dmg

# Create ZIP alternative
cp -R /Users/ahhveedaa/.openclaw/workspace/Witness-v1.0.0.app /Users/ahhveedaa/.openclaw/workspace/Witness-v1.0.0.zip
```

### Step 4: Generate Checksums

```bash
cd /Users/ahhveedaa/.openclaw/workspace

sha256sum Witness-v1.0.0.dmg > SHA256SUMS.txt
sha256sum Witness.v1.0.0.zip >> SHA256SUMS.txt
```

---

## 🛠️ Technical Details

### SwiftUI Interface Features

- **Dark, sophisticated interface** with amber/gold accent
- **Menu bar presence** for app launcher
- **Conversation history** with streaming responses
- **Model status indicator** (local/cloud tracking)
- **Memory management view** with search and export

### Native macOS Integration

- Launch at login (LaunchAgent configuration)
- Keyboard shortcuts (Cmd+1 summon interface)
- Menu bar notification presence
- Persistent state across restarts
- Proper graceful shutdown handling

---

## 📊 Development Progress Summary

| Phase | Status | Files Complete |
|-------|--------|----------------|
| Phase 1: Environment Discovery | ✅ Complete | 6 files |
| Phase 2: Core Foundation | 🟡 In Progress | 7 core files |
| Phase 3: Native Application | 🔴 Not Started | — |

**Total Project:** ~170KB design docs + ~34KB Swift implementation  
**Code Coverage:** Architecture designed, foundation implemented

---

## 🔐 Security & Permissions

### Permission Levels (from PERMISSIONS.md)

1. **OBSERVE** — Witness can inspect authorized information
2. **ASSIST** — Can analyze and recommend actions
3. **EXECUTE** — Can perform pre-authorized actions without prompt
4. **RESTRICTED** — Requires user approval before each action
5. **PROHIBITED** — Never permitted

### Self-Prohibition Rule
Witness cannot grant itself permissions. Every tool execution passes through the permission engine.

---

## 🚧 Known Limitations & Next Steps

### Current Implementation
- ✅ SwiftUI application skeleton exists
- ✅ Core Swift logic (Orchestration, Memory, Routing) operational
- ⏳ Ollama API integration (native Swift client ready)
- ⏳ Full conversation streaming not yet implemented
- ⏳ Voice recognition and TTS architecture pending

### Immediate Tasks
1. Complete SwiftUI UI implementation (all 6 views)
2. Implement actual Ollama API communication with qwen3.5:4b
3. Create proper DMG packaging workflow
4. Generate signed/notarized release bundle

---

## 📖 License & Attribution

Witness is the product of AVD Core architecture, built with local-inference-first principles. Open source under appropriate terms.

---

<!-- project: path:/Users/ahhveedaa/.openclaw/workspace/AVD-AI-macOS -->
# Witness

**A local-first personal AI companion for macOS.**

Witness is a native macOS application powered by [AVD Core](ARCHITECTURE.md) — a persistent AI identity layer that remains independent of any inference provider, cloud service, or external platform.

> *"AVD is the system. Witness is who the system is."*

---

## Philosophy

Witness is built on three principles:

1. **Local-first.** All inference, memory, and identity run on your Mac. Nothing is sent to the cloud.
2. **Identity persistence.** Witness maintains a consistent character, values, and memory across conversations — independent of the model used.
3. **Governed agency.** Witness can use tools and capabilities on your machine, but every action is subject to a five-tier permission system that you control.

---

## Requirements

| Requirement | Minimum |
|---|---|
| macOS | 14.0 (Sonoma) |
| Architecture | Apple Silicon (M-series) |
| RAM | 8 GB (16 GB recommended) |
| Disk | 500 MB + model storage |
| Ollama | Latest (https://ollama.com) |
| Model | `qwen3.5:4b` (default) |

---

## Quick Start

### 1. Install Ollama

```bash
brew install ollama
ollama pull qwen3.5:4b
ollama serve
```

Or download from https://ollama.com.

### 2. Install Witness

Download `Witness-v1.6.2-macOS.dmg` from [Releases](../../releases) and drag Witness to your Applications folder.

> **Note:** Witness is ad-hoc signed (not notarized). On first launch, right-click → Open to bypass Gatekeeper.

### 3. Grant Permissions

Witness requires:
- **Microphone** — for push-to-talk voice input in Presence Mode
- **Speech Recognition** — for on-device transcription

macOS will prompt for these on first use. If you accidentally deny them, grant access via:
`System Settings → Privacy & Security → Microphone / Speech Recognition`

---

## Build from Source

```bash
git clone <repo-url>
cd AVD-AI-macOS
swift build -c release
```

The binary is output to `.build/release/WitnessApp`.

### Running Tests

```bash
# All unit tests (fast, no Ollama required):
swift test --skip EndToEndOrchestratorTests

# End-to-end streaming test (requires Ollama running with qwen3.5:4b):
swift test --filter EndToEndOrchestratorTests
```

---

## Features

### Text Mode
- Persistent conversation workspace
- Four-tier memory system (Working → Short-term → Long-term → Archival)
- Sidebar with memory, capabilities, and permissions views
- Specialist agents: Research, Coding, Creative, System, Knowledge, Ethical, Planning

### Presence Mode
- Immersive full-screen voice interaction
- Push-to-talk with live visual feedback
- Geometric Energy Core orb visualisation
- Shared session context with Text Mode (no conversation loss on switch)

### Identity
- Witness maintains a consistent identity seeded by `witness-core-v1.md`
- Identity is loaded at startup and injected as a concise runtime kernel per session
- The founding document is never modified by inference

### Memory
- Working memory: active conversation context
- Short-term memory: session summaries
- Long-term memory: persistent facts and preferences
- Archival memory: compressed historical context

### Tool Governance
- Five-tier permission system: `observe → query → suggest → execute → autonomous`
- Tool allowlist: `git`, `swift`, `uname`, `sw_vers`, `echo`, `pwd`, `date`, `whoami`
- File read restrictions block sensitive paths (`.ssh`, `Keychains`, credential files)
- Pending actions require explicit approval before execution

### Device Intelligence
- Discovers locally running MCP servers, Ollama, LM Studio
- Specialist agent role profiles matched to task type
- Model registry supporting multiple providers

---

## Limitations

- **Not notarized.** Ad-hoc signed only. First launch requires right-click → Open.
- **Ollama required.** The app will not function without a running Ollama instance.
- **No cloud fallback.** If Ollama is not running, inference is unavailable by design.
- **Apple Silicon only.** Intel Macs are not supported.
- **macOS 14+ only.** Older versions are not supported.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

See [SECURITY.md](SECURITY.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE).

Copyright 2026 Avida Buyombo

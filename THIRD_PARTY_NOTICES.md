# Third-Party Notices — Witness

Witness is built entirely on Apple system frameworks and contains no third-party
Swift packages. The following notices apply.

---

## Apple System Frameworks

Witness uses the following Apple SDK frameworks under the standard Apple SDK
License Agreement. No separate attribution is required by Apple's terms, but we
list them here for transparency.

| Framework | Purpose |
|---|---|
| SwiftUI | Declarative UI |
| AppKit | macOS window management, menus |
| AVFoundation | Audio engine, speech synthesis |
| Speech | On-device speech recognition |
| NaturalLanguage | Language detection |
| Combine | Reactive state management |
| Foundation | Core types, networking, JSON |

---

## Runtime Dependencies (User-Installed, Not Bundled)

The following software is required at runtime but is **not bundled** with
Witness. It is installed separately by the user and subject to its own license.

### Ollama
- **Website:** https://ollama.com
- **License:** MIT License
- **Purpose:** Local inference server used as the default model provider
- **Note:** Witness communicates with Ollama only over localhost (127.0.0.1:11434).
  No data is sent to Ollama's servers. Users are responsible for complying with
  the terms of any models they download through Ollama.

### qwen3.5:4b (default model)
- **Provider:** Alibaba Cloud / Qwen Team
- **License:** Qwen License Agreement
  (https://huggingface.co/Qwen/Qwen2.5-7B/blob/main/LICENSE)
- **Purpose:** Default local language model for inference
- **Note:** This model runs entirely on the user's device via Ollama.
  Witness does not download, bundle, or redistribute model weights.

### LM Studio (optional)
- **Website:** https://lmstudio.ai
- **License:** LM Studio Terms of Service
- **Purpose:** Optional alternative local inference provider
- **Note:** Supported as a secondary provider; not required for Witness to
  function. Models run locally.

---

## No Other Third-Party Code

Witness has no third-party Swift package dependencies. The `Package.swift`
`dependencies` array is empty. All functionality is implemented using Apple
system frameworks or original code authored for this project.

---

*This file was generated as part of the Witness v1.6.1 Apache 2.0 release.*

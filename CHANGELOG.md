# Changelog

All notable changes to Witness are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.6.1] — 2026-11-11

### Fixed
- **Critical voice crash:** Missing `NSSpeechRecognitionUsageDescription` and `NSMicrophoneUsageDescription` in `Info.plist` caused macOS TCC to terminate the app immediately on first microphone access with no dialog shown.
- `VoiceManager.startListening()` now gates on both microphone and speech recognition authorisation before touching hardware.
- Audio engine and tap are properly cleaned up on failure via `cleanupAudioEngine()`.
- Mute enforcement blocks `startListening()` when `audioMuted == true`.
- `presenceState` transitions are correct across all paths: IDLE→LISTENING→IDLE, IDLE→SPEAKING→IDLE, PAUSED, ERROR.
- Overlapping recording and speech playback is now prevented.

### Added
- `AudioPermissionState` enum with `.authorized`, `.denied`, `.restricted`, `.notDetermined`, `.unavailable`.
- `refreshPermissionStates()` — checks both `AVCaptureDevice` (mic) and `SFSpeechRecognizer` (speech) independently.
- `requestPermissions(completion:)` — two-step sequential authorisation (mic first, then speech).
- `permissionGuidanceMessage` — UI-displayable System Settings path instructions for denied permissions.
- `Resources/Info.plist` with both required TCC keys.
- 4 new `VoiceStabilityV161Tests` unit tests covering permission lifecycle, unauthorised activation, repeated activation, and mute enforcement.

### Changed
- `Voice.swift` rewritten with safe state machine; all hardware access gated behind permission checks.
- `Info.plist` version set to 1.6.1, build 7.

### Documentation
- Apache License 2.0 (`LICENSE`, `NOTICE`, `THIRD_PARTY_NOTICES.md`)
- `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md`
- `.gitignore` added

---

## [1.6.0] — 2026-11

### Added
- **Presence Mode** — Immersive full-screen voice interaction interface.
- **Geometric Energy Core** — Animated orb visualisation reflecting AI state.
- Two interaction modes: Text Mode and Presence Mode, with shared session context.
- Push-to-talk voice input with visual feedback rings.
- Presence state machine: IDLE, LISTENING, CONTEMPLATING, SPEAKING, PAUSED, ERROR.
- Mute toggle and compact companion panel.

### Known Issues
- Missing `NSSpeechRecognitionUsageDescription` causes TCC crash on first voice activation (fixed in v1.6.1).

---

## [1.5.0] — 2026-11

### Added
- **Device Intelligence** — Discovers locally running services (Ollama, LM Studio, MCP servers).
- **Specialist Agent architecture** — Seven logical agent roles: Research, Coding, Creative, System, Knowledge, Ethical, Planning.
- **Model Registry** — Tracks available models across providers; routes tasks to appropriate specialist.
- `DeviceDiscovery.swift` — HTTP probes to localhost ports; no external network calls.
- `SpecialistAgents.swift` — Agent role profiles with capability descriptors.
- `ModelRegistry.swift` — Provider-agnostic model inventory.
- 6 new `DeviceIntelligenceV15Tests` unit tests.

---

## [1.4.0] — 2026-11

### Added
- **Four-tier memory** — Working, Short-term, Long-term, Archival with consolidation and retrieval.
- **Voice synthesis** — AVSpeechSynthesizer integration with interrupt and replay.
- **Push-to-talk recognition** — SFSpeechRecognizer with on-device transcription.
- **Five-tier permission enforcement** — observe, query, suggest, execute, autonomous.
- **Modular tool registry** — Command allowlist, file read restrictions, pending action approval workflow.
- **Model router** — Task classification and provider selection (Ollama primary, LM Studio secondary).
- 8 `AVDCoreContinuityVoiceAgencyTests` unit tests.

---

## [1.3.0] — 2026-11

### Added
- Memory relevance retrieval with ranking by recency and importance.
- Context injection into inference prompts.
- Conversation consolidation on session end.

---

## [1.2.0] — 2026-11

### Added
- Identity persistence across sessions.
- Witness runtime kernel (concise identity injection per request).
- Short-term and long-term memory tiers.
- End-to-end streaming conversation test.

---

## [1.1.0] — 2026-11

### Added
- Visual identity refinement — `WitnessTheme` colour palette.
- Native SwiftUI interface: conversation workspace, memory sidebar, permissions view.
- `AVDCore` library target separated from `WitnessApp` executable.

---

## [1.0.0] — 2026-11

### Added
- Initial `AVDCore` architecture — identity, memory, permissions, model routing, orchestrator.
- `witness-core-v1.md` founding document integrated.
- Basic Ollama streaming inference.
- 4 initial `AVDCoreTests` unit tests.

# VOICE_DESIGN.md - WITNESS V1 Voice Interface Specification

**Critical Status: Requires Rewrite to Reflect macOS Reality**

---

## EXECUTIVE SUMMARY - CRITICAL FEASIBILITY GAP IDENTIFIED

### ❌ Document Overstates macOS Capabilities

**Current document incorrectly claims:**
- Native Speech-to-Text (STT) integration exists on macOS
- Native SystemVoice for text-to-speech exists
- Whisper/Turbo modes are available in macOS API
- Voice identity matching is built into macOS session tracking

**macOS Reality Check:**
| Claimed Capability | Does macOS Support This? | Impact | Resolution Required |
|--------------------|--------------------------|--------|---------------------|
| Native STT (speech-to-text) | ❌ **NO** - not available in macOS native API | Cannot implement voice command handling without external service | **ASPIRATION ONLY** - must be marked as external dependency |
| SystemVoice TTS | ⚠️ Limited - basic text synthesis only | Not the "native" capability claimed in document | Document must clarify this is minimal feature |
| Whisper/Turbo modes | ❌ **NO** - not available in macOS API | Overpromises voice capabilities | Must state all voice uses external service |
| Voice identity matching | ❌ **NO** - requires complex session tracking | Impossible to match without user gesture | Must document limitation explicitly |

---

## CURRENT STATE: NO NATIVE VOICE SUPPORT ON macOS

Voice functionality is **NOT POSSIBLE** with current macOS runtime infrastructure. All voice commands require:

1. **External STT Service Integration** (not available in app shell)
2. **Network Access** to cloud-based speech recognition services (privacy concerns)
3. **Separate Session Tracking Layer** for voice identity matching

### What's NOT Possible on Current macOS:
- ❌ Native Speech-to-Text without external service
- ❌ "Turbo" or streaming STT modes in macOS API
- ❌ Voice identity matching across sessions without user action

---

## PROPOSED SOLUTION - EXTERNAL DEPENDENCY ARCHITECTURE

Since native voice support doesn't exist, the design must be rewritten as an **external dependency layer**:

### Recommended Architecture

**Voice Command Layer** should be implemented as:
- ✅ **External Integration Only** - Use Whisper API or similar external STT service
- ✅ **No Native Capabilities** - Document clearly that no macOS native voice features exist
- ✅ **Graceful Fallback** - All systems must degrade gracefully to text input

### Alternative Approaches (Ranked by Feasibility)

| Option | Description | Effort | Feasibility | MVP Impact |
|--------|-------------|--------|-------------|------------|
| External Whisper API | Integrate cloud-based STT service | ~6 hours + ongoing maintenance | ✅ High | Can be added post-MVP |
| macOS Voice Control App | Use system-level voice control integration | ~12 hours (requires app bundle registration) | ⚠️ Medium | Adds dependency, needs user setup |
| Text Only | No voice capability whatsoever | 0 extra hours | ✅ Highest | Voice layer completely optional |

**Recommended Approach: External Whisper API Integration**
- Add "Voice Command Layer" as Phase 2 external dependency (not core)
- Document clearly it requires external service, not native capability
- Keep MVP focused on identity/memory/reasoning
- Voice functionality added as optional enhancement

---

## DESIGN IMPLICATIONS

### Current Document Claims vs. Reality

| Current Claim | Actual macOS State | Required Fix | Priority |
|---------------|-------------------|---------------|----------|
| "SystemVoice STT integration" | Does NOT exist | Rewrite section to state limitation | **P0** |
| "Native whisper/Turbo modes" | Do NOT exist | Mark as external dependency only | **P0** |
| "Voice identity matching across sessions" | Not built-in | Document requires external tracking | **P1** |

---

## RECOMMENDED PHASE 3 SEQUENCE

### Phase 3A: Foundation Fix (Priority: HIGH)

| Step | Action | Dependencies | Effort | Status |
|------|--------|--------------|--------|--------|
| 3.1 | Document macOS reality in VOICE_DESIGN.md | None | 30 min | **BLOCKER** |
| 3.2 | Mark voice layer as external dependency only | 3.1 complete | 15 min | **BLOCKER** |

### Phase 3B: Build & Test (Priority: MEDIUM)

| Step | Action | Dependencies | Effort | Status |
|------|--------|--------------|--------|--------|
| 3.3 | Accept Xcode license (user action) | None | Manual | **BLOCKER** |
| 3.4 | Fix Swift syntax errors | 3.1-3.3 complete | 2 hours | **PRIORITY** |
| 3.5 | Create standalone executable | 3.4 complete | 1 hour | Ready |

### Phase 3C: Runtime Verification (Priority: MEDIUM)

| Step | Action | Dependencies | Effort | Status |
|------|--------|--------------|--------|--------|
| 3.8 | Test qwen3.5:4b via Ollama | 3.5-3B complete | 30 min | ✅ Verified working |
| 3.10 | Voice layer integration (external only) | 3.5 + user action | TBD | OPTIONAL |

---

## DECISION REQUIRED BEFORE PROCEEDING

### DEC-02: Voice Command Scope Definition

**Question**: Should voice commands be part of MVP?

**Options:**
- **External Service Only** (~6 hours setup, ongoing maintenance) → Voice works via Whisper API
- **Text Only** (0 extra hours) → No voice capability, fully text-based
- **Wait for macOS Feature** → Years development timeline (NOT feasible)

**Recommendation: Text-only MVP with External Voice Dependency**
- Focus MVP on core capabilities (identity, memory, reasoning)
- Add Whisper API integration as Phase 2 optional feature
- Document clearly that voice layer is external dependency

---

## CRITICAL NOTE

This document **MUST** be rewritten to reflect the actual capability gap. Current claims are factually incorrect and create unrealistic expectations about what can be built on current macOS infrastructure.

**Action Required: Rewrite complete VOICE_DESIGN.md before proceeding with build phases.**

# ROADMAP.md - WITNESS V1 Implementation Priority

**Version:** 0.2 | **Author:** Avida Buyombo | **Date:** 2026-11-11 | **Status:** ACTIVE

---

## Executive Summary

This document defines the execution sequence for building WITNESS V1, a native macOS intelligent agent application. The roadmap establishes priority ordering from foundation through production deployment, with clear dependency chains and milestone definitions.

---

## Phase 0: Pre-Build Foundation (Priority A)
**Duration:** 1-2 hours  
**Dependencies:** None

| Step | Action | Deliverable | Status | Effort |
|------|--------|--------------|--------|--------|
| 0.1 | Create ROADMAP.md | Implementation priority ordering exists | ✅ Complete | 30 min |
| 0.2 | Fix ARCHITECTURE status | "In Production Testing" vs "Pending Approval" resolved | ✅ Complete | 15 min |
| 0.3 | Rewrite VOICE_DESIGN.md | Reflects macOS reality (no native STT) | ✅ Complete | 30 min |

**Deliverables:**
- ROADMAP.md exists with clear phase sequencing
- ARCHITECTURE.md status matches actual state
- VOICE_DESIGN.md accurately reflects macOS limitations

---

## Phase 1: Core Foundation (Priority A)
**Duration:** 4-6 hours  
**Dependencies:** None

| Step | Action | Deliverable | Status | Effort |
|------|--------|--------------|--------|--------|
| 1.1 | Fix Swift syntax errors | All files compile without warnings | ⏳ Pending | 2-3 hours |
| 1.2 | Verify Ollama connectivity | qwen3.5:4b accessible via API | ❌ Not Tested | 30 min |
| 1.3 | Validate memory subsystem | Memory engine functional | ❌ Not Verified | 1 hour |

**Critical Issues Identified:**
- OllamaIntegration.swift does not exist (claimed in build report)
- Main.swift syntax requires verification
- AVDCore files need syntax validation

---

## Phase 2: Intelligence Layer Development (Priority A)
**Duration:** 6-8 hours  
**Dependencies:** Phase 1 complete

| Step | Action | Deliverable | Status | Effort |
|------|--------|--------------|--------|--------|
| 2.1 | Implement Identity System | Persistent identity storage & retrieval | ❌ Not Built | 4 hours |
| 2.2 | Build Memory Engine | Four-tier memory architecture (Working, Episodic, Semantic, Procedural) | ❌ Not Built | 5 hours |
| 2.3 | Create Model Routing Layer | qwen3.5:4b routing with cloud fallback | ⏳ In Progress | 3 hours |
| 2.4 | Integrate Permission System | Five-tier permission enforcement (OBSERVE→PROHIBITED) | ❌ Not Built | 3 hours |

**Voice Layer Status:**
- ❌ Native voice NOT available on macOS
- 🔲 External Whisper API option requires cloud service signup
- ✅ Text-only mode is feasible MVP approach

---

## Phase 3: Build & Validation (Priority B)
**Duration:** 4-8 hours  
**Dependencies:** Phase 2 complete

| Step | Action | Deliverable | Status | Effort | Dependencies |
|------|--------|--------------|--------|--------|-------------|
| 3.1 | Accept Xcode license | `xcodebuild -license` completed | ⏳ Pending (User) | N/A | None |
| 3.2 | Fix remaining Swift errors | Compilation succeeds | ⏳ Awaiting fixes | 1-2 hours | Phase 2.1-2.4 |
| 3.3 | Build native .app bundle | `/Users/ahhveedaa/.openclaw/workspace/AVD-AI-macOS/Witness.app` | ❌ Blocked | 2 hours | 3.1, 3.2 |
| 3.4 | Create standalone executable | `WitnessStandalone` at workspace root | ❌ Cannot build until 3.3 | 1 hour | 3.3 |

**Xcode License Requirement:**
```bash
# User must execute in Terminal:
sudo xcodebuild -license

# Result should confirm license acceptance before proceeding
```

---

## Phase 4: Runtime Testing (Priority B)
**Duration:** 2-4 hours  
**Dependencies:** Phase 3 complete

| Step | Action | Deliverable | Status | Effort | Dependencies |
|------|--------|--------------|--------|--------|-------------|
| 4.1 | Test Ollama integration | qwen3.5:4b returns rhyming responses | ❌ Not Tested | 1 hour | 3.4 |
| 4.2 | Verify memory persistence | Session continues across restarts | ❌ Not Tested | 1 hour | 3.4 |
| 4.3 | Test permission enforcement | Five-tier hierarchy enforced correctly | ❌ Not Tested | 1 hour | 3.4 |

**Test Scenarios:**
1. Chat with qwen3.5:4b via API → verify rhyming response pattern
2. Restart app → check MEMORY.md persistence retained
3. Attempt permission violation → verify rejection logged
4. Test memory retrieval → confirm semantic similarity works

---

## Phase 5: Artifact Delivery (Priority B)
**Duration:** 1-2 hours  
**Dependencies:** Phase 4 complete

| Step | Action | Deliverable | Status | Effort | Dependencies |
|------|--------|--------------|--------|--------|-------------|
| 5.1 | Build DMG package | `/Users/ahhveedaa/.openclaw/workspace/AVD-AI-macOS/Witness-v1.0.0.dmg` | ❌ Not Built | 30 min | 4.3 |
| 5.2 | Create ZIP archive | `Witness-v1.0.0.zip` | ❌ Not Built | 30 min | 4.3 |
| 5.3 | Generate SHA256 checksums | `SHA256SUMS.txt` | ❌ Cannot generate until build | 30 min | 5.1, 5.2 |

**Build Commands:**
```bash
# Build native app (requires Xcode license)
xcodebuild -project Witness.xcodeproj -configuration Release build

# Extract to standalone
cp -R Contents/MacOS/Witness .
mv Witness WitnessStandalone
rm -rf Witness.app
```

---

## Phase 6: Production Integration (Priority C)
**Duration:** Ongoing  
**Dependencies:** Phase 5 complete

| Step | Action | Deliverable | Status | Effort | Dependencies |
|------|--------|--------------|--------|--------|-------------|
| 6.1 | Mount DMG and test | Application launches cleanly | ❌ Not Tested | 1 hour | 5.1 |
| 6.2 | Integrate with OpenClaw control systems | App registers in agent infrastructure | ⏳ Plan TBD | TBD | N/A |
| 6.3 | Test memory session persistence | User preferences retained across sessions | ❌ Not Tested | Ongoing | 4.2 |

**Integration Points:**
- OpenClaw Control UI registration
- Gateway heartbeat monitoring
- Memory sync with cluster instances

---

## Implementation Timeline Summary

```
Time        Phase       Status         Blockers
----------------------------------------------------------------------------------
0:00-1:00   Phase 0    ✅ COMPLETE     None
1:00-5:00   Phase 1    ⏳ IN PROGRESS   Swift syntax, Xcode license
5:00-13:00  Phase 2    ❌ BLOCKED       Need syntax fixes first
13:00-17:00 Phase 3    ❌ BLOCKED       Need Phase 2 complete
```

---

## Critical Blockers (MUST BE RESOLVED)

| Blocker ID | Issue | Severity | Resolution |
|------------|-------|----------|------------|
| BLOCK-01 | Xcode License Required | **P0** | User must run `sudo xcodebuild -license` |
| BLOCK-02 | Swift Syntax Errors | P1 | Fix OllamaIntegration.swift, Main.swift (files may not exist) |
| BLOCK-03 | Missing Files | P1 | Verify what files actually exist vs. reported |

**Resolution Path:**
1. User accepts Xcode license (immediate action required)
2. Author verifies actual file state and fixes/create missing files
3. Build becomes possible → proceed to runtime testing

---

## Decision Required Before Proceeding

| Decision ID | Question | Options | Recommended Status |
|-------------|----------|---------|-------------------|
| DEC-04 | Xcode license acceptance | User accepts now vs. later | **Accept immediately** |
| DEC-05 | File state verification | Trust build report or verify files | **Verify first** |
| DEC-06 | Voice layer scope | Exclude from MVP or add external dependency | **Exclude from core MVP** |

---

## Phase Completion Criteria

| Phase | Criterion | Threshold |
|-------|-----------|-----------|
| Phase 0 | All design docs exist and accurate | 100% |
| Phase 1 | All Swift files compile without warnings | 100% |
| Phase 2 | Identity/memory/routing functional | ≥95% |
| Phase 3 | Full app builds successfully | 100% |
| Phase 4 | Runtime tests pass | ≥90% |
| Phase 5 | Artifacts verifiable | 100% |

---

<!-- project: path:/Users/ahhveedaa/.openclaw/workspace/AVD-AI-macOS -->

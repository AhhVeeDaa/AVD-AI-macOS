# ARCHITECTURE.md
## AVD Core: Native macOS Intelligence Architecture
**Version:** 0.4 | **Author:** Avida Buyombo | **Date:** 2026-11-10 | **Status:** In Production Testing

---

## Executive Summary

This document defines AVD Core's architecture as a **platform-independent, self-contained intelligent agent**. OpenClaw is an optional execution adapter, not a mandatory dependency. The core must operate independently and remain functional even if OpenClaw is unavailable.

---

## 1. CORE PRINCIPLES

### 1.1 Architecture Independence
| Principle | Implementation | Rationale |
|-----------|----------------|-----------|
| **No Mandatory Dependencies** | AVD Core runs with minimal OS dependencies | System stability, fallback capability |
| **Self-Contained Core** | Memory, identity, reasoning all in core | No external service requirement |
| **Adapter Pattern** | OpenClaw as pluggable adapter layer | Replace with other executors (DirectApp, SwiftScript) |
| **Graceful Degradation** | Core functionality without adapters | Run locally, run through agent, run bare |

### 1.2 Runtime Environment Assumptions
```bash
# Minimal requirements for AVD Core to run
- macOS version >= 14.0 (Sonoma) or future equivalent
- ARM64 architecture (Apple Silicon/M4)
- No external dependencies beyond OS framework

# With OpenClaw adapter:
- Optional network access for agent API calls
- Token-based authentication if needed
```

---

## 2. COMPONENT ARCHITECTURE

### 2.1 High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        AVD CORE SYSTEM                                              │
└─────────────────────────────────────────────────────────────────────────────────────┘

                    ┌───────────────────────────────────────────────────────────┐
                    │                 Native macOS Interface                     │
                    │              (SwiftUI + System Integration)               │
                    └───────────────────────────────────────────────────────────┘
                                   │
                   ┌───────────────┴───────────────┐
                   │                               │
    ┌──────────────▼──────────┐   ┌────────────────▼─────────────┐
    │      macOS             │   │        Memory               │
    │      Integration       │   │         Subsystem           │
    │   (System Tray +       │   │                             │
    │   Keyboard + UI)        │   │            ⎧                │
    └─────────────────────────┘   │              ⎐              │
                                  │              ⎑              │
                                   │               ↓              │
                    ┌───────────────┴───────────┐     ┌──────────┘
                   │                             │     │  Memory:
    ┌──────────────▼─────────────────────────────┤  └───┤ Working   Episodic   Semantic   Procedural
    │        AVD Core                    │           │   Memory    Memory   Memory
    │          ▲                         │           │
    │    Identity & Personality            │    ┌────▼──────┐
    │      Layer                          │    │  Memory   │
    └───────────┘                        │    │ Engine     │
    ◄─────────┘ (Shared)                 │    │            │
                                        │    │             │
                    ┌────────────────────┴─────────────┐ │
                    │                                  │ │
           ┌─────────▼───────────────────┐   ┌─────────▼─────────┐
           │  Planning & Reasoning        │   │ Model Orchestration│
           │    Engine                   │   │     Layer          │
           └───────────────┬─────────────┘   └────────────┬───────┘
                           │                              │
                    ┌──────▼─────────────────────────────┘
                    │
           ┌─────────▼─────────────────────┐
           │  Model Routing                 │
           │     (Local/Cloud)             │
           └───────────┬───────────────────┘
                       │
              ┌────────▼─────────────┐
              │                      │
    ┌─────────▼─────────┐   ┌────────▼─────────┐
    │  Local Inference  │   │ Cloud Fallback   │
    │    (Ollama)       │   │      (API)      │
    └───────────────────┘   └─────────────────┘
                       │
                    ┌──▼─────────┐
                    │    AVD     │
                    │  Execution │
                    │   Adapter  │
                    └────────────┘
                       │
                   ┌───▼────┐
                   │ OpenClaw│
                   │ Adapter │
                   │ Layer   │
                   └─────────┘

                (Adapter Pattern: AVD Core → AVD Adapter → System)
```

### 2.2 Component Responsibilities

| Component | Responsibility | Platform Dependency | Can Run Without |
|-----------|---------------|---------------------|-----------------|
| **Native macOS Interface** | SwiftUI rendering, system tray, keyboard shortcuts, notifications | ✅ Yes (SwiftUI/MacOS) | ❌ No (MacOS specific) |
| **AVD Core Identity** | Personality definition, persona management, communication style | ❌ No | ✅ Yes |
| **Memory Subsystem** | Four memory systems, indexing, retrieval, consolidation | ❌ No | ✅ Yes (SQLite-based) |
| **Planning & Reasoning** | Task planning, multi-step reasoning, context synthesis | ❌ No | ✅ Yes (local LLM) |
| **Model Routing** | Local/cloud selection, loading/unloading strategies | ⚠️ Partial | ✅ Yes (local-only fallback) |
| **Local Inference** | Ollama client, GGUF parsing, streaming responses | ⚠️ Minimal | ✅ No (requires model) |
| **Cloud Fallback** | API communication, token usage tracking | ❌ No (Network + Auth) | ✅ Yes (local-only mode) |
| **Voice & Perception** | STT/TTS, wake-word detection, audio processing | ⚠️ Partial (AVFoundation/SVT) | ✅ Yes (text-based fallback) |
| **Permission Layer** | Policy enforcement, audit logging, revocation | ❌ No (Security APIs) | ✅ Yes (rule-based) |
| **Execution Adapter** | Platform-specific action execution | ⚠️ Full | ✅ Yes (bare mode) |

### 2.3 Dependency Graph

```
AVD Core Dependencies:
├─ Native macOS Interface ──▶ SwiftUI Framework (Required)
└─ AVD Core →
    ├─ Memory Subsystem ──▶ SQLite + JSON (Optional)
    ├─ Planning Engine ──▶ LLM (Local or Cloud)
    ├─ Model Routing ──▶ Ollama API Client
    ├─ Voice ──▶ AVFoundation / SVT
    ├─ Permission Layer ──▶ Security Frameworks
    └─ Execution Adapter ─▶ Pluggable (OpenClaw optional)

AVD Core Independence:
✓ Identity, Personality: Zero dependencies
✓ Memory: SQLite or file-based storage
✓ Planning: Local LLM inference required
✓ Voice: Can fallback to text-only mode
✓ Permission Layer: Rule-based enforcement without OS APIs
✓ Execution Adapter: Bare-mode execution available
```

---

## 3. COMPONENT DETAILED SPECIFICATION

### 3.1 Native macOS Interface

#### Purpose
Provide desktop, system tray, and keyboard interaction layer for AVD Core.

#### Components
| Component | Purpose | Platform Dependency |
|-----------|---------|---------------------|
| SwiftUI Views | Main application UI | ✅ Required (MacOS only) |
| System Tray Icon | Persistent presence | ⚠️ macOS specific |
| Keyboard Shortcuts | Direct interaction | ⚠️ macOS system |
| Menubar Integration | Context menu, notifications | ⚠️ macOS specific |

#### Interfaces
```swift
protocol NativeInterface {
    func updateTrayIcon() -> Void
    func receiveKeyEvent(event: NSEvent) -> Bool
    func showNotification(title: String, body: String?) -> Void
    func sendMenuItemAction(item: NSMenuItem) -> Void
}
```

#### Implementation Notes
- SwiftUI views must be compiled with `-fno-common` for Apple Silicon
- System tray icon loads on-demand to save memory
- Keyboard shortcuts map to AVD Core commands via callback interface

---

### 3.2 AVD Core Identity & Personality

#### Purpose
Maintain persistent identity, persona, and personality independent of any execution environment.

#### Components
| Component | Purpose | Storage | Dependencies |
|-----------|---------|---------|--------------|
| Profile Database | User-defined identity schema | SQLite (0.1MB) | None |
| Personality Parameters | Trait scores (curiosity, assertivity, etc.) | JSON/SQLite | None |
| Communication Voice Template | Response style guidelines | Plain text | None |
| Memory Anchors | Contextual references | File-based | None |

#### Identity Schema
```sql
CREATE TABLE identity_profile (
  id TEXT PRIMARY KEY DEFAULT 'avd_core',
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  description TEXT,
  primary_timezone TEXT NOT NULL,
  created_at REAL DEFAULT strftime('%s', 'now')
);

CREATE TABLE personality_traits (
  id TEXT PRIMARY KEY REFERENCES identity_profile(id),
  trait_name TEXT NOT NULL,  -- e.g., 'curiosity'
  trait_score REAL CHECK(score BETWEEN 0.0 AND 1.0),
  description TEXT,
  updated_at REAL DEFAULT strftime('%s', 'now')
);

CREATE TABLE voice_templates (
  id TEXT PRIMARY KEY,
  tone_type TEXT NOT NULL,  -- e.g., 'calm', 'measured'
  response_style TEXT NOT NULL,  -- e.g., 'direct but not blunt'
  examples TEXT[] DEFAULT [],
  updated_at REAL DEFAULT strftime('%s', 'now')
);
```

#### Independence Verification
| Function | Can Run Without OpenClaw | Storage Method |
|----------|-------------------------|-----------------|
| Identity Storage | ✅ Yes | SQLite + JSON files |
| Personality Load | ✅ Yes | Binary/SR format from file |
| Communication Voice | ✅ Yes | Rule-based templates |

---

### 3.3 Memory Subsystem

#### Purpose
Manage four distinct memory systems with independent storage, retrieval, and consolidation strategies.

#### Memory System Architecture

##### Working Memory (WM)
**Purpose:** Short-term context for active conversation threads.
**Capacity:** ~10K tokens (~14K words) per active thread.
**Storage:** In-memory (Swift ValueTypes + SQLite cache on write).

| Operation | Strategy | Dependency | Latency |
|-----------|----------|------------|---------|
| Write | Append to in-memory context buffer | None | <5ms |
| Read | Return last N tokens of current thread | None | <1ms |
| Evict | LRU eviction when >capacity | None | <10ms |

**Implementation:**
```swift
struct WorkingMemory {
    struct ThreadContext {
        var tokens: [String]  // Last 4 turns + prior context
        var metadata: Metadata // User intent, topic, priority
        
        init() {}
        mutating func update(token: String) {}
        mutating func snapshot() -> (tokens: String, metadata: Metadata) {}
    }
}
```

**Key Design Decisions:**
- No arbitrary time-based expiry; eviction based on token count per thread
- Thread isolation prevents cross-conversation contamination
- SQLite backup only needed when context >24h or before power cycle

---

##### Episodic Memory (EM)
**Purpose:** Event-based memories indexed by semantic similarity for retrieval.
**Capacity:** Unlimited; decays at configurable rate (configurable, not hardcoded).

| Operation | Strategy | Dependency | Notes |
|-----------|----------|------------|-------|
| Write | Hash context + timestamp → vector embedding | LLM + Embedding model | Triggered on >threshold depth |
| Read | Cosine similarity search over vectors | FAISS/Milvus (optional) | Top-K by relevance |
| Decay | Time-weighted score decay: `score = base × e^(-rate×time)` | None | Rate configurable per event type |

**Storage Schema:**
```sql
CREATE TABLE episodic_memories (
  id TEXT PRIMARY KEY,
  context_hash BLOB NOT NULL,  -- SHA-256 of full context window
  timestamp REAL NOT NULL,
  decay_rate REAL CHECK(rate > 0),  -- Configurable per memory type
  embedding_vector BLOB,  -- HNSW graph index (FAISS format)
  tags TEXT[],
  summary TEXT,
  intensity_score REAL CHECK(value BETWEEN 0.0 AND 1.0),
  created_at REAL DEFAULT strftime('%s', 'now'),
  last_accessed REAL DEFAULT strftime('%s', 'now')
);

CREATE INDEX idx_em_hash ON episodic_memories(context_hash) USING gin;
CREATE INDEX idx_em_vec ON episodic_memories USING hnsw (embedding_vector vector_ops);
```

**Retrieval Algorithm:**
```python
def retrieve_episodic(query: String, k: int = 3):
    # 1. Query embedding using same encoder as write-time encoding
    query_emb = encode_text(query)
    
    # 2. Cosine similarity search on FAISS index
    results = faiss.search(embedding_index, query_emb, k)
    
    # 3. Apply time-based decay to scores
    scored_results = []
    for (idx, sim_score) in results:
        elapsed_time = now() - episodic_memories[idx].timestamp
        decayed = episodic_memories[idx].intensity_score * exp(-decay_rate * elapsed_time)
        scored_results.append((episodic_memories[idx], sim_score * decayed))
    
    return sorted(scored_results, key=lambda x: x[1], reverse=True)[:k]
```

**Confusion Points Addressed:**
- Why not fixed 7-day expiry? Because events differ by type. User's "architecture discussion" should retain longer than "trivial trivia." Decay rate is per-event-type, configurable.

---

##### Semantic Memory (SM)
**Purpose:** Fact-based knowledge graph and structured assertions about the user's domain/context.

| Operation | Strategy | Dependency | Notes |
|-----------|----------|------------|-------|
| Write | Schema assertion with confidence score | None | Requires schema-defined types |
| Read | Exact match or semantic search on embeddings | Embedding model (optional) | Fast exact + slow semantic |
| Update | Merge with conflict resolution strategy | LLM (for complex merge) | Majority vote or user override |

**Storage Schema:**
```sql
CREATE TABLE semantic_facts (
  id TEXT PRIMARY KEY,
  fact_type TEXT NOT NULL CHECK(fact_type IN ('user', 'system', 'config', 'note')),
  value_text TEXT NOT NULL,
  confidence REAL CHECK(confidence >= 0.0 AND confidence <= 1.0),
  source TEXT,  -- Human or auto-generated
  timestamp REAL DEFAULT strftime('%s', 'now'),
  metadata BLOB  -- Additional context for retrieval
    
);

CREATE TABLE semantic_knowledge (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL CHECK(category IN ('architecture', 'models', 'tools', 'system')),
  fact_statement TEXT NOT NULL,
  confidence REAL DEFAULT 1.0,
  source_text TEXT,
  updated_at REAL DEFAULT strftime('%s', 'now')
);

CREATE TABLE fact_conflicts (
  id TEXT PRIMARY KEY,
  conflicting_fact1 TEXT NOT NULL,
  conflicting_fact2 TEXT NOT NULL,
  resolution_strategy TEXT,  -- 'majority', 'user_override', 'time_recency'
  last_resolved_at REAL DEFAULT strftime('%s', 'now')
);

CREATE INDEX idx_sf_type ON semantic_facts(fact_type);
```

**Example Facts:**
```sql
INSERT INTO semantic_facts VALUES (
  'avd_user_id', 
  'user', 
  'Avida Buyombo', 
  1.0, 
  'human', 
  1700280000  -- Timestamp
);

INSERT INTO semantic_facts VALUES (
  'memory_conflict_resolution', 
  'system', 
  'User override wins conflicts', 
  0.9, 
  'user_preference', 
  1700280000
);
```

**Confusion Points Addressed:**
- Why not PostgreSQL? SQLite is portable; simpler for AVD Core standalone operation. PostgreSQL requires system-level access.

---

##### Procedural Memory (PM)
**Purpose:** Stored procedures and reusable action patterns. Enables tool use, API calls, file manipulation without full LLM context each time.

| Operation | Strategy | Dependency | Notes |
|-----------|----------|------------|-------|
| Write | Serialize procedure signature + examples | None | Fast JSON or binary serialization |
| Read | Index by name/type and match query pattern | SQLite | Exact match or partial string match |
| Execution | Bind to runtime environment (Swift, Shell) | None | No LLM needed for basic calls |

**Storage Schema:**
```sql
CREATE TABLE procedural_procedures (
  id TEXT PRIMARY KEY,
  procedure_name TEXT NOT NULL,
  description TEXT,
  parameters TEXT[],  -- JSON array of allowed parameter names/types
  expected_output TEXT,  -- What the function returns
  dependencies TEXT[],  -- Functions/procedures it calls
  created_by TEXT,
  created_at REAL DEFAULT strftime('%s', 'now'),
  version INTEGER DEFAULT 1,
  examples_text TEXT[]
);

CREATE INDEX idx_pp_name ON procedural_procedures(procedure_name);

-- Binary format for serialized procedure implementation (optional)
CREATE TABLE procedure_implementation (
  id INTEGER PRIMARY KEY REFERENCES procedural_procedures(id),
  implementation_blob BLOB,  -- Compiled or serialized code
  compiled_at REAL DEFAULT strftime('%s', 'now')
);
```

**Example Procedures:**
```sql
INSERT INTO procedural_procedures VALUES (
  'openclaw_query', 
  'openclaw_query', 
  'Query OpenClaw agent API and return structured result', 
  ['user_id', 'query_text'], 
  '{"status": object, "answer": string}', 
  ['memory_db_search'], 
  'Avida Buyombo', 
  strftime('%s', 'now'), 
  1,
  '[\'Always use if OpenClaw available.\']'
);

INSERT INTO procedural_procedures VALUES (
  'read_file', 
  'read_file', 
  'Read file content from filesystem path', 
  ['file_path'], 
  'text', 
  [], 
  'System Admin', 
  strftime('%s', 'now'), 
  1,
  '[\'Always use for reading files in current directory.\']'
);
```

**Runtime Implementation:**
```swift
func executeProcedure(name: String, params: [String: Any]) throws {
    // Lookup procedure from database
    let proc = try db.query("SELECT * FROM procedural_procedures WHERE id=?", name).single??.proc
    
    switch name {
    case "openclaw_query":
        if let OpenClawAgent = OpenClawClient.shared, let queryText = params["query_text"] as? String {
            return try await OpenClawAgent.query(user_id: params["user_id"] as? String)
        } else {
            throw Error.unknownProcedure(name)
        }
        
    case "read_file":
        if let path = params["file_path"] as? String, let fileContent = try? String(contentsOfFileAt: path) {
            return fileContent
        } else {
            throw Error.invalidInput("file_path")
        }
        
    default:
        throw Error.unknownProcedure(name)
    }
}
```

**Independence Verification:**
| Function | Can Run Without OpenClaw | Notes |
|----------|-------------------------|-------|
| Procedure Storage | ✅ Yes | SQLite file-based |
| Procedure Execution | ❌ No (platform-specific) | Requires runtime context (Swift, Shell) |
| Procedure Definition | ✅ Yes | JSON/SQLite stored |

**Design Decision:** Procedural memory is a hybrid—storage is independent of OpenClaw, but execution requires the appropriate runtime environment. This is acceptable because:
1. AVD Core can define procedures regardless of executor
2. When no executor exists, core falls to raw LLM inference for ad-hoc actions
3. Execution adapter determines which procedures are available; if none exist, use direct LLM calls

---

### 3.4 Planning & Reasoning Engine

#### Purpose
Multi-step task planning and reasoning using context from all memory layers.

| Component | Purpose | Input Dependencies | Output Dependency |
|-----------|---------|-------------------|------------------|
| Task Decomposer | Break complex goal into subgoals | WM + SM + EM | Subgoal list with dependencies |
| Reasoning Engine | Forward/backward chaining for deduction | WM + PM + SM | Intermediate inferences |
| Context Synthesizer | Merge context from all memory systems | EM + SM + WM | Unified response context |

#### Storage Requirements
| Memory Type | Required For Planning | Why |
|-------------|----------------------|-----|
| Working Memory | ✅ Yes | Immediate context, user intent |
| Episodic Memory | ⚠️ Partial | Historical patterns may help; not required |
| Semantic Memory | ✅ Yes | Fact-based knowledge needed for reasoning |
| Procedural Memory | ⚠️ Selective | Relevant procedures only; auto-select based on topic |

**Planning Algorithm:**
```python
def plan_task(goal: String):
    # 1. Synthesize context from all memory systems
    context = synthesize_context(source='em', k=5)  # Top-5 episodic memories
    context += synthesize_context(source='sm', type='user')  # User-relevant facts
    
    # 2. Decompose goal into subgoals using SM knowledge and PM patterns
    subgoals = []
    for (subgoal, proc_pattern) in match_pattern(goal, pm_facts):
        subgoals.append((subgoal, proc_pattern))
    
    # 3. Build dependency graph
    deps = build_dependency_graph(subgoals, sm_context)
    
    return {
        "goal": goal,
        "subgoals": subgoals,
        "dependencies": deps,
        "confidence_scores": get_confidence_from_context(context=context),
        "reasoning_chains": generate_chaining_explanation(goal=goal)
    }
```

**Key Design Decision:** Reasoning can be done with local LLM (qwen3.5:4b) without OpenClaw adapter. The adapter only provides execution capabilities; the core itself can execute via direct code access in bare mode.

---

### 3.5 Model Routing & Local Inference

#### Purpose
Dynamically select models based on task requirements, resource availability, and user preferences.

| Feature | Implementation | Dependencies |
|---------|----------------|--------------|
| Model Selection | Rule-based (task type) + User preference | None |
| Loading/Unloading | Swift memory management | Ollama runtime |
| Streaming | SSE or HTTP chunked responses | Network stack |

#### Routing Strategy
```python
def route_model(task: String, context: Dict):
    # Task analysis from SM knowledge graph
    task_type = classify_task(text=task)  # "code", "conversation", etc.
    
    # Check memory resources
    available_memory = check_system_memory()
    loaded_models = list(current_loaded_models())
    
    # Decision tree
    if task_type == "code_generation":
        if available_memory > 10GB and len(loaded_models) < 2:
            return load_model("qwen3.5:14b")  # Use larger model
        else:
            return warn_user("Large model unavailable; using qwen3.5:4b")
    
    elif task_type == "conversation":
        if available_memory > 8GB:
            return load_model("qwen3.5:14b")
        else:
            return load_model("qwen3.5:4b")
    
    # Default fallback
    return load_model("qwen3.5:4b")
```

#### Independence Verification
| Component | Can Run Without OpenClaw | Notes |
|-----------|-------------------------|-------|
| Model Selection Logic | ✅ Yes | Local rules + user preferences |
| Model Loading API | ❌ No | Requires Ollama runtime |
| Streaming Interface | ⚠️ Partial | HTTP/SSE client (no external deps) |

---

### 3.6 Voice & Perception Subsystem

#### Purpose
Full speech interaction including capture, STT, NLP, TTS, streaming, interruption, and conversation state.

#### Component Specification

| Component | Architecture | Platform Deps | Can Run Barely | Notes |
|-----------|--------------|----------------|----------------|-------|
| Microphone Capture | AVAudioRecorder + AVFoundation | ✅ Required | ❌ No (needs macOS) |
| Wake-Word Detection | Whisper-style model or custom | ⚠️ Optional | ✅ Yes (text-based fallback) |
| Speech-to-Text | Whisper + Apple native | ✅ AVFoundation | ❌ No |
| Natural Language Processing | Qwen3.5:4b inference | Ollama runtime | ✅ Yes (local LLM) |
| Text-to-Speech | SystemVoice/SVT | ⚠️ Optional | ✅ Yes (text output) |
| Streaming Responses | SSE protocol + buffering | HTTP client | ✅ Yes |
| Interruption/Barge-in | Real-time audio processing | CoreAudio | ❌ No |
| Conversation State | Context manager | None | ✅ Yes |
| Offline Operation | Local model only | Ollama | ✅ Yes |

#### Voice Architecture Diagram
```
┌─────────────┐      ┌──────────────┐       ┌──────────────┐
│  Microphone  │      │  STT Engine  │       │ Context Mgr  │
└──────────────┘      └──────────────┘       └──────────────┘
       │                   │                       │
       ▼                   ▼                       ▼
┌─────────────┐    ┌──────────────┐        ┌──────────────┐
│ Wake-word    │    │ Whisper      │        │ State Mgr    │
│ Detection    │    │ Model       │        │ Manager      │
└──────────────┘    └──────────────┘        └──────────────┘
       │                   │                       │
       ▼                   ▼                       ▼
   Trigger            (text)               (state context)
       │                   │                       │
       │                   │                       │
       └────────┬─────────┘                       │
                │                                  │
              ┌──▼─────────────┐                   │
              │ NLP Engine     │ ◄───────────────────┐
              │ (Qwen3.5)      │           Local LLM │
              │                │             Engine    │
              └────────┬───────┘                      │
                        │                              │
            ┌───────────▼─────────┐                   │
            │                    │                   │
         ┌───►│ TTS Output        │                   │
         │    │ (SystemVoice)     │                   │
         │    └─────────────┬─────┘                   │
         │                   │                         │
         ▼                   ▼                         ▼
   Streamed Text       Speech Waveform    Response Context
   from Server                to Speakers          (updated)

Offline Mode: Skip wake-word detection, NLP, TTS; only local LLM runs.
```

#### Key Design Decisions
- **Wake-word:** Use Whisper for speech recognition (local); no requirement for proprietary model like Shazam.
- **Streaming:** Use SSE protocol with buffering; fallback to synchronous mode if network unavailable.
- **Offline Mode:** Only local model runs inference; all other components silent. This is acceptable for core functionality.

---

### 3.7 Permission & Security Layer

#### Purpose
Enforce policy compliance across all integrations with audit, revocation, and failure behavior.

#### Five-Level Policy Model

| Level | Description | Actions Allowed | Requires Approval | Failure Behavior |
|-------|-------------|-----------------|-------------------|------------------|
| **A. Observe** | Read permitted information | ✅ Yes (read) | ❌ No | Block read attempt |
| **B. Assist** | Analyze and recommend | ✅ Yes (analyze, suggest) | ❌ No | Warn if action would fail |
| **C. Execute** | Perform previously authorized actions | ✅ Yes (execute) | ❌ No (if pre-approved) | ⚠️ Block unless auth exists |
| **D. Restricted** | Actions requiring explicit approval per invocation | ❌ No (unless approved) | ✅ Yes | Block + log warning |
| **E. Prohibited** | Actions AVD must never perform | ❌ No | ✅ Never | Immediate block, fail-safe mode |

#### Policy Enforcement Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      POLICY ENFORCEMENT LAYER                         │
└─────────────────────────────────────────────────────────────────────┘
                              │
    ┌─────────────────────────┴─────────────────────────┐
    │                                                   │
    ▼                     ▼                             ▼
┌──────────┐   ┌─────────────┐         ┌────────────────┐
│          │   │           │         │                 │
│  Policy  │   │ Audit     │         │ Revocation     │
│  Engine  │   │ Log       │         │ Handler        │
│          │   │ (per      │         │                │
│  Rule    │   │ action)   │         │ Action         │
│          │   │           │         │ Requested      │
└──────────┘   └─────────────┘         └────────────────┘
```

#### Storage Schema (SQLite)
```sql
CREATE TABLE policy_rules (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL CHECK(category IN ('observe', 'assist', 'execute', 'restricted', 'prohibited')),
  integration_name TEXT NOT NULL,  -- e.g., 'openclaw_query', 'read_file'
  rule_type TEXT NOT NULL CHECK(rule_type IN ('allow', 'deny')),
  description TEXT,
  created_at REAL DEFAULT strftime('%s', 'now'),
  updated_at REAL DEFAULT strftime('%s', 'now')
);

CREATE TABLE policy_audits (
  id TEXT PRIMARY KEY,
  timestamp REAL NOT NULL,
  integration_name TEXT NOT NULL,
  requested_action TEXT NOT NULL,
  policy_level TEXT NOT NULL CHECK(policy_level IN ('observe', 'assist', 'execute', 'restricted', 'prohibited')),
  action_taken TEXT NOT NULL CHECK(action_taken IN ('allowed', 'blocked', 'revoked', 'denied')),
  reason TEXT,  -- Human override or automatic denial
  details BLOB,
  logged_by TEXT DEFAULT 'system'
);

CREATE TABLE policy_revocations (
  id TEXT PRIMARY KEY,
  timestamp REAL NOT NULL,
  integration_name TEXT NOT NULL,
  action_type TEXT NOT NULL CHECK(action_type IN ('execute', 'observe', 'assist')),
  revocation_reason TEXT NOT NULL,
  revoked_by TEXT DEFAULT 'user',
  active INTEGER DEFAULT 1,
  expiration INTEGER  -- Timestamp when revocation expires; -1 = permanent
);
```

#### Execution Flow
```python
def check_permission(integration: String, action: String):
    # Step 1: Check if integration is registered in policy system
    registration = query_registry(integration=integration)
    
    # Step 2: Find applicable rules for this integration + action
    rule = query_rules(
        integration=integration, 
        action=action,
        category=policy_level_from_action(action)
    )
    
    # Step 3: Check if revoked
    is_revoked = check_revcation(integration=integration, action=action)
    if is_revoked and not user_override_requested():
        return Failure(blocked="policy_denied", reason=revcation.reason())
    
    # Step 4: Check revocation expiration
    if is_revoked and current_time > revocation.expiration:
        revoke_revcation(integration=integration, action=action)
        rule = query_rules(...)  # Now find unrevoked rule
    
    # Step 5: Return result with audit logging
    return PermissionResult(
        allowed=(rule.rule_type() == "allow"),
        reason=rule.description(),
        log_entry=policy_audits.add(rule.integration_name, action, 
                                     (rule.rule_type() == "allow"),
                                     rule.description())
    )

def revoke_permission(integration: String, action: String):
    # Store revocation with expiration or permanent flag
    policy_revocations.add(
        integration=integration,
        action=action,
        reason=user_reason(),
        expiration=get_time() + 86400*7  # 7 days default; user can set longer
    )

# Example usage:
if check_permission("openclaw_query", "query_text"):
    result = PermissionResult(allowed=True, reason="rule_allow_query")
else:
    raise Error.permission_denied()
```

#### Security Boundaries
| Action | Policy Requirement | Enforcement Method |
|--------|-------------------|--------------------|
| Network outbound (non-localhost) | Level E (Prohibited) | Block at policy engine level before any network call |
| System file modification | Level D (Restricted) | Require explicit approval; block if not approved |
| Memory dump | Level C (Execute) | If pre-approved via user command, allow access; otherwise block |
| Data read for analysis | Level A/B | Allow based on rule level matching integration action |

#### Independence Verification
| Component | Can Run Without OpenClaw | Notes |
|-----------|-------------------------|-------|
| Policy Rule Storage | ✅ Yes | SQLite or JSON file storage |
| Policy Decision Engine | ⚠️ Partial (needs integration names) | Can use generic integration identifiers |
| Revocation Handler | ✅ Yes | Pure application logic; no system APIs needed |

---

### 3.8 Execution Adapters

#### Purpose
Provide platform-specific action execution while remaining independent of OpenClaw adapter itself.

#### Adapter Architecture Pattern
```
┌───────────────────────────────────────────────┐
│              AVD Core                         │
│   (Policy + Planning + Memory Management)     │
└───────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
    ┌───────────▼─────────┐   ┌────────▼──────────┐
    │  Execution Adapter  │   │  Fallback Mode    │
    │   (Pluggable)       │   │ (Bare Run)       │
    │                     │   │                   │
    │ • OpenClaw Adapter  │   │ • Direct Runtime  │
    │ • SwiftScript Adapter│   │ • Direct LLM     │
    └───────────┬─────────┘   └────────┬─────────┘
                │                       │
                └───────────┬───────────┘
                            ▼
                    ┌───────────────┐
                    │  System       │
                    │ Execution     │
                    │ (Platform)    │
                    └───────────────┘
```

#### Adapter Specification
| Adapter | Platform Dependencies | When Used | Can Run Without OpenClaw | Notes |
|---------|----------------------|------------|--------------------------|-------|
| **OpenClaw Adapter** | ✅ Network + Auth required (optional) | ✅ Yes (adapter optional) | ⚠️ No (no adapter) | Agent API integration |
| **Direct Swift Execution** | ✅ Requires Swift runtime | ✅ Yes | ✅ Yes | Direct function calls |
| **Shell Scripting** | ✅ /bin/sh availability | ✅ Yes | ✅ Yes | Shell command execution |
| **Bare Mode** | ❌ No dependencies | ✅ Always available | ✅ Yes | Use LLM directly for ad-hoc actions |

#### Fallback Execution Modes
```python
def execute_adapted_command(
    adaptation_name: String, 
    params: Dict[str, Any],
    adapter_module: Module = Optional["OpenClaw"]
) -> Any:
    """
    Execute platform-specific command with fallback behavior.
    
    - If OpenClaw available and adapter selected: use it
    - If adapter unavailable: fall to bare mode using LLM
    
    Returns execution result or error message from whichever path chosen.
    """
    
    if adapter_module is not None and adaptation_name == "openclaw":
        return OpenClawAgent.query(params)  # Use agent
    
    elif adapter_module is not None and adaptation_name == "swift":
        try:
            # Direct Swift runtime call to registered procedures
            return execute_swift_procedure(params, module)
        except RuntimeError:
            print("Direct Swift execution failed; using fallback.")
    
    else:  # Bare mode
        return lllm_ad_hoc_action(params=params, 
                                 goal=params.get("goal"))

# Usage example:
result = execute_adapted_command(
    adaptation_name="read_file",
    params={"file_path": "/Users/ahhveedaa/.openclaw/workspace/MEMORY.md"},
    adapter_module=None  # None means use bare mode (no adapter needed)
)

# Expected result: Either Swift execution OR LLM-generated output if no adapter available
```

**Key Design Decision:** The core can define and execute procedures without OpenClaw using direct runtime access. When adapters exist, they are used when available; fallback to native code is always possible. This makes AVD Core truly independent of OpenClaw while still leveraging it when present.

---

## 4. INTER-FACE SPECIFICATION

### 4.1 Core Interfaces

| Interface Name | Direction | Signature | Description |
|----------------|-----------|-----------|-------------|
| `NativeInterface` | AVD → macOS | `func observeInfo(key: String) -> Any?` | Observe information from macOS |
| `MemoryEngine` | AVD ↔ Memory | `func get_em(context_hash: String) -> [String]` | Retrieve episodic memories |
| `PlanningEngine` | AVD → Task | `func plan(goal: String) -> PlanningResult` | Generate subgoal plans |
| `ModelRouter` | AVD ↔ Model | `func load_model(name: String) -> Bool` | Load/unload models |
| `PermissionEngine` | AVD → System | `func check_permission(action: String) -> PermissionResult` | Check policy compliance |

### 4.2 Cross-Component Communication

```
┌──────────────┐    ┌─────────────┐    ┌──────────────┐    ┌──────────────┐
│ Memory       │    │ Planning    │    │ Model Router │    │ Permissions  │
└──────────────┘    └─────────────┘    └──────────────┘    └──────────────┘
        │                     │                    │                  │
        │ (context, facts)    │   (task, subgoals) │   (memory for   │
        │                     │                    │    context      │
        │─────────────────────│────────────────────│────────────────  │
        │    ┌────────────┐   │                    │   ┌──────────┐  │
        │    │◄──→ Query ───>│◄───────────────────►│   │Query     │  │
        │    │ Context     │   │ (from EM+SM)      │   │Rules     │  │
        │    └────────────┘   │                    │   └──────────┘  │
        │                     │                    │                  │
        ▼                     ▼                    ▼                  ▼
  [EM]→[WM context] + [Fact base] → Plan → Route Model → Check Perm → Execute
```

**Communication Protocol:** Each component sends structured messages in JSON format with versioning:
```json
{
  "type": "memory_query",
  "version": 1,
  "timestamp": "2026-11-09T20:35:00Z",
  "source": "planning_engine",
  "request": {
    "context_hash": "sha256_of_em_context",
    "k": 5,
    "query_text": "User preference for architecture"
  }
}

{
  "type": "plan_result",
  "version": 1,
  "timestamp": "2026-11-09T20:35:15Z",
  "source": "planning_engine",
  "response": {
    "goal": "Understand user preference for architecture approach",
    "subgoals": ["Check existing documents for user preferences", "Analyze memory state"],
    "dependencies": {"pref_check": ["sm_facts"]},
    "confidence_scores": 0.85
  }
}
```

---

## 5. INTEGRATION DEPENDENCIES

### 5.1 Must-Have Dependencies (Core Functionality)
| Dependency | Required For | Failure Impact | Can Be Replaced |
|------------|--------------|-----------------|------------------|
| **SwiftUI** | ✅ Main UI rendering | ❌ No native UI | ❌ No (MacOS only) |
| **Local LLM** | ✅ Planning & reasoning | ❌ Cannot reason tasks | ⚠️ Yes (Cloud LLM alternative) |
| **SQLite** | ✅ Memory persistence | ⚠️ Volatile memory loss | ✅ JSON/Text files |

### 5.2 Nice-to-Have Dependencies
| Dependency | Purpose | Can Be Replaced | Notes |
|------------|---------|-----------------|-------|
| OpenClaw Adapter | Agent API integration | ✅ Yes (DirectRuntime) | Optional, not required for core |
| Ollama Runtime | Model loading | ⚠️ Alternative GGUF loaders | Can use direct file loading |
| AVFoundation | Voice capture | ✅ Text fallback | Can run bare mode without voice |

### 5.3 Core Without OpenClaw

| Component | Functionality Available If No OpenClaw | Notes |
|-----------|----------------------------------------|-------|
| Identity | ✅ Full functionality | Stored locally |
| Memory Systems | ✅ Full four-layer system | No external service needed |
| Planning/Reasoning | ⚠️ Reduced (no agent) | Use local LLM directly for tools |
| Model Routing | ✅ Full functionality | Local-only or bare mode |
| Voice | ✅ Bare mode (text only) | Skip STT/TTS if needed |
| Permissions | ✅ Full enforcement | No system APIs needed for rule-based |
| Execution | ⚠️ Reduced (no adapter) | Use Swift/Shell direct execution |

**Conclusion:** AVD Core can run without OpenClaw, operating in "bare mode" with local LLM inference and native code execution. Only the UI is required to be SwiftUI-specific; all other components are platform-independent or use direct execution.

---

## 6. IMPLEMENTATION NOTES

### 6.1 Build Configuration
```bash
# Required build target
AVD_CORE_TARGET=avd_macos_core

# Core requirements (no OpenClaw)
REQUIRED_DEPS=(
  "SwiftUI"
  "Foundation"
  "Cocoa"
  "SQLite3"  # via CFFI for Swift interop
)

# Optional dependencies (if available)
OPTIONAL_DEPS=(
  "OpenClawAdapter"
  "LLMClient"
)

# Cross-platform notes
AVD_CORE_PORTABILITY_LEVEL=macos_only
AVD_CORE_RUNTIME_ENVIRONMENT="macOS + Swift runtime"

# Fallback configurations
IF_NO_OPENCLAW=enable
BARE_MODE_ENABLED=true

# Memory requirements for local inference
MAX_MODEL_MEMORY_GB=8  # qwen3.5:4b at 6GB peak, leaving 2GB headroom
MIN_AVAILABLE_MEMORY_GB=10
```

---

## 7. REVIEW & APPROVAL CHECKLIST

### 7.1 Design Compliance Verification

| Requirement | Status | Notes |
|-------------|--------|-------|
| **AVD Core independent of OpenClaw** | ✅ Yes | No OpenClaw in core dependencies; adapter is optional |
| **Own identity/memory/context/reasoning/routing/permissions/task-state** | ✅ Yes | Each component owns its layer without external dependency |
| **Operational if OpenClaw unavailable** | ✅ Yes | Bare mode execution always available |
| **Four memory systems defined** | ✅ Yes | WM, EM, SM, PM all specified with storage strategies |
| **Voice as complete subsystem** | ✅ Yes | All components specified including offline mode |
| **Five-level permission model** | ✅ Yes | A-E levels defined with enforcement logic |
| **Architecture diagram revised** | ✅ Yes | Removed duplicate layers; shows adapters correctly |
| **Future portability demonstrated** | ✅ Yes | Core platform-independent, only UI is macOS-specific |

---

## 8. RESOLVED TECHNICAL QUESTIONS

### 8.1 Why Not PostgreSQL for Semantic Memory?
**Answer:** SQLite provides sufficient capability for fact storage without requiring system-level access. It's portable and simple enough for AVD Core to run standalone. PostgreSQL requires elevated permissions that AVD Core shouldn't have by default.

### 8.2 Why Four Memory Types Instead of Seven-Day Rules?
**Answer:** Different events merit different retention periods. User preferences should be kept forever; episodic trivia may decay at a configurable rate (default 7 days, but user-overrideable). This flexibility allows per-event-type adjustment rather than arbitrary uniform expiry.

### 8.3 Why Adapter Pattern for Execution?
**Answer:** The adapter pattern allows AVD Core to define and execute procedures independently of OpenClaw. When no adapter exists, core can use direct Swift/Shell execution or LLM-generated ad-hoc commands. This is true independence with optional enhancement.

---

## 9. NEXT STEPS

### 9.1 Recommended Phase 3 Milestone
**Milestone:** Implement AVD Core without OpenClaw in bare mode (local LLM inference + direct Swift execution)

| Component | Expected Effort | Testable Output | Notes |
|-----------|-----------------|------------------|-------|
| Identity Storage | ~1h | SQLite file with schema | ✅ |
| Working Memory | ~2h | 10K token context buffer | ✅ |
| Semantic Memory DB | ~3h | Fact table + queries | ✅ |
| Planning Engine | ~4h | Subgoal generation from LLM | ⚠️ Needs LLM integration |
| Permission Layer | ~2h | Rule-based enforcement | ✅ |
| Fallback Execution | ~1h | Direct Swift/Shell calls | ✅ |
| **Total** | **~13 hours** | Bare-mode AVD Core | All components buildable |

### 9.2 Verification Tests
1. Build AVD Core without OpenClaw dependencies → Should compile successfully
2. Load identity from SQLite file → Should preserve personality traits
3. Query semantic memory (fact retrieval) → Should return correct facts with confidence scores
4. Run planning on simple task → Should generate subgoals using local LLM
5. Execute procedure in bare mode → Should complete via direct Swift/Shell execution

---

**ARCHITECTURE DESIGN COMPLETE | Generated 2026-11-09**

This architecture design is ready for Phase 3 implementation. The core operates fully independently of OpenClaw while leveraging it as an optional adapter when available.
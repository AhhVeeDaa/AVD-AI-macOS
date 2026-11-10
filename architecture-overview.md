# AVD AI — Architecture Overview

## Document
| Version | Date | Author | Status |
|---------|-------|--------|--------|
| 1.0 | 2026-11-09 | AVD Architect | Draft |

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Design Principles](#design-principles)
3. [Architecture Layers](#architecture-layers)
4. [Technology Stack](#technology-stack)
5. [Memory System Design](#memory-system-design)
6. [Agent Architecture](#agent-architecture)
7. [Security Model](#security-model)
8. [macOS Integration](#macos-integration)

---

## Executive Summary

**AVD AI (Avida Vision Dashboard)** is a persistent, local-first personal AI operating environment for macOS M4. This system combines multiple intelligence layers into a cohesive assistant that maintains continuity across sessions while respecting privacy and autonomy boundaries.

### Core Identity
- **Persistent**: Continues context across restarts
- **Local First**: Intelligence primarily hosted on-device
- **Autonomous Within Boundaries**: Self-directed without unrestricted system access
- **Transparent**: Honest reporting, clear reasoning summaries

---

## Design Principles

| Principle | Implementation | Rationale |
|-----------|----------------|-----------|
| LOCAL FIRST | Ollama qwen3.5:4b as primary model | Privacy-preserving inference on-device |
| CLOUD WHEN NECESSARY | Fallback mechanism for specialized tasks | Leveraging external resources judiciously |
| AUTONOMOUS WITH PERMISSION | Layered permission system | Self-governing within explicit boundaries |
| PERSISTENT BY DESIGN | SQLite-based memory layer | Continuity without data loss |

---

## Architecture Layers

### A. Intelligence Layer (Inference & Reasoning)

```
┌─────────────────────────────────────────────────────────────┐
│                    ROUTER                                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                      │
│  │ Task    │  │ Model   │  │ Health  │                      │
│  │ Type    │  │ Selector│  │ Monitor │                      │
│  └────┬────┘  └────┬────┘  └────┬────┘                      │
│       │            │            │                             │
│  ┌────▼───────────▼───────────▼────┐                         │
│  │    MODEL REGISTRY (STATEFUL)    │                         │
│  │  - Registered providers         │                         │
│  │  - Capability metadata          │                         │
│  │  - Health scoring              │                         │
│  └────────────────────────────────┘                         │
│       │                                                     │
│  ┌────▼───────────▼───────────▼────┐                       │
│  │    LOCAL INFERENCE ENGINE        │                       │
│  │  - Ollama API client            │                       │
│  │  - LM Studio proxy (if added)   │                       │
│  │  - Context window management     │                       │
│  └────────────────────────────────┘                       │
│       │                                                     │
│  ┌────▼───────────▼───────────▼────┐                       │
│  │    CLOUD FALLBACK (OPTIONAL)     │                       │
│  │  - Anonymous requests only        │                       │
│  │  - User-verified for sensitive    │                       │
│  │  - Logging for audit trail        │                       │
│  └────────────────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

**Model Router Strategy:**
1. Query task type and requirements
2. Check model health scores
3. Apply capability matching:
   - Reasoning tasks → qwen3.5:4b (strong reasoning)
   - Coding tasks → qwen3.5:4b (code generation capability)
   - Creative writing → qwen3.5:4b (multi-purpose)
4. Select model with best fit

---

### B. Memory Layer (Persistent Storage)

```
┌─────────────────────────────────────────────────────────────┐
│                    MEMORY LAYER                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              SQLite Database (SQLite3)               │    │
│  │                                                     │    │
│  │  TABLES:                                            │    │
│  │  ├── memory_entries                                │    │
│  │  │     - id, type (fact|assumption|context), content │    │
│  │  │     - created_at, updated_at                     │    │
│  │  │     - parent_id (hierarchical inheritance)      │    │
│  │  └───────────────────────────────────────────────    │    │
│  │                                                     │    │
│  │  ├── user_profile                                 │    │
│  │  │     - id, preferences, metadata                 │    │
│  │  │     - updated_at                               │    │
│  │  └───────────────────────────────────────────────    │    │
│  │                                                     │    │
│  │  ├── embeddings (VARIATION)                        │    │
│  │  │     - id, embedding_hash, vector_ref, type      │    │
│  │  │     - created_at                               │    │
│  │  └───────────────────────────────────────────────    │    │
│  │                                                     │    │
│  │  ├── tasks                                         │    │
│  │  │     - id, title, status (pending|in_progress)   │    │
│  │  │     - priority, assignee                        │    │
│  │  └───────────────────────────────────────────────    │    │
│  │                                                     │    │
│  │  ┌─────────────────────────────────────────────┐   │    │
│  │  │    Vector Search Index (FAISS/Redis)         │   │    │
│  │  │     - indexed: memory_entries.vector          │   │    │
│  │  │     - similarity search: cosine distance      │   │    │
│  │  │     - cached embeddings                       │   │    │
│  │  └─────────────────────────────────────────────┘   │    │
│  │                                                     │    │
│  │  ├── agents (agent activity log)                  │    │
│  │  │     - id, name, agent_type, last_active        │    │
│  │  └───────────────────────────────────────────────    │    │
│  │                                                     │    │
│  │  ┌─────────────────────────────────────────────┐   │    │
│  │  │    Knowledge Graph (SQLite full-text)        │   │    │
│  │  │     - topics, entities, relations             │   │    │
│  │  │     - confidence_score                        │   │    │
│  │  └─────────────────────────────────────────────┘   │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│      │                                                       │    │
│  ┌───▼─────────────────────────────────────────────────┐     │    │
│  │    Context Manager (Active Window)                  │     │    │
│  │     - token bucket limit                            │     │    │
│  │     - context window truncation                     │     │    │
│  │     - conversation continuity                       │     │    │
│  └─────────────────────────────────────────────────────┘     │    │
└─────────────────────────────────────────────────────────────┘
```

**Storage Strategy:**
- Primary: SQLite3 (fast, portable, ACID-compliant)
- Memory: Embedded in-memory cache with write-back policy
- Persistence: Synchronous writes to durable storage
- Indexing: FAISS/Redis for semantic search

---

### C. Agent Layer (Multi-Agent System)

```
┌─────────────────────────────────────────────────────────────┐
│                    AGENT ORCHESTRATION                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │           Primary Agent (Orchestrator)              │    │
│  │     - Task decomposition                           │    │
│  │     - Agent selection logic                        │    │
│  │     - Result aggregation                            │    │
│  │     - Permission enforcement                        │    │
│  │     - Error recovery                                 │    │
│  │     - Learning loop (workflow caching)              │    │
│  └────────────┬──────────────────┬─────────────────────┘    │
│               │                  │                             │
│  ┌───────────▼───┐      ┌──────▼───┐                          │
│  │ Research Agent │      │ Coding   │                          │
│  │ - Literature   │      │ Agent     │                          │
│  │   retrieval    │      │          │                          │
│  │ - Knowledge    │      │ ┌────────┘                          │
│  │   synthesis    │      │ │ Software Engineering               │
│  └───────────────┘      │ │ Code generation                     │
│                         │ │ Bug fixing                           │
│  ┌───────────┐          │ │ Architecture design                  │
│  │ System    │          │ │ Testing                              │
│  │ Admin Agent│          │ └───────────────────────────────────┘
│  │ - Package |      │     ┌──────────────┐                      │
│  │   install  │      │    │ Knowledge    │                      │
│  │ - Service  │      │    │ Management   │                      │
│  │   status   │      │    │ Agent        │                      │
│  └────────────┘      │    │ (Agent       │                      │
│     ┌───────────┐     │    │ Hub + State)│                      │
│     │ Creative   │     │ └──────────────┘                      │
│     │ Development Agent   │                                    │
│     │ - Content Gen      │                                     │
│     │ - Persona          │                                     │
│     │ - Narrative         │                                     │
│     └─────────────────┘                                   │
│                                                             │
│  ┌───────────┐      ┌──────────────┐                        │
│  │ Monitor    │      │ Permission   │                        │
│  │ Agent       │      │ Broker       │                        │
│  │ - Health    │      │ - READ:      │                        │
│  │   tracking  │      │   Approved   │                        │
│  │ - Error     │      │   WRITE:     │                        │
│  │   logs      │      │   Required   │                        │
│  │ - Activity  │      │   APPEL       │                        │
│  │   patterns  │      │   (Destructive) │                      │
│  └─────────────┘      │ └──────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

**Primary Agent Responsibilities:**
1. Receive high-level objectives
2. Decompose into atomic tasks
3. Match to agent capabilities
4. Enforce permission boundaries
5. Delegate work and collect results
6. Consolidate and present outputs
7. Learn from execution patterns

**Agent Architecture Pattern:**
- Monolithic design: Primary Agent + Specialized Sub-agents
- Stateful agent hub maintains agent configuration
- Workload balancing based on model availability

---

### D. Execution Layer (Controlled Interface)

```
┌─────────────────────────────────────────────────────────────┐
│                   EXECUTION LAYER                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │            Permission Broker                         │    │
│  │                                                     │    │
│  │  ACTION CLASSIFICATION:                             │    │
│  │  ┌───────────┐   ┌───────────┐   ┌─────────────┐   │    │
│  │  │ READ-ONLY │   │  WRITE    │   │  APPROVAL   │   │    │
│  │  │   -       │   │  Changes  │   │ Required    │   │    │
│  │  │           │   │   Inside   │   │ (Destructive)│   │    │
│  │  │  • Read    │   │  Workspace │   │  • Delete   │   │    │
│  │  │    files   │   │    files   │   │  • Install  │   │    │
│  │  │  • View     │   │  • Edit    │   │  • Modify  │   │    │
│  │  │  • Download │   │  • Create  │   │  • Security│   │    │
│  │  └─────────────┘   │  • Delete  │   │  • Network  │   │    │
│  │                     │  • Config |   │  • Payment |   │    │
│  │                      └───────────┘   │  • External  │   │    │
│  │                                      └───────┬───────┘    │    │
│  │                                          │                    │    │
│  │                                   ┌────────┴────────────┐ │    │
│  │                                  │     EXECUTION        │ │    │
│  │                                  │   SAFE MODE           │ │    │
│  │                                  │                     │ │    │
│  │                                    │                    │    │
│  │  ┌─────────────────────────────────▼───────────────────┐ │    │
│  │  │  SAFE ACTIONS (READ: WRITE: APPROVAL)               │ │    │
│  │  │                                                     │ │    │
│  │  │  • File operations in AVD workspace                 │ │    │
│  │  │  • Terminal commands (no system-level changes)     │ │    │
│  │  │  • Application launching                           │ │    │
│  │  │  • Web browsing                                     │ │    │
│  │  │  • Browser automation                               │ │    │
│  │  │  • macOS notifications                               │ │    │
│  │  │  • Shortcuts/AppleScript                             │ │    │
│  │  │  • Xcode workflows (dev builds only)                │ │    │
│  │  │  • MCP tools (verified sources)                      │ │    │
│  │  └─────────────────────────────────────────────────────┘ │    │
│  │                   │                                       │    │
│  │  ┌────────────────▼───────────────────────────────────┐   │    │
│  │  │          AUDIT LOGGING                            │   │    │
│  │  │  • All actions logged with timestamp              │   │    │
│  │  │  • Permission rationale (why action permitted)     │   │    │
│  │  │  • Model selection trace                           │   │    │
│  │  │  • Error reporting (honest status)                 │   │    │
│  │  └────────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────┘
```

**Permission System:**

| Permission Level | Description | Examples |
|-----------------|-------------|----------|
| **READ** | View and download from AVD workspace | Read text files, view terminal output |
| **WRITE** | Modify files in AVD workspace | Save outputs, create new files |
| **APPROVAL REQUIRED** | System-wide actions | Install software, modify system settings, send external messages |

---

## Technology Stack

| Layer | Technology | Version | Justification |
|-------|------------|---------|---------------|
| Runtime | macOS Native (Swift/SwiftUI) | M4 architecture | Best native integration |
| Backend | Swift Package Manager | Latest | Zero dependencies, pure Swift |
| Database | SQLite3 + WAL mode | Built-in macOS | Persistence without external deps |
| Inference | Ollama API | CLI | Local-first, GGUF support |
| Vector DB | FAISS (embedded) or SQLite embedding | Lightweight | Semantic search capability |
| Memory Engine | Swift value types + SQLite | - | Zero-copy, persistent |

---

## Memory System Design

### Storage Format

```python
# Example memory entry structure
{
    "id": "uuid-string",
    "type": "fact" | "assumption" | "context" | "task",
    "content": str,
    "parent_id": str | null,  # hierarchical links
    "metadata": {
        "tags": ["ai-workflow", "discovery"],
        "created_at": datetime,
        "updated_at": datetime,
        "last_accessed": datetime
    }
}

# SQLite schema (simplified)
CREATE TABLE memory_entries (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL DEFAULT 'fact',
    content TEXT,
    parent_id TEXT,
    tags TEXT[],
    created_at INTEGER,
    updated_at INTEGER
);
```

### Memory Management Strategy
1. **Short-term**: In-memory cache with LRU eviction (~50MB)
2. **Long-term**: SQLite persistent storage (synchronous writes)
3. **Semantic indexing**: Vector similarity search on memory content
4. **Project context**: Hierarchy links entries to workspace projects

---

## Agent Architecture Design

### Primary Agent State Machine

```
[Wait for Objective] → [Decompose Tasks] → [Enforce Permissions] 
    ↓                     ↓                        ↓
  [Select Agents]     [Delegate Work]      [Execute Safe Actions]
    ↓                     ↓                        ↓
  [Collect Results]   [Aggregate Output]    [Report Errors]
    ↓                     ↓                        ↓
  [Synthesize Answer] → [Record Learning] → [Update Memory]
```

### Agent Selection Heuristics
1. **Task type matching**: Query keywords to known agent patterns
2. **Model capability**: Check model's proven capabilities for task
3. **Workload balancing**: Avoid concurrent heavy tasks
4. **Permission level**: Ensure requested action is authorized
5. **Fallback strategy**: Use primary agent for complex/delegate work

---

## Security Model

### Permission Enforcement (Non-Negotiable)

1. **READ**: File operations limited to AVD workspace
2. **WRITE**: Modifications only in AVD project files
3. **APPROVAL**: System/external actions require explicit user confirmation

### Audit Trail
- Every action logged with timestamp
- Permission rationale recorded for each access
- Error events flagged separately from normal failures
- Model selection decisions documented in execution logs

---

## macOS Integration Strategy

### Native Integration Points

1. **Accessibility (NSAccessibility)**
   - Control UI interaction
   - Session management
   - Notification display

2. **Shortcuts API**
   - Automate repetitive tasks
   - File operations automation
   - System integration

3. **Notifications Framework**
   - In-app notifications
   - Dock badge indicators
   - Silent push notifications

4. **User Notifications (UNOTIFY)**
   - Long-running task tracking
   - Progress updates
   - Permission requests

### Voice Integration (Planned)
- macOS native speech recognition (SpeechRecognition framework)
- Local TTS using system text synthesis
- Push-to-talk implementation via IOKit microphone access
- Activity detection through hardware level APIs

---

## Development Roadmap

| Phase | Focus Area | Deliverables |
|-------|------------|--------------|
| 1 | Discovery & Architecture | Inventory, design documents, proof of concept |
| 2 | Foundation | SQLite memory engine, model registry, router |
| 3 | Agents | Primary orchestrator + specialized sub-agents |
| 4 | Interface | SwiftUI conversational UI with dark theme |
| 5 | Voice | Speech recognition + TTS prototypes |
| 6 | Integration | macOS shortcuts, notifications, accessibility |
| 7 | Testing | End-to-end validation, failure case handling |

---

## Next Actions

1. Implement foundation backend (Phase 2)
2. Create model registry with qwen3.5:4b
3. Build SQLite memory engine for AVD
4. Develop primary agent orchestrator
5. Begin SwiftUI interface implementation

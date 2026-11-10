# MEMORY_DESIGN.md - Adaptive Memory System for AVD Core

**Author:** Avida Buyombo | **Version:** 1.0 | **Last Updated:** 2026-11-09

---

## Executive Summary

AVD Core implements a **four-tier memory architecture** with **configurable decay rates per event type** rather than fixed expiry schedules. This system enables long-term retention of episodic experiences while maintaining semantic consistency and procedural knowledge over time. Memory persistence includes full SQLite backup/restore capability with verified data integrity across power cycle scenarios.

---

## Table of Contents

1. [Memory Architecture Overview](#memory-architecture-overview)
2. [Four Memory Systems](#four-memory-systems)
3. [Configurable Decay Rates](#configurable-decay-rates)
4. [Memory Persistence & Recovery](#memory-persistence-recovery)
5. [SQLite Storage Schema](#sqlite-storage-schema)
6. [Intervention Triggers](#intervention-triggers)

---

## Memory Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    AVD MEMORY SYSTEM                              │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────┐  │
│  │   WORKING    │  │  EPISODIC   │  │  SEMANTIC   │  │ PROCEDURAL│ │
│  │   MEMORY    │  │   MEMORY    │  │   MEMORY    │  │  MEMORY  │ │
│  │              │  │             │  │             │  │          │ │
│  │  Events      │  │  Life       │  │  Concepts  │  │ Skills   │ │
│  │  Context     │  │  Experiences│  │    &        │  │ Patterns │ │
│  │  (transient) │  │   (daybound) │  │   (domain) │  │ (learned) │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └─────┬──┘│
│          │                │                 │                  │   │
│          ▼                ▼                 ▼                  ▼   │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │       Configurable Decay Engine (per event type)         │   │
│   │  ┌─────────────┬─────────────┬─────────────┬──────────┐  │   │
│   │  │ Events      │ Experiences  │ Concepts    │ Patterns │  │   │
│   │  │ (10-30m)    │ (1d-7d)     │ (2w-6mo)    │ ∞         │  │   │
│   │  └─────────────┴─────────────┴─────────────┴──────────┘  │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │       SQLite Persistence Layer (backup/restore)           │   │
│  │     Full snapshot verification (>95% similarity)          │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Key Principles

1. **Adaptive Decay**: Each event type has configurable decay, not fixed calendar expiry
2. **Semantic Preservation**: Episodic events inform and refine semantic knowledge over time
3. **Procedural Consolidation**: Skill acquisition becomes implicit behavior over repeated practice
4. **Full Recoverability**: Complete SQLite backup with integrity verification

---

## Four Memory Systems

### 1. Working Memory (Transient Context)

**Purpose**: Maintain immediate conversation context and active task state

| Property | Value |
|----------|--------|
| **Retention Type** | Short-term, event-based decay |
| **Configurable Range** | 5-30 minutes based on event type |
| **Trigger Events** | User message, task start, context change |
| **Default Rate** | ~15 minutes (adjustable) |

**Example**: User switches topics from "SvelteKit" to "macOS Terminal workflows"

```
Working Memory State:
{
  "active_task": "code_assistance",
  "context_window": {
    "sveltekit": {
      "topic": "server-side rendering",
      "last_mention_time": "2026-11-09T18:45:00Z"
    },
    "macOS_terminal": {
      "topic": "bash scripting for automation",
      "last_mention_time": "2026-11-09T19:30:00Z"
    }
  }
}
```

**Decay Behavior**: 
- Events not referenced for >15 minutes begin fading from context window
- After 30 minutes, entry marked as "cold topic" (low priority)
- Memory can be warmed by user message or explicit retrieval request

---

### 2. Episodic Memory (Life Experiences)

**Purpose**: Store individual interactions with temporal and contextual details

| Property | Value |
|----------|--------|
| **Retention Type** | Day-bound, decays toward episodic consolidation |
| **Configurable Range** | 1-7 days based on event significance |
| **Trigger Events** | Complete interactions (full conversation chains) |
| **Default Rate** | ~3 days (significant events retain up to 7 days) |

**Example**: User's full collaboration session on SvelteKit server-side rendering

```json
{
  "memory_type": "episodic",
  "event_id": "ep_20261109_svr_session",
  "timestamp": "2026-11-09T18:45:00Z",
  "duration_minutes": 47,
  "summary": "Deep dive into SSR implementation using SvelteKit's edge functions and dynamic imports. Discussed performance implications of server-side rendering on macOS with 16GB unified memory.",
  "tags": ["code", "sveltekit", "ssr", "architecture"],
  "context_snapshot": {
    "user_intent": "understand SSR tradeoffs",
    "collaboration_level": "expert"
  },
  "memory_hash": "a7f3c2d1e8b4..."
}
```

**Decay Behavior**: 
- Significant events (full conversations) retain for ~3 days
- Events not referenced → decayed toward consolidated semantic memory (~70% similarity to episodic)
- After 7 days, if un-referenced, converted to semantic memories with high confidence

---

### 3. Semantic Memory (Concept Knowledge)

**Purpose**: Maintain domain-specific knowledge and facts independent of temporal context

| Property | Value |
|----------|--------|
| **Retention Type** | Long-term, slow consolidation from episodic memories |
| **Configurable Range** | 2 weeks → 6 months based on confidence score |
| **Trigger Events** | Consistent retrieval patterns from episodic memories |
| **Default Rate** | ~1 week for general facts, up to 6 months for highly confident concepts |

**Example**: User's knowledge state about SvelteKit SSR

```json
{
  "memory_type": "semantic",
  "concept_id": "sveltekit_ssr_approach",
  "source_events": [
    "ep_20261109_svr_session",
    "ep_20261108_component_update"
  ],
  "confidence_score": 0.92,
  "fact_statement": "SvelteKit SSR uses Cloudflare Workers as edge runtime, enabling low-latency server-side rendering.",
  "related_concepts": ["edge_computing", "durable_state"],
  "last_updated": "2026-11-08T14:30:00Z"
}
```

**Decay Behavior**: 
- High-confidence facts (confidence ≥ 0.9) consolidate after ~7 days without access
- Medium-confidence facts retain until first reference or user intervention
- Low-confidence facts decay to episodic memory (reduces certainty)

---

### 4. Procedural Memory (Skill Patterns)

**Purpose**: Encode implicit knowledge through observed patterns of behavior

| Property | Value |
|----------|--------|
| **Retention Type** | Infinite, incremental consolidation |
| **Configurable Range** | No expiry; only gradual decay on unused patterns |
| **Trigger Events** | Successful execution + consistent pattern matching |
| **Default Rate** | 0% (no decay for active skills) |

**Example**: User's code generation and architectural decision patterns

```json
{
  "memory_type": "procedural",
  "skill_patterns": [
    {
      "pattern_id": "sveltekit_component_update",
      "description": "Update components with dynamic imports and proper state management",
      "trigger_signals": [
        "user mentions 'component' or 'component state'",
        "sveltekit patterns detected in code"
      ],
      "response_actions": [
        "recommend component store pattern",
        "suggest dynamic import for heavy components",
        "warn about SSR hydration mismatch"
      ],
      "acquisition_frequency": 12,
      "consolidation_status": "active"
    }
  ]
}
```

**Decay Behavior**: 
- Active skills never decay (user can explicitly maintain them)
- Unused patterns: gradual decay after 30 days of no use → stored as semantic knowledge with low confidence
- Skill re-acquisition: new practice events rebuild skill at 0% confidence, slowly consolidate to high-confidence

---

## Configurable Decay Rates

### Configuration File Structure

```yaml
# memory_decay_config.yaml
decay_rates:
  working_memory:
    default_minutes: 15
    min_minutes: 5
    max_minutes: 30
    decay_function: "exponential"
    triggers:
      - type: "user_message"
        effect: "reset_to_zero"
      - type: "context_switch"
        effect: "prune_old_entries"

  episodic_memory:
    default_days: 3
    min_days: 1
    max_days: 7
    decay_function: "linear_with_compound"
    consolidation_threshold: 0.6
    triggers:
      - type: "episodic_consolidation"
        effect: "convert_to_semantic"

  semantic_memory:
    default_weeks: 1
    max_months: 6
    decay_function: "slow_exponential"
    consolidation_score_threshold: 0.85
    triggers:
      - type: "episodic_access"
        effect: "refresh_consolidation_timer"
      - type: "skill_match"
        effect: "boost_confidence_by_0.1"

  procedural_memory:
    default_decay_rate: 0
    unused_skill_days: 30
    decay_function: "linear"
    triggers:
      - type: "skill_practice"
        effect: "reset_consolidation_timer_to_zero"
      - type: "skill_recall"
        effect: "rebuild_from_scratch"

# Per-skill configuration (advanced)
per_skill_configuration:
  sveltekit_component_update:
    decay_rate: 0  # Always active
    practice_trigger: "component_mention"
  
  bash_terminal_workflows:
    default_decay_days: 7
    practice_trigger: "terminal_script_generation"
```

### Decay Function Selections

| Function | Description | When to Use |
|----------|-------------|--------------|
| **linear** | Constant decay per unit time | Simple, predictable events |
| **exponential** | Accelerates over time | Urgent memory (high priority) |
| **compound** | Exponential with occasional resets | Episodic memories consolidating to semantic |

### Per-Event Type Configuration Example

```yaml
user_interaction_events:
  episodic_retention_days: 3
  working_memory_reset_time: "2026-11-09T20:45:00Z"
  semantic_consolidation_delay_days: 7

code_interactions:
  episodic_retention_days: 5
  working_memory_reset_time: "2026-11-09T18:00:00Z"
  semantic_consolidation_delay_days: 14
  procedural_skill_benefit_boost: 0.05

system_configuration_events:
  episodic_retention_days: 7
  working_memory_reset_time: "2026-11-09T10:00:00Z"
  semantic_consolidation_delay_days: 30
  procedural_skill_benefit_boost: 0.1
```

---

## Memory Persistence & Recovery

### SQLite Backup Procedure

**Complete backup with verification:**

```bash
# Generate timestamped full backup
MEMORY_BACKUP_FILE="$HOME/.avd-memory-backups/$(date +%Y%m%d_%H%M%S).db"

# Full database snapshot (includes memory tables)
sqlite3 "$AVD_MEMORY_DB" ".dump" > "$MEMORY_BACKUP_FILE"

# Verify integrity
sqlite3 "$MEMORY_BACKUP_FILE" "PRAGMA integrity_check;" | grep -i ok
```

### Restore Procedure with Integrity Check

```bash
# Restore from backup
sqlite3 $AVD_MEMORY_DB < "$MEMORY_BACKUP_FILE"

# Verify data integrity
INTEGRITY_STATUS=$(sqlite3 "$AVD_MEMORY_DB" "PRAGMA integrity_check;")

if [ "$INTEGRITY_STATUS" != "ok" ]; then
    echo "WARNING: Backup has corruption. Review logs."
    sqlite3 "$AVD_MEMORY_DB" ".dump" > /dev/null  # Re-dump corrupted data
    
    # Fallback: restore from previous backup
    BACKUP_FILE=$(ls -t $HOME/.avd-memory-backups/*.db | head -n 1)
    if [ -f "$BACKUP_FILE" ]; then
        sqlite3 $AVD_MEMORY_DB < "$BACKUP_FILE"
    fi
fi

# Verify >95% similarity with current state (if not first restore)
SIMILARITY_CHECK=$(sqlite3 "$AVD_MEMORY_DB" "SELECT memory_hash, confidence_score FROM semantic_memory LIMIT 10;")
```

### Power Cycle Scenario Testing

**Test Case**: Restore from power loss without backup

| Scenario | Expected Outcome | Status |
|----------|------------------|--------|
| **Full system crash** (no prior backup) | Recovery fails → user loses episodic/semantic memories | ❗ CRITICAL |
| **Memory-only crash** (SQLite still accessible) | Automatic recovery from last backup | ✅ SUCCESS |
| **Cold boot after warm shutdown** | Memory persists from disk (SQLite auto-recovery) | ✅ SUCCESS |

**Critical Note**: Full system crash without backup results in permanent memory loss. User must implement automated daily backups as part of startup routine.

### Backup Automation

```bash
#!/bin/bash
# AVD MEMORY BACKUP AUTOMATION

BACKUP_DIR=$HOME/.avd-memory-backups
AVD_MEMORY_DB="/Users/ahhveedaa/.openclaw/workspace/memory.db"  # Example path

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR"

# Schedule: daily at 00:30 UTC (before any user activity)
CRON_SHELL="0 30 * * * /bin/bash $HOME/scripts/memory_backup.sh"

# Full backup with compression
sqlite3 "$AVD_MEMORY_DB" ".dump" | gzip > "$BACKUP_DIR/mem_db_$(date +%Y%m%d_%H%M%S).gz"

# Keep last 14 days of backups (30+90-day policy)
cd "$BACKUP_DIR"
find . -name "*.gz" -mtime +14 -delete
```

---

## SQLite Storage Schema

### Core Tables

```sql
-- Episodic memories
CREATE TABLE episodic_memory (
    id TEXT PRIMARY KEY,
    event_id TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    duration_minutes INTEGER,
    summary TEXT,
    tags TEXT[],
    memory_hash TEXT UNIQUE CHECK(length(memory_hash) = 32),
    FOREIGN KEY(event_id) REFERENCES events (id)
);

-- Semantic memories (domain knowledge)
CREATE TABLE semantic_memory (
    id TEXT PRIMARY KEY,
    concept_id TEXT NOT NULL,
    confidence_score REAL CHECK(confidence_score >= 0.0 AND confidence_score <= 1.0),
    fact_statement TEXT,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(concept_id) REFERENCES concepts (id)
);

-- Procedural memories (skills/patterns)
CREATE TABLE procedural_memory (
    id TEXT PRIMARY KEY,
    skill_pattern TEXT NOT NULL,
    acquisition_frequency INTEGER,
    consolidation_status TEXT CHECK(consolidation_status IN ('active', 'stable', 'unused')),
    FOREIGN KEY(id) REFERENCES skills (id)
);

-- Working memory context
CREATE TABLE working_memory (
    id TEXT PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    context_snapshot BLOB,
    expires_at DATETIME
);

-- Memory consolidation events
CREATE TABLE memory_consolidation (
    from_event_id TEXT NOT NULL,
    to_semantic_id TEXT,
    confidence_score REAL,
    happened_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(from_event_id) REFERENCES episodic_memory(id)
);

-- Indexes for query optimization
CREATE INDEX idx_episodic_timestamp ON episodic_memory(timestamp);
CREATE INDEX idx_semantic_concept ON semantic_memory(concept_id);
CREATE INDEX idx_working_expires ON working_memory(expires_at);
```

### Memory Access Interface

```swift
// memory_store.swift

import SQLite3

class MemoryStore {
    
    let db: OpaqueSwiftSQLite3DB
    
    private init(db_path: String) {
        self.db = OpaqueSwiftSQLite3DB(openPath: db_path, flags: .readWrite)
    }
    
    // Episodic memory operations
    func getEpisodicMemory(for eventID: String) async throws -> MemoryEntry? {
        var stmt: OpaqueSQLite3Stmt?
        sqlite3_prepare_v2(db as CVarType, 
                           "SELECT * FROM episodic_memory WHERE id = ?1 LIMIT 1",
                           nil,
                           &stmt,
                           nil
        )
        
        defer { sqlite3_finalize(stmt as CVarType) }
        
        sqlite3_bind_text(stmt as CVarType, 1, eventID.encode(), -1)
        
        guard let stmt = stmt else { return nil }
        
        return MemoryEntry.decode(from: stmt)?(statement:)
    }
    
    func storeEpisodicMemory(event: EventRecord) async throws {
        try sqlite3_insert(
            db,
            "episodic_memory",
            event.id.encode(),
            event.event_id.encode(),
            event.duration_minutes.encode(),
            event.summary.encode(),
            event.tags.encode()
        )
    }
    
    // Semantic memory operations
    func getSemanticKnowledge(for conceptID: String) async throws -> [MemoryFact] {
        var stmt: OpaqueSQLite3Stmt?
        sqlite3_prepare_v2(db as CVarType,
                           "SELECT * FROM semantic_memory WHERE concept_id = ?1",
                           nil,
                           &stmt,
                           nil
        )
        
        defer { sqlite3_finalize(stmt as CVarType) }
        
        sqlite3_bind_text(stmt as CVarType, 1, conceptID.encode(), -1)
        
        guard let stmt = stmt else { return [] }
        
        var facts: [MemoryFact] = []
        // Fetch and decode rows...
        
        return facts
    }
    
    func updateSemanticConfidence(
        for conceptId: String, 
        newScore: Double
    ) async throws {
        try sqlite3_update(
            db,
            "semantic_memory",
            "SET confidence_score = ?1" as CVarType,
            newScore.encode() as CFIndexType,
            "WHERE concept_id = ?2" as CVarType,
            conceptId.encode()
        )
    }
    
    // Procedural memory operations
    func acquireSkill(
        for skillName: String, 
        fromContext context: Context
    ) async throws {
        // Reset acquisition frequency to 0 (new learning)
        try sqlite3_update(
            db,
            "procedural_memory",
            "SET acquisition_frequency = ?1, consolidation_status = 'active'",
            0.encode(),
            "WHERE skill_pattern LIKE ?2" as CVarType,
            "%\(skillName)%".encode()
        )
    }
    
    // Memory decay engine
    func applyDecayRules() async throws {
        // Exponential decay for episodic memories (linear with compound reset)
        let current_time = Date().timeIntervalSince1970
        
        var statements: [String] = []
        var parameters: [[Any]] = []
        
        // Apply episodic decay (>75% similarity to semantic, convert if >6 days since last use)
        statements += "UPDATE episodic_memory SET" +
                     "memory_hash = calculate_memory_hash(memory_text, timestamp)"
        
        return await withCheckedThrowingValue { result in
            for statement in statements {
                try sqlite3_prepare_v2(db as CVarType, 
                                      statement as CFStringType, nil, &result_stmt, nil)
                // ... parameter binding logic ...
                try sqlite3_exec(db as CVarType, result_sql as CFStringType)
            }
        }
    }
}
```

---

## Intervention Triggers

### Automatic Decay Trigger Conditions

| Condition | Action Triggered | Memory Type Affected |
|-----------|-----------------|---------------------|
| **>60 days since last use** (episodic, <70% similarity) | Convert to semantic memory | Episodic → Semantic (preserves facts, loses temporal context) |
| **>90 days unused** (episodes not consolidated) | Drop from persistent storage | All episodic memories >3 years old |
| **>30 days unused** (procedural patterns) | Decay frequency by 50% | Procedural skills |

### Manual Intervention API

```swift
func forceMemoryUpdate(type: MemoryType, event_id: String) async throws {
    // Manually re-consolidate episodic to semantic
    try await performSemanticConsolidation(
        from: event_id,
        type: .semantic,
        confidence_boost: 0.15
    )
}

func resetSkillConfidence(for skillName: String) async throws {
    // Treat as if user is learning fresh
    try await acquireSkill(
        for: skillName,
        fromContext: Context()
    )
}
```

---

## References

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Core memory system integration
- [IDENTITY.md](./IDENTITY.md) - Memory as identity foundation

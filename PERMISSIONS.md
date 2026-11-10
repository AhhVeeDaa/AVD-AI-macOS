# PERMISSIONS.md - Permission and Policy Enforcement System

**Author:** Avida Buyombo | **Version:** 1.0 | **Last Updated:** 2026-11-09

---

## Executive Summary

AVD Core implements a rigorous, five-tiered permission model with audit logging, revocation support, and context-aware access control. This system ensures safe execution by enforcing policy before any operation proceeds. The permission framework operates independently of OpenClaw while integrating seamlessly when OpenClaw is used as an execution adapter.

---

## Table of Contents

1. [Permission Levels](#permission-levels)
2. [Policy Engine Architecture](#policy-engine-architecture)
3. [Access Control Flow](#access-control-flow)
4. [Audit Logging Framework](#audit-logging-framework)
5. [Revocation Mechanisms](#revocation-mechanisms)
6. [Swift Execution Integration](#swift-execution-integration)

---

## Permission Levels

### Five-Tiered Model

| Level | Capability | Description | Risk Tier |
|-------|------------|-------------|-----------|
| **OBSERVE** | `read`, `query`, `log` | Read-only access to system state and user data | Low |
| **ASSIST** | `modify_config`, `start_service`, `create_file` | Configuration changes, service orchestration | Medium |
| **EXECUTE** | `run_code`, `spawn_process`, `execute_shell`, `write_file` | Execute user-provided code and binaries | High |
| **RESTRICTED** | `install_package`, `modify_launchd`, `alter_permissions` | System-level changes requiring root privileges | Very High |
| **PROHIBITED** | *none* | Zero-execution capability | N/A |

---

### Permission Definitions

#### OBSERVE
- **Allowed Operations:**
  - Read files and directories
  - Query system state via CLI tools
  - Access user-provided content (messages, documents)
  - Log audit trails
- **Forbidden Operations:**
  - Writing to any file or directory
  - Starting or stopping services
  - Executing code or binaries

#### ASSIST
- **Allowed Operations:**
  - Modify configuration files (YAML, JSON, TOML)
  - Start/stop services via `launchd` plist files
  - Create/delete user-owned files in writable directories
  - Use standard CLI tools (`brew`, `npm`, etc.) with pre-defined packages

#### EXECUTE
- **Allowed Operations:**
  - Run any Swift code from AVD Core (`.swift` files)
  - Execute shell scripts and commands
  - Spawn subprocesses with inherited environment
  - Write to user's home directory (`~/`)
  - Read and execute binaries in `/Applications/`, `~/Applications/`

#### RESTRICTED
- **Allowed Operations:**
  - Install system packages (Homebrew, etc.)
  - Modify LaunchAgent/LaunchDaemon plists
  - Adjust system permissions via `chmod`
  - Access network interfaces (`networksetup`)
  - Modify system-wide configurations (`/etc/`, `/Library/`, `/usr/local/`)

#### PROHIBITED
- **Allowed Operations:** *none*
- **Purpose:** Serves as baseline for zero-trust execution environments

---

## Policy Engine Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────┐
│                     AVD CORE                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │    Requester  │  │   Resource   │  │   Action     │  │
│  │    Context    │  │      State   │  │   Definition │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                           ▼
              ┌──────────────────────────────────────┐
              │         Policy Decision Point        │
              │    (context-aware, rule-based)      │
              └──────────────────────────────────────┘
                           ▼
              ┌──────────────────────────────────────┐
              │       Permission Level Assigner       │
              │   (checks against user profile)       │
              └──────────────────────────────────────┘
                           ▼
              ┌──────────────────────────────────────┐
              │         Audit Logger                  │
              │     (SQLite with context capture)     │
              └──────────────────────────────────────┘
```

### Data Flow

1. **Request Submission**: User submits an action request (e.g., "Run `npm install @sveltejs/vite-plugin-svelte`")
2. **Context Capture**: AVD Core captures:
   - Requester identity (`"who"` field)
   - Resource target (file path, system component)
   - Action semantics (install, execute, modify)
   - Timestamp with timezone
3. **Policy Evaluation**: Rule-based evaluation against:
   - User-defined permission profile (default: `OBSERVE`)
   - Temporal constraints (time-of-day rules)
   - Resource sensitivity classification
4. **Decision Enforcement**: Grant or deny with reason code
5. **Audit Recording**: Immutable log entry to SQLite

---

## Access Control Flow

### Permission Request Lifecycle

```
User Request → Context Capture → Policy Evaluation → Decision → Execution
                                    └───────┘
                                    │
                                    ▼
                            ┌──────────────┐
                            │   Logging    │
                            │  (concurrent) │
                            └──────────────┘
```

### Example: npm Installation Flow

**Input:** `npm install sveltekit`

| Step | Action | Result | Log Entry |
|------|--------|--------|-----------|
| **1** | User submits request | - | N/A |
| **2** | Capture context | `{ requester: "main", action: "install", package: "sveltekit" }` | `req_id=abc123 user=main op=install pkg=sveltekit t=2026-11-09 21:14Z level=OBSERVE` |
| **3** | Evaluate policy | Level = `OBSERVE` (default) → action `install` requires `RESTRICTED` | **DENY**: level=OBSERVE required_level=RESTRICTED reason="Insufficient permissions" |
| **4** | Reject execution | - | Log entry saved in step 2 |
| **5** | Offer assistance | Suggest: `npm create-svelte --install` or manual install by user | N/A |

---

## Audit Logging Framework

### SQLite Schema

```sql
CREATE TABLE permission_logs (
    req_id TEXT PRIMARY KEY,
    requester TEXT NOT NULL,
    action TEXT NOT NULL,
    resource TEXT,
    requested_level TEXT NOT NULL,
    granted_level TEXT NOT NULL,
    decision TEXT NOT NULL CHECK(decision IN ('granted', 'denied')),
    reason TEXT,
    ip_address TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    context_json TEXT,
    INDEX(requester_action),
    INDEX(timestamp)
);

CREATE TABLE permission_profiles (
    profile_id TEXT PRIMARY KEY,
    user_name TEXT NOT NULL,
    default_level TEXT NOT NULL,
    custom_rules TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_modified DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Log Format Example

```json
{
  "req_id": "abc123def456",
  "user_name": "main",
  "action": "npm-install",
  "resource": "@sveltejs/kit",
  "requested_level": "RESTRICTED",
  "granted_level": "OBSERVE",
  "decision": "denied",
  "reason": "User permission profile requires RESTRICTED for installation actions",
  "timestamp": "2026-11-09T21:14:32Z",
  "ip_address": "192.168.1.101"
}
```

### Query Examples

```sql
-- Get all requests denied by current user
SELECT * FROM permission_logs 
WHERE requester = 'main' AND decision = 'denied'
ORDER BY timestamp DESC 
LIMIT 5;

-- Track execution attempts for user over past day
SELECT COUNT(*) as failed_execs, SUM(requested_level) as total_requests
FROM permission_logs 
WHERE requester = 'main' 
AND date(timestamp) = date('now')
GROUP BY requested_level;
```

---

## Revocation Mechanisms

### Policy Revocation Events

| Event Type | Trigger | Action Required | Recovery Options |
|------------|---------|-----------------|------------------|
| **user_revoked** | User manually revokes permission via AVD Core UI | Immediate profile update to `PROHIBITED` for affected action type | None (re-execution re-evaluates) |
| **policy_update** | System policy change detected | All pending requests cached and delayed until re-evaluation | Automatic retry within 5 minutes |
| **context_change** | Time-based rules changed (e.g., hours before 00:00) | Context-aware re-check for active operations | Automatic based on new time window |

### Revocation API

```swift
/// User-initiated permission revocation
func revokePermission(for action: String, by user: String, until date: Date?) {
    // Query current profile level
    let currentLevel = await getPermissionLevel(action: action)
    
    // Set to PROHIBITED (zero capability)
    try await setPermissionLevel(
        action: action,
        level: .prohibited,
        by: user,
        expiryDate: date
    )
    
    // Update context for all future requests
    await updateRequesterContext(user: user)
}
```

### Revocation Log Example

```json
{
  "req_id": "xyz789",
  "user_name": "main",
  "action": "npm-install",
  "resource": "sveltekit",
  "requested_level": "RESTRICTED",
  "granted_level": "PROHIBITED",
  "decision": "denied",
  "reason": "User revoked npm installation permission via AVD Core UI",
  "timestamp": "2026-11-09T23:45:22Z",
  "revoked_by": "main"
}
```

---

## Swift Execution Integration

### Execution Sandboxing

```
┌──────────────────────────────────────────────────────────┐
│                   AVD EXECUTION                           │
│                                                           │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│   │  Swift      │    │   Shell     │    │  Sandbox   │  │
│   │  Code       │    │   Commands  │    │   Env       │  │
│   │  (.swift)   │    │     (sh/bz) │    │   Isolated │  │
│   └──────┬───────┘    └──────┬───────┘    └──────┬───────┘  │
│          │                   │                 │         │
│          ▼                   ▼                 ▼         │
│   ┌─────────────────────────────────────────────┐       │
│   │           EXECUTION MONITOR                  │
│   │   (timeout tracking, resource limits)      │
│   └─────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────┘
```

### Execution Monitoring

**Phase 2 Deliverable**: Implementation specification for execution monitoring:

```swift
// ExecutionMonitor.swift

struct ExecutionMonitor {
    
    let maxTimeout: TimeInterval = 300 // 5 minutes
    var startedAt: Date?
    var resourceUsage: ResourceMetrics
    
    func startExecution(code: String, command: String?) -> ExecutionResult {
        guard let command = command else {
            return .error("command not provided")
        }
        
        startedAt = Date()
        process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        
        // Capture stdout/stderr for audit
        process.standardOutput = { output in
            await logAudit(output, category: "stdout", code: code)
        }
        process.standardError = { error in
            await logAudit(error, category: "stderr", code: code)
        }
        
        // Initial permission check before spawn
        let level = await getPermissionLevel(command: command)
        guard level >= .execute else {
            return .error("execution permission denied")
        }
        
        let result = try? process.run()
        
        // Check for hung/timeout
        if let status = process.waitUntilTimedOut(timeout: maxTimeout) {
            await logAudit(status, code: code, event: "hung")
        }
        
        return result
    }
    
    func checkResources(resourceUsage: ResourceMetrics) -> Bool {
        // Monitor memory usage (16GB unified limit)
        guard resourceUsage.memory > 14_000_000_000 else {
            return true
        }
        
        // Warn on high usage (>90%)
        if resourceUsage.memory > 14_000_000_000 {
            await logAudit(
                "High memory usage detected",
                code: "main",
                event: "warning"
            )
            return false // block execution on >90%
        }
        
        // Monitor file descriptors (limit: 1024)
        guard resourceUsage.fds > 1000 else {
            return true
        }
        
        await logAudit("File descriptor count approaching limit", code: "main")
        return true
    }
}
```

---

## User-Defined Profiles

### Profile Management Interface

| Feature | Description | Default Behavior |
|---------|-------------|------------------|
| **Default Level** | Baseline permission level | `OBSERVE` (read-only) |
| **Custom Actions** | Per-action custom levels | Requires explicit request |
| **Automatic Promotions** | Auto-promotion of actions | Disabled by default |
| **Auto-Decay** | Time-based decay | None (manual management only) |

### Profile Schema Example

```json
{
  "profile_id": "dev_primary",
  "user_name": "main",
  "default_level": "OBSERVE",
  "custom_rules": [
    {
      "action_type": "npm-install",
      "level": "RESTRICTED"
    },
    {
      "action_type": "swift-exec",
      "level": "EXECUTE"
    }
  ],
  "automatic_promotions": false,
  "auto_decay": false,
  "created_at": "2026-11-08T15:30:00Z",
  "last_modified": "2026-11-09T08:22:15Z"
}
```

---

## Security Model Summary

### Zero Trust Enforcement

AVD Core enforces the principle of least privilege at every layer:

1. **User Intent**: Every user action is logged as a permission request with full context
2. **Policy Check**: Request passes through rule-based policy engine before any execution
3. **Level Enforced**: Operation proceeds only if `user_level >= required_level`
4. **Audit Trail**: All requests (granted and denied) are logged immutably

### Violation Handling

**Violation Detection:**
- Any attempt by AVD Core to bypass permission checks triggers immediate alert
- Affected actions are set to `PROHIBITED` level for 24 hours or until manual override

**Alerting Thresholds:**
- Attempted elevation: User-level → RESTRICTED without approval
- Unauthorized system modification beyond user permissions

---

## References

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Core architecture overview
- [IDENTITY.md](./IDENTITY.md) - System personality definition

# Security Policy

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

To report a security vulnerability, email the maintainer directly. Describe the issue in sufficient detail to reproduce it. You will receive a response within 72 hours.

Please include:
- A description of the vulnerability and its potential impact
- Steps to reproduce
- Any suggested mitigations if you have them

We will acknowledge the report, investigate it, and coordinate a fix and disclosure timeline with you.

---

## Privacy Guarantees

Witness is designed to be private by construction:

| Property | Guarantee |
|---|---|
| Inference | Runs entirely on-device via Ollama (127.0.0.1) |
| Memory | Stored in local application data only |
| Identity | Loaded from local files; never transmitted |
| Tool execution | Restricted to an explicit allowlist |
| File access | Blocked from sensitive paths by default |
| Network | Only contacts localhost inference providers |
| Telemetry | None. Zero analytics, crash reporting, or usage tracking. |

Witness does **not**:
- Send conversation history, memory, or identity data to any remote server
- Use cloud inference or fall back to it silently
- Track usage, errors, or behavior
- Store credentials, API keys, or tokens

---

## Tool Execution Security

The tool execution allowlist is defined in `ToolRegistry.commandAllowlist`:

```
git, swift, uname, sw_vers, echo, pwd, date, whoami
```

Commands outside this list are rejected regardless of model instructions.

File read operations are blocked for paths containing any of:
`id_rsa`, `.ssh`, `Keychains`, `Credentials`, `token`, `.env`

The five-tier permission system enforces escalation gates for all tool actions:
`observe → query → suggest → execute → autonomous`

No model instruction can elevate its own permission tier.

---

## MCP Server Policy

Discovered MCP servers are **not automatically trusted**. Each MCP server and each of its tools requires individual permission policies before Witness will execute calls against them.

---

## Supported Versions

| Version | Supported |
|---|---|
| v1.6.1 | ✅ |
| v1.6.0 | ⚠️ Known voice crash — upgrade recommended |
| < v1.6.0 | ❌ |

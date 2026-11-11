# Contributing to Witness

Thank you for your interest in contributing to Witness. This document explains how to contribute code, documentation, tests, and bug reports.

---

## Principles

Before contributing, understand the core constraints that are **non-negotiable**:

- **AVD Core must remain independent of OpenClaw.** Do not introduce cross-dependencies.
- **Witness identity must remain independent of the inference provider.** Do not tie identity state to any model.
- **Memory must remain independent of the model.** Memory tiers are stored locally and are model-agnostic.
- **Permissions must be enforced independently of model instructions.** A model must never grant itself additional permissions.
- **Local-first always.** No cloud inference, external memory transmission, or silent fallback.
- **No feature may be represented as working when it is only a placeholder.**

---

## Getting Started

```bash
git clone <repo-url>
cd AVD-AI-macOS

# Build debug
swift build

# Run tests (no Ollama required for unit tests)
swift test --skip EndToEndOrchestratorTests
```

Requirements: macOS 14+, Xcode 16+, Apple Silicon.

---

## Code Standards

### Swift Version
- Swift 6 strict concurrency is enforced.
- All shared mutable state must be `@MainActor` or use proper actor isolation.
- Use `@unchecked Sendable` only when the type contains non-Sendable types unavoidably (e.g., `[String: Any]`), and document why.

### No External Dependencies
- `Package.swift` dependencies must remain empty.
- Do not add third-party Swift packages without explicit discussion in an issue first.
- All functionality must use Apple system frameworks or original code.

### Formatting
- Use 4-space indentation.
- Maximum line length: 120 characters.
- Document all public types and methods with doc comments.
- Add `// Copyright 2026 Avida Buyombo` and `// SPDX-License-Identifier: Apache-2.0` headers to new source files.

### Testing
- Every new feature must include unit tests.
- Tests must not remove or weaken existing assertions to achieve a green build.
- Tests must not require network access except `EndToEndOrchestratorTests` (which is explicitly marked as an integration test).
- Do not use `XCTSkip` to hide failures.

---

## Submitting Changes

1. Fork the repository and create a branch from `main`:
   ```bash
   git checkout -b feat/my-feature
   ```

2. Make your changes with focused, atomic commits.

3. Run the full unit test suite before submitting:
   ```bash
   swift test --skip EndToEndOrchestratorTests
   ```

4. Open a pull request against `main` with:
   - A clear title and description
   - A summary of what changed and why
   - Test results (paste the `swift test` output)
   - Any known limitations

---

## Reporting Bugs

Open an issue and include:
- macOS version and Mac model
- Witness version (from the app menu or `CFBundleShortVersionString`)
- Steps to reproduce
- What you expected to happen
- What actually happened
- Crash logs if applicable (from `~/Library/Logs/DiagnosticReports/`)

---

## Security Vulnerabilities

Do **not** file public issues for security vulnerabilities. See [SECURITY.md](SECURITY.md).

---

## Code of Conduct

All contributors are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

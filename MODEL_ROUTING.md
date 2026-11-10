# MODEL_ROUTING.md - Model Selection and Routing Strategy

**Author:** Avida Buyombo | **Version:** 1.0 | **Last Updated:** 2026-11-09

---

## Executive Summary

AVD Core implements a **dynamic model routing system** with qwen3.5:4b (4GB GGUF) as the default local inference engine, supplemented by an explicit cloud fallback mechanism triggered only under >90% memory usage or user command. This architecture ensures offline operation capability while maintaining graceful degradation to cloud-based alternatives when necessary.

---

## Table of Contents

1. [Model Selection Strategy](#model-selection-strategy)
2. [Routing Architecture](#routing-architecture)
3. [Automatic Fallback Triggers](#automatic-fallback-triggers)
4. [User Override Mechanism](#user-override-mechanism)
5. [Local Inference Configuration](#local-inference-configuration)
6. [Cloud Fallback Protocol](#cloud-fallback-protocol)

---

## Model Selection Strategy

### Primary Model: qwen3.5:4b (4GB GGUF)

| Property | Value |
|----------|--------|
| **Quantization** | Q4_K_M (4-bit compressed) |
| **Raw Size** | ~4.7 GB compressed |
| **Memory Footprint** | 1.6 GB VRAM equivalent + overhead (~6GB peak with context) |
| **Inference Speed** | 30-50 tokens/sec (arm64 native inference) |
| **Offline Capability** | Full local execution without network dependency |

### Model Selection Criteria Matrix

| Criterion | qwen3.5:4b | Cloud Alternative | Decision |
|-----------|-------------|-------------------|----------|
| Offline operation required | ✅ Yes | ❌ No | Select local |
| Memory ≤16GB | ✅ 4GB loaded + context | ⚠️ Risky (cloud can't be used) | Select local |
| Latency <500ms | ✅ ~150ms (arm64) | ⚠️ Varies by region | Select local |
| Cost-sensitive | ✅ $0 | ❌ $/token charged | Select local |
| Complex reasoning required | ⚠️ Moderate capability | ✅ Better performance | Evaluate context-specifically |
| Privacy-first requirement | ✅ Local execution | ⚠️ Data sent to server | Select local |

### Dynamic Threshold-Based Model Switching

```swift
// model_router.swift

struct ModelSelector {
    
    static let qwen35_4b = "/Users/ahhveedaa/.openclaw/tmp/qwen3.5-4b.Q4K_M.gguf"
    
    enum RoutingDecision {
        case local
        case cloud(reason: String)
    }
    
    func determineModel(for query: String) async throws -> RoutingDecision {
        
        // Check current memory usage (threshold: >90% = 14.4GB)
        let memoryUsage = await getCurrentMemoryUsage()
        
        // Decision tree based on context and memory pressure
        if memoryUsage >= 14400_000_000 { // >90%
            return .cloud(reason: "Local memory exhausted")
        }
        
        // Check explicit user preference
        if let userPreference = await getUserModelPreference() {
            return .userOverride(userPreference)
        }
        
        // No cloud fallback unless explicitly requested
        if !await userRequestedCloudFallback() {
            return .local
        }
        
        // Default: prefer local for all inference
        return .local
    }
}
```

### Model Selection Scoring Algorithm

```swift
// model_selection_score.swift

struct ModelScoringEngine {
    
    enum ScoreComponent {
        case memoryUsage(Double)          // Memory pressure
        case latencyTarget(Double)         // Network vs local latency
        case userPreference(Int8)          // Preference weight
        case privacyWeight(Int8)           // Privacy priority
        case capabilityGap(Double)         // Model capability vs task requirement
        
        var total: Double {
            return memoryUsage + 
                   (latencyTarget * 2) +   // Local is much faster
                   (userPreference * 3) +   // User preference heavily weighted
                   privacyWeight +
                   (capabilityGap * 0.5)
        }
    }
    
    func scoreModel(for task: TaskRequirement, currentMemory: Double) -> [ScoreComponent] {
        
        let memoryPressure = min(Double.min, max(currentMemory / 16_000_000_000, 0.5), 0.95)
        
        // Local model score (qwen3.5:4b)
        let localScore: [Double] = {
            var scores = [double]()
            
            // Memory penalty if using >90% of available
            scores.append(-memoryPressure * 100)
            
            // No network overhead (baseline score: 0)
            scores.append(0.0)
            
            // User preference (default: prefer local = -50 penalty for cloud)
            let userPref = await getUserPreference()
            scores.append(userPref < 0 ? -50 : 25)
            
            // Privacy weight (always prefer local = +75)
            scores.append(75.0)
            
            // Capability gap (qwen3.5:4b is adequate for most tasks = 10)
            scores.append(10.0)
            
            return scores
        }()
        
        // Cloud model score
        let cloudScore: [Double] = {
            var scores = [double]()
            
            // Memory penalty: none (cloud uses separate compute)
            scores.append(0.0)
            
            // Network latency estimate (~500ms average to US servers)
            scores.append(-500 * 0.167)  // Convert to tokens/sec
            scores.append(-83.3)
            
            // User preference (same as above)
            let userPref = await getUserPreference()
            scores.append(userPref < 0 ? -50 : 25)
            
            // Privacy weight (penalty for cloud = -100)
            scores.append(-100.0)
            
            // Capability gap (cloud models may be more capable)
            let cloudCapability: Double = await assessCloudCapabilityGap()
            scores.append(cloudCapability * 0.5)
            
            return scores
        }()
        
        // Return winning model choice
        return localScore + cloudScore
    }
}
```

---

## Routing Architecture

### Model Selection Decision Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     INPUT LAYER                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │   Query   │  │ User     │  │ System   │                  │
│  │  Request  │  │ Input    │  │ Context  │                  │
│  └─────┬─────┘  └─────┬────┘  └─────┬───┘                  │
│        │              │              │                      │
└────────┴──────────────┴──────────────┴──────────────────────┘
                 ▼
┌─────────────────────────────────────────────────────────────┐
│                    DECISION ENGINE                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Memory Usage Check (90% threshold)                  │   │
│  │ User Preference Retrieval                          │   │
│  │ Privacy Policy Enforcement                         │   │
│  │ Capability Assessment                              │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────┐     ┌─────────┐     ┌─────────┐              │
│  │ Local    │     │ Cloud   │     │ Hybrid  │              │
│  │ Choice   │     │ Mode    │     │ State   │              │
│  └─────┬─────┘     └─────┬───┘     └─────┬───┘              │
│        │                  │                 │                 │
└────────┴──────────────────┴─────────────────┴─────────────────┘
                 ▼
┌─────────────────────────────────────────────────────────────┐
│                   EXECUTION ROUTER                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Local Inference Engine (qwen3.5:4b GGUF)             │   │
│  │  • Direct CPU/GPU inference                          │   │
│  │  • No network dependency                             │   │
│  │  • Streaming responses to client                     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Cloud Gateway (LLM API Proxy)                        │   │
│  │  • Fallback mode only                                 │   │
│  │  • Explicit permission or memory exhaustion           │   │
│  │  • Streaming response aggregation                     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Runtime State Machine

```swift
// model_routing_state.swift

enum ModelRoutingState {
    
    case readyForLocal(modelPath: String)
    case local(modelPath: String, context: MemoryContext)
    case cloud(targetEndpoint: String, requestToken: String)
    case hybrid(local: ModelRoute?, cloud: ModelRoute?)
    
    // State transitions
    func attemptModelSwitch(from: State, reason: String) async throws -> State {
        switch from {
        case .readyForLocal(let path):
            if let local = try await LocalRoute.init(modelPath: path) {
                // Check memory first before any cloud request
                if currentMemory < 14_400_000_000 {
                    return .local(modelPath: path, context: MemoryContext())
                } else {
                    // Switch to cloud fallback only after memory check fails
                    return .cloud(targetEndpoint: await cloudGatewayEndpoint(), 
                                  requestToken: generateRequestToken(reason))
                }
            }
            
        case .local(let path):
            if currentMemory > 14_400_000_000 {
                // Memory pressure exceeds threshold, switch to cloud
                return await transitionToCloud(path: path)
            }
            
            return .readyForLocal(modelPath: path)
        }
    }
}
```

---

## Automatic Fallback Triggers

### Memory-Based Fallback (Primary Trigger)

| Condition | Action | Response Time |
|-----------|--------|----------------|
| **Memory >90%** (14.4GB+) | Switch to cloud only if user accepts cloud fallback | Immediate |
| **Memory 80-90%** (12.8-14.4GB) | Warning; continue with local until threshold exceeded | Gradual degradation |

```swift
// memory_triggers.swift

struct AutomaticFALLBACKTriggers {
    
    func shouldFallbackForLocalUsage(usage: Double) -> Bool {
        // Primary fallback trigger: >90% memory usage
        return usage >= 14_400_000_000
        
        // Detailed logging for user visibility
        await logFALLOUTTrigger {
            "Memory threshold exceeded: \(usage/1024/1024/1024)GB > 14.4GB threshold"
        }
    }
}

func handleFallbackTrigger(reason: String) async throws {
    
    // Notify user about fallback decision
    await sendNotification(
        type: .modelFallback,
        reason: reason,
        message: "Switching to cloud inference due to \(reason)"
    )
    
    // Transition routing state
    let newState = await transitionToCloudGateway()
    
    // Continue operation in cloud mode
    return await withCheckedThrowingValue { result in
        // Stream responses from cloud
        for response in await streamCloudResponseStream() {
            print(response)
        }
    }
}
```

---

## User Override Mechanism

### Explicit Model Selection

| Action | Trigger Method | Effect |
|--------|----------------|--------|
| `--use-local` | Flag or argument | Force local inference regardless of memory pressure |
| `--use-cloud` | Flag or argument | Force cloud fallback even if not required |
| `--model=MODEL_NAME` | Argument | Override default model selection entirely |

```bash
# User override mechanism
$ llm --user-preference=cloud  # Always use cloud (if available)
$ llm --local-only             # Force local inference (ignore memory threshold)
$ llm --model=qwen3.5-4b.Q4K_M  # Explicit model selection

# Programmatic override in Swift
func overrideModelUsage(for query: String, to: LocalModel | CloudModel) async throws {
    // Bypass automatic decision tree, force specified routing choice
    let forcedDecision = await withCheckedThrowingValue {
        ModelSelector.forceRoutingChoice(model: to, 
                                         reason: "user_override")
    }()
    
    return .routing(fallback: .none, userOverride: .yes)
}

overrideModelUsage(query: "What's the weather?", to: .cloud)  # Force cloud
```

### User Preference Storage

```json
{
  "model_routing_preference": {
    "default_strategy": "local_preferred",
    "automatic_threshold": 14_400_000_000,  // 90% memory threshold in bytes
    "cloud_gateway_endpoint": "http://your-cloud-llm-api.com/v1/chat",
    "privacy_policy_accepted": true,
    "local_only_mode_enabled": false
  }
}
```

---

## Local Inference Configuration

### qwen3.5:4b GGUF Loading Configuration

```bash
# qwen3.5:4b loading configuration (LLAMA.cpp)
llama-cli -m /Users/ahhveedaa/.openclaw/tmp/qwen3.5-4b.Q4K_M.gguf \
          -p "Assistant" \
          -n 128  # Prompt context size: 128 tokens
```

### Memory Management Configuration

| Parameter | Recommended Value | Reason |
|-----------|-------------------|--------|
| **Memory Budget** | 50% (6GB) | Prevent OOM with system background processes |
| **Max Context Size** | 4096 tokens | Balance between context and memory usage |
| **Batch Size** | 16-32 tokens | Optimize for CPU inference speed |
| **Thread Count** | 4 cores (arm64) | Parallel inference for faster output |

```swift
// local_inference_config.swift

struct LocalInferenceConfig {
    
    static let defaultMemoryBudget: UInt64 = 6 * 1024 * 1024 * 1024  // 6GB
    
    static var maxContextTokens: Int32 {
        return 4096  // Maximum context size (adjustable)
    }
    
    static var batchTokensPerBatch: UInt64 {
        return 32  // Tokens processed in parallel per request
    }
}

func initializeLocalInference(
    modelPath: String,
    memoryBudget: UInt64 = LocalInferenceConfig.defaultMemoryBudget
) async throws {
    
    // Load qwen3.5:4b GGUF into CPU context with specified memory budget
    let gguf = try await GGUFFile.load(from: modelPath)
    let kv = try await KVFile.initialize(gguf, memoryLimit: memoryBudget)
    
    // Monitor memory usage during inference
    while !isMemoryThresholdExceeded() {
        await monitorInferenceState(memoryBudget: memoryBudget)
        
        if shouldSwitchToCloud(forReason: .memory_pressure_exceeded) {
            await notifyUserOfModelFallback(reason: "Memory pressure exceeded")
        }
    }
    
    return .readyForLocalInference(modelPath: modelPath, config: kv)
}
```

---

## Cloud Fallback Protocol

### Cloud Endpoint Configuration

| Property | Value |
|----------|-------|
| **Default Gateway** | None (local-only first) |
| **FALLOUT Endpoint** | User-configured or cloud service endpoint |
| **Authentication Method** | API key / service account credentials |
| **Rate Limiting** | 30 requests/minute per user |

```json
{
  "cloud_fallback_config": {
    "default_gateway": null,  // No default; explicit selection required
    "fallback_endpoints": [
      {
        "name": "local_cloud_gateway",
        "endpoint": "https://your-cloud-llm-server.com/api/v1/chat/completions",
        "authentication": "Bearer <API_KEY>",
        "rate_limit": 30,
        "priority": 2
      }
    ],
    "fallback_conditions": [
      {
        "condition": "memory_threshold_exceeded",
        "threshold_bytes": 14_400_000_000,
        "action": "user_consent_required"
      },
      {
        "condition": "explicit_user_override",
        "method": "command_line_or_ui_toggle",
        "action": "force_cloud_fallback"
      }
    ]
  }
}
```

### Cloud Request Response Handling

```swift
// cloud_response_handler.swift

enum CloudResponseState {
    case success(response: ChatCompletionResponse)
    case timeout(error: Error)
    case partialResponse(receivedTokens: Int)
    case fallbackTriggered(reason: String)
}

func handleCloudResponse(state: State) async throws -> ChatMessage {
    
    switch state {
    case .success(let response):
        return await processCloudResponse(response)
        
    case .timeout(let error):
        // Automatically fall back to local inference
        let newState = await transitionToLocalInference(reason: "cloud_timeout")
        return await retryWithLocalFALLOUT(newState)
        
    case .partialResponse(let tokensReceived):
        // Continue streaming remaining tokens locally or via secondary cloud endpoint
        return await aggregateStreamingTokens(tokens: tokensReceived)
        
    case .fallbackTriggered(let reason):
        return await withCheckedThrowingValue { result in
            // Cloud fallback is mandatory due to user's request or system constraint
            print("Attempting cloud fallback: \(reason)")
            return await withCheckedThrowingValue { try? await queryCloudGateway() }
        }
    }
}

func transitionToLocalFALLOUT(
    from: State,
    reason: String
) async throws -> LocalRoute.State {
    
    // Bypass cloud entirely, use local inference only
    let localRoute = try await LocalRoute.init(
        modelPath: qwen35_4b_path,
        context: Context()
    )
    
    return .local(modelPath: localRoute.modelPath)
}
```

---

## References

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Model selection integration
- [IDENTITY.md](./IDENTITY.md) - Capability assessment framework

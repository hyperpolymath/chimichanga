;; STATE.scm - Checkpoint/Restore for AI Conversations
;; Project: Munition (chimichanga)
;; Format: Guile Scheme

(define state
  '((metadata
     (format-version . "1.0")
     (created . "2025-12-08")
     (updated . "2025-12-08")
     (project-name . "Munition")
     (repository . "hyperpolymath/chimichanga"))

    ;; =========================================================================
    ;; CURRENT POSITION
    ;; =========================================================================
    (current-position
     (version . "0.1.0-alpha")
     (phase . "core-complete")
     (completion-percentage . 35)
     (status . "in-progress")

     (summary . "Core execution framework complete with fuel metering, memory
                 isolation, forensic capture, and capability-restricted host
                 functions. RSR Gold compliance achieved. Ready to advance
                 toward production-grade features.")

     (implemented
      ("Core execution engine with compile → instantiate → execute → cleanup lifecycle")
      ("Fuel metering system with configurable allocation and exhaustion handling")
      ("Memory isolation - fresh zero-initialized memory per execution")
      ("Forensic capture on all failure paths with serialization")
      ("Pluggable runtime abstraction (Wasmex/Wasmtime default)")
      ("Capability-gated host functions: time, random, logging")
      ("Capability validation with risk classification")
      ("Comprehensive test suite: unit, integration, benchmarks")
      ("RSR Gold compliance: 15+ justfile tasks, SPDX headers, pinned deps")
      ("Full documentation: ARCHITECTURE.md, capability_model.md, ROADMAP.md")))

    ;; =========================================================================
    ;; ROUTE TO MVP v1.0
    ;; =========================================================================
    (mvp-roadmap
     (target-version . "1.0.0")
     (target-status . "production-ready")

     (milestones
      ((version . "0.2.0")
       (name . "pooling-and-host-functions")
       (completion . 0)
       (tasks
        ("Instance pooling for pre-compiled/instantiated WASM modules")
        ("Enhanced host functions: sandboxed filesystem read")
        ("Enhanced host functions: allowlisted HTTP client")
        ("Structured logging with capability-controlled output")
        ("Improved forensics: stack traces, variable reconstruction")
        ("Crash classification and pattern detection")))

      ((version . "0.3.0")
       (name . "resource-control")
       (completion . 0)
       (tasks
        ("Wizer integration for snapshot-and-restore pre-initialization")
        ("Configurable memory page limits")
        ("Wall-clock timeout integration alongside fuel bounds")
        ("Memory allocation bounds before instantiation")))

      ((version . "1.0.0")
       (name . "production-ready")
       (completion . 0)
       (tasks
        ("Independent security audit")
        ("Performance optimization pass")
        ("API stability guarantee and semantic versioning")
        ("Production deployment documentation")
        ("Alternative runtime support: Wasmer, WAMR")))))

    ;; =========================================================================
    ;; KNOWN ISSUES
    ;; =========================================================================
    (issues
     (code-issues
      ((location . "lib/munition.ex:208-215")
       (severity . "medium")
       (description . "Export/import validation stubbed - returns :ok without checking")
       (impact . "Cannot verify WASM modules export required functions before execution"))

      ((location . "lib/munition/host/functions.ex:124")
       (severity . "low")
       (description . "Log host function does not read message from WASM memory")
       (impact . "Logging calls acknowledge but don't capture actual log content"))

      ((location . "lib/munition/instance/manager.ex:100")
       (severity . "medium")
       (description . "execute_pooled/4 returns {:crash, :not_implemented}")
       (impact . "No performance optimization for repeated executions")))

     (design-considerations
      ("Timing attacks possible - execution time varies with input")
      ("Side-channel attacks via CPU cache theoretically possible")
      ("Memory allocation before instantiation not bounded")
      ("Dependent on Wasmtime security advisories for underlying safety")))

    ;; =========================================================================
    ;; QUESTIONS FOR MAINTAINER
    ;; =========================================================================
    (questions
     ((id . 1)
      (category . "architecture")
      (question . "For instance pooling, should pools be global (application-level)
                   or per-supervisor? Trade-off between resource efficiency and isolation.")
      (context . "v0.2.0 planning"))

     ((id . 2)
      (category . "security")
      (question . "What allowlist strategy for HTTP host function? Domain-based,
                   URL pattern, or capability token per-endpoint?")
      (context . "Host function expansion"))

     ((id . 3)
      (category . "priority")
      (question . "Should Wizer integration (v0.3.0) be prioritized over instance
                   pooling if startup latency is the primary bottleneck?")
      (context . "Roadmap sequencing"))

     ((id . 4)
      (category . "ecosystem")
      (question . "Are there specific attenuator languages (Lua, JS, Pony) that
                   should be reference implementations for v1.0 launch?")
      (context . "Ecosystem strategy"))

     ((id . 5)
      (category . "compliance")
      (question . "Is formal verification (TLA+/Coq) a v1.0 requirement or a
                   post-1.0 research direction?")
      (context . "Scope definition")))

    ;; =========================================================================
    ;; LONG-TERM ROADMAP
    ;; =========================================================================
    (long-term-roadmap
     (vision . "Become the definitive capability attenuation framework for safe
                execution of untrusted code in the Elixir ecosystem and beyond.")

     (post-v1-features
      ((category . "runtime-ecosystem")
       (items
        ("Wasmer runtime integration")
        ("WAMR (WebAssembly Micro Runtime) for embedded")
        ("Lunatic runtime exploration for actor model")))

      ((category . "attenuator-ecosystem")
       (items
        ("Reference Lua → WASM attenuator")
        ("Reference JavaScript → WASM attenuator")
        ("Capability-preserving Pony → WASM attenuator")))

      ((category . "advanced-capabilities")
       (items
        ("Graduated trust - dynamic capability expansion based on behavior")
        ("Capability inference from WASM module analysis")
        ("Cross-execution state sharing with explicit grants")
        ("Distributed execution across nodes")))

      ((category . "formal-methods")
       (items
        ("TLA+ specification of capability model")
        ("Coq proofs of isolation guarantees")
        ("Property-based testing with PropEr/StreamData")))

      ((category . "observability")
       (items
        ("OpenTelemetry integration for execution tracing")
        ("Prometheus metrics for fuel consumption patterns")
        ("Grafana dashboards for sandbox health"))))

     (use-cases
      ("Plugin systems with untrusted user code")
      ("Multi-tenant SaaS with isolated computation")
      ("Edge computing with resource-constrained execution")
      ("Research sandbox for language experimentation")
      ("Smart contract execution environments")))

    ;; =========================================================================
    ;; CRITICAL NEXT ACTIONS
    ;; =========================================================================
    (next-actions
     ((priority . 1)
      (action . "Implement export validation in lib/munition.ex")
      (rationale . "Security: verify WASM modules before execution")
      (effort . "small"))

     ((priority . 2)
      (action . "Implement import validation in lib/munition.ex")
      (rationale . "Security: ensure only expected imports are present")
      (effort . "small"))

     ((priority . 3)
      (action . "Complete log host function memory reading")
      (rationale . "Feature completeness: capture actual log messages")
      (effort . "small"))

     ((priority . 4)
      (action . "Design and implement instance pooling")
      (rationale . "Performance: reduce startup latency for repeated executions")
      (effort . "large"))

     ((priority . 5)
      (action . "Add memory limit configuration")
      (rationale . "Security: bound resource usage before instantiation")
      (effort . "medium")))

    ;; =========================================================================
    ;; PROJECT CATALOG
    ;; =========================================================================
    (project-catalog
     ((name . "munition-core")
      (status . "in-progress")
      (completion . 80)
      (phase . "stabilization")
      (next-action . "Complete stubbed validation functions"))

     ((name . "munition-pooling")
      (status . "not-started")
      (completion . 0)
      (phase . "design")
      (blocker . "Awaiting v0.2.0 cycle start")
      (next-action . "Design pool supervision strategy"))

     ((name . "munition-host-functions")
      (status . "in-progress")
      (completion . 40)
      (phase . "implementation")
      (next-action . "Implement filesystem read capability"))

     ((name . "munition-forensics")
      (status . "in-progress")
      (completion . 70)
      (phase . "enhancement")
      (next-action . "Add stack trace extraction")))

    ;; =========================================================================
    ;; SESSION HISTORY
    ;; =========================================================================
    (history
     ((date . "2025-12-08")
      (event . "STATE.scm created")
      (snapshot
       (overall-completion . 35)
       (version . "0.1.0-alpha")
       (status . "core-complete"))))))

;; End of STATE.scm

<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# Munition (Chimichanga) — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              PUBLIC API                 │
                        │          (Munition.fire/4)              │
                        └───────────────────┬─────────────────────┘
                                            │
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           INSTANCE MANAGER              │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │  Compile  │──►   Instantiate     │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        │        │                 │              │
                        │        └────────┬────────┘              │
                        │                 ▼                       │
                        │        ┌────────────────┐               │
                        │        │    Execute     │               │
                        │        │ (Fuel Gated)   │               │
                        │        └────────┬────────┘              │
                        └─────────────────│───────────────────────┘
                                          │
                                          ▼ Failure Path
                        ┌─────────────────────────────────────────┐
                        │           FORENSIC CAPTURE              │
                        │    (Atomic state, Memory snapshots)     │
                        └───────────────────┬─────────────────────┘
                                            │
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           RUNTIME INTERFACE             │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │  Wasmex   │  │  Capability       │  │
                        │  │ (Wasmtime)│  │  Gating           │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        └────────│─────────────────│──────────────┘
                                 │                 │
                                 ▼                 ▼
                        ┌─────────────────────────────────────────┐
                        │          WASM SANDBOX (CORE)            │
                        │      (Linear Memory, Fuel metering)     │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  TLA+ Spec          Justfile            │
                        │  Test WASM (Rust)   .machine_readable/  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CORE RUNTIME
  Instance Manager                  ██████████ 100%    Lifecycle orchestration stable
  Fuel Metering                     ██████████ 100%    Guaranteed termination active
  Memory Isolation                  ██████████ 100%    No state leaks between runs
  Wasmex / Wasmtime                 ██████████ 100%    Host backend verified

FORENSICS & CAPS
  Forensic Capture                  ██████████ 100%    Atomic snapshots on crash
  Analyser (MNTN)                   ████████░░  80%    Pattern search refining
  Capability Gating                 ██████████ 100%    Attenuation model active

REPO INFRASTRUCTURE
  TLA+ Formal Spec                  ██████████ 100%    Safety properties proven
  Justfile                          ██████████ 100%    RSR Gold validation tasks
  .machine_readable/                ██████████ 100%    STATE.a2ml tracking

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ██████████ 100%    v0.1.0 RSR Gold Compliant
```

## Key Dependencies

```
TLA+ Proof ───► Elixir Core ───► Wasmex ───► WASM Sandbox
                    │               │             │
                    ▼               ▼             ▼
              Instance Mgr ──► Fuel Meter ──► Forensics
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).

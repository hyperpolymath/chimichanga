<!--
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: 2025-2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

[![OpenSSF Best Practices](https://img.shields.io/badge/OpenSSF-Best_Practices-green?logo=opensourcesecurity)](https://www.bestpractices.dev/en/projects/new?repo_url=https://github.com/hyperpolymath/chimichanga)
[![License: PMPL-1.0](https://img.shields.io/badge/License-MPL--2.0-blue.svg)](https://github.com/hyperpolymath/palimpsest-license) <embed
src="https://api.thegreenwebfoundation.org/greencheckimage/github.com"
data-link="https://www.thegreenwebfoundation.org/green-web-check/?url=github.com" />
:toc: macro :toclevels: 3 :icons: font :source-highlighter: rouge
:sectanchors: :sectlinks:

A capability attenuation framework for sandboxed WASM execution in
Elixir.

![RSR Gold](https://img.shields.io/badge/RSR-Gold-gold)
[![License: PMPL-1.0](https://img.shields.io/badge/License-MPL--2.0-blue.svg)](https://github.com/hyperpolymath/palimpsest-license)
image:[Elixir](https://img.shields.io/badge/Elixir-1.14+-purple)

<div id="toc">

</div>

# Overview

Munition provides secure execution of untrusted WebAssembly code with
three core guarantees:

| Guarantee | Description |
|----|----|
| **Bounded Execution** | Fuel-metered computation that guarantees termination. Every WASM instruction consumes fuel; exhaustion halts execution deterministically. |
| **Memory Isolation** | Each execution gets fresh, isolated linear memory. No state leaks between executions. |
| **Forensic Capture** | Failure state is automatically captured for post-mortem analysis. Memory snapshots, fuel state, and execution context preserved atomically. |

# The Capability Attenuation Model

Munition implements a formal model for capability attenuation across
language boundaries:

    ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
    │  Source Code    │     │   Attenuator    │     │    Runtime      │
    │  (rich caps)    │ ──▶ │   (compiler)    │ ──▶ │  (restricted)   │
    │                 │     │                 │     │                 │
    │  PHP: can do    │     │  Removes/maps   │     │  WASM: can only │
    │  anything       │     │  capabilities   │     │  do what host   │
    │                 │     │                 │     │  permits        │
    │  Pony: typed    │     │  Preserves      │     │                 │
    │  capabilities   │     │  proofs         │     │  Elixir: super- │
    │                 │     │                 │     │  vises, captures│
    └─────────────────┘     └─────────────────┘     └─────────────────┘

## Attenuation Strategies

| Strategy | Source Languages | Description |
|----|----|----|
| **Restrictive** | PHP, JavaScript | Source has implicit universal capabilities. Attenuator removes/intercepts all capability exercise. |
| **Preserving** | Pony | Source has typed capabilities. Attenuator maps source capabilities to target capabilities. |
| **Additive** | Rust | Source already has ownership guarantees. Runtime adds additional isolation (fuel, memory bounds). |

# Architecture

## Component Overview

    ┌────────────────────────────────────────────────────────────────────┐
    │                           Public API                               │
    │                         Munition.fire/4                            │
    └─────────────────────────────────┬──────────────────────────────────┘
                                      │
    ┌─────────────────────────────────▼──────────────────────────────────┐
    │                       Instance Manager                             │
    │                   Munition.Instance.Manager                        │
    │                                                                    │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │
    │  │   Compile    │→ │ Instantiate  │→ │       Execute            │ │
    │  └──────────────┘  └──────────────┘  └──────────────────────────┘ │
    │          │                │                      │                 │
    │          ▼                ▼                      ▼                 │
    │  ┌──────────────────────────────────────────────────────────────┐ │
    │  │                    Forensic Capture                          │ │
    │  │                 (on any failure path)                        │ │
    │  └──────────────────────────────────────────────────────────────┘ │
    └─────────────────────────────────┬──────────────────────────────────┘
                                      │
    ┌─────────────────────────────────▼──────────────────────────────────┐
    │                      Runtime Behaviour                             │
    │                     Munition.Runtime                               │
    │                                                                    │
    │  ┌────────────────────┐  ┌────────────────────┐                   │
    │  │  Wasmex (default)  │  │  (future runtimes) │                   │
    │  │   via Wasmtime     │  │                    │                   │
    │  └────────────────────┘  └────────────────────┘                   │
    └────────────────────────────────────────────────────────────────────┘

## Module Structure

| Module | Responsibility |
|----|----|
| `lib/munition.ex` | Public API: `fire/4`, `fire_pooled/4`, `validate/2` |
| `lib/munition/instance/manager.ex` | Lifecycle orchestration: compile → instantiate → execute → capture → cleanup |
| `lib/munition/instance/state.ex` | Instance lifecycle state tracking |
| `lib/munition/runtime/behaviour.ex` | Pluggable WASM engine interface |
| `lib/munition/runtime/wasmex.ex` | Wasmtime implementation via Wasmex |
| `lib/munition/forensics/dump.ex` | Structured crash dump format with MNTN serialization |
| `lib/munition/forensics/capture.ex` | Atomic state capture on failure |
| `lib/munition/forensics/analyser.ex` | Memory introspection and pattern searching |
| `lib/munition/fuel/policy.ex` | Default fuel allocations and complexity calculation |
| `lib/munition/fuel/meter.ex` | Consumption tracking and statistics |
| `lib/munition/host/functions.ex` | Host function registry with capability gating |
| `lib/munition/host/capabilities.ex` | Capability definitions and validation |

# Quick Start

## Installation

```elixir
# Add to mix.exs
{:munition, "~> 0.1.0"}
```

## Basic Usage

```elixir
wasm = File.read!("plugin.wasm")

case Munition.fire(wasm, "process", [input], fuel: 100_000) do
  {:ok, result, metadata} ->
    IO.puts("Result: #{inspect(result)}")
    IO.puts("Fuel remaining: #{metadata.fuel_remaining}")

  {:crash, :fuel_exhausted, forensics} ->
    IO.puts("Execution exceeded fuel limit")
    IO.puts(Munition.Forensics.Dump.summary(forensics))

  {:crash, :trap, forensics} ->
    IO.puts("WASM trap occurred")
    analyser = Munition.Forensics.Analyser.new(forensics)
    IO.puts(Munition.Forensics.Analyser.hex_dump(analyser, 0, 256))
end
```

## Features in Action

### Fuel Metering (Guaranteed Termination)

```elixir
# This will ALWAYS terminate - no infinite loops possible
{:crash, :fuel_exhausted, _} =
  Munition.fire(wasm, "infinite_loop", [], fuel: 1_000)
```

### Memory Isolation

```elixir
# Execution A writes to memory
Munition.fire(wasm, "write_data", [pattern])

# Execution B cannot see it - fresh memory every time
{:ok, [0], _} = Munition.fire(wasm, "read_data", [0])
```

### Forensic Capture

```elixir
{:crash, reason, forensics} = Munition.fire(wasm, "buggy_function", [])

# Serialize for offline analysis
binary = Munition.Forensics.Dump.serialize(forensics)
File.write!("crash_dump.mntn", binary)

# Extract insights
analyser = Munition.Forensics.Analyser.new(forensics)
strings = Munition.Forensics.Analyser.extract_strings(analyser)
```

# Formal Specification

Munition includes a formal TLA+ specification proving capability safety,
termination, and forensic capture guarantees. See [Capability
Model](docs/capability_model.md) for:

- Formal definitions (Source Language, Target Runtime, Attenuator)

- Soundness and Completeness properties

- Forensic Capture specification

- Full TLA+ model

- Soundness proof sketch

## Security Guarantees

| Property | Guarantee |
|----|----|
| **Termination** | Fuel exhaustion guarantees all executions terminate |
| **Memory Safety** | WASM linear memory is bounds-checked |
| **Isolation** | No shared state between executions |
| **Capability Restriction** | Only explicitly granted capabilities are accessible |
| **Forensic Preservation** | All failures are captured atomically for audit |

## Non-Guarantees

- Execution time is bounded but not constant (timing side-channels
  possible)

- CPU cache timing attacks remain possible

- Memory allocation before instantiation may exhaust host resources

- Custom host functions must be implemented securely

# Development

## Prerequisites

- Elixir 1.14+

- Rust (for building test WASM modules)

- [just](https://github.com/casey/just) (task runner)

## Setup

```bash
git clone https://github.com/hyperpolymath/chimichanga
cd chimichanga

# Full setup (deps + WASM)
just setup

# Or manually:
mix deps.get
cd test_wasm && cargo build --target wasm32-unknown-unknown --release
mkdir -p test/fixtures
cp test_wasm/target/wasm32-unknown-unknown/release/munition_test_wasm.wasm test/fixtures/test.wasm
```

## Testing

```bash
just test              # All tests
just test-unit         # Unit tests only (no WASM required)
just test-integration  # Integration tests only
just test-coverage     # With coverage report
```

## Code Quality

```bash
just check             # Run all checks (fmt, lint, dialyzer)
just lint              # Credo analysis
just dialyzer          # Type checking
just validate          # Full RSR Gold validation
```

# Project Statistics

| Metric           | Value                           |
|------------------|---------------------------------|
| Elixir Source    | ~1,955 lines (14 modules)       |
| Test Suite       | ~380 lines (unit + integration) |
| Test WASM (Rust) | ~286 lines                      |
| Documentation    | 40+ KB across 14 files          |
| Version          | 0.1.0 (pre-release)             |
| RSR Compliance   | Gold                            |

# Documentation

- [Architecture](ARCHITECTURE.md) - System design and execution flows

- [Capability Model](docs/capability_model.md) - Formal specification
  and proofs

- [Contributing](CONTRIBUTING.adoc) - Tri-Perimeter Contribution
  Framework

- [Governance](GOVERNANCE.adoc) - Decision-making model

- [Security](SECURITY.md) - Vulnerability reporting policy

- [Reversibility](REVERSIBILITY.md) - Safe operations commitment

- [Roadmap](ROADMAP.adoc) - Future development plans

# License

Dual-licensed under MIT OR MPL-2.0.

See <a href="LICENSE.txt" class="txt">LICENSE</a> for details.

# Maintainers

See <a href="MAINTAINERS.md" class="md">MAINTAINERS</a> for the current
maintainer list.

------------------------------------------------------------------------

*Maintained by [Hyperpolymath](https://github.com/hyperpolymath)*

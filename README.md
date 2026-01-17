# Munition

A capability attenuation framework for sandboxed WASM execution in Elixir.

## Overview

Munition provides a framework for running untrusted code in isolated WASM sandboxes with:

- **Bounded Execution**: Fuel-metered computation that guarantees termination
- **Memory Isolation**: Each execution gets fresh, isolated memory
- **Forensic Capture**: Crash state is captured for analysis

## The Capability Attenuation Model

Munition implements a general model for capability attenuation:

```
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
```

Different source languages require different attenuator strategies:

- **Restrictive** (PHP, JavaScript): Source has implicit universal capabilities. Attenuator removes/intercepts all capability exercise.
- **Preserving** (Pony): Source has typed capabilities. Attenuator maps source capabilities to target capabilities.
- **Additive** (Rust): Source already has ownership guarantees. Runtime adds additional isolation.

## Quick Start

```elixir
# Add to mix.exs
{:munition, "~> 0.1.0"}

# Execute WASM code with safety guarantees
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
    # Analyse the memory dump
    analyser = Munition.Forensics.Analyser.new(forensics)
    IO.puts(Munition.Forensics.Analyser.hex_dump(analyser, 0, 256))
end
```

## Features

### Fuel Metering

Every WASM instruction consumes fuel. When fuel is exhausted, execution halts deterministically:

```elixir
# This will always terminate
{:crash, :fuel_exhausted, _} =
  Munition.fire(wasm, "infinite_loop", [], fuel: 1_000)
```

### Memory Isolation

Each execution gets completely fresh memory. State never leaks between executions:

```elixir
# Execution A writes to memory
Munition.fire(wasm, "write_data", [pattern])

# Execution B cannot see it
{:ok, [0], _} = Munition.fire(wasm, "read_data", [0])
```

### Forensic Capture

When execution fails, the complete memory state is captured:

```elixir
{:crash, reason, forensics} = Munition.fire(wasm, "buggy_function", [])

# Serialize for later analysis
binary = Munition.Forensics.Dump.serialize(forensics)
File.write!("crash_dump.mntn", binary)

# Analyse
analyser = Munition.Forensics.Analyser.new(forensics)
strings = Munition.Forensics.Analyser.extract_strings(analyser)
```

## Development

### Prerequisites

- Elixir 1.14+
- Rust (for building test WASM modules)
- [just](https://github.com/casey/just) (optional, for convenience commands)

### Setup

```bash
# Clone and setup
git clone https://github.com/hyperpolymath/chimichanga
cd chimichanga

# Install dependencies and build test WASM
just setup

# Or manually:
mix deps.get
cd test_wasm && cargo build --target wasm32-unknown-unknown --release
mkdir -p test/fixtures
cp test_wasm/target/wasm32-unknown-unknown/release/munition_test_wasm.wasm test/fixtures/test.wasm
```

### Running Tests

```bash
# All tests (requires WASM)
just test

# Unit tests only (no WASM required)
just test-unit

# Integration tests only
just test-integration
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed design documentation.

See [docs/capability_model.md](docs/capability_model.md) for the formal capability attenuation model.

## License

MIT

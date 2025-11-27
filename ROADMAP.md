# Roadmap

This document outlines the development roadmap for Munition.

## Vision

Munition aims to be the definitive capability attenuation framework for
running untrusted code safely. The core insight—that capability restriction
through compilation is a general pattern—enables safe execution of code
from any source language.

## Current Status: v0.1.0 (Alpha)

- [x] Core execution engine
- [x] Fuel metering
- [x] Memory isolation
- [x] Forensic capture
- [x] Formal capability model
- [x] RSR compliance

## Short Term: v0.2.0

### Instance Pooling

Pre-compile and cache modules for faster startup:

```elixir
Munition.Pool.start_link(:my_plugin, wasm_bytes, size: 10)
Munition.fire_pooled(:my_plugin, "process", [data])
```

### Enhanced Host Functions

Expand capability-gated host functions:

- [ ] Controlled filesystem access (read-only sandboxed paths)
- [ ] HTTP client (allowlisted domains)
- [ ] Structured logging with context

### Improved Forensics

- [ ] Stack trace extraction
- [ ] Variable state reconstruction
- [ ] Automated crash classification

## Medium Term: v0.3.0

### Wizer Integration

Use Wizer for snapshot-and-restore:

- Pre-initialize instances to skip startup
- Snapshot known-good states
- Fast recovery from snapshots

### Memory Limits

Configurable memory bounds:

```elixir
Munition.fire(wasm, "func", [],
  fuel: 100_000,
  memory_pages: 16  # 1MB limit
)
```

### Timeout Integration

Wall-clock timeout in addition to fuel:

```elixir
Munition.fire(wasm, "func", [],
  fuel: 1_000_000,
  timeout: 5_000  # 5 second hard limit
)
```

## Long Term: v1.0.0

### Production Ready

- [ ] Comprehensive security audit
- [ ] Performance optimization
- [ ] API stability guarantee
- [ ] Long-term support commitment

### Alternative Runtimes

- [ ] Wasmer backend option
- [ ] WAMR for embedded/constrained
- [ ] Native Lunatic integration

### Attenuator Ecosystem

Reference implementations for source languages:

- [ ] Lua attenuator (restrictive)
- [ ] JavaScript subset (AssemblyScript)
- [ ] Pony capability mapping (preserving)

## Research Directions

### Capability Inference

Automatically infer minimum required capabilities:

```elixir
{:ok, caps} = Munition.infer_capabilities(wasm)
# => [:time, :random]
```

### Graduated Trust

Dynamic capability expansion based on behavior:

```elixir
Munition.fire(wasm, "func", [],
  trust_policy: :graduated,
  initial_capabilities: [:time],
  expandable_to: [:filesystem_read]
)
```

### Formal Verification

- TLA+ model checking for core properties
- Coq proofs for capability soundness
- Property-based testing integration

## End-of-Life Planning

### Deprecation Policy

- Features deprecated with one minor version notice
- Deprecated features removed in next major version
- Security fixes backported for one year

### Archive Strategy

If project becomes unmaintained:

1. Clear notice in README
2. Archive repository (read-only)
3. Point to active forks if any
4. Preserve documentation

### Data Export

Users can always:

- Export WASM modules (portable standard)
- Export forensic dumps (documented format)
- Fork and continue development (MIT license)

## Contributing

See [CONTRIBUTING.adoc](CONTRIBUTING.adoc) for how to contribute to
this roadmap. Feature requests welcome via issues.

## Contact

- Feature requests: Open an issue
- Roadmap discussions: maintainers@hyperpolymath.dev

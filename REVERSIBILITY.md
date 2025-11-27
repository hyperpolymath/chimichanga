# Reversibility

This document describes Munition's commitment to reversible operations
and safe experimentation.

## Principle

> Every operation should be reversible. Destructive actions require
> explicit confirmation. The system should support safe experimentation.

## Design Decisions

### 1. No Mutable Global State

Munition uses isolated execution:

```elixir
# Each execution is independent
Munition.fire(wasm, "func", [args])  # Fresh instance
Munition.fire(wasm, "func", [args])  # Another fresh instance
```

No execution can affect another. There is no global state to corrupt.

### 2. Forensic Capture on Failure

Failed executions are preserved, not lost:

```elixir
{:crash, reason, forensics} = Munition.fire(wasm, "buggy", [])

# The forensics dump contains complete state at failure
# Nothing is lost, everything can be analysed
```

### 3. Fuel Bounds Prevent Runaway

Operations cannot run forever:

```elixir
# This will terminate, guaranteed
Munition.fire(wasm, "infinite_loop", [], fuel: 1000)
```

### 4. Serializable State

Forensic dumps can be serialized and restored:

```elixir
# Save for later analysis
binary = Munition.Forensics.Dump.serialize(forensics)
File.write!("crash.mntn", binary)

# Restore and analyse
{:ok, restored} = Munition.Forensics.Dump.deserialize(File.read!("crash.mntn"))
```

## Operational Reversibility

### Git History

All changes are version controlled. Use RVC (Robot Vacuum Cleaner)
for automated tidying that preserves history.

### Dependency Pinning

Dependencies are pinned to exact versions:

```elixir
# mix.exs - no floating versions
{:wasmex, "0.9.0"}  # Not "~> 0.9" or "^0.9"
```

This ensures builds are reproducible and reversible.

### Configuration as Code

All configuration is in version-controlled files:

- `config/*.exs` - Elixir configuration
- `flake.nix` - Nix environment
- `Justfile` - Task automation

No hidden state or manual configuration steps.

## User Guidelines

### Safe Experimentation

1. **Use fuel limits**: Always set reasonable fuel bounds
2. **Capture failures**: Save forensic dumps for analysis
3. **Version control**: Commit before major changes
4. **Test in isolation**: Use separate instances for testing

### Destructive Operations

Munition has no destructive operations by default. The runtime:

- Cannot modify the host filesystem
- Cannot access the network
- Cannot affect other processes
- Cannot persist state between executions

### Recovery Procedures

If something goes wrong:

1. **Execution hung**: Fuel will eventually exhaust
2. **Memory issue**: Each execution is isolated
3. **Bad WASM**: Compilation fails safely
4. **Trap occurred**: Forensics captured, nothing corrupted

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
- [docs/capability_model.md](docs/capability_model.md) - Formal model

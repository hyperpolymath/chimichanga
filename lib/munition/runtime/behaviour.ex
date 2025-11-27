# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Runtime do
  @moduledoc """
  Behaviour for pluggable WASM runtimes.

  This abstraction allows swapping the underlying WASM runtime implementation
  without changing the supervision and forensic capture logic. The default
  implementation uses Wasmex (Wasmtime bindings), but alternative runtimes
  could be plugged in for:

  - **Native Lunatic integration**: If running under Lunatic, use its
    native WASM support instead of spawning Wasmtime
  - **Testing**: Mock runtime for unit testing supervision logic
  - **Alternative engines**: Wasmer, WAMR, or other WASM runtimes

  ## Implementation Requirements

  Implementations must:

  1. Support fuel-bounded execution
  2. Provide memory capture at any point (including after traps)
  3. Handle compilation and instantiation separately
  4. Report fuel consumption accurately

  ## Example Implementation

      defmodule MyRuntime do
        @behaviour Munition.Runtime

        @impl true
        def compile(wasm_bytes, opts) do
          # Return compiled module reference
        end

        @impl true
        def instantiate(module_ref, imports) do
          # Return instance + store
        end

        # ... other callbacks
      end

  """

  @type instance :: term()
  @type store :: term()
  @type module_ref :: term()

  @type compile_opts :: %{
          optional(:fuel) => non_neg_integer()
        }

  @type call_result ::
          {:ok, term()}
          | {:error, :fuel_exhausted}
          | {:error, :trap, term()}
          | {:error, term()}

  @doc """
  Compile WASM bytes into a module reference.

  The module reference can be used to create multiple instances.
  This step should validate the WASM binary and prepare it for
  fast instantiation.

  ## Parameters

  - `wasm_bytes` - Raw WASM binary
  - `opts` - Compilation options including fuel configuration

  ## Returns

  - `{:ok, module_ref}` - Compiled module reference
  - `{:error, reason}` - Compilation failed

  """
  @callback compile(wasm_bytes :: binary(), opts :: compile_opts()) ::
              {:ok, module_ref()} | {:error, term()}

  @doc """
  Create an instance from a compiled module.

  Each instance has its own linear memory and global state.
  The imports map provides host functions the module can call.

  ## Parameters

  - `module_ref` - Previously compiled module
  - `imports` - Map of import namespace -> function implementations

  ## Returns

  - `{:ok, instance, store}` - Fresh instance and its store
  - `{:error, reason}` - Instantiation failed

  """
  @callback instantiate(module_ref(), imports :: map()) ::
              {:ok, instance(), store()} | {:error, term()}

  @doc """
  Call an exported function on an instance.

  Execution is fuel-bounded. The call will return when:
  - The function returns normally
  - Fuel is exhausted
  - A trap occurs (division by zero, unreachable, out of bounds, etc.)

  ## Parameters

  - `instance` - WASM instance
  - `function` - Name of exported function
  - `args` - Arguments to pass

  ## Returns

  - `{:ok, result}` - Function returned successfully
  - `{:error, :fuel_exhausted}` - Ran out of fuel
  - `{:error, :trap, details}` - WASM trap occurred
  - `{:error, reason}` - Other error

  """
  @callback call(instance(), function :: atom() | String.t(), args :: list()) :: call_result()

  @doc """
  Get remaining fuel in the store.

  Called after execution to determine how much fuel was consumed.

  """
  @callback get_fuel_remaining(store()) :: non_neg_integer()

  @doc """
  Capture the current state of instance memory.

  This should work even after a trap. The returned binary is
  a snapshot of linear memory that can be used for forensic analysis.

  ## Parameters

  - `instance` - WASM instance (may be in trapped state)

  ## Returns

  Binary snapshot of linear memory, or empty binary if capture fails.

  """
  @callback capture_memory(instance()) :: binary()

  @doc """
  Clean up instance resources.

  Called when the instance is no longer needed. Implementations should
  release any native resources.

  """
  @callback cleanup(instance()) :: :ok
end

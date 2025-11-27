# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Instance.Manager do
  @moduledoc """
  Manages munition lifecycle: compile, instantiate, execute, capture, cleanup.

  The Manager is responsible for the complete lifecycle of a WASM execution:

  1. **Compile**: Transform WASM bytes into an executable module
  2. **Instantiate**: Create a fresh instance with isolated memory
  3. **Execute**: Run the target function with fuel bounds
  4. **Capture**: On failure, capture forensic state
  5. **Cleanup**: Release resources

  ## Isolation Guarantees

  Each call to `execute/4` creates a completely fresh WASM instance.
  There is no state sharing between executions:

  - Memory is zero-initialized
  - Globals are reset to initial values
  - Fuel is fresh allocation

  ## Error Handling

  The Manager distinguishes between:

  - **Compilation errors**: Invalid WASM, unsupported features
  - **Instantiation errors**: Missing imports, memory limits
  - **Execution errors**: Fuel exhaustion, traps, timeouts

  All errors result in forensic capture where possible.

  """

  alias Munition.Runtime
  alias Munition.Forensics.{Capture, Dump}
  alias Munition.Host.Functions

  @runtime Application.compile_env(:munition, :runtime, Munition.Runtime.Wasmex)

  @type config :: %{
          fuel: non_neg_integer(),
          timeout: non_neg_integer(),
          capabilities: [Munition.capability()]
        }

  @doc """
  Execute a function in a WASM module.

  Creates a fresh instance, runs the function, and captures forensics
  on failure.

  ## Parameters

  - `wasm_bytes` - Compiled WASM binary
  - `function` - Exported function name
  - `args` - Arguments to pass
  - `config` - Execution configuration

  ## Returns

  - `{:ok, result, metadata}` - Success with result and metadata
  - `{:crash, reason, forensics}` - Failure with reason and dump

  """
  @spec execute(binary(), atom() | String.t(), list(), config()) :: Munition.fire_result()
  def execute(wasm_bytes, function, args, config) do
    start_time = System.monotonic_time(:microsecond)

    with {:ok, module_ref} <- @runtime.compile(wasm_bytes, %{fuel: config.fuel}),
         {:ok, instance, store} <- @runtime.instantiate(module_ref, build_imports(config)) do
      result = execute_with_capture(instance, store, function, args, config, start_time)
      @runtime.cleanup(instance)
      result
    else
      {:error, reason} ->
        elapsed = System.monotonic_time(:microsecond) - start_time

        forensics =
          Capture.capture_minimal(%{
            reason: {:compilation_failed, reason},
            function_called: to_string(function),
            args: args,
            fuel_allocated: config.fuel,
            execution_time_us: elapsed
          })

        {:crash, {:compilation_failed, reason}, forensics}
    end
  end

  @doc """
  Execute using a pre-warmed instance from a pool.

  Not yet implemented - returns error.
  """
  @spec execute_pooled(atom(), atom() | String.t(), list(), config()) :: Munition.fire_result()
  def execute_pooled(_pool_name, _function, _args, _config) do
    {:crash, :not_implemented,
     Capture.capture_minimal(%{
       reason: :not_implemented,
       function_called: "pooled_execution",
       args: [],
       fuel_allocated: 0,
       execution_time_us: 0
     })}
  end

  # Execute with forensic capture on failure
  defp execute_with_capture(instance, store, function, args, config, start_time) do
    case @runtime.call(instance, function, args) do
      {:ok, result} ->
        elapsed = System.monotonic_time(:microsecond) - start_time

        metadata = %{
          fuel_remaining: @runtime.get_fuel_remaining(store),
          execution_time_us: elapsed,
          memory_high_water: byte_size(@runtime.capture_memory(instance))
        }

        {:ok, result, metadata}

      {:error, :fuel_exhausted} ->
        elapsed = System.monotonic_time(:microsecond) - start_time

        forensics =
          Capture.capture(instance, store, %{
            reason: :fuel_exhausted,
            function_called: to_string(function),
            args: args,
            fuel_allocated: config.fuel,
            execution_time_us: elapsed
          })

        {:crash, :fuel_exhausted, forensics}

      {:error, :trap, details} ->
        elapsed = System.monotonic_time(:microsecond) - start_time

        forensics =
          Capture.capture(instance, store, %{
            reason: {:trap, details},
            function_called: to_string(function),
            args: args,
            fuel_allocated: config.fuel,
            execution_time_us: elapsed
          })

        {:crash, :trap, forensics}

      {:error, reason} ->
        elapsed = System.monotonic_time(:microsecond) - start_time

        forensics =
          Capture.capture(instance, store, %{
            reason: reason,
            function_called: to_string(function),
            args: args,
            fuel_allocated: config.fuel,
            execution_time_us: elapsed
          })

        {:crash, reason, forensics}
    end
  end

  # Build host function imports based on granted capabilities
  defp build_imports(config) do
    capabilities = Map.get(config, :capabilities, [])
    Functions.build(capabilities)
  end
end

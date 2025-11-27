# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Forensics.Capture do
  @moduledoc """
  Captures forensic state from crashed WASM instances.

  This module is responsible for extracting diagnostic information
  from a WASM instance after a failure occurs. The capture includes:

  - Linear memory snapshot
  - Fuel consumption data
  - Execution timing
  - Failure context

  ## Capture Timing

  Capture must happen immediately after failure detection, before:
  - The instance is cleaned up
  - Memory is deallocated
  - Any state is modified

  The capture process is designed to be fast and non-allocating where
  possible, to minimize impact on the failure state.

  """

  alias Munition.Forensics.Dump
  alias Munition.Runtime

  @runtime Application.compile_env(:munition, :runtime, Munition.Runtime.Wasmex)

  @doc """
  Capture forensic state from a crashed instance.

  ## Parameters

  - `instance` - The WASM instance (may be in trapped state)
  - `store` - The Wasmtime store containing fuel state
  - `context` - Execution context map containing:
    - `:reason` - Why execution failed
    - `:function_called` - Name of the function
    - `:args` - Arguments passed
    - `:fuel_allocated` - Initial fuel
    - `:execution_time_us` - Execution duration

  ## Returns

  A `Munition.Forensics.Dump` struct containing all captured state.

  """
  @spec capture(Runtime.instance(), Runtime.store(), map()) :: Dump.t()
  def capture(instance, store, context) do
    # Capture memory immediately - this is the critical state
    memory = @runtime.capture_memory(instance)

    # Get remaining fuel
    fuel_remaining = @runtime.get_fuel_remaining(store)

    # Build the dump
    Dump.new(%{
      reason: context.reason,
      memory: memory,
      fuel_remaining: fuel_remaining,
      fuel_allocated: context.fuel_allocated,
      function_called: context.function_called,
      args: context.args,
      execution_time_us: context.execution_time_us,
      stack_trace: context[:stack_trace]
    })
  end

  @doc """
  Capture minimal forensic data when full capture isn't possible.

  Used when the instance is not available (e.g., compilation failure)
  but we still want to record what happened.

  """
  @spec capture_minimal(map()) :: Dump.t()
  def capture_minimal(context) do
    Dump.new(%{
      reason: context.reason,
      memory: <<>>,
      fuel_remaining: 0,
      fuel_allocated: Map.get(context, :fuel_allocated, 0),
      function_called: Map.get(context, :function_called, "unknown"),
      args: Map.get(context, :args, []),
      execution_time_us: Map.get(context, :execution_time_us, 0)
    })
  end
end

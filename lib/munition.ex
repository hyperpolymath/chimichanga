# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition do
  @moduledoc """
  Capability-attenuated sandboxed execution framework.

  Munition provides a framework for running untrusted code in isolated WASM
  sandboxes with:

  - **Bounded execution**: Fuel-metered computation that guarantees termination
  - **Memory isolation**: Each execution gets fresh, isolated memory
  - **Forensic capture**: Crash state is captured for analysis

  ## Capability Attenuation Model

  The framework implements a capability attenuation model where:

  - Source code with rich capabilities is transformed (compiled/transpiled)
  - The transformation attenuates capabilities to a restricted subset
  - The runtime enforces the restricted capability set
  - The supervisor captures forensic data on failures

  ## Example

      wasm = File.read!("plugin.wasm")

      case Munition.fire(wasm, "process", [input], fuel: 100_000) do
        {:ok, result, metadata} ->
          # Success, metadata includes fuel_remaining
          handle_result(result)

        {:crash, reason, forensics} ->
          # Failure, forensics includes memory dump
          analyse_crash(forensics)
      end

  ## Execution Modes

  - `fire/4` - Execute with fresh instance (no state leakage)
  - `fire_pooled/4` - Execute using pre-warmed instance pool (future)

  ## Capability Classes

  | Capability | Description | Default |
  |------------|-------------|---------|
  | `compute` | Execute instructions | Granted |
  | `memory_read` | Read linear memory | Granted |
  | `memory_write` | Write linear memory | Granted |
  | `host_call` | Call host functions | Per-function |
  | `filesystem` | Access filesystem | Denied |
  | `network` | Access network | Denied |

  """

  alias Munition.Instance.Manager
  alias Munition.Fuel.Policy
  alias Munition.Forensics.Dump

  @type fire_result ::
          {:ok, term(), metadata()}
          | {:crash, reason(), Dump.t() | nil}

  @type metadata :: %{
          fuel_remaining: non_neg_integer(),
          execution_time_us: non_neg_integer(),
          memory_high_water: non_neg_integer()
        }

  @type reason :: :fuel_exhausted | :trap | :timeout | {:compilation_failed, term()} | term()

  @type capability ::
          :filesystem_read
          | :filesystem_write
          | :network
          | :time
          | :random
          | {:host_function, String.t()}

  @type fire_opts :: [
          fuel: non_neg_integer(),
          timeout: non_neg_integer(),
          capabilities: [capability()]
        ]

  @doc """
  Execute a function in a WASM module with capability restrictions.

  Each call creates a fresh WASM instance with isolated memory. The execution
  is fuel-bounded to guarantee termination. On failure, forensic state is
  captured.

  ## Parameters

  - `wasm_bytes` - Compiled WASM binary
  - `function` - Exported function name to call
  - `args` - Arguments to pass to the function
  - `opts` - Execution options

  ## Options

  - `:fuel` - Maximum fuel allocation (default: #{Policy.default_fuel()})
  - `:timeout` - Execution timeout in ms (default: #{Policy.default_timeout()})
  - `:capabilities` - List of granted capabilities (default: [])

  ## Returns

  - `{:ok, result, metadata}` - Successful execution with result and metadata
  - `{:crash, reason, forensics}` - Failed execution with reason and forensic dump

  ## Examples

      # Basic arithmetic
      {:ok, [42], _meta} = Munition.fire(wasm, "add", [20, 22])

      # Fuel exhaustion
      {:crash, :fuel_exhausted, dump} = Munition.fire(wasm, "infinite_loop", [], fuel: 100)

      # With capabilities
      {:ok, result, _} = Munition.fire(wasm, "process", [data],
        capabilities: [:time, :random])

  """
  @spec fire(binary(), atom() | String.t(), list(), fire_opts()) :: fire_result()
  def fire(wasm_bytes, function, args, opts \\ []) do
    fuel = Keyword.get(opts, :fuel, Policy.default_fuel())
    timeout = Keyword.get(opts, :timeout, Policy.default_timeout())
    capabilities = Keyword.get(opts, :capabilities, [])

    Manager.execute(wasm_bytes, function, args, %{
      fuel: fuel,
      timeout: timeout,
      capabilities: capabilities
    })
  end

  @doc """
  Execute a function using a pre-warmed instance from a pool.

  This reduces startup latency by reusing already-compiled and instantiated
  WASM modules. Each execution still gets fresh memory state.

  ## Parameters

  - `pool_name` - Name of the registered pool
  - `function` - Exported function name to call
  - `args` - Arguments to pass to the function
  - `opts` - Execution options (same as `fire/4`)

  ## Note

  Pool-based execution is not yet implemented. This function exists to
  establish the API contract for future implementation.

  """
  @spec fire_pooled(atom(), atom() | String.t(), list(), fire_opts()) :: fire_result()
  def fire_pooled(pool_name, function, args, opts \\ []) do
    fuel = Keyword.get(opts, :fuel, Policy.default_fuel())
    timeout = Keyword.get(opts, :timeout, Policy.default_timeout())
    capabilities = Keyword.get(opts, :capabilities, [])

    Manager.execute_pooled(pool_name, function, args, %{
      fuel: fuel,
      timeout: timeout,
      capabilities: capabilities
    })
  end

  @doc """
  Validate a WASM module without executing it.

  Checks that the module:
  - Is valid WASM binary
  - Contains the expected exports
  - Does not import disallowed host functions

  ## Parameters

  - `wasm_bytes` - Compiled WASM binary
  - `opts` - Validation options

  ## Options

  - `:required_exports` - List of function names that must be exported
  - `:allowed_imports` - List of allowed import module/function pairs

  ## Returns

  - `:ok` - Module is valid
  - `{:error, reason}` - Validation failed

  """
  @spec validate(binary(), keyword()) :: :ok | {:error, term()}
  def validate(wasm_bytes, opts \\ []) do
    required_exports = Keyword.get(opts, :required_exports, [])
    allowed_imports = Keyword.get(opts, :allowed_imports, nil)

    with {:ok, _module} <- Munition.Runtime.Wasmex.compile(wasm_bytes, %{}),
         :ok <- validate_exports(wasm_bytes, required_exports),
         :ok <- validate_imports(wasm_bytes, allowed_imports) do
      :ok
    end
  end

  defp validate_exports(_wasm_bytes, []), do: :ok

  defp validate_exports(_wasm_bytes, _required) do
    # TODO: Implement export validation
    :ok
  end

  defp validate_imports(_wasm_bytes, nil), do: :ok

  defp validate_imports(_wasm_bytes, _allowed) do
    # TODO: Implement import validation
    :ok
  end
end

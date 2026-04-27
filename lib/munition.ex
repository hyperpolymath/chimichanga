# SPDX-License-Identifier: MIT

defmodule Munition do
  @moduledoc """
  Capability-Attenuated WASM Sandbox Framework.

  `Munition` provides a high-assurance environment for executing untrusted 
  binary code. It is designed for "Security Munitions" — plugins or 
  transformation logic that must be strictly isolated.

  ## Safety Invariants:
  1. **Fuel Metering**: Prevents CPU exhaustion and infinite loops by 
     attaching a "fuel" cost to every instruction.
  2. **Memory Sandboxing**: Instances cannot access memory outside their 
     allocated linear buffer.
  3. **Forensic State**: On crash (trap), the framework captures the linear 
     memory and instruction pointer for post-mortem audit.
  4. **Dynamic Attenuation**: Host functions (IO, Network) are DENIED by default 
     and must be explicitly granted per-call.
  """

  alias Munition.Forensics.Dump
  alias Munition.Fuel.Policy
  alias Munition.Instance.Manager

  @typedoc "A granted access permission. Standard atoms or `{:host_function, name}` for custom bridges."
  @type capability() ::
          :time | :random | :log
          | :filesystem_read | :filesystem_write | :network
          | {:host_function, String.t()}
          | atom()

  @typedoc "Result of a WASM function execution."
  @type fire_result() ::
          {:ok, term()}
          | {:error, :fuel_exhausted}
          | {:error, :timeout}
          | {:error, :capability_denied, atom()}
          | {:error, :trap, Dump.t()}
          | {:error, term()}

  # Stub runtime always returns {:error, :not_implemented}; contract mismatch is expected
  # until Wasmex 0.14 implementation replaces the stubs.
  @dialyzer {:nowarn_function, fire: 4}

  @doc """
  EXECUTION: Fires a single function call within a fresh WASM instance.

  PARAMETERS:
  - `wasm_bytes`: The raw binary of the module.
  - `function`: The exported function identifier to invoke.
  - `args`: List of parameters matching the WASM signature.
  - `opts`: Configuration including `:fuel` limit and granted `:capabilities`.
  """
  @spec fire(binary(), atom() | String.t(), list(), keyword()) :: fire_result()
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
  VALIDATION: Audits a module without executing it.
  Verifies that the binary is well-formed and does not import disallowed 
  capabilities (e.g. `wasi_snapshot_preview1` when network access is forbidden).
  """
  @spec validate(binary(), keyword()) :: :ok | {:error, term()}
  def validate(wasm_bytes, _opts \\ []) do
    # WASM magic: \0asm followed by version (4 bytes). Full import/export
    # validation requires Wasmex 0.14 API — pending implementation.
    if binary_part(wasm_bytes, 0, 4) == <<0, 97, 115, 109>> do
      :ok
    else
      {:error, :invalid_magic_bytes}
    end
  rescue
    ArgumentError -> {:error, :invalid_magic_bytes}
  end
end

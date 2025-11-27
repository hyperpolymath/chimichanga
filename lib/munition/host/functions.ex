# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Host.Functions do
  @moduledoc """
  Host function registry for WASM imports.

  Host functions are functions implemented in Elixir that WASM code
  can call. They provide controlled access to capabilities that
  WASM cannot perform natively:

  - Time access
  - Random number generation
  - Logging/debugging
  - (Future) Controlled filesystem access
  - (Future) Controlled network access

  ## Capability Model

  Each host function is associated with a capability. WASM code can
  only call host functions for which capabilities have been granted:

      # Only time and random are available
      Munition.fire(wasm, "process", [data],
        capabilities: [:time, :random])

  ## Defining Host Functions

  Host functions must follow the WASM calling convention:

  - Parameters are primitive types (i32, i64, f32, f64)
  - Return values are primitive types or void
  - Memory access is via linear memory read/write

  """

  @type capability :: Munition.capability()

  @doc """
  Build import map based on granted capabilities.

  Returns a map suitable for passing to Wasmex instance creation.
  Only functions for granted capabilities are included.

  ## Parameters

  - `capabilities` - List of granted capabilities

  """
  @spec build([capability()]) :: map()
  def build(capabilities) do
    capabilities
    |> Enum.flat_map(&functions_for_capability/1)
    |> Map.new()
  end

  @doc """
  Get all available host functions.
  """
  @spec available() :: [{atom(), {String.t(), String.t()}}]
  def available do
    [
      {:time, {"env", "get_time_ms"}},
      {:random, {"env", "get_random_u32"}},
      {:random, {"env", "get_random_u64"}},
      {:log, {"env", "log_debug"}},
      {:log, {"env", "log_info"}},
      {:log, {"env", "log_warn"}},
      {:log, {"env", "log_error"}}
    ]
  end

  # Get functions for a specific capability
  defp functions_for_capability(:time) do
    [
      {"env", %{
        "get_time_ms" => {:fn, [], [:i64], &host_get_time_ms/1}
      }}
    ]
  end

  defp functions_for_capability(:random) do
    [
      {"env", %{
        "get_random_u32" => {:fn, [], [:i32], &host_get_random_u32/1},
        "get_random_u64" => {:fn, [], [:i64], &host_get_random_u64/1}
      }}
    ]
  end

  defp functions_for_capability(:log) do
    [
      {"env", %{
        "log_debug" => {:fn, [:i32, :i32], [], &host_log/1},
        "log_info" => {:fn, [:i32, :i32], [], &host_log/1},
        "log_warn" => {:fn, [:i32, :i32], [], &host_log/1},
        "log_error" => {:fn, [:i32, :i32], [], &host_log/1}
      }}
    ]
  end

  defp functions_for_capability({:host_function, name}) when is_binary(name) do
    # Custom host functions would be defined elsewhere
    []
  end

  defp functions_for_capability(_), do: []

  # Host function implementations

  defp host_get_time_ms(_context) do
    System.system_time(:millisecond)
  end

  defp host_get_random_u32(_context) do
    :rand.uniform(0xFFFFFFFF)
  end

  defp host_get_random_u64(_context) do
    :rand.uniform(0xFFFFFFFFFFFFFFFF)
  end

  defp host_log(_context) do
    # TODO: Implement memory read for log message
    # For now, just acknowledge the call
    :ok
  end
end

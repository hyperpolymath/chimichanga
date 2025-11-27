# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Runtime.Wasmex do
  @moduledoc """
  Wasmtime implementation of the Munition runtime behaviour.

  Uses Wasmex (Elixir bindings for Wasmtime) to provide:

  - Fuel-bounded execution
  - Memory isolation
  - Trap handling with memory capture

  ## Fuel Metering

  Wasmtime's fuel mechanism assigns a cost to each WASM instruction.
  When fuel is exhausted, execution halts and returns an error.
  This provides deterministic resource bounding.

  ## Memory Model

  Each instance gets its own linear memory. Memory is zero-initialized
  on instantiation and isolated from other instances.

  """

  @behaviour Munition.Runtime

  require Logger

  @impl true
  def compile(wasm_bytes, opts) do
    fuel = Map.get(opts, :fuel, 100_000)

    try do
      # Create store with fuel configuration
      {:ok, store} =
        Wasmex.Store.new_wasi(%Wasmex.Wasi.WasiOptions{
          args: [],
          env: %{}
        })

      # Configure fuel
      :ok = Wasmex.Store.set_fuel(store, fuel)

      # Compile the module
      case Wasmex.Module.compile(store, wasm_bytes) do
        {:ok, module} ->
          {:ok, {module, store, fuel}}

        {:error, reason} ->
          {:error, {:compilation_failed, reason}}
      end
    rescue
      e ->
        {:error, {:compilation_failed, Exception.message(e)}}
    end
  end

  @impl true
  def instantiate({module, store, _fuel}, imports) do
    # Convert imports to Wasmex format
    wasmex_imports = convert_imports(imports)

    case Wasmex.Instance.new(store, module, wasmex_imports) do
      {:ok, instance} ->
        {:ok, {instance, store}, store}

      {:error, reason} ->
        {:error, {:instantiation_failed, reason}}
    end
  end

  @impl true
  def call({instance, _store}, function, args) do
    function_name = to_string(function)

    try do
      case Wasmex.Instance.call_exported_function(instance, function_name, args) do
        {:ok, result} ->
          {:ok, result}

        {:error, msg} when is_binary(msg) ->
          cond do
            String.contains?(msg, "fuel") or String.contains?(msg, "Fuel") ->
              {:error, :fuel_exhausted}

            String.contains?(msg, "unreachable") ->
              {:error, :trap, {:unreachable, msg}}

            String.contains?(msg, "out of bounds") ->
              {:error, :trap, {:out_of_bounds, msg}}

            String.contains?(msg, "trap") or String.contains?(msg, "Trap") ->
              {:error, :trap, {:trap, msg}}

            true ->
              {:error, msg}
          end

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        message = Exception.message(e)

        cond do
          String.contains?(message, "fuel") ->
            {:error, :fuel_exhausted}

          String.contains?(message, "trap") ->
            {:error, :trap, {:trap, message}}

          true ->
            {:error, {:exception, message}}
        end
    end
  end

  @impl true
  def get_fuel_remaining(store) do
    case Wasmex.Store.get_fuel(store) do
      {:ok, fuel} -> fuel
      _ -> 0
    end
  end

  @impl true
  def capture_memory({instance, _store}) do
    try do
      case Wasmex.Instance.memory(instance, :uint8, 0) do
        {:ok, memory} ->
          # Get memory size and read all bytes
          size = Wasmex.Memory.size(memory)
          # Size is in pages (64KB each)
          byte_size = size * 65536

          if byte_size > 0 do
            Wasmex.Memory.read_binary(memory, 0, byte_size)
          else
            <<>>
          end

        {:error, _} ->
          # Try alternative memory access
          <<>>
      end
    rescue
      _ -> <<>>
    end
  end

  @impl true
  def cleanup(_instance) do
    # Wasmex handles cleanup via garbage collection
    # No explicit cleanup needed
    :ok
  end

  # Convert our capability-based imports to Wasmex format
  defp convert_imports(imports) when is_map(imports) do
    imports
  end

  defp convert_imports(_), do: %{}
end

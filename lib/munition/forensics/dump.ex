# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Forensics.Dump do
  @moduledoc """
  Structured forensic dump from a crashed munition.

  A dump captures the complete state of a WASM instance at the moment
  of failure. This includes:

  - **Memory snapshot**: Complete linear memory contents
  - **Execution context**: Function called, arguments, fuel state
  - **Timing data**: When the crash occurred, execution duration
  - **Failure reason**: Why execution terminated

  ## Serialization Format

  Dumps can be serialized to a binary format for storage and later analysis:

      dump = %Dump{...}
      binary = Dump.serialize(dump)
      {:ok, recovered} = Dump.deserialize(binary)

  The format is:

      ┌─────────────────────────────────────────┐
      │ Magic: "MNTN" (4 bytes)                 │
      │ Version: u16                            │
      │ Memory size: u64                        │
      │ Metadata length: u32                    │
      │ Metadata: Erlang term (variable)        │
      │ Compressed memory: zlib (variable)      │
      └─────────────────────────────────────────┘

  ## Analysis

  Use `Munition.Forensics.Analyser` to extract information from dumps:

      analyser = Analyser.new(dump)
      Analyser.find_pattern(analyser, <<0xDE, 0xAD, 0xBE, 0xEF>>)

  """

  @enforce_keys [:id, :timestamp, :reason]
  defstruct [
    :id,
    :timestamp,
    :reason,
    :memory,
    :fuel_remaining,
    :fuel_allocated,
    :function_called,
    :args_hash,
    :execution_time_us,
    :stack_trace
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          timestamp: DateTime.t(),
          reason: reason(),
          memory: binary(),
          fuel_remaining: non_neg_integer(),
          fuel_allocated: non_neg_integer(),
          function_called: String.t(),
          args_hash: binary(),
          execution_time_us: non_neg_integer(),
          stack_trace: list() | nil
        }

  @type reason ::
          :fuel_exhausted
          | {:trap, term()}
          | {:compilation_failed, term()}
          | term()

  @magic_bytes "MNTN"
  @current_version 1

  @doc """
  Create a new forensic dump from execution state.

  ## Parameters

  - `attrs` - Map containing:
    - `:reason` - Why execution failed
    - `:memory` - Linear memory snapshot
    - `:fuel_remaining` - Fuel at time of failure
    - `:fuel_allocated` - Initial fuel allocation
    - `:function_called` - Name of function that was called
    - `:args` - Arguments passed (will be hashed)
    - `:execution_time_us` - Execution duration in microseconds

  """
  @spec new(map()) :: t()
  def new(attrs) do
    %__MODULE__{
      id: generate_id(),
      timestamp: DateTime.utc_now(),
      reason: attrs.reason,
      memory: Map.get(attrs, :memory, <<>>),
      fuel_remaining: Map.get(attrs, :fuel_remaining, 0),
      fuel_allocated: Map.get(attrs, :fuel_allocated, 0),
      function_called: Map.get(attrs, :function_called, "unknown"),
      args_hash: hash_args(Map.get(attrs, :args, [])),
      execution_time_us: Map.get(attrs, :execution_time_us, 0),
      stack_trace: Map.get(attrs, :stack_trace)
    }
  end

  @doc """
  Serialize a dump to binary format for storage.

  The memory is compressed using zlib to reduce storage requirements.
  A typical 64KB memory page compresses to ~1-10KB depending on content.

  """
  @spec serialize(t()) :: binary()
  def serialize(%__MODULE__{} = dump) do
    # Prepare metadata (everything except memory)
    metadata =
      :erlang.term_to_binary(%{
        id: dump.id,
        timestamp: dump.timestamp,
        reason: dump.reason,
        fuel_remaining: dump.fuel_remaining,
        fuel_allocated: dump.fuel_allocated,
        function_called: dump.function_called,
        args_hash: dump.args_hash,
        execution_time_us: dump.execution_time_us,
        stack_trace: dump.stack_trace
      })

    # Compress memory
    compressed_memory =
      if byte_size(dump.memory) > 0 do
        :zlib.compress(dump.memory)
      else
        <<>>
      end

    memory_size = byte_size(dump.memory)
    metadata_size = byte_size(metadata)

    <<
      @magic_bytes::binary,
      @current_version::16,
      memory_size::64,
      metadata_size::32,
      metadata::binary,
      compressed_memory::binary
    >>
  end

  @doc """
  Deserialize a dump from binary format.

  Returns `{:ok, dump}` on success or `{:error, reason}` on failure.

  """
  @spec deserialize(binary()) :: {:ok, t()} | {:error, term()}
  def deserialize(<<@magic_bytes, version::16, memory_size::64, rest::binary>>) do
    if version > @current_version do
      {:error, {:unsupported_version, version}}
    else
      <<metadata_size::32, metadata_bin::binary-size(metadata_size), compressed::binary>> = rest

      metadata = :erlang.binary_to_term(metadata_bin, [:safe])

      memory =
        if memory_size > 0 and byte_size(compressed) > 0 do
          :zlib.uncompress(compressed)
        else
          <<>>
        end

      dump = %__MODULE__{
        id: metadata.id,
        timestamp: metadata.timestamp,
        reason: metadata.reason,
        memory: memory,
        fuel_remaining: metadata.fuel_remaining,
        fuel_allocated: metadata.fuel_allocated,
        function_called: metadata.function_called,
        args_hash: metadata.args_hash,
        execution_time_us: metadata.execution_time_us,
        stack_trace: metadata[:stack_trace]
      }

      {:ok, dump}
    end
  rescue
    e -> {:error, {:deserialization_failed, Exception.message(e)}}
  end

  def deserialize(_), do: {:error, :invalid_format}

  @doc """
  Get a summary of the dump suitable for logging.
  """
  @spec summary(t()) :: String.t()
  def summary(%__MODULE__{} = dump) do
    fuel_pct =
      if dump.fuel_allocated > 0 do
        remaining_pct = dump.fuel_remaining / dump.fuel_allocated * 100
        "#{Float.round(remaining_pct, 1)}% remaining"
      else
        "no fuel data"
      end

    memory_kb = Float.round(byte_size(dump.memory) / 1024, 1)

    "Dump[#{dump.id}] #{dump.function_called} -> #{inspect(dump.reason)} " <>
      "(#{dump.execution_time_us}µs, #{fuel_pct}, #{memory_kb}KB memory)"
  end

  # Generate a unique dump ID
  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  # Hash arguments for later correlation without storing raw data
  defp hash_args(args) do
    :crypto.hash(:sha256, :erlang.term_to_binary(args))
  end
end

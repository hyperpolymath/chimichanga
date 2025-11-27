# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Forensics.Analyser do
  @moduledoc """
  Analysis utilities for forensic memory dumps.

  Provides tools to extract information from captured memory snapshots:

  - Pattern searching
  - String extraction
  - Memory region analysis
  - State reconstruction

  ## Example

      dump = get_crash_dump()
      analyser = Analyser.new(dump)

      # Find a specific pattern
      offsets = Analyser.find_pattern(analyser, <<0xDE, 0xAD, 0xBE, 0xEF>>)

      # Extract strings
      strings = Analyser.extract_strings(analyser, min_length: 4)

      # Read a value at known offset
      {:ok, value} = Analyser.read_i32(analyser, 0x100)

  """

  alias Munition.Forensics.Dump

  defstruct [:dump, :memory_size]

  @type t :: %__MODULE__{
          dump: Dump.t(),
          memory_size: non_neg_integer()
        }

  @doc """
  Create an analyser for a dump.
  """
  @spec new(Dump.t()) :: t()
  def new(%Dump{} = dump) do
    %__MODULE__{
      dump: dump,
      memory_size: byte_size(dump.memory)
    }
  end

  @doc """
  Find all occurrences of a byte pattern in memory.

  Returns a list of offsets where the pattern was found.
  """
  @spec find_pattern(t(), binary()) :: [non_neg_integer()]
  def find_pattern(%__MODULE__{dump: dump}, pattern) when is_binary(pattern) do
    find_pattern_recursive(dump.memory, pattern, 0, [])
    |> Enum.reverse()
  end

  defp find_pattern_recursive(<<>>, _pattern, _offset, acc), do: acc

  defp find_pattern_recursive(memory, pattern, offset, acc) do
    pattern_size = byte_size(pattern)

    case memory do
      <<^pattern::binary-size(pattern_size), rest::binary>> ->
        # Found a match
        find_pattern_recursive(
          <<0, rest::binary>>,
          pattern,
          offset + 1,
          [offset | acc]
        )

      <<_, rest::binary>> ->
        find_pattern_recursive(rest, pattern, offset + 1, acc)
    end
  end

  @doc """
  Extract printable ASCII strings from memory.

  ## Options

  - `:min_length` - Minimum string length (default: 4)
  - `:max_length` - Maximum string length (default: 256)

  """
  @spec extract_strings(t(), keyword()) :: [{non_neg_integer(), String.t()}]
  def extract_strings(%__MODULE__{dump: dump}, opts \\ []) do
    min_length = Keyword.get(opts, :min_length, 4)
    max_length = Keyword.get(opts, :max_length, 256)

    extract_strings_recursive(dump.memory, 0, [], min_length, max_length)
    |> Enum.reverse()
  end

  defp extract_strings_recursive(<<>>, _offset, acc, _min, _max), do: acc

  defp extract_strings_recursive(memory, offset, acc, min_length, max_length) do
    case extract_one_string(memory, max_length) do
      {str, rest} when byte_size(str) >= min_length ->
        extract_strings_recursive(rest, offset + byte_size(str), [{offset, str} | acc], min_length, max_length)

      {str, rest} ->
        extract_strings_recursive(rest, offset + max(byte_size(str), 1), acc, min_length, max_length)
    end
  end

  defp extract_one_string(memory, max_length) do
    extract_printable(memory, <<>>, max_length)
  end

  defp extract_printable(<<>>, acc, _max), do: {acc, <<>>}
  defp extract_printable(rest, acc, 0), do: {acc, rest}

  defp extract_printable(<<byte, rest::binary>>, acc, remaining) when byte >= 32 and byte < 127 do
    extract_printable(rest, <<acc::binary, byte>>, remaining - 1)
  end

  defp extract_printable(<<_, rest::binary>>, acc, _remaining), do: {acc, rest}

  @doc """
  Read a 32-bit signed integer at the given offset.
  """
  @spec read_i32(t(), non_neg_integer()) :: {:ok, integer()} | {:error, :out_of_bounds}
  def read_i32(%__MODULE__{dump: dump, memory_size: size}, offset)
      when offset >= 0 and offset + 4 <= size do
    <<_::binary-size(offset), value::little-signed-32, _::binary>> = dump.memory
    {:ok, value}
  end

  def read_i32(_, _), do: {:error, :out_of_bounds}

  @doc """
  Read a 64-bit signed integer at the given offset.
  """
  @spec read_i64(t(), non_neg_integer()) :: {:ok, integer()} | {:error, :out_of_bounds}
  def read_i64(%__MODULE__{dump: dump, memory_size: size}, offset)
      when offset >= 0 and offset + 8 <= size do
    <<_::binary-size(offset), value::little-signed-64, _::binary>> = dump.memory
    {:ok, value}
  end

  def read_i64(_, _), do: {:error, :out_of_bounds}

  @doc """
  Read a slice of memory.
  """
  @spec read_bytes(t(), non_neg_integer(), non_neg_integer()) ::
          {:ok, binary()} | {:error, :out_of_bounds}
  def read_bytes(%__MODULE__{dump: dump, memory_size: size}, offset, length)
      when offset >= 0 and offset + length <= size do
    <<_::binary-size(offset), bytes::binary-size(length), _::binary>> = dump.memory
    {:ok, bytes}
  end

  def read_bytes(_, _, _), do: {:error, :out_of_bounds}

  @doc """
  Get a hex dump of a memory region.
  """
  @spec hex_dump(t(), non_neg_integer(), non_neg_integer()) :: String.t()
  def hex_dump(%__MODULE__{} = analyser, offset, length) do
    case read_bytes(analyser, offset, length) do
      {:ok, bytes} ->
        format_hex_dump(bytes, offset)

      {:error, :out_of_bounds} ->
        "Error: offset #{offset} + length #{length} out of bounds"
    end
  end

  defp format_hex_dump(bytes, start_offset) do
    bytes
    |> :binary.bin_to_list()
    |> Enum.chunk_every(16)
    |> Enum.with_index()
    |> Enum.map(fn {chunk, line} ->
      offset = start_offset + line * 16
      hex = chunk |> Enum.map(&String.pad_leading(Integer.to_string(&1, 16), 2, "0")) |> Enum.join(" ")
      ascii = chunk |> Enum.map(fn b -> if b >= 32 and b < 127, do: <<b>>, else: "." end) |> Enum.join()
      String.pad_leading(Integer.to_string(offset, 16), 8, "0") <> "  " <> String.pad_trailing(hex, 48) <> "  " <> ascii
    end)
    |> Enum.join("\n")
  end

  @doc """
  Get memory statistics.
  """
  @spec stats(t()) :: map()
  def stats(%__MODULE__{dump: dump, memory_size: size}) do
    bytes = :binary.bin_to_list(dump.memory)
    zero_count = Enum.count(bytes, &(&1 == 0))
    non_zero_count = size - zero_count

    %{
      size_bytes: size,
      size_pages: div(size, 65536),
      zero_bytes: zero_count,
      non_zero_bytes: non_zero_count,
      utilization: if(size > 0, do: non_zero_count / size, else: 0.0)
    }
  end
end

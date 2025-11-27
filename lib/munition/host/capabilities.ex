# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Host.Capabilities do
  @moduledoc """
  Capability definitions and validation.

  Capabilities define what operations WASM code is permitted to perform.
  The capability model follows the principle of least privilege:

  - No capabilities by default
  - Capabilities must be explicitly granted
  - Capabilities cannot be escalated at runtime

  ## Capability Hierarchy

  Some capabilities imply others:

      :filesystem_read_write implies :filesystem_read
      :network implies :network_connect, :network_listen

  ## Standard Capabilities

  | Capability | Description | Risk |
  |------------|-------------|------|
  | `:time` | Access system time | Low |
  | `:random` | Access entropy | Low |
  | `:log` | Write to log output | Low |
  | `:filesystem_read` | Read files | Medium |
  | `:filesystem_write` | Write files | High |
  | `:network` | Network access | High |

  """

  @type capability :: Munition.capability()

  @standard_capabilities [
    :time,
    :random,
    :log,
    :filesystem_read,
    :filesystem_write,
    :network
  ]

  @doc """
  List all standard capabilities.
  """
  @spec standard() :: [atom()]
  def standard, do: @standard_capabilities

  @doc """
  Check if a capability is valid.
  """
  @spec valid?(term()) :: boolean()
  def valid?(cap) when cap in @standard_capabilities, do: true
  def valid?({:host_function, name}) when is_binary(name), do: true
  def valid?(_), do: false

  @doc """
  Expand implied capabilities.

  For example, `:filesystem_write` implies `:filesystem_read`.

  """
  @spec expand([capability()]) :: [capability()]
  def expand(capabilities) do
    capabilities
    |> Enum.flat_map(&expand_one/1)
    |> Enum.uniq()
  end

  defp expand_one(:filesystem_write), do: [:filesystem_write, :filesystem_read]
  defp expand_one(:network), do: [:network]
  defp expand_one(cap), do: [cap]

  @doc """
  Validate a list of requested capabilities.

  Returns `:ok` if all capabilities are valid, or `{:error, invalid}`
  with the list of invalid capabilities.

  """
  @spec validate([capability()]) :: :ok | {:error, [term()]}
  def validate(capabilities) do
    invalid = Enum.reject(capabilities, &valid?/1)

    if Enum.empty?(invalid) do
      :ok
    else
      {:error, invalid}
    end
  end

  @doc """
  Check if a set of capabilities includes a specific one.

  Respects capability implications.

  """
  @spec includes?([capability()], capability()) :: boolean()
  def includes?(granted, requested) do
    expanded = expand(granted)
    requested in expanded
  end

  @doc """
  Get a human-readable description of a capability.
  """
  @spec describe(capability()) :: String.t()
  def describe(:time), do: "Access system time"
  def describe(:random), do: "Access cryptographic randomness"
  def describe(:log), do: "Write to log output"
  def describe(:filesystem_read), do: "Read files from filesystem"
  def describe(:filesystem_write), do: "Write files to filesystem"
  def describe(:network), do: "Access network"
  def describe({:host_function, name}), do: "Call host function: #{name}"
  def describe(other), do: "Unknown capability: #{inspect(other)}"

  @doc """
  Get the risk level of a capability.
  """
  @spec risk_level(capability()) :: :low | :medium | :high
  def risk_level(:time), do: :low
  def risk_level(:random), do: :low
  def risk_level(:log), do: :low
  def risk_level(:filesystem_read), do: :medium
  def risk_level(:filesystem_write), do: :high
  def risk_level(:network), do: :high
  def risk_level({:host_function, _}), do: :medium
  def risk_level(_), do: :high
end

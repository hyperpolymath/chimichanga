# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Runtime.Config do
  @moduledoc """
  Runtime configuration and feature detection.

  Provides utilities for checking available runtimes and configuring
  runtime-specific options.
  """

  @doc """
  Get the configured runtime module.
  """
  @spec runtime() :: module()
  def runtime do
    Application.get_env(:munition, :runtime, Munition.Runtime.Wasmex)
  end

  @doc """
  Check if fuel metering is available.

  Fuel metering requires Wasmtime with the consume_fuel feature enabled.
  """
  @spec fuel_available?() :: boolean()
  def fuel_available? do
    # Wasmex with Wasmtime supports fuel metering
    runtime() == Munition.Runtime.Wasmex
  end

  @doc """
  Get Wasmtime engine configuration.

  These options are passed when creating the Wasmtime engine.
  """
  @spec engine_config() :: keyword()
  def engine_config do
    [
      # Enable fuel consumption for bounded execution
      consume_fuel: true,
      # Enable epoch interruption as a backup timeout mechanism
      epoch_interruption: false,
      # Cranelift optimization level
      # 0 = none, 1 = speed, 2 = speed and size
      cranelift_opt_level: 1
    ]
  end

  @doc """
  Check if memory 64 (64-bit memory) is available.
  """
  @spec memory64_available?() :: boolean()
  def memory64_available? do
    # Not yet enabled by default
    false
  end
end

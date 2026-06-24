# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Fuel.Meter do
  @moduledoc """
  Fuel Consumption Tracker — Execution Efficiency Observability.

  This GenServer provides real-time monitoring of "Fuel" usage within 
  sandboxed WASM instances. It allows the system to detect inefficient 
  algorithms or potential infinite loop attacks.

  DATA STORAGE: Uses a named ETS table (`:munition_fuel_meter`) for 
  high-concurrency writes without bottlenecking the main execution loop.
  """

  use GenServer

  @table_name :munition_fuel_meter

  @doc """
  RECORDS a single fuel event.
  Calculates `consumed = allocated - remaining` and updates the ETS table.
  """
  @spec record(String.t(), non_neg_integer(), non_neg_integer()) :: :ok
  def record(function, allocated, remaining) do
    GenServer.cast(__MODULE__, {:record, function, allocated, remaining})
  end

  @doc """
  AGGREGATE STATS: Computes mean, max, and min consumption for a function.
  Used by the self-healing coordinator to adjust fuel policies.
  """
  @spec stats(String.t()) :: map() | nil
  def stats(function) do
    GenServer.call(__MODULE__, {:stats, function})
  end

  @impl true
  def init(_opts) do
    # Optimized for many readers and many writers.
    table = :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{table: table}}
  end

  # ... [Handle calls and casts for ETS manipulation]
end

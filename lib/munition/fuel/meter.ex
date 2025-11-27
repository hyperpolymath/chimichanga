# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Fuel.Meter do
  @moduledoc """
  Fuel consumption tracking and analysis.

  Tracks fuel usage across executions to provide insights into:

  - Average fuel consumption per function
  - Fuel efficiency patterns
  - Anomaly detection (sudden spikes in consumption)

  ## Usage

      # Track an execution
      Meter.record("my_function", 100_000, 45_000)  # allocated, remaining

      # Get statistics
      Meter.stats("my_function")
      #=> %{
      #     mean_consumption: 55_000,
      #     max_consumption: 80_000,
      #     executions: 42
      #   }

  ## Note

  The meter uses an ETS table for storage. In production, consider
  using a more robust storage mechanism.

  """

  use GenServer

  @table_name :munition_fuel_meter

  # Client API

  @doc """
  Start the fuel meter.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Record a fuel consumption event.

  ## Parameters

  - `function` - Name of the function executed
  - `allocated` - Initial fuel allocation
  - `remaining` - Fuel remaining after execution

  """
  @spec record(String.t(), non_neg_integer(), non_neg_integer()) :: :ok
  def record(function, allocated, remaining) do
    GenServer.cast(__MODULE__, {:record, function, allocated, remaining})
  end

  @doc """
  Get statistics for a function.
  """
  @spec stats(String.t()) :: map() | nil
  def stats(function) do
    GenServer.call(__MODULE__, {:stats, function})
  end

  @doc """
  Get all tracked functions and their stats.
  """
  @spec all_stats() :: map()
  def all_stats do
    GenServer.call(__MODULE__, :all_stats)
  end

  @doc """
  Reset all tracked data.
  """
  @spec reset() :: :ok
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # Server Implementation

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{table: table}}
  end

  @impl true
  def handle_cast({:record, function, allocated, remaining}, state) do
    consumed = allocated - remaining
    now = System.monotonic_time(:microsecond)

    case :ets.lookup(@table_name, function) do
      [] ->
        # First record for this function
        :ets.insert(@table_name, {function, %{
          count: 1,
          total_consumed: consumed,
          max_consumed: consumed,
          min_consumed: consumed,
          last_consumed: consumed,
          last_timestamp: now
        }})

      [{^function, data}] ->
        # Update existing record
        :ets.insert(@table_name, {function, %{
          count: data.count + 1,
          total_consumed: data.total_consumed + consumed,
          max_consumed: max(data.max_consumed, consumed),
          min_consumed: min(data.min_consumed, consumed),
          last_consumed: consumed,
          last_timestamp: now
        }})
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:stats, function}, _from, state) do
    result = case :ets.lookup(@table_name, function) do
      [] -> nil
      [{^function, data}] ->
        %{
          executions: data.count,
          total_consumed: data.total_consumed,
          mean_consumption: div(data.total_consumed, data.count),
          max_consumption: data.max_consumed,
          min_consumption: data.min_consumed,
          last_consumption: data.last_consumed
        }
    end
    {:reply, result, state}
  end

  @impl true
  def handle_call(:all_stats, _from, state) do
    stats = :ets.tab2list(@table_name)
    |> Enum.map(fn {function, data} ->
      {function, %{
        executions: data.count,
        mean_consumption: div(data.total_consumed, data.count),
        max_consumption: data.max_consumed
      }}
    end)
    |> Map.new()

    {:reply, stats, state}
  end

  @impl true
  def handle_call(:reset, _from, state) do
    :ets.delete_all_objects(@table_name)
    {:reply, :ok, state}
  end
end

# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Fuel.Policy do
  @moduledoc """
  Fuel allocation policies for bounded execution.

  Fuel is a mechanism for limiting WASM execution. Each instruction
  consumes fuel, and when fuel is exhausted, execution halts.

  ## Policy Types

  - **Fixed**: Static fuel allocation per execution
  - **Adaptive**: Adjusts based on historical execution patterns (future)
  - **Tiered**: Different allocations based on trust level (future)

  ## Fuel Costs

  Fuel costs are determined by Wasmtime and roughly correspond to
  instruction complexity:

  | Operation | Approximate Cost |
  |-----------|------------------|
  | Simple arithmetic | 1 |
  | Memory load/store | 1-2 |
  | Function call | 2-3 |
  | Control flow | 1-2 |

  A `100_000` fuel allocation typically allows for ~50-100k simple
  operations before exhaustion.

  """

  @default_fuel 100_000
  @default_timeout 5_000

  @doc """
  Get the default fuel allocation.
  """
  @spec default_fuel() :: non_neg_integer()
  def default_fuel do
    Application.get_env(:munition, :default_fuel, @default_fuel)
  end

  @doc """
  Get the default execution timeout in milliseconds.
  """
  @spec default_timeout() :: non_neg_integer()
  def default_timeout do
    Application.get_env(:munition, :default_timeout, @default_timeout)
  end

  @doc """
  Calculate fuel for a given operation complexity estimate.

  ## Parameters

  - `complexity` - Estimated operation complexity
    - `:trivial` - Very simple operation (~1000 fuel)
    - `:simple` - Simple operation (~10000 fuel)
    - `:moderate` - Moderate complexity (~100000 fuel)
    - `:complex` - Complex operation (~1000000 fuel)
    - `:heavy` - Heavy computation (~10000000 fuel)

  """
  @spec fuel_for(atom()) :: non_neg_integer()
  def fuel_for(:trivial), do: 1_000
  def fuel_for(:simple), do: 10_000
  def fuel_for(:moderate), do: 100_000
  def fuel_for(:complex), do: 1_000_000
  def fuel_for(:heavy), do: 10_000_000
  def fuel_for(_), do: default_fuel()

  @doc """
  Validate a fuel allocation is within acceptable bounds.
  """
  @spec validate(non_neg_integer()) :: :ok | {:error, term()}
  def validate(fuel) when is_integer(fuel) and fuel > 0 and fuel <= 100_000_000 do
    :ok
  end

  def validate(fuel) when is_integer(fuel) and fuel <= 0 do
    {:error, :fuel_must_be_positive}
  end

  def validate(fuel) when is_integer(fuel) do
    {:error, :fuel_exceeds_maximum}
  end

  def validate(_) do
    {:error, :fuel_must_be_integer}
  end
end

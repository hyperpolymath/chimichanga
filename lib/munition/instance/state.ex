# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Instance.State do
  @moduledoc """
  State structure for tracking WASM instance lifecycle.

  Used internally by the Manager and Pool to track:

  - Compilation status
  - Instantiation state
  - Fuel consumption
  - Execution history

  """

  @enforce_keys [:id, :status, :created_at]
  defstruct [
    :id,
    :status,
    :created_at,
    :module_ref,
    :instance,
    :store,
    :fuel_allocated,
    :executions
  ]

  @type status :: :compiling | :compiled | :instantiated | :executing | :completed | :crashed

  @type t :: %__MODULE__{
          id: String.t(),
          status: status(),
          created_at: integer(),
          module_ref: term() | nil,
          instance: term() | nil,
          store: term() | nil,
          fuel_allocated: non_neg_integer() | nil,
          executions: non_neg_integer()
        }

  @doc """
  Create a new instance state.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      id: generate_id(),
      status: :compiling,
      created_at: System.monotonic_time(:microsecond),
      module_ref: nil,
      instance: nil,
      store: nil,
      fuel_allocated: nil,
      executions: 0
    }
  end

  @doc """
  Transition to compiled state.
  """
  @spec compiled(t(), term()) :: t()
  def compiled(%__MODULE__{} = state, module_ref) do
    %{state | status: :compiled, module_ref: module_ref}
  end

  @doc """
  Transition to instantiated state.
  """
  @spec instantiated(t(), term(), term(), non_neg_integer()) :: t()
  def instantiated(%__MODULE__{} = state, instance, store, fuel) do
    %{state |
      status: :instantiated,
      instance: instance,
      store: store,
      fuel_allocated: fuel
    }
  end

  @doc """
  Mark as executing.
  """
  @spec executing(t()) :: t()
  def executing(%__MODULE__{} = state) do
    %{state | status: :executing, executions: state.executions + 1}
  end

  @doc """
  Mark as completed.
  """
  @spec completed(t()) :: t()
  def completed(%__MODULE__{} = state) do
    %{state | status: :completed}
  end

  @doc """
  Mark as crashed.
  """
  @spec crashed(t()) :: t()
  def crashed(%__MODULE__{} = state) do
    %{state | status: :crashed}
  end

  @doc """
  Get instance age in microseconds.
  """
  @spec age_us(t()) :: non_neg_integer()
  def age_us(%__MODULE__{created_at: created_at}) do
    System.monotonic_time(:microsecond) - created_at
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end

# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Application do
  @moduledoc """
  OTP Application for the Munition framework.

  Starts the supervision tree for managing WASM instance lifecycle,
  forensic capture, and (future) instance pooling.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Future: Instance pool supervisor
      # {Munition.Instance.PoolSupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: Munition.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/hyperpolymath/chimichanga"

  def project do
    [
      app: :munition,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),

      # Docs
      name: "Munition",
      source_url: @source_url,
      homepage_url: "https://hyperpolymath.dev/munition",
      docs: docs(),

      # Package
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Munition.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # RSR Compliance: Pinned versions (no floating ranges)
  defp deps do
    [
      # WASM runtime - pinned version
      {:wasmex, "0.9.2"},

      # JSON encoding for benchmarks and dumps - pinned version
      {:jason, "1.4.4"},

      # Development and testing - pinned versions
      {:ex_doc, "0.31.1", only: :dev, runtime: false},
      {:credo, "1.7.3", only: [:dev, :test], runtime: false},
      {:dialyxir, "1.4.3", only: [:dev, :test], runtime: false},

      # Benchmarking - pinned version
      {:benchee, "1.3.0", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      test: ["test"],
      "test.integration": ["test --only integration"],
      bench: ["run bench/startup_bench.exs"]
    ]
  end

  defp docs do
    [
      main: "Munition",
      extras: [
        "README.md",
        "ARCHITECTURE.md",
        "CHANGELOG.md",
        "docs/capability_model.md"
      ],
      groups_for_modules: [
        "Core": [Munition],
        "Runtime": [
          Munition.Runtime,
          Munition.Runtime.Wasmex,
          Munition.Runtime.Config
        ],
        "Forensics": [
          Munition.Forensics.Dump,
          Munition.Forensics.Capture,
          Munition.Forensics.Analyser
        ],
        "Fuel": [
          Munition.Fuel.Policy,
          Munition.Fuel.Meter
        ],
        "Host": [
          Munition.Host.Functions,
          Munition.Host.Capabilities
        ],
        "Instance": [
          Munition.Instance.Manager,
          Munition.Instance.State
        ]
      ]
    ]
  end

  defp description do
    """
    Capability attenuation framework for sandboxed WASM execution.
    Provides bounded execution, memory isolation, and forensic capture.
    """
  end

  defp package do
    [
      name: "munition",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      files: ~w(
        lib
        mix.exs
        README.md
        LICENSE.txt
        CHANGELOG.md
      )
    ]
  end
end

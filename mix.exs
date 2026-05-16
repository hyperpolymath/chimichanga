# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

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
      package: package(),

      # Coverage: threshold disabled — meaningful coverage requires the WASM
      # test binary (test/fixtures/test.wasm); integration tests are excluded
      # in CI until the binary is built and committed.
      test_coverage: [threshold: 0]
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
      {:wasmex, "0.14.0"},

      # JSON encoding for benchmarks and dumps - pinned version
      {:jason, "1.4.5"},

      # Development and testing - pinned versions
      {:ex_doc, "0.40.2", only: :dev, runtime: false},
      {:credo, "1.7.18", only: [:dev, :test], runtime: false},
      {:dialyxir, "1.4.7", only: [:dev, :test], runtime: false},

      # Benchmarking - pinned version
      {:benchee, "1.5.0", only: [:dev, :test]}
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

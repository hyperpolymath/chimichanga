# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath
#
# Boundary Crossing Benchmark
#
# Measures the overhead of crossing the Elixir <-> WASM boundary.
#
# Run with: mix run bench/boundary_bench.exs

defmodule Munition.Bench.Boundary do
  @moduledoc """
  Benchmarks for WASM boundary crossing overhead.

  Compares:
  - Pure Elixir computation
  - WASM computation (same algorithm)
  - Multiple boundary crossings vs single
  """

  @wasm_path "test/fixtures/test.wasm"
  @iterations 1_000

  def run do
    unless File.exists?(@wasm_path) do
      IO.puts("Error: Test WASM not found at #{@wasm_path}")
      IO.puts("Build it with: just build-wasm")
      System.halt(1)
    end

    wasm = File.read!(@wasm_path)

    IO.puts("\n=== Munition Boundary Crossing Benchmark ===\n")
    IO.puts("Iterations: #{@iterations}\n")

    # Pure Elixir addition
    IO.puts("--- Pure Elixir: add(20, 22) ---")
    elixir_add_times = benchmark(@iterations, fn ->
      _ = 20 + 22
    end)
    print_stats(elixir_add_times)

    # WASM addition
    IO.puts("\n--- WASM: add(20, 22) ---")
    wasm_add_times = benchmark(@iterations, fn ->
      {:ok, _, _} = Munition.fire(wasm, "add", [20, 22], fuel: 1_000)
    end)
    print_stats(wasm_add_times)

    # Calculate overhead
    elixir_mean = Enum.sum(elixir_add_times) / @iterations
    wasm_mean = Enum.sum(wasm_add_times) / @iterations
    overhead = wasm_mean - elixir_mean

    IO.puts("\n  Boundary overhead: #{format_ns(round(overhead))}")

    # Multiple calls vs batched
    IO.puts("\n--- 10 separate WASM calls ---")
    multi_times = benchmark(div(@iterations, 10), fn ->
      for _ <- 1..10 do
        {:ok, _, _} = Munition.fire(wasm, "add", [1, 1], fuel: 1_000)
      end
    end)
    print_stats(multi_times)

    # Single call with loop inside
    IO.puts("\n--- 1 WASM call with internal loop (spin(10)) ---")
    single_times = benchmark(div(@iterations, 10), fn ->
      {:ok, _, _} = Munition.fire(wasm, "spin", [10], fuel: 10_000)
    end)
    print_stats(single_times)

    multi_mean = Enum.sum(multi_times) / length(multi_times)
    single_mean = Enum.sum(single_times) / length(single_times)

    IO.puts("\n  Batching saves: #{format_ns(round(multi_mean - single_mean))}")

    IO.puts("\n=== Benchmark Complete ===\n")
  end

  defp benchmark(iterations, func) do
    for _ <- 1..iterations do
      start = System.monotonic_time(:nanosecond)
      func.()
      System.monotonic_time(:nanosecond) - start
    end
  end

  defp print_stats(times) do
    sorted = Enum.sort(times)
    count = length(sorted)

    mean = Enum.sum(times) / count
    median = Enum.at(sorted, div(count, 2))
    p95 = Enum.at(sorted, round(count * 0.95))
    min = List.first(sorted)
    max = List.last(sorted)

    IO.puts("  Min:    #{format_ns(min)}")
    IO.puts("  Max:    #{format_ns(max)}")
    IO.puts("  Mean:   #{format_ns(round(mean))}")
    IO.puts("  Median: #{format_ns(median)}")
    IO.puts("  P95:    #{format_ns(p95)}")
  end

  defp format_ns(ns) when ns < 1_000, do: "#{ns}ns"
  defp format_ns(ns) when ns < 1_000_000, do: "#{Float.round(ns / 1_000, 2)}µs"
  defp format_ns(ns), do: "#{Float.round(ns / 1_000_000, 2)}ms"
end

Munition.Bench.Boundary.run()

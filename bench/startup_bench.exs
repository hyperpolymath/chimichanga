# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath
#
# Startup Latency Benchmark
#
# Measures the time from receiving WASM bytes to function execution completion.
#
# Run with: mix run bench/startup_bench.exs

defmodule Munition.Bench.Startup do
  @moduledoc """
  Benchmarks for WASM instance startup latency.

  Measures:
  - Cold start (compile + instantiate + execute)
  - Module compilation only
  - Instantiation only
  - Execution only
  """

  @wasm_path "test/fixtures/test.wasm"
  @iterations 100

  def run do
    unless File.exists?(@wasm_path) do
      IO.puts("Error: Test WASM not found at #{@wasm_path}")
      IO.puts("Build it with: just build-wasm")
      System.halt(1)
    end

    wasm = File.read!(@wasm_path)

    IO.puts("\n=== Munition Startup Latency Benchmark ===\n")
    IO.puts("WASM size: #{byte_size(wasm)} bytes")
    IO.puts("Iterations: #{@iterations}\n")

    # Warm up
    IO.puts("Warming up...")
    for _ <- 1..10 do
      Munition.fire(wasm, "add", [1, 2], fuel: 1_000)
    end

    # Cold start benchmark
    IO.puts("\n--- Cold Start (full execution) ---")
    cold_times = benchmark("cold_start", @iterations, fn ->
      {:ok, _, _} = Munition.fire(wasm, "add", [1, 2], fuel: 10_000)
    end)

    print_stats(cold_times)

    # Computation benchmark
    IO.puts("\n--- Computation (spin(100)) ---")
    compute_times = benchmark("compute", @iterations, fn ->
      {:ok, _, _} = Munition.fire(wasm, "spin", [100], fuel: 100_000)
    end)

    print_stats(compute_times)

    # Heavy computation benchmark
    IO.puts("\n--- Heavy Computation (nested_loops(10)) ---")
    heavy_times = benchmark("heavy", @iterations, fn ->
      {:ok, _, _} = Munition.fire(wasm, "nested_loops", [10], fuel: 1_000_000)
    end)

    print_stats(heavy_times)

    IO.puts("\n=== Benchmark Complete ===\n")
  end

  defp benchmark(name, iterations, func) do
    times =
      for i <- 1..iterations do
        start = System.monotonic_time(:nanosecond)
        func.()
        elapsed = System.monotonic_time(:nanosecond) - start

        if rem(i, div(iterations, 10)) == 0 do
          IO.write(".")
        end

        elapsed
      end

    IO.puts("")
    times
  end

  defp print_stats(times) do
    sorted = Enum.sort(times)
    count = length(sorted)

    mean = Enum.sum(times) / count
    median = Enum.at(sorted, div(count, 2))
    p95 = Enum.at(sorted, round(count * 0.95))
    p99 = Enum.at(sorted, round(count * 0.99))
    min = List.first(sorted)
    max = List.last(sorted)

    variance = Enum.map(times, fn t -> (t - mean) * (t - mean) end) |> Enum.sum() |> Kernel./(count)
    std_dev = :math.sqrt(variance)

    IO.puts("  Min:    #{format_ns(min)}")
    IO.puts("  Max:    #{format_ns(max)}")
    IO.puts("  Mean:   #{format_ns(round(mean))}")
    IO.puts("  Median: #{format_ns(median)}")
    IO.puts("  P95:    #{format_ns(p95)}")
    IO.puts("  P99:    #{format_ns(p99)}")
    IO.puts("  StdDev: #{format_ns(round(std_dev))}")
  end

  defp format_ns(ns) when ns < 1_000, do: "#{ns}ns"
  defp format_ns(ns) when ns < 1_000_000, do: "#{Float.round(ns / 1_000, 2)}µs"
  defp format_ns(ns), do: "#{Float.round(ns / 1_000_000, 2)}ms"
end

Munition.Bench.Startup.run()

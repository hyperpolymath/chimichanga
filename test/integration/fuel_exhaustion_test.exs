# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Integration.FuelExhaustionTest do
  use ExUnit.Case, async: true

  @moduletag :integration

  setup do
    if Munition.TestSupport.test_wasm_available?() do
      {:ok, wasm: Munition.TestSupport.load_test_wasm()}
    else
      :ok
    end
  end

  describe "fuel exhaustion" do
    @tag :skip_without_wasm
    test "bounded loop completes with sufficient fuel", %{wasm: wasm} do
      # spin(100) should complete with 10_000 fuel
      assert {:ok, _result, metadata} =
               Munition.fire(wasm, "spin", [100], fuel: 100_000)

      assert metadata.fuel_remaining > 0
      assert metadata.fuel_remaining < 100_000
    end

    @tag :skip_without_wasm
    test "bounded loop exhausts insufficient fuel", %{wasm: wasm} do
      # spin(10_000) should exhaust 100 fuel
      assert {:crash, :fuel_exhausted, forensics} =
               Munition.fire(wasm, "spin", [10_000], fuel: 100)

      assert forensics.fuel_remaining == 0
      assert forensics.reason == :fuel_exhausted
    end

    @tag :skip_without_wasm
    test "infinite loop always exhausts fuel", %{wasm: wasm} do
      assert {:crash, :fuel_exhausted, forensics} =
               Munition.fire(wasm, "infinite_loop", [], fuel: 1_000)

      assert forensics.fuel_remaining == 0
    end

    @tag :skip_without_wasm
    test "fuel consumption is deterministic", %{wasm: wasm} do
      # Same computation should consume same fuel
      results =
        for _ <- 1..5 do
          {:ok, _, metadata} = Munition.fire(wasm, "spin", [50], fuel: 100_000)
          metadata.fuel_remaining
        end

      # All results should be identical
      assert Enum.uniq(results) |> length() == 1
    end

    @tag :skip_without_wasm
    test "nested loops consume fuel quadratically", %{wasm: wasm} do
      # nested_loops(n) has O(n^2) fuel consumption
      {:ok, _, meta_10} = Munition.fire(wasm, "nested_loops", [10], fuel: 1_000_000)
      {:ok, _, meta_20} = Munition.fire(wasm, "nested_loops", [20], fuel: 1_000_000)

      consumed_10 = 1_000_000 - meta_10.fuel_remaining
      consumed_20 = 1_000_000 - meta_20.fuel_remaining

      # 20x20 should consume roughly 4x the fuel of 10x10
      ratio = consumed_20 / consumed_10
      assert ratio > 3.0 and ratio < 5.0
    end
  end
end

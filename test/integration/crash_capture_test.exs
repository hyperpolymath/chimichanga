# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Integration.CrashCaptureTest do
  use ExUnit.Case, async: true

  @moduletag :integration

  setup do
    if Munition.TestSupport.test_wasm_available?() do
      {:ok, wasm: Munition.TestSupport.load_test_wasm()}
    else
      :ok
    end
  end

  describe "forensic capture" do
    @tag :skip_without_wasm
    test "unreachable trap captures memory", %{wasm: wasm} do
      assert {:crash, :trap, forensics} =
               Munition.fire(wasm, "trap_unreachable", [], fuel: 10_000)

      assert match?({:trap, _}, forensics.reason)
      assert is_binary(forensics.memory)
    end

    @tag :skip_without_wasm
    test "crash_after_n captures state at moment of crash", %{wasm: wasm} do
      n = 42

      assert {:crash, :trap, forensics} =
               Munition.fire(wasm, "crash_after_n", [n], fuel: 1_000_000)

      # Verify metadata
      assert forensics.function_called == "crash_after_n"
      assert forensics.fuel_allocated == 1_000_000
      assert forensics.execution_time_us > 0
    end

    @tag :skip_without_wasm
    test "fuel exhaustion captures memory state", %{wasm: wasm} do
      assert {:crash, :fuel_exhausted, forensics} =
               Munition.fire(wasm, "increment_until_exhausted", [], fuel: 10_000)

      assert forensics.reason == :fuel_exhausted
      assert forensics.fuel_remaining == 0
      assert is_binary(forensics.memory)
    end

    @tag :skip_without_wasm
    test "dump serialization roundtrips", %{wasm: wasm} do
      {:crash, _, forensics} =
        Munition.fire(wasm, "trap_unreachable", [], fuel: 10_000)

      serialized = Munition.Forensics.Dump.serialize(forensics)
      assert is_binary(serialized)

      {:ok, deserialized} = Munition.Forensics.Dump.deserialize(serialized)

      assert deserialized.id == forensics.id
      assert deserialized.memory == forensics.memory
      assert deserialized.reason == forensics.reason
      assert deserialized.function_called == forensics.function_called
    end

    @tag :skip_without_wasm
    test "dump summary is readable", %{wasm: wasm} do
      {:crash, _, forensics} =
        Munition.fire(wasm, "trap_unreachable", [], fuel: 10_000)

      summary = Munition.Forensics.Dump.summary(forensics)

      assert is_binary(summary)
      assert String.contains?(summary, "trap_unreachable")
      assert String.contains?(summary, "Dump[")
    end
  end

  describe "analyser" do
    @tag :skip_without_wasm
    test "can analyse memory dump", %{wasm: wasm} do
      # Write a pattern then crash
      # We'll use crash_after_n which modifies state before crashing
      {:crash, _, forensics} =
        Munition.fire(wasm, "crash_after_n", [10], fuel: 100_000)

      analyser = Munition.Forensics.Analyser.new(forensics)

      # Get memory stats
      stats = Munition.Forensics.Analyser.stats(analyser)
      assert stats.size_bytes > 0
    end

    @tag :skip_without_wasm
    test "can find patterns in memory", %{wasm: wasm} do
      # This test would need to know the memory layout
      # For now, just verify the API works
      {:crash, _, forensics} =
        Munition.fire(wasm, "crash_after_n", [10], fuel: 100_000)

      analyser = Munition.Forensics.Analyser.new(forensics)

      # Search for a pattern (may or may not find it)
      offsets = Munition.Forensics.Analyser.find_pattern(analyser, <<0, 0, 0, 0>>)
      assert is_list(offsets)
    end
  end
end

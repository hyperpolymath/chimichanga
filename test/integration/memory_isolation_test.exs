# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule Munition.Integration.MemoryIsolationTest do
  use ExUnit.Case, async: true

  @moduletag :integration
  @poison_pattern 0xDE

  setup do
    if Munition.TestSupport.test_wasm_available?() do
      {:ok, wasm: Munition.TestSupport.load_test_wasm()}
    else
      :ok
    end
  end

  describe "memory isolation" do
    @tag :skip_without_wasm
    test "fresh instance has zeroed buffer", %{wasm: wasm} do
      # Read from fresh instance should return 0
      assert {:ok, [0], _} =
               Munition.fire(wasm, "read_buffer", [0], fuel: 10_000)

      assert {:ok, [0], _} =
               Munition.fire(wasm, "read_buffer", [500], fuel: 10_000)
    end

    @tag :skip_without_wasm
    test "writes do not leak between executions", %{wasm: wasm} do
      # Execution A: Write poison pattern
      assert {:ok, _, _} =
               Munition.fire(wasm, "write_pattern", [@poison_pattern, 100], fuel: 100_000)

      # Execution B: Scan for pattern (should not find it)
      assert {:ok, [-1], _} =
               Munition.fire(wasm, "scan_for_pattern", [@poison_pattern], fuel: 100_000)
    end

    @tag :skip_without_wasm
    test "state does not persist between executions", %{wasm: wasm} do
      # Execution A: Increment state several times
      for _ <- 1..5 do
        Munition.fire(wasm, "stateful_increment", [], fuel: 10_000)
      end

      # Execution B: Fresh state should be 0
      assert {:ok, [0], _} =
               Munition.fire(wasm, "get_state", [], fuel: 10_000)
    end

    @tag :skip_without_wasm
    test "isolation holds under concurrent execution", %{wasm: wasm} do
      # Spawn many concurrent executions, each writing different patterns
      tasks =
        for pattern <- 0..50 do
          Task.async(fn ->
            # Write pattern
            {:ok, _, _} = Munition.fire(wasm, "write_pattern", [pattern, 100], fuel: 100_000)

            # Immediately check fresh instance (different execution)
            {:ok, [read_value], _} = Munition.fire(wasm, "read_buffer", [0], fuel: 10_000)

            # Should be 0 (fresh instance) not our pattern
            read_value
          end)
        end

      results = Task.await_many(tasks, 30_000)

      # All reads should return 0 (isolation maintained)
      assert Enum.all?(results, &(&1 == 0))
    end

    @tag :skip_without_wasm
    test "memory captured in forensics shows execution state", %{wasm: wasm} do
      # Write a recognizable pattern then crash
      # The crash_after_n function increments STATE n times then crashes

      assert {:crash, :trap, forensics} =
               Munition.fire(wasm, "crash_after_n", [42], fuel: 100_000)

      # Memory should be captured
      assert byte_size(forensics.memory) > 0
    end
  end
end

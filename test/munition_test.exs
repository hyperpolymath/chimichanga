# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

defmodule MunitionTest do
  use ExUnit.Case, async: true
  doctest Munition

  alias Munition.Fuel.Policy

  describe "fire/4" do
    @tag :integration
    test "executes simple addition" do
      if Munition.TestSupport.test_wasm_available?() do
        wasm = Munition.TestSupport.load_test_wasm()

        assert {:ok, result, metadata} = Munition.fire(wasm, "add", [20, 22])

        assert result == [42]
        assert metadata.fuel_remaining > 0
        assert metadata.execution_time_us > 0
      end
    end

    @tag :integration
    test "respects fuel limits" do
      if Munition.TestSupport.test_wasm_available?() do
        wasm = Munition.TestSupport.load_test_wasm()

        # Small loop should complete with enough fuel
        assert {:ok, _, _} = Munition.fire(wasm, "spin", [10], fuel: 10_000)

        # Infinite loop should exhaust fuel
        assert {:crash, :fuel_exhausted, forensics} =
                 Munition.fire(wasm, "infinite_loop", [], fuel: 1_000)

        assert forensics.fuel_remaining == 0
      end
    end
  end

  describe "validate/2" do
    @tag :integration
    test "validates correct WASM" do
      if Munition.TestSupport.test_wasm_available?() do
        wasm = Munition.TestSupport.load_test_wasm()
        assert :ok = Munition.validate(wasm)
      end
    end

    test "rejects invalid WASM" do
      invalid = <<0, 1, 2, 3>>
      assert {:error, _} = Munition.validate(invalid)
    end
  end

  describe "options" do
    test "default fuel is configurable" do
      assert Policy.default_fuel() > 0
    end

    test "default timeout is configurable" do
      assert Policy.default_timeout() > 0
    end
  end
end

# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

ExUnit.start()

# Test support modules
defmodule Munition.TestSupport do
  @moduledoc """
  Test support utilities for Munition tests.
  """

  @test_wasm_path "test/fixtures/test.wasm"

  @doc """
  Get the path to the test WASM file.
  """
  def test_wasm_path, do: @test_wasm_path

  @doc """
  Load the test WASM bytes.

  Raises if the file doesn't exist (run `just build-wasm` first).
  """
  def load_test_wasm do
    case File.read(@test_wasm_path) do
      {:ok, bytes} ->
        bytes

      {:error, :enoent} ->
        raise """
        Test WASM file not found at #{@test_wasm_path}.

        Build it with:
          cd test_wasm && cargo build --target wasm32-unknown-unknown --release
          mkdir -p test/fixtures
          cp test_wasm/target/wasm32-unknown-unknown/release/munition_test_wasm.wasm test/fixtures/test.wasm
        """
    end
  end

  @doc """
  Check if test WASM is available.
  """
  def test_wasm_available? do
    File.exists?(@test_wasm_path)
  end
end

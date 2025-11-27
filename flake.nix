# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath
#
# Munition - Capability Attenuation Framework
# Nix flake for reproducible development environment

{
  description = "Munition: Capability attenuation framework for sandboxed WASM execution";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
        };

      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Elixir ecosystem
            elixir_1_16
            erlang_26
            rebar3

            # Rust for WASM compilation
            rustToolchain

            # Build tools
            just
            gnumake

            # Documentation
            vale
            lychee

            # Security tools
            trivy

            # Utilities
            jq
            yq
            ripgrep
            fd
          ];

          shellHook = ''
            echo "🔒 Munition Development Environment"
            echo "   Elixir: $(elixir --version | head -1)"
            echo "   Rust:   $(rustc --version)"
            echo ""
            echo "Commands:"
            echo "   just setup    - Initialize development environment"
            echo "   just test     - Run all tests"
            echo "   just validate - Run RSR compliance checks"
          '';
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "munition";
          version = "0.1.0";
          src = ./.;

          buildInputs = with pkgs; [
            elixir_1_16
            erlang_26
          ];

          buildPhase = ''
            export MIX_ENV=prod
            export HEX_OFFLINE=1
            mix compile
          '';

          installPhase = ''
            mkdir -p $out/lib
            cp -r _build/prod/lib/munition $out/lib/
          '';
        };

        checks = {
          format = pkgs.runCommand "format-check" {} ''
            cd ${self}
            ${pkgs.elixir_1_16}/bin/mix format --check-formatted
            touch $out
          '';
        };
      }
    );
}

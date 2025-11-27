# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath
#
# Justfile for Munition project
# RSR Gold Compliance: 15+ task recipes

wasm_target := "wasm32-unknown-unknown"
wasm_out := "test/fixtures"

# Default: show available commands
default:
    @just --list

# ============================================================================
# Development Setup
# ============================================================================

# Setup development environment
setup:
    just deps
    just build-wasm
    @echo "✅ Development environment ready!"

# Get dependencies
deps:
    mix deps.get

# Compile the project
compile:
    mix compile

# Interactive shell
iex:
    iex -S mix

# ============================================================================
# Building
# ============================================================================

# Build test WASM modules
build-wasm:
    cd test_wasm && cargo build --target {{wasm_target}} --release
    mkdir -p {{wasm_out}}
    cp test_wasm/target/{{wasm_target}}/release/munition_test_wasm.wasm {{wasm_out}}/test.wasm
    @echo "✅ Built test WASM to {{wasm_out}}/test.wasm"

# Build release
build-release:
    MIX_ENV=prod mix compile

# ============================================================================
# Testing
# ============================================================================

# Run all tests
test: build-wasm
    mix test

# Run only unit tests (no WASM required)
test-unit:
    mix test --exclude integration

# Run only integration tests (requires WASM)
test-integration: build-wasm
    mix test --only integration

# Run tests with coverage
test-coverage: build-wasm
    mix test --cover

# ============================================================================
# Code Quality
# ============================================================================

# Format all code
fmt:
    mix format
    cd test_wasm && cargo fmt
    @echo "✅ Code formatted"

# Check formatting
check-format:
    mix format --check-formatted
    cd test_wasm && cargo fmt --check

# Run linters
lint:
    mix compile --warnings-as-errors
    -mix credo --strict
    cd test_wasm && cargo clippy -- -D warnings

# Run dialyzer
dialyzer:
    mix dialyzer

# Full code quality check
check: check-format lint test
    @echo "✅ All checks passed"

# ============================================================================
# Documentation
# ============================================================================

# Generate documentation
docs:
    mix docs

# Check documentation links
check-links:
    @echo "Checking documentation links..."
    @command -v lychee >/dev/null 2>&1 && lychee --verbose docs/ *.md *.adoc || echo "⚠️ lychee not installed, skipping link check"

# ============================================================================
# Security & Compliance
# ============================================================================

# Audit SPDX license headers
audit-licence:
    @echo "Checking SPDX headers..."
    @missing=0; \
    for f in lib/**/*.ex lib/*.ex test/**/*.exs test/*.exs; do \
        if [ -f "$$f" ] && ! grep -q "SPDX-License-Identifier" "$$f"; then \
            echo "❌ Missing SPDX header: $$f"; \
            missing=$$((missing + 1)); \
        fi; \
    done; \
    for f in test_wasm/src/*.rs; do \
        if [ -f "$$f" ] && ! grep -q "SPDX-License-Identifier" "$$f"; then \
            echo "❌ Missing SPDX header: $$f"; \
            missing=$$((missing + 1)); \
        fi; \
    done; \
    if [ $$missing -gt 0 ]; then \
        echo "❌ $$missing files missing SPDX headers"; \
        exit 1; \
    else \
        echo "✅ All source files have SPDX headers"; \
    fi

# Audit dependencies
audit-deps:
    @echo "Checking dependencies..."
    mix deps.audit || true
    cd test_wasm && cargo audit || echo "⚠️ cargo-audit not installed"

# Generate SBOM (Software Bill of Materials)
sbom-generate:
    @echo "Generating SBOM..."
    mix deps > sbom-elixir.txt
    cd test_wasm && cargo tree > ../sbom-rust.txt
    @echo "✅ SBOM generated: sbom-elixir.txt, sbom-rust.txt"

# Security scan
security-scan:
    @echo "Running security scan..."
    @command -v trivy >/dev/null 2>&1 && trivy fs . || echo "⚠️ trivy not installed"

# ============================================================================
# RSR Compliance Validation
# ============================================================================

# Validate RSR compliance (full check)
validate: validate-docs validate-security validate-code
    @echo ""
    @echo "======================================"
    @echo "✅ RSR Gold Compliance Validation Complete"
    @echo "======================================"

# Validate documentation compliance
validate-docs:
    @echo "📋 Validating documentation..."
    @test -f README.md || test -f README.adoc || (echo "❌ README missing" && exit 1)
    @test -f LICENSE.txt || (echo "❌ LICENSE.txt missing" && exit 1)
    @test -f SECURITY.md || (echo "❌ SECURITY.md missing" && exit 1)
    @test -f CODE_OF_CONDUCT.md || test -f CODE_OF_CONDUCT.adoc || (echo "❌ CODE_OF_CONDUCT missing" && exit 1)
    @test -f CONTRIBUTING.md || test -f CONTRIBUTING.adoc || (echo "❌ CONTRIBUTING missing" && exit 1)
    @test -f FUNDING.yml || (echo "❌ FUNDING.yml missing" && exit 1)
    @test -f GOVERNANCE.adoc || (echo "❌ GOVERNANCE.adoc missing" && exit 1)
    @test -f MAINTAINERS.md || (echo "❌ MAINTAINERS.md missing" && exit 1)
    @test -f .gitignore || (echo "❌ .gitignore missing" && exit 1)
    @test -f .gitattributes || (echo "❌ .gitattributes missing" && exit 1)
    @test -f CHANGELOG.md || (echo "❌ CHANGELOG.md missing" && exit 1)
    @test -f ROADMAP.md || (echo "❌ ROADMAP.md missing" && exit 1)
    @test -f REVERSIBILITY.md || (echo "❌ REVERSIBILITY.md missing" && exit 1)
    @test -d .well-known || (echo "❌ .well-known/ missing" && exit 1)
    @test -f .well-known/security.txt || (echo "❌ .well-known/security.txt missing" && exit 1)
    @test -f .well-known/ai.txt || (echo "❌ .well-known/ai.txt missing" && exit 1)
    @test -f .well-known/provenance.json || (echo "❌ .well-known/provenance.json missing" && exit 1)
    @test -f .well-known/humans.txt || (echo "❌ .well-known/humans.txt missing" && exit 1)
    @echo "✅ Documentation compliance passed"

# Validate security compliance
validate-security:
    @echo "🔒 Validating security..."
    @grep -q "SPDX-License-Identifier" LICENSE.txt || (echo "❌ LICENSE.txt missing SPDX" && exit 1)
    @grep -q "Vulnerability" SECURITY.md || (echo "❌ SECURITY.md incomplete" && exit 1)
    @grep -q "Perimeter" CONTRIBUTING.adoc || (echo "❌ TPCF not documented" && exit 1)
    just audit-licence
    @echo "✅ Security compliance passed"

# Validate code compliance
validate-code:
    @echo "💻 Validating code..."
    just check-format
    @test -f mix.exs || (echo "❌ mix.exs missing" && exit 1)
    @test -f flake.nix || (echo "❌ flake.nix missing" && exit 1)
    @echo "✅ Code compliance passed"

# ============================================================================
# Benchmarking
# ============================================================================

# Run startup benchmark
bench: build-wasm
    mix run bench/startup_bench.exs

# Run boundary benchmark
bench-boundary: build-wasm
    mix run bench/boundary_bench.exs

# Run all benchmarks
bench-all: build-wasm
    mix run bench/startup_bench.exs
    mix run bench/boundary_bench.exs

# ============================================================================
# Cleanup
# ============================================================================

# Clean WASM build artifacts
clean-wasm:
    cd test_wasm && cargo clean
    rm -f {{wasm_out}}/test.wasm

# Clean all build artifacts
clean:
    mix clean
    just clean-wasm
    rm -f sbom-*.txt

# Deep clean (including deps)
clean-all: clean
    rm -rf deps _build
    @echo "✅ Deep clean complete"

# ============================================================================
# Release
# ============================================================================

# Prepare release
release-prepare:
    @echo "Preparing release..."
    just validate
    just test-coverage
    just docs
    @echo "✅ Release prepared"

# Tag release
release-tag version:
    git tag -a v{{version}} -m "Release {{version}}"
    @echo "✅ Tagged v{{version}}"

# ============================================================================
# Git Hooks (RVC - Robot Vacuum Cleaner)
# ============================================================================

# Install git hooks
hooks-install:
    @echo "Installing git hooks..."
    @mkdir -p .git/hooks
    @echo '#!/bin/sh\njust check-format' > .git/hooks/pre-commit
    @echo '#!/bin/sh\njust lint' >> .git/hooks/pre-commit
    @chmod +x .git/hooks/pre-commit
    @echo '#!/bin/sh\njust test-unit' > .git/hooks/pre-push
    @chmod +x .git/hooks/pre-push
    @echo "✅ Git hooks installed"

# Uninstall git hooks
hooks-uninstall:
    rm -f .git/hooks/pre-commit .git/hooks/pre-push
    @echo "✅ Git hooks uninstalled"

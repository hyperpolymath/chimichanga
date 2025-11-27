# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

import Config

# Test-specific configuration
config :logger, level: :warning

config :munition,
  # Lower defaults for faster tests
  default_fuel: 10_000,
  default_timeout: 1_000

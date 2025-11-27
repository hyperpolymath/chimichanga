# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

import Config

# Production configuration
config :logger, level: :info

config :munition,
  default_fuel: 1_000_000,
  default_timeout: 30_000

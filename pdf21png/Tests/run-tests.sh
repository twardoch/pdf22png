#!/bin/bash

# Run unit tests for pdf21png
# Runs the simple C-based unit tests

set -euo pipefail

# Simply delegate to the unit test runner
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/run-unit-tests.sh" "$@"
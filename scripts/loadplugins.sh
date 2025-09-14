#!/bin/bash
# Main entry script to initialize plugins for ORRHDOCKER.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="/config/scripts/orrh_plugins"

export OLD_PWD="$PWD"
cd "$ROOT_DIR"

./setup.sh

cd "$OLD_PWD"
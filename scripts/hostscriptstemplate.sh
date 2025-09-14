#!/bin/bash

set -euo pipefail

ROOT_DIR="/config/OnlyRetroRobloxHere/data/clients"

for client_dir in "$ROOT_DIR"/*/; do
    host_script="${client_dir}scripts/host.lua"
    if [[ -f "$host_script" ]]; then
        mv $host_script "${client_dir}scripts/host.lua.template"
    fi
done
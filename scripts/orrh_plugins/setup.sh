#!/bin/bash
# ORRHDOCKER Plugin Setup Script (new-style plugins)
# Scans for *.lua plugins, base64-encodes them, and injects loader into client host.lua files.

set -euo pipefail

### CONFIGURATION ###
LAUNCHER_DIR="/config/OnlyRetroRobloxHere"            # Path to Roblox launcher
USER_PLUGINS_DIR="/config/Plugins"                    # Path for user-installed plugins
BUILTIN_PLUGINS_DIR="$(dirname "$0")/plugins"         # Builtin plugins directory
CLIENT="${CLIENT:-2013L}"                             # Default client version
LOADER_TEMPLATE="$(dirname "$0")/newloader.lua.template"
CLIENTS_DIR="$LAUNCHER_DIR/data/clients"

### PREPARATION ###
mkdir -p "$USER_PLUGINS_DIR"

### FUNCTION: scan for plugins (*.lua only) ###
get_plugins() {
    local dir="$1"
    [[ -d "$dir" ]] || return 0
    for plugin_file in "$dir"/*.lua; do
        [[ -f "$plugin_file" ]] || continue
        PLUGINS+=("$plugin_file")
    done
}

PLUGINS=()
get_plugins "$USER_PLUGINS_DIR"
get_plugins "$BUILTIN_PLUGINS_DIR"

PLUGIN_COUNT="${#PLUGINS[@]}"
echo "[ORRH PLUGINS] Found $PLUGIN_COUNT plugin(s)."

### FUNCTION: base64 encode a file ###
base64_encode() {
    if command -v base64 >/dev/null 2>&1; then
        base64 -w 0 "$1"
    else
        # Fallback: POSIX-friendly base64 via openssl
        openssl base64 -A -in "$1"
    fi
}

### CREATE TEMP FILES ###
PLUGIN_LOADS_TEMP="$(mktemp)"

for plugin_path in "${PLUGINS[@]}"; do
    PLUGIN_B64=$(base64_encode "$plugin_path")
    echo "AddModule(\"$PLUGIN_B64\")" >> "$PLUGIN_LOADS_TEMP"
done

### GENERATE FINAL LOADER CONTENT ###
LOADER_CONTENT_TEMP="$(mktemp)"
if [[ -s "$PLUGIN_LOADS_TEMP" ]]; then
    sed "/\[\[plugins\]\]/ {
        r $PLUGIN_LOADS_TEMP
        d
    }" "$LOADER_TEMPLATE" > "$LOADER_CONTENT_TEMP"
else
    sed "s/\[\[plugins\]\]//" "$LOADER_TEMPLATE" > "$LOADER_CONTENT_TEMP"
fi

# Replace __CLIENT__ placeholder
sed -i "s/__CLIENT__/$CLIENT/g" "$LOADER_CONTENT_TEMP"

### INJECT LOADER INTO EACH CLIENT'S host.lua FILE ###
if [[ -d "$CLIENTS_DIR" ]]; then
    for client_dir in "$CLIENTS_DIR"/*; do
        if [[ -d "$client_dir" && -f "$client_dir/scripts/host.lua.template" ]]; then
            # Copy template to host.lua
            cp "$client_dir/scripts/host.lua.template" "$client_dir/scripts/host.lua"

            # Append loader content
            {
                echo ""
                cat "$LOADER_CONTENT_TEMP"
                echo ""
            } >> "$client_dir/scripts/host.lua"
        fi
    done
else
    echo "[ORRH PLUGINS] Warning: Clients directory not found: $CLIENTS_DIR"
fi

# Clean up
rm -f "$PLUGIN_LOADS_TEMP" "$LOADER_CONTENT_TEMP"

echo "[ORRH PLUGINS] Plugin setup completed. Injected into all client host.lua files."

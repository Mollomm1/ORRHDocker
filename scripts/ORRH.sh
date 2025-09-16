#!/usr/bin/env bash

# Exit immediately on error or undefined variable
set -eu

# =============================
# ENVIRONMENT CONFIGURATION
# =============================

export WINEPREFIX="/config/.wine"
export WINEDEBUG=-all
export SDL_AUDIODRIVER=dummy
export XDG_RUNTIME_DIR="/tmp/sockets"
export DXVK_LOG_LEVEL=none

# Disable Wine audio driver to prevent conflicts
wine reg add "HKCU\\Software\\Wine\\Drivers" /v Audio /d "null" /f >/dev/null 2>&1

# =============================
# CLEANUP PREVIOUS RUN ARTIFACTS
# =============================

# Ensure log directories exist
mkdir -p "/config/.wine/drive_c/users/abc/AppData/Local/Roblox/logs/" \
         "/config/.wine/drive_c/users/abc/AppData/Local/ORRbxH/logs/" \
         "/config/.wine/drive_c/users/abc/AppData/Local/OnlyRetroRobloxHere" 2>/dev/null || true

# Clear old logs and app data
rm -rf "/config/.wine/drive_c/users/abc/AppData/Local/ORRbxH/logs/"* \
       "/config/.wine/drive_c/users/abc/AppData/Local/OnlyRetroRobloxHere"/*

# =============================
# DISPLAY STARTUP BANNER
# =============================

echo "
-----------------------------------------------------
                 ORRHDOCKER
-----------------------------------------------------
"

# =============================
# LAUNCH SERVICES & GAME SERVER
# =============================

# Default client version (can be overridden via env var)
: "${CLIENT:=2013L}"

# Start FastAPI web server for health/status endpoints
(cd /config/scripts && python3 -m uvicorn server:app --host 0.0.0.0 --port 3000 --log-level critical) >/dev/null 2>&1 &

# Load any required plugins or mods
/config/scripts/loadplugins.sh

# Start ORRH game server with specified client and map
WINEARCH=win32 \
WINEDLLOVERRIDES="wininet=b;winhttp=n" \
wine /config/OnlyRetroRobloxHere/OnlyRetroRobloxHere.exe \
    --host \
    --client "$CLIENT" \
    --port 53640 \
    --map "Z:\\\\config\\\\map.rbxl"

# Monitor and forward logs
/config/scripts/getlogs.sh

# Wait for all background processes to complete
wait
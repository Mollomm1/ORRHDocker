#!/usr/bin/env bash

source /config/scripts/ORRHActions.sh

export WINEPREFIX=/config/.wine
export WINEDEBUG=-all
export SDL_AUDIODRIVER=dummy
export XDG_RUNTIME_DIR=/tmp/sockets
export DXVK_LOG_LEVEL=none
wine reg add "HKCU\Software\Wine\Drivers" /v Audio /d "null" /f 1>/dev/null # force using no audio driver

# clean logs and app data
mkdir -p /config/.wine/drive_c/users/abc/AppData/Local/Roblox/logs/ 1>/dev/null
rm -rf /config/.wine/drive_c/users/abc/AppData/Local/ORRbxH/logs/* 1>/dev/null
rm -rf /config/.wine/drive_c/users/abc/AppData/Local/OnlyRetroRobloxHere 1>/dev/null

echo "
-----------------------------------------------------

		    ORRHDOCKER		    

-----------------------------------------------------
"

# start everything
(cd /config/scripts && python3 -m uvicorn server:app --host 0.0.0.0 --port 3000 --log-level critical) > /dev/null 2>&1 &
/config/scripts/loadplugins.sh 
WINEDLLOVERRIDES="wininet=b;winihttp=n" wine /config/OnlyRetroRobloxHere/OnlyRetroRobloxHere.exe &
/config/scripts/getlogs.sh & startServer
wait
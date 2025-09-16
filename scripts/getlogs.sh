#!/bin/bash

# on clients older than 2009L logs are kinda weird
if [[ "$CLIENT" == *200[89]* ]]; then
    if [[ "$CLIENT" != "2009L" ]]; then
        echo "[!] CLIENTS UNDER 2009L ARE WEIRD WITH LOGS"
    fi
fi

# Directories to monitor
DIR1="/config/.wine/drive_c/users/abc/AppData/Roaming/Roblox/logs"
DIR2="/config/.wine/drive_c/users/abc/AppData/Local/ORRbxH/logs"

mkdir -p $DIR1 $DIR2

# Associative array to track already tailed files (bash 4+)
declare -A TAILING

tail_if_match() {
    local file="$1"
    # Only proceed if file exists, matches pattern, and not already being tailed
    if [[ -f "$file" && "$(basename "$file")" == *TaskScheduler* && -z "${TAILING[$file]}" ]]; then
        tail -n 0 -F "$file" &
        TAILING["$file"]=1  # Mark as tailed
    fi
    if [[ -f "$file" && "$(basename "$file")" == *runProc* && -z "${TAILING[$file]}" ]]; then
        tail -n 0 -F "$file" &
        TAILING["$file"]=1  # Mark as tailed
    fi
}

# Monitor for create/modify events
inotifywait -m -r -e create,modify --format '%w%f' "$DIR1" "$DIR2" 2>/dev/null |
while IFS= read -r file; do
    tail_if_match "$file"
done
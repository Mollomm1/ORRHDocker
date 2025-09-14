#!/bin/bash
# Script to monitor log directories for new/modified files
# Prints only log lines, handles dynamic file creation, avoids duplicate tailing,
# and tags lines with "ROBLOX Client version ... loaded" context.

mkdir -p /config/.wine/drive_c/users/abc/AppData/Local/ORRbxH/logs /config/.wine/drive_c/users/abc/AppData/Roaming/Roblox/logs

# Directories to monitor
dirs=(
    "/config/.wine/drive_c/users/abc/AppData/Roaming/Roblox/logs"
    "/config/.wine/drive_c/users/abc/AppData/Local/ORRbxH/logs"
)

# Validate directories
valid_dirs=()
for dir in "${dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        valid_dirs+=("$dir")
    else
        echo "Warning: Directory '$dir' does not exist, skipping." >&2
    fi
done
if [[ ${#valid_dirs[@]} -eq 0 ]]; then
    echo "No valid directories to monitor. Exiting." >&2
    exit 1
fi

# Track tail processes and file tags
declare -A tail_pids
declare -A file_tags

cleanup() {
    for pid in "${tail_pids[@]}"; do
        kill "$pid" 2>/dev/null
    done
    exit 0
}
trap cleanup INT TERM

# Function to start tailing a file with tagging logic
start_tail() {
    local file="$1"
    tail -F "$file" 2>/dev/null | while read -r line; do
        # Detect ROBLOX Client version line
        if [[ "$line" =~ ROBLOX[[:space:]]+Client[[:space:]]+version.*loaded ]]; then
            file_tags["$file"]="$line"
            echo "$line"
        else
            # If tag exists, append it to the line
            if [[ -n "${file_tags[$file]}" ]]; then
                echo "$line [${file_tags[$file]}]"
            else
                echo "$line"
            fi
        fi
    done &
    tail_pids["$file"]=$!
}

# Tail existing files
for dir in "${valid_dirs[@]}"; do
    find "$dir" -type f | while read -r file; do
        if [[ -f "$file" ]]; then
            start_tail "$file"
        fi
    done
done

# Watch for new files
inotifywait -m -r -e create,moved_to --format '%w%f %e' "${valid_dirs[@]}" 2>/dev/null | while read -r line; do
    event="${line##* }"
    path="${line% *}"

    [[ ! "$event" =~ CREATE|MOVED_TO ]] && continue
    [[ ! -f "$path" ]] && continue

    if [[ -n "${tail_pids[$path]}" ]] && kill -0 "${tail_pids[$path]}" 2>/dev/null; then
        continue
    fi

    start_tail "$path"
done

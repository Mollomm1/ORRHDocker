#!/bin/bash

#
# set launcher config and also make things like clicking buttons and stuff lol
#

wait_window() {
  local name="$1"
  local timeout="${2:-15}"
  local interval=0.5
  local elapsed=0
  local winid="Only Retro Roblox Here"

  while (( $(echo "$elapsed < $timeout" | bc -l) )); do
    # use xdotool search --name --limit 1 for the first matching window
    winid=$(xdotool search --name --limit 1 --name "$name" 2>/dev/null | head -n1 || true)
    if [[ -n "$winid" ]]; then
      printf '%s' "$winid"
      return 0
    fi
    sleep "$interval"
    elapsed=$(echo "$elapsed + $interval" | bc -l)
  done

  # timed out
  return 1
}

startServer() {
  local winname="Only Retro Roblox Here"
  local ORRH_WIN_ID
  export CLIENT=${CLIENT:-"2013L"}

  # wait up to 20 seconds for orrh launcher to appear
  ORRH_WIN_ID=$(wait_window "$winname" 20) || {
    echo "Error: window \"$winname\" not found within timeout." >&2
    return 1
  }

  sleep 1

  # helper: convert version tags like 2007E, 2010E, 2013L to comparable numeric keys
  ver_key() {
    local v=$1
    # year = first 4 chars, suffix = rest (E/M/L)
    local year=${v:0:4}
    local suf=${v:4}
    # map suffix to numeric: E=0, M=1, L=2 so ordering E < M < L within a year
    local sufnum=0
    case "$suf" in
      E) sufnum=0 ;;
      M) sufnum=1 ;;
      L) sufnum=2 ;;
      *) sufnum=0 ;;
    esac
    # produce a numeric key: year*10 + sufnum (e.g., 2010E -> 20100)
    printf '%d' $((year * 10 + sufnum))
  }

  # decide whether to enable "no render" (only for clients after 2010E)
  local cutoff_key
  cutoff_key=$(ver_key "2010E")
  local client_key
  client_key=$(ver_key "$CLIENT")

  # Set client version by clicking the appropriate coordinates
  case "$CLIENT" in
    "2007E")      xdotool mousemove --window "$ORRH_WIN_ID" 600 363 && xdotool click 1 ;;
    "2007E-FakeFeb") xdotool mousemove --window "$ORRH_WIN_ID" 600 375 && xdotool click 1 ;;
    "2007M")      xdotool mousemove --window "$ORRH_WIN_ID" 600 388 && xdotool click 1 ;;
    "2007L")      xdotool mousemove --window "$ORRH_WIN_ID" 600 400 && xdotool click 1 ;;
    "2008E")      xdotool mousemove --window "$ORRH_WIN_ID" 600 412 && xdotool click 1 ;;
    "2008M")      xdotool mousemove --window "$ORRH_WIN_ID" 600 427 && xdotool click 1 ;;
    "2008L")      xdotool mousemove --window "$ORRH_WIN_ID" 600 438 && xdotool click 1 ;;
    "2009E")      xdotool mousemove --window "$ORRH_WIN_ID" 600 450 && xdotool click 1 ;;
    "2009M")      xdotool mousemove --window "$ORRH_WIN_ID" 600 463 && xdotool click 1 ;;
    "2009L")      xdotool mousemove --window "$ORRH_WIN_ID" 600 478 && xdotool click 1 ;;
    "2010E")      xdotool mousemove --window "$ORRH_WIN_ID" 600 489 && xdotool click 1 ;;
    "2010M")      xdotool mousemove --window "$ORRH_WIN_ID" 600 502 && xdotool click 1 ;;
    "2010L")      xdotool mousemove --window "$ORRH_WIN_ID" 600 515 && xdotool click 1 ;;
    "2011E")      xdotool mousemove --window "$ORRH_WIN_ID" 600 529 && xdotool click 1 ;;
    "2011M")      xdotool mousemove --window "$ORRH_WIN_ID" 600 542 && xdotool click 1 ;;
    "2011L")      xdotool mousemove --window "$ORRH_WIN_ID" 600 558 && xdotool click 1 ;;
    "2012E")      xdotool mousemove --window "$ORRH_WIN_ID" 600 568 && xdotool click 1 ;;
    "2012M")      xdotool mousemove --window "$ORRH_WIN_ID" 600 582 && xdotool click 1 ;;
    "2012L")      xdotool mousemove --window "$ORRH_WIN_ID" 600 595 && xdotool click 1 ;;
    "2013E")      xdotool mousemove --window "$ORRH_WIN_ID" 600 608 && xdotool click 1 ;;
    "2013M")      xdotool mousemove --window "$ORRH_WIN_ID" 600 620 && xdotool click 1 ;;
    "2013L")      xdotool mousemove --window "$ORRH_WIN_ID" 600 632 && xdotool click 1 ;;
    *) echo "Unknown CLIENT \"$CLIENT\"" >&2 ;;
  esac

  sleep 0.05

  # Move to Host tab and click
  xdotool mousemove --window "$ORRH_WIN_ID" 50 310
  xdotool click 1

  sleep 0.05

  # If client is after 2010E (client_key > cutoff_key), enable no-render and select map, else keep render but launch the window resizer script and select the map.
  if (( client_key > cutoff_key )); then
    xdotool mousemove --window "$ORRH_WIN_ID" 132 528
    xdotool click 1
  else
    /config/scripts/resizeClient.sh & sleep 0.05
  fi

  sleep 0.05

  # Select map (always click this coordinate)
  xdotool mousemove --window "$ORRH_WIN_ID" 640 670
  xdotool click 1

  sleep 0.05

  # Move to Start Server button and click
  xdotool mousemove --window "$ORRH_WIN_ID" 325 625
  xdotool click 1

  return 0
}

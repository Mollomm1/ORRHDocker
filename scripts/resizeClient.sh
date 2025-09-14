#!/usr/bin/env bash

# resize client window to take less resources.
while true; do
  # run the pipeline but prevent the whole script from exiting on errors
  {
    xdotool search --name "Roblox - " 2>/dev/null | while IFS= read -r id; do
      # validate numeric id
      [[ $id =~ ^[0-9]+$ ]] || continue
      xdotool windowsize "$id" 200 200 >/dev/null 2>&1 || true
    done
  } || true

  sleep 4
done
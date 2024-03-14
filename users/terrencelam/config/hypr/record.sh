#!/usr/bin/env bash

# Dependencies:
# wl-screenrec
# slurp

DATETIME=$(date +"%Y-%m-%d_%I-%M-%S")
VIDEO="${HOME}/Videos/recordings/${DATETIME}.mp4"

record_area() {
    geometry=$(slurp)
    read -r -a geometry_pair <<< "${geometry}"
    # --encode-resolution is a wordaround for https://github.com/russelltg/wl-screenrec/issues/47
    wl-screenrec -g "${geometry}" --encode-resolution "${geometry_pair[1]}" --low-power off -f "${VIDEO}" &> /dev/null
    wl-copy "${VIDEO}"
    notify-send "Recording saved to ${VIDEO}"
}

record() {
    if pgrep -x "wl-screenrec" > /dev/null; then
        notify-send "Stopping recoding"
        pkill -INT -x "wl-screenrec"
    else
        record_area
    fi
}

record

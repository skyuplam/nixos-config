#!/usr/bin/env bash

# kill any running instances if they exist
eww kill

# start a bar for each monitor
monitors=$(hyprctl monitors -j | jq '.[] | .id')
# monitors=$(hyprctl monitors -j | jq '.[] | .id' | wc -l)

for monitor in ${monitors}; do
    eww open bar${monitor}
done

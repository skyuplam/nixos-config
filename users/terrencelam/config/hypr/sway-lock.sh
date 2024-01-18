#!/usr/bin/env bash

# Dependencies:
# imagemagick
# swaylock
# grim

IMAGE=/tmp/i3lock.png
LOCKARGS=""

for OUTPUT in $(hyprctl -j monitors | jq -r '.[] | .name')
do
    IMAGE="/tmp/$OUTPUT-lock.png"
    grim -o "$OUTPUT" "$IMAGE" && \
    convert -scale 2.5% "$IMAGE" -blur 0x5 -scale 4000% "$IMAGE"
    LOCKARGS="${LOCKARGS} --image=${OUTPUT}:${IMAGE}"
    IMAGES="${IMAGES} ${IMAGE}"
done
swaylock $LOCKARGS
rm $IMAGES

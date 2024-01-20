#!/bin/bash

qemu-system-aarch64 -machine virt \
  -cpu max \
  -accel hvf \
  -smp 6 \
  -m 32G \
  -usb \
  -display cocoa \
  -vga std \
  -nic user,id=enp01,ipv6=off

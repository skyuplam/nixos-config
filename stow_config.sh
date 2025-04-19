#!/usr/bin/env bash

stow_config() {
  if [ "$#" -lt 1 ]
  then
    echo "stow_config requires at least 1 argument"
    exit 1
  fi

  local CONFIG_HOME=~/.config
  local TARGET=$CONFIG_HOME/$1

  echo "linking $1 config to $TARGET"
  # Ensure the folder is there
  mkdir -p "$TARGET"
  # Perform unrestricted find all the symbolic links in the folder to execute rm
  # ${pkgs.fd}/bin/fd -u -t l . $TARGET -x rm
  stow -d ./users/terrencelam/config -t "$TARGET" -S "$1"
}

stow_config "$@"

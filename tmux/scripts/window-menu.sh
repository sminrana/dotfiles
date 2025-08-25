#! /bin/bash

tmux list-windows -F '#I:#W' \
  | awk 'BEGIN {ORS=" "} {print $1, NR, "\"select-window -t", $1 "\""}' \
  | xargs tmux display-menu -T "Switch-window"

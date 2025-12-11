#!/bin/bash
alacritty --class bw-quicksearch \
  -t "Bitwarden Quick Search" \
  -o window.dimensions.columns=60 \
  -o window.dimensions.lines=12 \
  -e bw-quicksearch

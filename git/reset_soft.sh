#!/bin/bash

# Set default value if no argument is provided
COMMITS=${1:-1}

# Validate that the argument is a positive integer (greater than 0)
if ! [[ "$COMMITS" =~ ^[0-9]+$ ]] || [ "$COMMITS" -eq 0 ]; then
  echo "Error: Argument must be a positive integer."
  exit 1
fi

# Perform the git reset
git reset --soft HEAD~"$COMMITS"

#!/bin/bash

if [ -n "$GT_ROLE" ]; then
  # Run your command here
  gt prime --hook "$GT_ROLE"
fi

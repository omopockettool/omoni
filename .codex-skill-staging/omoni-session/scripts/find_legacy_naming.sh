#!/bin/sh
set -eu

ROOT="${1:-.}"

echo "Scanning for legacy naming: OMOMoney"
rg -n --hidden --glob '!.git' --glob '!build' --glob '!DerivedData' 'OMOMoney|omomoney' "$ROOT"

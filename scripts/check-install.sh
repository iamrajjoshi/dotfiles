#!/bin/bash
set -euo pipefail

if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
    echo 'Usage: ./scripts/check-install.sh'
    echo 'Check the installed interactive Fish prompt, tool paths, plugins, and enabled tmux configuration.'
    exit 0
fi
[[ $# == 0 ]] || { echo 'Unexpected arguments. Use --help.' >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo 'FAIL: python3 is required for the interactive terminal check.' >&2; exit 1; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/check_install.py"

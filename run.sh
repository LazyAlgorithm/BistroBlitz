#!/usr/bin/env bash
# Builds BistroBlitz and starts it.
# Usage:
#   ./run.sh                      main menu (Solo/Host/Join/Settings)
#   ./run.sh --host               host a multiplayer match straight away
#   ./run.sh --connect 127.0.0.1  join a match at specified IP
#   ./run.sh --editor             open the project in the Tessera editor
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"${BEEFBUILD:-BeefBuild}" -workspace="$project_root" -config=Debug -verbosity=minimal
exec "$project_root/build/Debug_Linux64/BistroBlitz/BistroBlitz" --project "$project_root" "$@"

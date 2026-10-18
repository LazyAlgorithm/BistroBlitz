#!/usr/bin/env bash
# Build a WebAssembly player. --setup installs the matching browser toolchain first.
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
engine_root="${TESSERA_ENGINE:-/home/zerker24/BeefProjects/Tessera}"
setup_web=false
if [ "${1:-}" = --setup ]; then setup_web=true; shift; fi
if [ "$#" -ne 0 ]; then printf '%s\n' 'Usage: tools/build_web.sh [--setup]' >&2; exit 2; fi
if $setup_web; then "$engine_root/tools/web/setup.sh"; fi
web_sdk="${EMSDK:-$HOME/.local/share/tessera-web/emsdk}"
export PATH="$web_sdk/upstream/emscripten:$PATH"
python3 "$engine_root/tools/build_player.py" "$project_root" --platform web --config Release --single-pack --output "$project_root/Builds/BistroBlitz-Web" --replace
python3 "$project_root/tools/validate_web.py" "$project_root/Builds/BistroBlitz-Web"
python3 - "$project_root/Builds/BistroBlitz-Web" <<'PY'
from pathlib import Path
import sys, zipfile
folder=Path(sys.argv[1])
with zipfile.ZipFile(folder.with_suffix('.zip'),'w',zipfile.ZIP_DEFLATED) as output:
    for file in sorted(folder.rglob('*')):
        if file.is_file(): output.write(file,str(Path(folder.name)/file.relative_to(folder)))
print('Web build:',folder)
print('Serve with: python3 -m http.server 8080 --directory '+str(folder))
PY

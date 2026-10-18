#!/usr/bin/env python3
"""Check a real packaged web player; fail rather than accepting a placeholder page."""
import argparse
import json
from pathlib import Path


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package',type=Path)
    args=parser.parse_args()
    root=args.package
    for name in ('index.html','BistroBlitz.js','BistroBlitz.wasm','game.tpak','tessera-net.js','manifest.webmanifest'):
        if not (root/name).is_file() or not (root/name).stat().st_size:
            parser.error('Missing web runtime file: '+name)
    with (root/'BistroBlitz.wasm').open('rb') as wasm:
        if wasm.read(8)!=b'\0asm\x01\0\0\0': parser.error('Invalid WebAssembly module')
    html=(root/'index.html').read_text()
    if 'BistroBlitz.js' not in html or any(token in html for token in ('{{NAME}}','{{SCRIPT}}','{{PACK}}','{{LATER_PACKS}}')): parser.error('Unresolved web shell template')
    if json.loads((root/'manifest.webmanifest').read_text())['orientation']!='landscape':
        parser.error('Expected landscape mobile application manifest')
    if any(root.rglob('*.bf')) or (root/'BistroBlitz.exe').exists(): parser.error('Web package contains development or desktop files')
    print('Web package checks passed: WebAssembly, loader, asset pack and mobile manifest.')


if __name__=='__main__': main()

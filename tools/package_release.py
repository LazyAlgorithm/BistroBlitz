#!/usr/bin/env python3
"""Validate and archive a standalone BistroBlitz runtime package."""
import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', required=True, choices=('linux', 'windows'))
    parser.add_argument('--package', required=True, type=Path)
    parser.add_argument('--archive-only', action='store_true')
    args = parser.parse_args()
    package = args.package.resolve()
    executable = package / ('BistroBlitz.exe' if args.platform == 'windows' else 'BistroBlitz')
    if not executable.is_file() or not (package / 'game.tpak').is_file():
        parser.error('Expected a standalone player and game.tpak')
    if not args.archive_only:
        runtime = 'steam_api64.dll' if args.platform == 'windows' else 'libsteam_api.so'
        if (package / runtime).read_bytes() != (ROOT / 'Libraries' / runtime).read_bytes():
            raise SystemExit('Steamworks runtime missing or mismatched')
        if (package / 'steam_appid.txt').read_text().strip() != '480':
            raise SystemExit('Incorrect Steam test App ID')
        shutil.copy2(ROOT / 'docs/PLAYER-README.txt', package / 'README.txt')
        result = subprocess.run([str(executable), '--headless', '--self-test', '--frames', '5'],
                                cwd=package, capture_output=True, text=True, timeout=120)
        report = result.stdout + result.stderr
        (package / 'validation-kitchen.log').write_text(report, encoding='utf-8')
        print(report)
        if result.returncode or 'BistroBlitz integration checks passed:' not in report:
            raise SystemExit(f'Kitchen validation failed ({result.returncode})')
    else:
        files = sorted(file for file in package.rglob('*') if file.is_file() and file.suffix != '.log')
        if any(file.suffix in ('.bf', '.glb', '.fbx', '.blend') or '.git' in file.parts for file in files):
            raise SystemExit('Source files must not be published in player packages')
        archive = package.with_suffix('.zip')
        with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as output:
            for file in files:
                output.write(file, str(Path(package.name) / file.relative_to(package)))
        print(f'{archive.name}: {archive.stat().st_size} bytes; SHA256 {hashlib.sha256(archive.read_bytes()).hexdigest()}')


if __name__ == '__main__':
    main()

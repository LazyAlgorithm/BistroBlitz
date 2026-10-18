#!/usr/bin/env python3
"""Publish tested runtime ZIPs to the public repository; never publish game source."""
import argparse
import base64
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

REPO = 'LazyAlgorithm/bistro-blitz-releases'
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--packages', required=True, type=Path)
p.add_argument('--source', required=True)
p.add_argument('--engine', required=True)
a = p.parse_args()
if not os.environ.get('GH_TOKEN'):
    raise SystemExit('HUB_RELEASE_TOKEN is missing; packages remain in the private draft staging release.')
if not re.fullmatch(r'[0-9a-f]{40}', a.source):
    p.error('--source must be a full commit hash')
files = [a.packages / f'BistroBlitz-{platform}.zip' for platform in ('Windows', 'Linux')]
for file in files:
    if not file.is_file():
        p.error(f'Missing validated package: {file}')
checksums = a.packages / 'SHA256SUMS.txt'
checksums.write_text(''.join(f'{hashlib.sha256(f.read_bytes()).hexdigest()}  {f.name}\n' for f in files), encoding='utf-8')

def gh(*args, data=None):
    run = subprocess.run(['gh', *args], input=json.dumps(data) if data is not None else None,
                         text=True, capture_output=True, check=True)
    return run.stdout.strip()

manifest = json.dumps({'game_source': a.source, 'engine_release': a.engine,
                       'built_at': datetime.now(timezone.utc).isoformat()}, indent=2) + '\n'
endpoint = f'repos/{REPO}/contents/build.json'
try:
    previous = json.loads(gh('api', endpoint))['sha']
except subprocess.CalledProcessError as error:
    if '404' not in error.stderr:
        raise
    previous = None
body = {'message': 'Record validated player build ' + a.source[:7],
        'content': base64.b64encode(manifest.encode()).decode()}
if previous:
    body['sha'] = previous
commit = json.loads(gh('api', '--method', 'PUT', endpoint, '--input', '-', data=body))['commit']['sha']
tag = 'bistro-blitz-' + datetime.now(timezone.utc).strftime('%Y.%m.%d-%H%M%S') + '-' + a.source[:7]
notes = ('Cooperative kitchen beta: ingredient stations, chopping, cooking and burning, burger/hot dog/salad recipes, '
         'timed orders, combos and round results. Solo, direct networking, Steam friends and audio settings.\n\n'
         'Windows and Linux packages passed deterministic headless kitchen and UI document checks. '
         'Rendered desktop playtesting, audible audio testing and live cross-account Steam testing remain pending. '
         'Uses Steam test App ID 480. Runtime builds only; game source stays private.\n\n'
         f'Private source revision: {a.source}\nEngine release: {a.engine}\n')
gh('release', 'create', tag, *(str(f) for f in files), str(checksums), '--repo', REPO,
   '--target', commit, '--title', 'Bistro Blitz — kitchen beta', '--notes', notes, '--prerelease')
release = json.loads(gh('api', f'repos/{REPO}/releases/tags/{tag}'))
assert {f.name for f in files} | {'SHA256SUMS.txt'} <= {f['name'] for f in release['assets']}
print(release['html_url'])

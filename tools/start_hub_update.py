#!/usr/bin/env python3
"""Merge the approved game catalog entry, then start the Hub Windows/Linux self-update."""
import base64
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
HUB = 'LazyAlgorithm/tessera-hub'


def api(path, payload=None):
    command = ['gh', 'api', path]
    if payload is not None:
        command += ['--method', 'PUT', '--input', '-']
    result = subprocess.run(command, input=json.dumps(payload) if payload is not None else None,
                            text=True, capture_output=True, check=True)
    return json.loads(result.stdout)


def main():
    entry = json.loads((ROOT / 'Distribution/Hub/catalog-entry.json').read_text())
    endpoint = f'repos/{HUB}/contents/src/Data/catalog.json'
    current = api(endpoint)
    catalog = json.loads(base64.b64decode(current['content']))
    existing = next((item for item in catalog['items'] if item['id'] == entry['id']), None)
    if existing is None:
        catalog['items'].append(entry)
    else:
        existing.update(entry)
    content = (json.dumps(catalog, indent=2) + '\n').encode()
    if content != base64.b64decode(current['content']):
        api(endpoint, {'message': 'Add Bistro Blitz kitchen beta to the Hub',
                       'sha': current['sha'], 'branch': 'main',
                       'content': base64.b64encode(content).decode()})
        # The Hub's existing main-push workflow automatically builds and publishes both platforms.
        print(f'Hub catalog updated; self-update started: https://github.com/{HUB}/actions/workflows/build.yml')
    else:
        # No catalog commit means there is no push event; explicitly start the existing workflow.
        subprocess.run(['gh', 'workflow', 'run', 'build.yml', '--repo', HUB, '--ref', 'main',
                        '-f', 'publish=true'], check=True)
        print(f'Hub self-update started: https://github.com/{HUB}/actions/workflows/build.yml')


if __name__ == '__main__':
    main()

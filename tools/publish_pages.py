#!/usr/bin/env python3
"""Publish the validated site to the game's repository's gh-pages branch."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import urllib.request


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--site',type=Path,required=True)
    parser.add_argument('--repo',default='LazyAlgorithm/BistroBlitz')
    parser.add_argument('--source',required=True)
    args=parser.parse_args()
    if args.repo!='LazyAlgorithm/BistroBlitz':parser.error('Unexpected Pages repository')
    if not os.environ.get('GH_TOKEN'):parser.error('HUB_RELEASE_TOKEN is required to publish Pages')
    site=args.site.resolve()
    for name in ('index.html','play/index.html','play/BistroBlitz.wasm','play/game.tpak'):
        if not (site/name).is_file():parser.error('Incomplete validated site: '+name)
    environment=dict(os.environ,GIT_TERMINAL_PROMPT='0')
    def api(method,payload=None):
        command=['gh','api',f'repos/{args.repo}/pages','--method',method]
        if payload is not None:command+=['--input','-']
        result=subprocess.run(command,input=json.dumps(payload) if payload is not None else None,text=True,capture_output=True,env=environment)
        if result.returncode:
            # Pages creation can succeed while gh fails to decode its empty response.
            # Confirm the resulting state instead of reporting a failed deployment.
            if method in ('POST', 'PUT') and 'unexpected end of JSON input' in result.stderr:
                for attempt in range(6):
                    time.sleep(2)
                    try:
                        confirmed = api('GET')
                        if all(confirmed.get(key) == value for key, value in payload.items()):
                            return confirmed
                    except RuntimeError:
                        pass
            raise RuntimeError(result.stderr)
        return json.loads(result.stdout) if result.stdout.strip() else {}
    with tempfile.TemporaryDirectory(prefix='bistro-pages-') as temporary:
        folder=Path(temporary)
        def git(*arguments,check=True):
            return subprocess.run(['git','-c','credential.helper=','-c','credential.helper=!gh auth git-credential',*arguments],cwd=folder,env=environment,check=check,text=True,capture_output=True)
        git('init','-b','gh-pages')
        git('remote','add','origin',f'https://github.com/{args.repo}.git')
        branch=git('ls-remote','--exit-code','--heads','origin','refs/heads/gh-pages',check=False)
        if branch.returncode==0:
            git('fetch','--depth','1','origin','gh-pages')
            git('reset','--hard','FETCH_HEAD')
        elif branch.returncode!=2:raise RuntimeError(branch.stderr)
        for child in folder.iterdir():
            if child.name in ('.git','CNAME'):continue
            if child.is_dir():shutil.rmtree(child)
            else:child.unlink()
        shutil.copytree(site,folder,dirs_exist_ok=True)
        (folder/'build-info.json').write_text(json.dumps({'game_source':args.source},indent=2)+'\n')
        git('config','user.name','github-actions[bot]')
        git('config','user.email','41898282+github-actions[bot]@users.noreply.github.com')
        git('add','--all')
        if git('diff','--cached','--quiet',check=False).returncode:
            git('commit','-m','Publish BistroBlitz web player '+args.source[:7])
            git('push','origin','HEAD:gh-pages')
    desired={'build_type':'legacy','source':{'branch':'gh-pages','path':'/'}}
    try:current=api('GET')
    except RuntimeError as error:
        if '404' not in str(error):raise
        current=api('POST',desired)
    if current.get('build_type')!='legacy' or current.get('source')!={'branch':'gh-pages','path':'/'}:
        current=api('PUT',desired)
    url=current.get('html_url','https://lazyalgorithm.github.io/BistroBlitz/')
    print('Pages configured from gh-pages:',url,flush=True)
    # Check the deployed version, not an older successful page in the CDN.
    deadline=time.monotonic()+240
    last_error='Pages deployment is pending'
    while time.monotonic()<deadline:
        try:
            with urllib.request.urlopen(url+'build-info.json?source='+args.source,timeout=15) as response:
                deployed=json.load(response)
            if deployed.get('game_source')!=args.source:
                raise RuntimeError('Pages is still serving the previous build')
            for path in ('index.html','play/index.html','play/BistroBlitz.js','play/game.tpak'):
                with urllib.request.urlopen(url+path,timeout=15) as response:
                    if response.status!=200 or not response.read(16):
                        raise RuntimeError('Missing published file: '+path)
            with urllib.request.urlopen(url+'play/BistroBlitz.wasm',timeout=15) as response:
                if response.read(4)!=b'\0asm':raise RuntimeError('Invalid published WebAssembly')
            print('Live web build verified:',url+'play/',flush=True)
            return
        except (OSError,ValueError,RuntimeError) as error:
            last_error=str(error)
            time.sleep(10)
    raise RuntimeError('Could not verify the live web build: '+last_error)


if __name__=='__main__':main()

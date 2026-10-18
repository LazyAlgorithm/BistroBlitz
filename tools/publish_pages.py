#!/usr/bin/env python3
"""Publish the validated site to this private source repository's gh-pages branch."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


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
        if result.returncode:raise RuntimeError(result.stderr)
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
    print('Pages published from gh-pages:',current.get('html_url','https://lazyalgorithm.github.io/BistroBlitz/'))


if __name__=='__main__':main()

#!/usr/bin/env python3
"""Stage the repository's game page and a validated browser player for GitHub Pages."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT=Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--archive',type=Path)
    group.add_argument('--package',type=Path)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    if args.output.exists() and any(args.output.iterdir()):
        parser.error('Output must be empty; choose a new staging directory.')
    with tempfile.TemporaryDirectory() as temporary:
        package=args.package
        if args.archive:
            with zipfile.ZipFile(args.archive) as archive:
                for entry in archive.infolist():
                    relative=Path(entry.filename)
                    if relative.is_absolute() or '..' in relative.parts:
                        parser.error('Invalid archive entry')
                archive.extractall(temporary)
            package=Path(temporary)/'BistroBlitz-Web'
        subprocess.run([sys.executable,str(ROOT/'tools/validate_web.py'),str(package)],check=True)
        args.output.mkdir(parents=True,exist_ok=True)
        shutil.copytree(package,args.output/'play')
        shutil.copy2(ROOT/'docs/index.html',args.output/'index.html')
        artwork=args.output/'artwork'
        artwork.mkdir()
        for name in ('hub-cover.jpg','hub-icon.jpg'):
            shutil.copy2(ROOT/'Art/Branding'/name,artwork/name)
        (args.output/'.nojekyll').write_text('')
        print('Pages site staged at',args.output)


if __name__=='__main__':main()

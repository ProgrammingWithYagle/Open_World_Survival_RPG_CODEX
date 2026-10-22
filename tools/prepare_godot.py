"""Download the pinned official Godot editor used by local and CI validation."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import stat
import urllib.request
import zipfile
from build_release_metadata import github_release

ROOT=Path(__file__).resolve().parents[1]
VERSION='4.5.1-stable'

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--platform',choices=['windows','linux'],default='windows' if os.name=='nt' else 'linux');args=parser.parse_args()
    release=github_release('godotengine/godot-builds',VERSION)
    suffix='_win64.exe.zip' if args.platform=='windows' else '_linux.x86_64.zip'
    asset=next(entry for entry in release['assets'] if entry['name'].endswith(suffix) and 'mono' not in entry['name'])
    output=ROOT/'.tools/godot/editor';output.mkdir(parents=True,exist_ok=True)
    target=output/asset['name']
    if not target.exists():
        with urllib.request.urlopen(asset['browser_download_url'],timeout=120) as response:target.write_bytes(response.read())
    digest=hashlib.sha256(target.read_bytes()).hexdigest()
    if asset.get('digest') and asset['digest']!='sha256:'+digest:raise RuntimeError('Official editor download digest mismatch')
    with zipfile.ZipFile(target) as archive:
        # Official editor archives contain only executables and their directory.
        for member in archive.infolist():
            destination=(output/member.filename).resolve()
            if not destination.is_relative_to(output.resolve()):raise RuntimeError('Unsafe editor archive path')
        archive.extractall(output)
    executable=next(output.rglob('*_console.exe')) if args.platform=='windows' else next(output.glob('Godot*_linux.x86_64'))
    executable.chmod(executable.stat().st_mode|stat.S_IXUSR|stat.S_IXGRP|stat.S_IXOTH)
    (output/'receipt.json').write_text(json.dumps({'source':asset['browser_download_url'],'sha256':digest,'executable':executable.relative_to(ROOT).as_posix()},indent=2)+'\n',encoding='utf-8')
    print(executable)

if __name__=='__main__':main()

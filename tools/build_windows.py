"""Export, stamp and package a complete offline Windows build."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import zipfile
from urllib.parse import unquote,urlsplit

ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--godot',type=Path,required=True);parser.add_argument('--skip-dependencies',action='store_true');args=parser.parse_args()
    if not args.skip_dependencies:
        from fetch_export_templates import main as templates
        from prepare_windows_export import main as resources
        templates();resources()
    from check_godot import run
    run(args.godot,['--editor','--import','--quit'],'export-import')
    output=ROOT/'exports/windows';output.mkdir(parents=True,exist_ok=True)
    exe=output/'The Mossbound Atlas.exe'
    run(args.godot,['--export-release','Windows Desktop',str(exe)],'windows-export')
    version=json.loads((ROOT/'godot/data/releases.json').read_text(encoding='utf-8'))[0]['version']
    subprocess.run([str(ROOT/'.tools/rcedit/rcedit.exe'),str(exe),'--set-icon',str(ROOT/'godot/art/app_icon.ico'),
                    '--set-file-version',version+'.0','--set-product-version',version+'.0',
                    '--set-version-string','ProductName','The Mossbound Atlas',
                    '--set-version-string','FileDescription','The Mossbound Atlas - Wilderness RPG',
                    '--set-version-string','CompanyName','ProgrammingWithYagle',
                    '--set-version-string','LegalCopyright','ProgrammingWithYagle'],check=True,timeout=30)
    mapping={ROOT/'docs/PLAYING.md':output/'READ ME FIRST.md',ROOT/'CHANGELOG.md':output/'CHANGELOG.md',ROOT/'LICENSE':output/'licenses/Game-MIT.txt'}
    for folder in [ROOT/'third_party',ROOT/'godot/fonts']:
        mapping.update({file:output/'licenses'/file.name for file in folder.glob('*.txt')})
    mapping.update({file:output/'wiki'/file.name for file in (ROOT/'docs/wiki').glob('*.md')})
    for name in ['DESIGN_RESEARCH.md','ASSETS.md','IMPLEMENTATION_STATUS.md','PROJECT.md','ORIGINAL_AUDIO_SCORE.json']:
        mapping[ROOT/'docs'/name]=output/name
    for source,name in [('art/source/provenance.json','art.json'),('art/animation_manifest.json','animation.json'),('audio/audio_manifest.json','audio.json'),('fonts/provenance.json','fonts.json')]:
        mapping[ROOT/'godot'/source]=output/'provenance'/name
    for source,destination in mapping.items():
        destination.parent.mkdir(parents=True,exist_ok=True)
        if source.suffix!='.md':shutil.copyfile(source,destination);continue
        def link(match):
            parts=urlsplit(match[1])
            if parts.scheme or not parts.path:return match[0]
            target=(source.parent/unquote(parts.path)).resolve()
            if target in mapping:href=os.path.relpath(mapping[target],destination.parent).replace('\\','/')
            else:href='https://github.com/ProgrammingWithYagle/Open_World_Survival_RPG_CODEX/blob/main/'+target.relative_to(ROOT).as_posix()
            return ']('+href+('#'+parts.fragment if parts.fragment else '')+')'
        destination.write_text(re.sub(r'\]\(([^)]+)\)',link,source.read_text(encoding='utf-8')),encoding='utf-8')
    revision=subprocess.run(['git','rev-parse','HEAD'],cwd=ROOT,capture_output=True,text=True,check=True).stdout.strip()
    files=[file for file in output.rglob('*') if file.is_file() and file.name not in ['manifest.json','SHA256SUMS.txt']]
    manifest={'title':'The Mossbound Atlas','version':version,'source_commit':revision,'engine':'Godot 4.5.1','platform':'Windows x86_64',
              'files':{file.relative_to(output).as_posix():{'bytes':file.stat().st_size,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()} for file in sorted(files)}}
    (output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    (output/'SHA256SUMS.txt').write_text(''.join(info['sha256']+'  '+name+'\n' for name,info in manifest['files'].items()),encoding='utf-8')
    archive=ROOT/'exports'/f'The-Mossbound-Atlas-{version}-Windows-x64.zip'
    with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as bundle:
        for file in sorted(output.rglob('*')):
            if file.is_file():bundle.write(file,'The Mossbound Atlas/'+file.relative_to(output).as_posix())
    digest=hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix('.zip.sha256').write_text(digest+'  '+archive.name+'\n',encoding='utf-8')
    print(json.dumps({'archive':str(archive),'bytes':archive.stat().st_size,'sha256':digest,'source_commit':revision},indent=2))

if __name__=='__main__':main()

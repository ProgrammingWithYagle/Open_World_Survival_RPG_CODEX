"""Publish the generated player Wiki to an already initialized GitHub Wiki."""
import argparse
import json
from pathlib import Path
import re
import subprocess

ROOT=Path(__file__).resolve().parents[1]
REPO='https://github.com/ProgrammingWithYagle/Open_World_Survival_RPG_CODEX'

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--checkout',type=Path,required=True);parser.add_argument('--push',action='store_true');args=parser.parse_args()
    checkout=args.checkout.resolve()
    if not (checkout/'.git').is_dir():raise SystemExit('Initialize and clone the GitHub Wiki first.')
    sources=sorted((ROOT/'docs/wiki').glob('*.md'));names=[]
    def link(match):
        target=match[1]
        if target.startswith('../'):target=REPO+'/blob/main/docs/'+target[3:]
        elif not target.startswith(('https://','http://','#')):target=re.sub(r'\.md(?=#|$)','',target)
        return ']('+target+')'
    for source in sources:
        body=re.sub(r'\]\(([^)]+)\)',link,source.read_text(encoding='utf-8'))
        (checkout/source.name).write_text(body,encoding='utf-8');names.append(source.name)
    sidebar='# The Mossbound Atlas\n\n'+''.join(f'- [{path.stem.replace("-"," ")}]({path.stem})\n' for path in sources)
    (checkout/'_Sidebar.md').write_text(sidebar,encoding='utf-8');names.append('_Sidebar.md')
    (checkout/'_Footer.md').write_text(f'[Source]({REPO}) · [Downloads]({REPO}/releases) · [Report an issue]({REPO}/issues)\n',encoding='utf-8');names.append('_Footer.md')
    if not args.push:
        print(f'Prepared {len(sources)} Wiki pages in {checkout}');return
    def git(*arguments,**kwargs):return subprocess.run(['git',*arguments],cwd=checkout,check=True,text=True,**kwargs)
    git('add','--',*names)
    changed=subprocess.run(['git','diff','--cached','--quiet'],cwd=checkout).returncode!=0
    if changed:
        author=subprocess.run(['git','config','user.name'],cwd=ROOT,capture_output=True,text=True,check=True).stdout.strip()
        email=subprocess.run(['git','config','user.email'],cwd=ROOT,capture_output=True,text=True,check=True).stdout.strip()
        git('-c','user.name='+author,'-c','user.email='+email,'commit','-m','Publish The Mossbound Atlas player Wiki')
        git('push','origin','HEAD')
    revision=git('rev-parse','HEAD',capture_output=True).stdout.strip()
    receipt={'url':REPO+'/wiki','commit':revision,'pages':names}
    (ROOT/'verification/wiki_publication.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(receipt,indent=2))

if __name__=='__main__':main()

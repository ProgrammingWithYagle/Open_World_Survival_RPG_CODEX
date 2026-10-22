"""Prepare an original game icon and official resource-editor dependency."""
import hashlib
import json
from pathlib import Path
import urllib.request
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]

def main():
    icon=Image.open(ROOT/'godot/art/icons/relic.png').convert('RGBA')
    icon.resize((256,256),Image.Resampling.NEAREST).save(ROOT/'godot/art/app_icon.png')
    icon.resize((256,256),Image.Resampling.NEAREST).save(ROOT/'godot/art/app_icon.ico',sizes=[(16,16),(32,32),(48,48),(64,64),(128,128),(256,256)])
    output=ROOT/'.tools/rcedit';output.mkdir(parents=True,exist_ok=True)
    request=urllib.request.Request('https://api.github.com/repos/electron/rcedit/releases/tags/v2.0.0',headers={'User-Agent':'Mossbound-build-tools'})
    with urllib.request.urlopen(request,timeout=30) as response:release=json.load(response)
    asset=next(x for x in release['assets'] if x['name']=='rcedit-x64.exe')
    target=output/'rcedit.exe'
    if not target.exists():
        with urllib.request.urlopen(asset['browser_download_url'],timeout=60) as response:target.write_bytes(response.read())
    digest=hashlib.sha256(target.read_bytes()).hexdigest()
    if digest!='3e7801db1a5edbec91b49a24a094aad776cb4515488ea5a4ca2289c400eade2a':raise RuntimeError('Pinned resource editor checksum mismatch')
    if asset.get('digest') and asset['digest']!='sha256:'+digest:raise RuntimeError('Resource editor download digest mismatch')
    (output/'receipt.json').write_text(json.dumps({'source':asset['browser_download_url'],'version':release['tag_name'],'sha256':digest},indent=2)+'\n')
    print(target)

if __name__=='__main__':main()

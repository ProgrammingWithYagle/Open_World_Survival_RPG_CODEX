"""Vendor the regional Noto CJK faces and their OFL license from the official repository."""
import hashlib
import json
import urllib.request
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/fonts'
SOURCES={
 'NotoSansCJKsc-Regular.otf':'Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf',
 'NotoSansCJKtc-Regular.otf':'Sans/OTF/TraditionalChinese/NotoSansCJKtc-Regular.otf',
 'NotoSansCJKjp-Regular.otf':'Sans/OTF/Japanese/NotoSansCJKjp-Regular.otf',
 'OFL.txt':'Sans/LICENSE',
 'AtkinsonHyperlegible-Regular.ttf':'https://raw.githubusercontent.com/google/fonts/main/ofl/atkinsonhyperlegible/AtkinsonHyperlegible-Regular.ttf',
 'Atkinson-OFL.txt':'https://raw.githubusercontent.com/google/fonts/main/ofl/atkinsonhyperlegible/OFL.txt',
 'Lora-Regular.ttf':'https://raw.githubusercontent.com/google/fonts/main/ofl/lora/Lora%5Bwght%5D.ttf',
 'Lora-OFL.txt':'https://raw.githubusercontent.com/google/fonts/main/ofl/lora/OFL.txt',
}
def main():
    OUT.mkdir(parents=True,exist_ok=True)
    receipts=[]
    for name,path in SOURCES.items():
        url=path if path.startswith('https://') else 'https://raw.githubusercontent.com/notofonts/noto-cjk/main/'+path
        target=OUT/name
        if not target.exists():
            request=urllib.request.Request(url,headers={'User-Agent':'MossboundAtlas-build'})
            with urllib.request.urlopen(request,timeout=60) as response:body=response.read()
            if name.endswith('.otf') and not body.startswith(b'OTTO'):raise ValueError('Invalid OpenType download')
            target.write_bytes(body)
        body=target.read_bytes()
        receipts.append({'file':name,'source':url,'bytes':len(body),'sha256':hashlib.sha256(body).hexdigest(),'license':'SIL Open Font License 1.1'})
        print(name,len(body))
    (OUT/'provenance.json').write_text(json.dumps(receipts,indent=2)+'\n')
if __name__=='__main__':main()

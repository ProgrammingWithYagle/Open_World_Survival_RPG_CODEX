"""Fetch only official Windows templates from Godot's export ZIP using HTTP ranges."""
import io
import json
import hashlib
from pathlib import Path
import urllib.request
import zipfile
import zlib
from build_release_metadata import github_release

ROOT=Path(__file__).resolve().parents[1]
VERSION='4.5.1-stable'

class RemoteFile(io.RawIOBase):
    def __init__(self,url,size):self.url=url;self.size=size;self.position=0;self.requests=0
    def readable(self):return True
    def seekable(self):return True
    def tell(self):return self.position
    def seek(self,offset,whence=0):
        self.position=offset if whence==0 else self.position+offset if whence==1 else self.size+offset
        return self.position
    def read(self,size=-1):
        size=min(size if size>=0 else self.size-self.position,self.size-self.position)
        if size<=0:return b''
        request=urllib.request.Request(self.url,headers={'Range':f'bytes={self.position}-{self.position+size-1}','User-Agent':'Mossbound-build-tools'})
        with urllib.request.urlopen(request,timeout=120) as response:
            if response.status!=206:raise RuntimeError('Download host did not honor the byte range; refusing an unexpected full archive download')
            data=response.read()
        self.position+=len(data);self.requests+=1
        return data

def main():
    release=github_release('godotengine/godot-builds',VERSION)
    asset=next(x for x in release['assets'] if x['name'].endswith('_export_templates.tpz'))
    output=ROOT/'.tools/godot/templates/4.5.1.stable';output.mkdir(parents=True,exist_ok=True)
    receipt=[]
    print('Reading official export archive directory',flush=True)
    with zipfile.ZipFile(RemoteFile(asset['browser_download_url'],asset['size'])) as archive:
        for name in ['version.txt','windows_release_x86_64.exe','windows_debug_x86_64.exe']:
            entry=next(x for x in archive.infolist() if x.filename.split('/')[-1]==name)
            target=output/name
            if not target.exists() or target.stat().st_size!=entry.file_size:
                print('Downloading '+name,flush=True)
                data=archive.read(entry)
                if len(data)!=entry.file_size:raise RuntimeError('Truncated template')
                target.write_bytes(data)
            if zlib.crc32(target.read_bytes())!=entry.CRC:raise RuntimeError('Template CRC does not match the official archive')
            receipt.append({'file':name,'bytes':target.stat().st_size,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'crc32':f'{entry.CRC:08x}'})
    if (output/'version.txt').read_text().strip()!='4.5.1.stable':raise RuntimeError('Unexpected export template version')
    receipt={'source':asset['browser_download_url'],'release':release['html_url'],'templates':receipt}
    (output/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print('Official Windows templates ready',flush=True)

if __name__=='__main__':main()

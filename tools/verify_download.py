"""Verify every ZIP member, then launch a freshly extracted standalone game."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import uuid
import zipfile
from urllib.parse import unquote,urlsplit

ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser();parser.add_argument('archive',type=Path);args=parser.parse_args()
    archive=args.archive.resolve()
    expected=archive.with_suffix('.zip.sha256').read_text(encoding='utf-8').split()[0]
    assert hashlib.sha256(archive.read_bytes()).hexdigest()==expected,'ZIP digest mismatch'
    target=ROOT/'exports'/('verified_'+uuid.uuid4().hex[:8]);target.mkdir()
    with zipfile.ZipFile(archive) as bundle:
        assert bundle.testzip() is None,'ZIP CRC failure'
        names=bundle.namelist();assert len(names)==len(set(names)),'Duplicate ZIP member'
        for member in bundle.infolist():
            assert (target/member.filename).resolve().is_relative_to(target.resolve()),'Unsafe archive path'
        bundle.extractall(target)
    install=target/'The Mossbound Atlas'
    manifest=json.loads((install/'manifest.json').read_text(encoding='utf-8'))
    actual={path.relative_to(install).as_posix() for path in install.rglob('*') if path.is_file()}
    assert actual==set(manifest['files'])|{'manifest.json','SHA256SUMS.txt'},'Unexpected or missing package file'
    for name,info in manifest['files'].items():
        file=install/name
        assert file.stat().st_size==info['bytes'] and hashlib.sha256(file.read_bytes()).hexdigest()==info['sha256'],name
    for document in install.rglob('*.md'):
        for link in re.findall(r'\]\(([^)]+)\)',document.read_text(encoding='utf-8')):
            parts=urlsplit(link)
            if not parts.scheme and parts.path:assert (document.parent/unquote(parts.path)).exists(),f'Broken packaged link: {document.name}: {link}'
    result=subprocess.run([str(install/'The Mossbound Atlas.exe'),'--headless','--','--smoke=1'],cwd=install,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=60)
    output=result.stdout+result.stderr
    report={'archive':archive.name,'sha256':expected,'members':len(actual),'source_commit':manifest['source_commit'],'exit_code':result.returncode,'output':output}
    (ROOT/'verification/download_verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(output)
    assert result.returncode==0 and 'EXPORT_SMOKE passed' in output and 'ERROR' not in output,'Standalone smoke test failed'
    print(f'Verified {len(actual)} files and standalone startup from fresh extraction.')

if __name__=='__main__':main()

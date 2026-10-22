"""Check repository Markdown links and release/version agreement without network."""
import json
from pathlib import Path
import re
from urllib.parse import unquote,urlsplit

ROOT=Path(__file__).resolve().parents[1]

def main():
    files=[ROOT/'README.md',ROOT/'CHANGELOG.md',*(ROOT/'docs').rglob('*.md'),ROOT/'godot/art/README.md']
    failures=[]
    for source in files:
        for match in re.finditer(r'\[[^\]\n]+\]\(([^\s)]+)\)',source.read_text(encoding='utf-8')):
            link=match[1];parts=urlsplit(link)
            if parts.scheme or not parts.path:continue
            target=(source.parent/unquote(parts.path)).resolve()
            if not target.is_relative_to(ROOT) or not target.exists():failures.append(f'{source.relative_to(ROOT)}: {link}')
    version=json.loads((ROOT/'godot/data/releases.json').read_text(encoding='utf-8'))[0]['version']
    assert f'config/version="{version}"' in (ROOT/'godot/project.godot').read_text(encoding='utf-8')
    assert f'const VERSION := "{version}"' in (ROOT/'godot/scripts/core/content.gd').read_text(encoding='utf-8')
    assert not failures,'Broken local links:\n'+'\n'.join(failures)
    print(f'Validated links in {len(files)} documents and consistent version {version}.')

if __name__=='__main__':main()

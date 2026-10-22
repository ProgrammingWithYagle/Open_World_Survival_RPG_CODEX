"""Bounded engine import and gameplay checks; any engine error fails CI."""
import argparse
import os
from pathlib import Path
import re
import subprocess

ROOT=Path(__file__).resolve().parents[1]

def run(godot,args,label,marker=None):
    result=subprocess.run([str(godot),'--headless','--path',str(ROOT/'godot'),*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=120)
    output=result.stdout+result.stderr
    (ROOT/'verification').mkdir(exist_ok=True)
    (ROOT/'verification'/f'{label}.log').write_text(output,encoding='utf-8')
    if result.returncode or re.search(r'(?:SCRIPT ERROR|SHADER ERROR|^ERROR:|FAIL:)',output,re.M) or (marker and not re.search(marker,output)):
        print(output[-6000:])
        raise SystemExit(f'Godot check failed: {label}')
    print(output.strip() if marker else label+': passed')

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--godot',type=Path,default=os.environ.get('GODOT','godot'));args=parser.parse_args()
    run(args.godot,['--editor','--import','--quit'],'ci-import')
    run(args.godot,['res://tests/TestSuite.tscn','--quit-after','1200'],'ci-runtime',r'RUNTIME_TESTS \d+ checks; 0 failures')
    run(args.godot,['res://tests/IntegrationSuite.tscn','--quit-after','1200'],'ci-integration',r'INTEGRATION_TESTS \d+ checks; 0 failures')

if __name__=='__main__':main()

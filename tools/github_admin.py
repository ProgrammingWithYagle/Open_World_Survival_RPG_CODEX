"""Authorized repository administration through the user's Git credential helper.

Credentials stay in process memory. They are never written to this repository,
passed on a command line, or printed. The GitHub connector handles ordinary
repository reads; this helper supplies release/ruleset/Project administration.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import urllib.error
import urllib.request

REPO='ProgrammingWithYagle/Open_World_Survival_RPG_CODEX'

def credential(prefer_cli=False):
    cli=Path(__file__).resolve().parents[1]/'.tools/github-cli/bin/gh.exe'
    if prefer_cli and cli.exists():
        result=subprocess.run([str(cli),'auth','token','--hostname','github.com'],text=True,capture_output=True)
        if result.returncode==0 and result.stdout.strip():return result.stdout.strip()
    env=os.environ.copy()
    env.update(GIT_TERMINAL_PROMPT='0',GCM_INTERACTIVE='never')
    result=subprocess.run(['git','credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True,env=env,check=True)
    values=dict(line.split('=',1) for line in result.stdout.splitlines() if '=' in line)
    if not values.get('password'):raise RuntimeError('GitHub credential helper returned no credential')
    return values['password']

def api(path,method='GET',payload=None,raw=None):
    url=path if path.startswith('https://') else 'https://api.github.com'+path
    if not url.startswith(('https://api.github.com/','https://uploads.github.com/')):raise ValueError('Unexpected GitHub API host')
    headers={'Authorization':'Bearer '+credential(url=='https://api.github.com/graphql'),'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28','User-Agent':'Mossbound-release-tools'}
    body=None
    if payload is not None:body=json.dumps(payload,ensure_ascii=False).encode();headers['Content-Type']='application/json'
    if raw is not None:body=Path(raw).read_bytes();headers['Content-Type']='application/octet-stream'
    request=urllib.request.Request(url,data=body,headers=headers,method=method)
    try:
        with urllib.request.urlopen(request,timeout=90) as response:
            data=response.read()
            return (json.loads(data) if data else {}),dict(response.headers)
    except urllib.error.HTTPError as error:
        # API errors do not include the Authorization request header.
        raise RuntimeError(f'GitHub HTTP {error.code}: {error.read().decode()[:1000]}') from None

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('action',choices=['status','request'])
    parser.add_argument('--path');parser.add_argument('--method',default='GET')
    parser.add_argument('--body-file',type=Path);parser.add_argument('--upload-file',type=Path)
    args=parser.parse_args()
    if args.action=='status':
        user,headers=api('/user')
        repo,_=api('/repos/'+REPO)
        print(json.dumps({'login':user['login'],'scopes':headers.get('X-OAuth-Scopes',headers.get('x-oauth-scopes','unavailable')),'permissions':repo.get('permissions'),'default_branch':repo['default_branch']},indent=2))
    else:
        if not args.path:parser.error('--path required')
        payload=json.loads(args.body_file.read_text(encoding='utf-8')) if args.body_file else None
        data,_=api(args.path,args.method,payload,args.upload_file)
        print(json.dumps(data,ensure_ascii=False,indent=2))

if __name__=='__main__':main()

"""Read public dependency metadata using CI's read-only GitHub API allowance."""
import json
import os
import urllib.request


def github_release(repository, tag):
    headers = {'User-Agent': 'Mossbound-build-tools', 'Accept': 'application/vnd.github+json'}
    token = os.environ.get('GITHUB_TOKEN')
    if token:
        headers['Authorization'] = 'Bearer ' + token
    request = urllib.request.Request(
        'https://api.github.com/repos/' + repository + '/releases/tags/' + tag,
        headers=headers,
    )
    # This request only reads release JSON. Asset downloads use separate,
    # unauthenticated requests and never receive the workflow token.
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)

#!/bin/bash
curl -s https://api.github.com/repos/Dao-AILab/flash-attention/releases \
  | python3 -c "
import sys, json
releases = json.load(sys.stdin)
for rel in releases[:10]:
    wheels = [a['browser_download_url'] for a in rel['assets'] if 'cp310' in a['name'] and 'linux' in a['name']]
    if wheels:
        print('=== Release:', rel['tag_name'])
        for w in wheels:
            print(' ', w)
"

#!/bin/bash
# 生成项目访问统计 JSON

LOG="/var/log/nginx/access.log"
OUT="/usr/share/nginx/html/showcase/stats.json"
SEEN_FILE="/tmp/showcase_uv.json"

today=$(date +%d/%b/%Y)
[ -f "$SEEN_FILE" ] && seen=$(cat "$SEEN_FILE") || seen="{}"

python3 << 'PYEOF'
import json, sys
from collections import defaultdict

log_path = '/var/log/nginx/access.log'
seen = defaultdict(set)
pv = defaultdict(int)

try:
    with open(log_path) as f:
        for line in f:
            if '18/May/2026' not in line:
                continue
            if any(x in line for x in ['favicon', 'wp-admin', 'wp-login', '400', '404', '.css', '.js', '.woff', '.png', '.svg']):
                continue
            
            for proj in ['inkflow', 'promptlab']:
                if f'/{proj}/' in line:
                    pv[proj] += 1
                    ip = line.split()[0]
                    seen[proj].add(ip)
except:
    pass

result = {}
for proj in ['inkflow', 'promptlab']:
    result[proj] = {'uv': len(seen[proj]), 'pv': pv[proj]}

print(json.dumps(result))
PYEOF
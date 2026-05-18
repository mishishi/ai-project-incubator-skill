#!/bin/bash
# parse-access-log.sh — 解析 nginx access.log 生成项目访问统计
# Output: JSON with {project: {uv, pv}}

LOG="/var/log/nginx/access.log"
SINCE="${1:-2026-05-01}"  # 统计起始日期

TMP=$(mktemp)
grep "\[${SINCE#-}" "$LOG" 2>/dev/null | grep -v "favicon\|wp-admin\|wp-login\|404\|400" > "$TMP"

# 项目路径映射
declare -A MAP=(
  ["inkflow"]="inkflow inkflow/"
  ["promptlab"]="promptlab promptlab/"
)

echo "{"
FIRST=1
for proj in inkflow promptlab; do
  paths=${MAP[$proj]}
  pv=$(grep -E "$(echo $paths | tr ' ' '|')" "$TMP" | wc -l)
  uv=$(grep -E "$(echo $paths | tr ' ' '|')" "$TMP" | awk '{print $1}' | sort -u | wc -l)
  [ -z "$uv" ] && uv=0
  [ -z "$pv" ] && pv=0
  [ $FIRST -eq 1 ] && FIRST=0 || echo ","
  echo -n "  \"$proj\": { \"uv\": $uv, \"pv\": $pv }"
done
echo ""
echo "}"
rm -f "$TMP
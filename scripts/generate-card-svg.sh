#!/bin/bash
# generate-card-svg.sh — 生成电路星图风格 SVG 展示卡片
# Usage: bash generate-card-svg.sh {project-name} [card|modal] [width] [height]

PROJECT_NAME="${1:-}"
SIZE="${2:-card}"
CW="${3:-}"
CH="${4:-}"
WORKSPACE="/root/.openclaw/workspace"
PROJ_DIR="$WORKSPACE/projects/incubated/$PROJECT_NAME"
OUTPUT_DIR="/usr/share/nginx/html/showcase/cards"
META="$PROJ_DIR/metadata.json"

if [ -z "$PROJECT_NAME" ] || [ ! -f "$META" ]; then
  echo "Usage: generate-card-svg.sh {project-name} [card|modal] [width] [height]"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Base design is 511x220 (modal). Scale card to 361x170.
if [ -n "$CW" ] && [ -n "$CH" ]; then
  VW=$CW; VH=$CH
elif [ "$SIZE" = "modal" ]; then
  VW=511; VH=220
else
  VW=361; VH=170
fi

# Read metadata
read_meta() {
  python3 -c "
import json
d = json.load(open('$META'))
print('NAME:', d.get('name', '$PROJECT_NAME'))
print('TAGLINE:', d.get('tagline', ''))
print('TECH:', ','.join(d.get('techStack', []) or ['React','TS']))
print('ACCENT:', d.get('accent', '') or '')
print('DATE:', d.get('incubatedAt', ''))
" 2>/dev/null
}

META_OUTPUT=$(read_meta)
NAME=$(echo "$META_OUTPUT" | grep "^NAME:" | cut -d: -f2- | xargs | tr -d '\n')
TAGLINE=$(echo "$META_OUTPUT" | grep "^TAGLINE:" | cut -d: -f2- | xargs | tr -d '\n')
TECH=$(echo "$META_OUTPUT" | grep "^TECH:" | cut -d: -f2- | xargs | tr -d '\n')
ACCENT=$(echo "$META_OUTPUT" | grep "^ACCENT:" | cut -d: -f2- | xargs | tr -d '\n')
INCUBATED_DATE=$(echo "$META_OUTPUT" | grep "^DATE:" | cut -d: -f2- | xargs | tr -d '\n')

[ -z "$ACCENT" ] && ACCENT="#E07A3A"
SFY=$(python3 -c "print(round($VH / 220.0, 3))")
SFX=$(python3 -c "print(round($VW / 511.0, 3))")

y() { python3 -c "print(int($1 * $SFY))"; }
x() { python3 -c "print(int($1 * $SFX))"; }

# ─── Node positions (scaled from 511x220 base) ───
# Top row
N1X=$(x 80)   N1Y=$(y 50)
N2X=$(x 175)  N2Y=$(y 35)
N3X=$(x 255)  N3Y=$(y 68)  # Main node (center)
N4X=$(x 340)  N4Y=$(y 48)
N5X=$(x 430)  N5Y=$(y 38)

# Bottom row
N6X=$(x 60)   N6Y=$(y 140)
N7X=$(x 155)  N7Y=$(y 118)
N8X=$(x 255)  N8Y=$(y 148)  # Main node bottom
N9X=$(x 360)  N9Y=$(y 128)
N10X=$(x 460) N10Y=$(y 145)

# Main center text area
CTA_X=$(x 170) CTA_Y=$(y 78) CTA_W=$(x 171) CTA_H=$(y 50)
TITLE_X=$(x 255) TITLE_Y=$(y 102)
SUB_X=$(x 255) SUB_Y=$(y 116)

# Font sizes
FS_TITLE=$(python3 -c "print(int(max(14, 24 * $SFX)))")
FS_SUB=$(python3 -c "print(int(max(6, 8 * $SFX)))")

OUTPUT="$OUTPUT_DIR/$PROJECT_NAME-$SIZE.svg"

cat > "$OUTPUT" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" width="$VW" height="$VH" viewBox="0 0 $VW $VH">
  <defs>
    <filter id="glow">
      <feGaussianBlur stdDeviation="2.5" result="blur"/>
      <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
    <filter id="softglow">
      <feGaussianBlur stdDeviation="1.5" result="blur"/>
      <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>

  <!-- Background -->
  <rect width="$VW" height="$VH" fill="#0a0a0e"/>

  <!-- Connection lines - top row -->
  <g stroke="rgba(224,122,58,0.2)" stroke-width="1">
    <line x1="$N1X" y1="$N1Y" x2="$N2X" y2="$N2Y"/>
    <line x1="$N2X" y1="$N2Y" x2="$N3X" y2="$N3Y"/>
    <line x1="$N3X" y1="$N3Y" x2="$N4X" y2="$N4Y"/>
    <line x1="$N4X" y1="$N4Y" x2="$N5X" y2="$N5Y"/>
  </g>

  <!-- Connection lines - bottom row -->
  <g stroke="rgba(224,122,58,0.2)" stroke-width="1">
    <line x1="$N6X" y1="$N6Y" x2="$N7X" y2="$N7Y"/>
    <line x1="$N7X" y1="$N7Y" x2="$N8X" y2="$N8Y"/>
    <line x1="$N8X" y1="$N8Y" x2="$N9X" y2="$N9Y"/>
    <line x1="$N9X" y1="$N9Y" x2="$N10X" y2="$N10Y"/>
  </g>

  <!-- Cross vertical connections (dashed) -->
  <g stroke="rgba(224,122,58,0.12)" stroke-width="1" stroke-dasharray="3,4">
    <line x1="$N3X" y1="$N3Y" x2="$N8X" y2="$N8Y"/>
  </g>

  <!-- Diagonal connections -->
  <g stroke="rgba(224,122,58,0.08)" stroke-width="0.75">
    <line x1="$N2X" y1="$N2Y" x2="$N7X" y2="$N7Y"/>
    <line x1="$N3X" y1="$N3Y" x2="$N9X" y2="$N9Y"/>
    <line x1="$N4X" y1="$N4Y" x2="$N8X" y2="$N8Y"/>
  </g>

  <!-- Nodes - top row -->
  <g fill="#E07A3A">
    <circle cx="$N1X" cy="$N1Y" r="$(x 3)" opacity="0.7"/>
    <circle cx="$N2X" cy="$N2Y" r="$(x 2)" opacity="0.5"/>
    <circle cx="$N3X" cy="$N3Y" r="$(x 4)" opacity="1" filter="url(#glow)"/>
    <circle cx="$N4X" cy="$N4Y" r="$(x 2.5)" opacity="0.65"/>
    <circle cx="$N5X" cy="$N5Y" r="$(x 2)" opacity="0.45"/>
  </g>

  <!-- Nodes - bottom row -->
  <g fill="#E07A3A">
    <circle cx="$N6X" cy="$N6Y" r="$(x 2)" opacity="0.45"/>
    <circle cx="$N7X" cy="$N7Y" r="$(x 3)" opacity="0.6"/>
    <circle cx="$N8X" cy="$N8Y" r="$(x 2.5)" opacity="0.55"/>
    <circle cx="$N9X" cy="$N9Y" r="$(x 3)" opacity="0.7"/>
    <circle cx="$N10X" cy="$N10Y" r="$(x 2)" opacity="0.45"/>
  </g>

  <!-- Pulse ring on main node -->
  <circle cx="$N3X" cy="$N3Y" r="$(x 8)" stroke="rgba(224,122,58,0.2)" stroke-width="1" fill="none"/>

  <!-- Central text area -->
  <rect x="$CTA_X" y="$CTA_Y" width="$CTA_W" height="$CTA_H" fill="rgba(26,26,30,0.92)" rx="4"/>

  <!-- Title -->
  <text x="$TITLE_X" y="$TITLE_Y" text-anchor="middle" font-family="Georgia,'Times New Roman',serif" font-size="$FS_TITLE" fill="#E8E4DC" letter-spacing="3">${NAME}</text>

  <!-- Subtitle -->
  <text x="$SUB_X" y="$SUB_Y" text-anchor="middle" font-family="Georgia,'Times New Roman',serif" font-size="$FS_SUB" fill="rgba(224,122,58,0.8)" letter-spacing="3">${TAGLINE}</text>

  <!-- Accent dot on the right -->
  <circle cx="$(x 480)" cy="$(y 185)" r="$(x 2.5)" fill="rgba(224,122,58,0.4)"/>
  <circle cx="$(x 30)" cy="$(y 185)" r="$(x 2.5)" fill="rgba(224,122,58,0.4)"/>
</svg>
SVGEOF

echo "SVG: $OUTPUT ($VW x $VH, $(wc -c < "$OUTPUT") bytes)"
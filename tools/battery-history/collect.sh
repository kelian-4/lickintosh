#!/usr/bin/env bash
set -euo pipefail

HISTORY_FILE="${1:-$HOME/.local/share/quickshell/battery-history.csv}"
mkdir -p "$(dirname "$HISTORY_FILE")"

HEADER="timestamp,percent,state,screen_on"

BAT_PATH="$(upower -e 2>/dev/null | grep -i BAT | head -1 || true)"
if [ -z "$BAT_PATH" ]; then
    exit 0
fi

INFO="$(upower -i "$BAT_PATH" 2>/dev/null || true)"
PERCENT="$(echo "$INFO" | grep -i 'percentage:' | head -1 | grep -oE '[0-9]+' | head -1)"
STATE="$(echo "$INFO" | grep -i 'state:' | head -1 | awk '{print $2}')"

if [ -z "$PERCENT" ]; then
    exit 0
fi

SCREEN_ON=1
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    DPMS="$(hyprctl monitors -j 2>/dev/null | jq -r '[.[].dpmsStatus] | any' 2>/dev/null || true)"
    if [ "$DPMS" = "false" ]; then
        SCREEN_ON=0
    fi
fi

TIMESTAMP="$(date +%s)"

if [ ! -s "$HISTORY_FILE" ]; then
    echo "$HEADER" > "$HISTORY_FILE"
elif ! head -1 "$HISTORY_FILE" | grep -q "screen_on"; then
    TMP_MIGRATE="${HISTORY_FILE}.migrate"
    {
        echo "$HEADER"
        tail -n +2 "$HISTORY_FILE" | awk -F',' 'BEGIN{OFS=","} {print $1,$2,$3,1}'
    } > "$TMP_MIGRATE"
    mv "$TMP_MIGRATE" "$HISTORY_FILE"
fi

echo "${TIMESTAMP},${PERCENT},${STATE:-unknown},${SCREEN_ON}" >> "$HISTORY_FILE"

CUTOFF=$((TIMESTAMP - 10 * 24 * 3600))
TMP_FILE="${HISTORY_FILE}.tmp"
{
    head -1 "$HISTORY_FILE"
    tail -n +2 "$HISTORY_FILE" | awk -F',' -v cutoff="$CUTOFF" '$1 >= cutoff'
} > "$TMP_FILE"
mv "$TMP_FILE" "$HISTORY_FILE"

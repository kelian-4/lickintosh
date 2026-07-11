#!/usr/bin/env bash
set -uo pipefail

COMM="${1:-}"
[ -z "$COMM" ] && exit 0

APP_DIRS=(
    "$HOME/.local/share/applications"
    "/usr/share/applications"
    "/usr/local/share/applications"
    "/run/current-system/sw/share/applications"
    "$HOME/.nix-profile/share/applications"
    "/var/lib/flatpak/exports/share/applications"
)

ICON_NAME=""

for dir in "${APP_DIRS[@]}"; do
    [ -d "$dir" ] || continue
    for desktop_file in "$dir"/*.desktop; do
        [ -f "$desktop_file" ] || continue
        base_name=$(basename "$desktop_file" .desktop)
        if [[ "${base_name,,}" == *"${COMM,,}"* ]]; then
            ICON_NAME=$(grep -m1 '^Icon=' "$desktop_file" | cut -d'=' -f2-)
            [ -n "$ICON_NAME" ] && break 2
        fi
    done
done

[ -z "$ICON_NAME" ] && exit 0

if [[ "$ICON_NAME" == /* ]]; then
    [ -f "$ICON_NAME" ] && echo "$ICON_NAME"
    exit 0
fi

ICON_DIRS=(
    "$HOME/.local/share/icons"
    "$HOME/.icons"
    "/usr/share/icons"
    "/usr/share/pixmaps"
    "/run/current-system/sw/share/icons"
    "$HOME/.nix-profile/share/icons"
)

for dir in "${ICON_DIRS[@]}"; do
    [ -d "$dir" ] || continue
    found=$(find "$dir" \( -iname "${ICON_NAME}.svg" -o -iname "${ICON_NAME}.png" \) 2>/dev/null | sort -r | head -n 1)
    if [ -n "$found" ]; then
        echo "$found"
        exit 0
    fi
done

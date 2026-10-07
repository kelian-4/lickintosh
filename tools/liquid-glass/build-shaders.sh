#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
dir="$root/assets/shaders/liquidglass"
qsb_bin="${QSB:-qsb}"

if ! command -v "$qsb_bin" >/dev/null 2>&1; then
    echo "qsb introuvable. Sous NixOS : nix shell nixpkgs#qt6.qtshadertools -c $0" >&2
    exit 1
fi

for name in LiquidGlass LiquidGlassBlur; do
    for stage in vert frag; do
        "$qsb_bin" --qt6 \
            --glsl "100 es,120,150,300 es,320 es,440" \
            --hlsl 50 \
            --msl 12 \
            -o "$dir/$name.$stage.qsb" \
            "$dir/$name.$stage"
        echo "ok $name.$stage.qsb"
    done
done

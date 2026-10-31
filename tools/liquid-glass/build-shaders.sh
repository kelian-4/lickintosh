#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
qsb_bin="${QSB:-qsb}"

if ! command -v "$qsb_bin" >/dev/null 2>&1; then
    echo "qsb introuvable. Sous NixOS : nix shell nixpkgs#qt6.qtshadertools -c $0" >&2
    exit 1
fi

build() {
    local dir="$root/assets/shaders/$1"
    local name="$2"
    local glsl="$3"
    local stage
    for stage in vert frag; do
        "$qsb_bin" --qt6 \
            --glsl "$glsl" \
            --hlsl 50 \
            --msl 12 \
            -o "$dir/$name.$stage.qsb" \
            "$dir/$name.$stage"
        echo "ok $name.$stage.qsb"
    done
}

build liquidglass LiquidGlass "100 es,120,150,300 es,320 es,440"
build liquidglass LiquidGlassBlur "100 es,120,150,300 es,320 es,440"
build tahoeglass TahoeGlass "150,300 es,320 es,440"
build liquidglass WindowAlpha "100 es,120,150,300 es,320 es,440"
build liquidglass GlyphGlass "100 es,120,150,300 es,320 es,440"
build liquidglass SplitLiquidGlass "100 es,120,150,300 es,320 es,440"


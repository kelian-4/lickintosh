#!/bin/sh
dir="$1"
cache="$2"
mode="$3"

case "$dir" in
    "~"*) dir="$HOME${dir#\~}" ;;
esac

mkdir -p "$cache"

list() {
    find "$dir" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) 2>/dev/null | sort | head -60
}

thumb_of() {
    printf '%s/%s.jpg' "$cache" "$(printf '%s' "$1" | md5sum | cut -c1-32)"
}

if [ "$mode" = "--generate" ]; then
    if command -v magick >/dev/null 2>&1; then conv=magick
    elif command -v convert >/dev/null 2>&1; then conv=convert
    else exit 42
    fi
    list | while IFS= read -r p; do
        case "$p" in
            *.mp4|*.MP4|*.webm|*.mkv|*.mov) continue ;;
        esac
        t=$(thumb_of "$p")
        if [ -f "$t" ] && [ ! "$p" -nt "$t" ]; then continue; fi
        tmp="$t.tmp.$$"
        if "$conv" "$p[0]" -thumbnail 224x224^ -gravity center -extent 224x224 -quality 82 "$tmp" 2>/dev/null; then
            mv -f "$tmp" "$t"
        else
            rm -f "$tmp"
        fi
    done
    exit 0
fi

list | while IFS= read -r p; do
    t=$(thumb_of "$p")
    if [ -f "$t" ] && [ ! "$p" -nt "$t" ]; then
        printf '%s\t%s\n' "$p" "$t"
    else
        printf '%s\t\n' "$p"
    fi
done

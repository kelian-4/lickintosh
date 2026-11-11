# CI Status

Commit: a3f3ae0d5bbf052d89201740461ef912669d3a73
Branche: dev
Date: 2026-11-11 05:02:27 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/42963074189

| Etape | Resultat |
|---|---|
| Syntaxe Python | success |
| ShellCheck | failure |

## Log complet - Syntaxe Python
```
```

## Log complet - ShellCheck
```

In tools/wallpaper-thumbs/spotlight-list.sh line 30:
        if [ -f "$t" ] && [ ! "$p" -nt "$t" ]; then continue; fi
                                   ^-^ SC3013 (warning): In POSIX sh, -nt is undefined.


In tools/wallpaper-thumbs/spotlight-list.sh line 32:
        if "$conv" "$p[0]" -thumbnail 224x224^ -gravity center -extent 224x224 -quality 82 "$tmp" 2>/dev/null; then
                    ^-- SC1087 (error): Use braces when expanding arrays, e.g. ${array[idx]} (or ${var}[.. to quiet).


In tools/wallpaper-thumbs/spotlight-list.sh line 43:
    if [ -f "$t" ] && [ ! "$p" -nt "$t" ]; then
                               ^-^ SC3013 (warning): In POSIX sh, -nt is undefined.

For more information:
  https://www.shellcheck.net/wiki/SC1087 -- Use braces when expanding arrays,...
  https://www.shellcheck.net/wiki/SC3013 -- In POSIX sh, -nt is undefined.
```

# CI Status

Commit: 3372b8ee6f589bae85c9631e291a45a9448c50f9
Branche: dev
Date: 2026-09-19 01:46:11 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35413657852

| Etape | Resultat |
|---|---|
| Syntaxe Python | success |
| ShellCheck | failure |

## Log complet - Syntaxe Python
```
```

## Log complet - ShellCheck
```

In tools/energy-usage/sample-processes copie.sh line 73:
        while IFS=' ' read -r key value unit _; do
                                        ^--^ SC2034 (warning): unit appears unused. Verify use (or export if used externally).

For more information:
  https://www.shellcheck.net/wiki/SC2034 -- unit appears unused. Verify use (...
```

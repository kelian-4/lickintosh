# CI Status

Commit: faa09e4c59a183cf6b6ede078b57721c5c756ee0
Branche: dev
Date: 2026-09-19 18:07:26 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35460177253

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

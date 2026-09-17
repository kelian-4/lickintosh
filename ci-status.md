# CI Status

Commit: fa0f967a1c6459cf93e4efd394171570efde95ff
Branche: dev
Date: 2026-09-17 11:20:56 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35215190266

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

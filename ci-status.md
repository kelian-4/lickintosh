# CI Status

Commit: df92873cc84eaec31c896163ef27c4a7aeeb7d2a
Branche: dev
Date: 2026-09-18 11:52:47 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35341786993

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

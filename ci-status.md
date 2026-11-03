# CI Status

Commit: 5c79ffe4e56e727ba967e00af36fe03453a642a6
Branche: dev
Date: 2026-11-03 09:58:30 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/41615305714

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

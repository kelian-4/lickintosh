# CI Status

Commit: 6efa5225e0c7a28eaa8a8e203dcdb627b0e86a82
Branche: dev
Date: 2026-11-05 08:32:01 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/41995176829

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

# CI Status

Commit: 0348ee95e200741b69cf3fa353966eefc760948a
Branche: dev
Date: 2026-11-05 08:34:34 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/41995512248

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

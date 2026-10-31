# CI Status

Commit: cb376eb1582dc3e474e62e36052b1da503cce365
Branche: dev
Date: 2026-10-31 15:14:44 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/41213906357

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

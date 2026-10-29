# CI Status

Commit: 5fcdc7a1a740f40d0775cb94a554bbc5f72c983b
Branche: dev
Date: 2026-10-29 13:17:27 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/40880535903

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

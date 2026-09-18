# CI Status

Commit: 41dd7a7f59653e056be5c0fa3c4731606948c77d
Branche: dev
Date: 2026-09-18 08:17:57 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35323598601

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

# CI Status

Commit: 6c4b3a5fc5a84ee571df138798bd18b05577110c
Branche: dev
Date: 2026-09-18 06:44:50 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35316214259

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

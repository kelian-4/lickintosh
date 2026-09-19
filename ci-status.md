# CI Status

Commit: 092b07d369e4e2c5c16957709f3b2d8b6766a374
Branche: dev
Date: 2026-09-19 19:30:14 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35464525658

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

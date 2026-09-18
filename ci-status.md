# CI Status

Commit: 442a5cc6dc3047d2c147054b39b683cdd7565e0f
Branche: dev
Date: 2026-09-18 07:56:45 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35321874031

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

# CI Status

Commit: 8078399a0a5622ad131c0cd0959b30af1a85b613
Branche: dev
Date: 2026-11-05 12:51:00 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/42030591205

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

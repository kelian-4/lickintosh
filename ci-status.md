# CI Status

Commit: 831cdd808717ba5d28087d0997916eda35eab5b4
Branche: dev
Date: 2026-09-16 19:17:29 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35139649230

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

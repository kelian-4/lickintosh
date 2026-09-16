# CI Status

Commit: 8d638a68ed13e13f0856bd455b3b38776a14e58a
Branche: dev
Date: 2026-09-16 06:37:29 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35064549537

| Etape | Resultat |
|---|---|
| Syntaxe Python | success |
| ShellCheck | failure |

## Log complet - Syntaxe Python
```
```

## Log complet - ShellCheck
```

In tools/energy-usage/sample-processes.sh line 73:
        while IFS=' ' read -r key value unit _; do
                                        ^--^ SC2034 (warning): unit appears unused. Verify use (or export if used externally).

For more information:
  https://www.shellcheck.net/wiki/SC2034 -- unit appears unused. Verify use (...
```

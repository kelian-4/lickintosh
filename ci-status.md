# CI Status

Commit: f41fc0f83159c7fb4984b8c81977403e6de0920a
Branche: dev
Date: 2026-09-15 11:24:06 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/34963068779

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

# CI Status

Commit: 4bd16ea88153cd5a17315a637c6732dab36c21ce
Branche: dev
Date: 2026-09-17 11:46:36 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35217460697

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

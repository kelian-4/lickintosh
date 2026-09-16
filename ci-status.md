# CI Status

Commit: 3339dcf5b832260a7add7b3ce8d4a21698b93633
Branche: dev
Date: 2026-09-16 04:07:32 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35054376091

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

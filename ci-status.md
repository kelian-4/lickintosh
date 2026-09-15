# CI Status

Commit: cf9fd89c25c252a8fd4be85fe947472e72e75f28
Branche: dev
Date: 2026-09-15 19:21:09 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35013080291

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

# CI Status

Commit: 06b27699e4e71f09c184db576df62e4466d1c5cc
Branche: dev
Date: 2026-09-16 06:39:52 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35064731746

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

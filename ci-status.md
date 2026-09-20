# CI Status

Commit: 7b73e61573e641436a321e18daba00b977603aff
Branche: dev
Date: 2026-09-20 00:21:52 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35478569708

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

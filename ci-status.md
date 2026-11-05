# CI Status

Commit: 51ac700117f4ee6ec5056979284b63fa42fc2be3
Branche: dev
Date: 2026-11-05 19:12:12 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/42091590058

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

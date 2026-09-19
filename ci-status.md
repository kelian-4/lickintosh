# CI Status

Commit: f884e35e8461cf8a2c150e91a5a4fb49afb6bd82
Branche: dev
Date: 2026-09-19 19:18:17 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35463920070

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

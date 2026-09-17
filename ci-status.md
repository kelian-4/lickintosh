# CI Status

Commit: 6f0f972191daba958099d9eb0709b216c3e3352e
Branche: dev
Date: 2026-09-17 05:51:31 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35187381002

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

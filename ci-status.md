# CI Status

Commit: 350915ad7300c6c955484ce4d39e3be20deb317f
Branche: dev
Date: 2026-09-17 06:27:17 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35189879940

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

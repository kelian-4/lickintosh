# CI Status

Commit: 0bb546ea2f26ff4ab7e684c1d18b6848f912cb71
Branche: dev
Date: 2026-09-19 01:55:56 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35414150096

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

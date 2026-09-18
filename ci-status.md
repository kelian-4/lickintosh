# CI Status

Commit: fb3cf7de15f916a1f8dae88767084e5a2c420c22
Branche: dev
Date: 2026-09-18 06:57:55 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35317188027

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

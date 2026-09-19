# CI Status

Commit: 7c172914586b785eea9acb8e86dba6664695c7c5
Branche: dev
Date: 2026-09-19 19:25:26 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35464297567

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

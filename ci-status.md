# CI Status

Commit: c5bcb18203dfbc144337b74eda4d4e834b155bd5
Branche: dev
Date: 2026-11-05 07:32:49 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/41987965216

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

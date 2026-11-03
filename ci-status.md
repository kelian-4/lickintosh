# CI Status

Commit: 2b550ff02479e34628d00af1fb3d9ca51289ac50
Branche: dev
Date: 2026-11-03 08:37:26 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/41604632992

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

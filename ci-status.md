# CI Status

Commit: 211fda6e2f22a8553eebc1da52dadf8023a3c1a1
Branche: dev
Date: 2026-10-29 13:41:44 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/40884263412

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

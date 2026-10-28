# CI Status

Commit: 237ad308b0d25c7265c97377855765e39b941738
Branche: dev
Date: 2026-10-28 11:51:57 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/40683221080

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

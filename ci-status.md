# CI Status

Commit: bba9726684cb633b84daf3af714c1e95825bbf9f
Branche: dev
Date: 2026-09-18 06:29:08 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35315061675

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

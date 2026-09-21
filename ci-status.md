# CI Status

Commit: 989da683a766c2a34feac06086eb4f3e9069665c
Branche: dev
Date: 2026-09-21 11:06:37 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/35592277930

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

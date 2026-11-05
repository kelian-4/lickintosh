# CI Status

Commit: 1895950962098c2ca5aec4494a85df2e484fd6bb
Branche: dev
Date: 2026-11-05 08:08:15 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/41992151141

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

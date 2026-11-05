# CI Status

Commit: 4f2debe3c2c05ea24896577db54ed2bb8f015fc4
Branche: dev
Date: 2026-11-05 08:38:26 UTC
Run: https://github.com/kelian-4/lickintosh/actions/runs/41996013065

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

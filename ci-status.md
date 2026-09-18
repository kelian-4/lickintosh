# CI Status

Commit: 40f6f0117afed79129ec0bacb6a9e312b85f03d4
Branche: dev
Date: 2026-09-18 07:34:01 UTC
Run: https://github.com/kelian-4/shell-macos/actions/runs/35320019970

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

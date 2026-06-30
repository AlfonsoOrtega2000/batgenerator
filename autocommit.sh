#!/usr/bin/env bash
cd /Users/alfonsoortegarodriguez/batgenerator

# Actualizar timestamp en HANDOFF.md
FECHA=$(date '+%Y-%m-%d %H:%M')
sed -i '' "s/> \*\*Última actualización automática:\*\* .*/> **Última actualización automática:** $FECHA/" HANDOFF.md

# Si hay cambios → commit y push
if ! git diff --quiet || \
   ! git diff --cached --quiet || \
   [ -n "$(git ls-files --others --exclude-standard)" ]; then

    git add -A
    git commit -m "Auto-guardado $FECHA"
    git push origin main
fi

#!/usr/bin/env bash
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

# Actualizar timestamp en HANDOFF.md
FECHA=$(date '+%Y-%m-%d %H:%M')
sed -i '' "s/> \*\*Última actualización automática:\*\* .*/> **Última actualización automática:** $FECHA/" HANDOFF.md 2>/dev/null || \
sed -i    "s/> \*\*Última actualización automática:\*\* .*/> **Última actualización automática:** $FECHA/" HANDOFF.md

# Si hay cambios → pull + commit + push
if ! git diff --quiet || \
   ! git diff --cached --quiet || \
   [ -n "$(git ls-files --others --exclude-standard)" ]; then

    git pull --rebase origin main 2>/dev/null
    git add -A
    git commit -m "Auto-guardado $FECHA"
    git push origin main
fi

#!/usr/bin/env bash
# setup.sh — instala el autocommit de 15 minutos en este dispositivo
set -e

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST="$HOME/Library/LaunchAgents/com.tooloptimizalo.autocommit.plist"
LOG="/tmp/tooloptimizalo-autocommit.log"

echo "==> Repo: $REPO"

# Descargar últimos cambios
git -C "$REPO" pull origin main

# Hacer ejecutable el autocommit
chmod +x "$REPO/autocommit.sh"

# Descargar plist anterior si existe
launchctl unload "$PLIST" 2>/dev/null || true

# Generar plist con las rutas de este dispositivo
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.tooloptimizalo.autocommit</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$REPO/autocommit.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>900</integer>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardOutPath</key>
    <string>$LOG</string>
    <key>StandardErrorPath</key>
    <string>$LOG</string>
</dict>
</plist>
EOF

# Activar
launchctl load "$PLIST"

echo "==> Autocommit activado. Cada 15 minutos sincronizará con GitHub."
echo "==> Log: $LOG"

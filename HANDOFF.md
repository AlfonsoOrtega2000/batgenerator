# HANDOFF — tooloptimizalo.xyz / batgenerator

> **Última actualización automática:** 2026-07-01 02:45

## Qué es este proyecto

Herramienta para técnicos IT de Optimizalo. Sirve un menú TUI interactivo vía PowerShell
(y Bash) que permite configurar carpetas compartidas, instalar NubePrint y descargar drivers
HP, generando scripts `.bat` listos para ejecutar en Windows.

---

## Acceso y URLs

| Recurso | URL |
|---|---|
| Producción web | https://tooloptimizalo.xyz |
| Menú PowerShell | `pwsh -c "iex(irm tooloptimizalo.xyz/m)"` |
| API generate | `POST https://tooloptimizalo.xyz/api/generate` |
| API auth | `POST https://tooloptimizalo.xyz/api/auth` |
| Panel web | `GET https://tooloptimizalo.xyz/` (requiere login) |

**Credenciales de acceso:**
- Usuario: `admin`
- Contraseña: `RDP57g7P`
- Secret HMAC: `opt-batgen-2025` (en `api/_auth.py`)
- Token: HMAC-SHA256 de `admin:RDP57g7P` — válido por sesión, guardado en `localStorage`

---

## Estructura de archivos

```
batgenerator/
├── deploy.sh            # Build + deploy: comprime menu.ps1 → actualiza menu.py → vercel --prod
├── menu.ps1             # Fuente del TUI PowerShell (EDITAR AQUÍ, no en menu.py)
├── menu.sh              # TUI Bash equivalente (para Mac/Linux con Git Bash en Windows)
├── vercel.json          # Rutas y builds de Vercel
├── api/
│   ├── _auth.py         # Usuarios, tokens HMAC (fuente de verdad de credenciales)
│   ├── auth.py          # Endpoint POST /api/auth
│   ├── generate.py      # Endpoint POST /api/generate — genera el .bat
│   └── menu.py          # Endpoint GET /m — sirve el PS1 comprimido/ofuscado
└── public/
    ├── index.html       # Web UI del generador (requiere token en localStorage)
    └── login.html       # Página de login web
```

---

## Flujo de despliegue

```
1. Editar menu.ps1  (fuente del TUI)
2. bash deploy.sh
   ├── Comprime menu.ps1 con gzip + base64
   ├── Actualiza _PAYLOAD y _LOADER en api/menu.py automáticamente
   └── Ejecuta: npx vercel --prod --yes
```

**IMPORTANTE:** Nunca editar `_PAYLOAD` ni `_LOADER` en `menu.py` a mano.
Siempre editar `menu.ps1` y correr `deploy.sh`.

---

## Cómo funciona cada parte

### GET /m — menu.py
- Detecta el User-Agent: si es navegador devuelve 404, si es PowerShell sirve el script
- Sirve `_LOADER`: un one-liner PS1 que descomprime y ejecuta `_PAYLOAD` (gzip+base64 de menu.ps1)
- Resultado: el script nunca se ve en texto plano en la URL

### POST /api/auth — auth.py + _auth.py
- Recibe `{username, password}` en JSON
- Valida contra `_USERS` en `_auth.py`
- Devuelve `{token}` (HMAC-SHA256) o 401 con delay de 3s anti-brute-force

### POST /api/generate — generate.py
- Requiere header `X-Auth-Token` válido
- Recibe `{nombre, steps: [{type, params}]}` en JSON
- Devuelve el archivo `.bat` como `application/octet-stream`

**Tipos de step disponibles:**

| type | params |
|---|---|
| `crear_carpeta` | `nombre`, `ruta` |
| `compartir_red` | `nombre_compartido`, `ruta_completa` |
| `visible_red` | _(sin params)_ |
| `acceso_directo` | `nombre`, `ruta_completa` |
| `copiar_archivos` | `origen`, `destino` |
| `ejecutar_comando` | `descripcion`, `comando` |
| `instalar_nubeprint` | `nombre_proyecto` |

### menu.ps1 — TUI PowerShell
Menú con 3 secciones:
1. **Carpeta compartida** — checkboxes para seleccionar pasos, luego genera/descarga .bat o ejecuta ahora
2. **NubePrint** — descarga `Nubeprint CPM.msi` desde zero.nubeprint.com
3. **Driver Universal HP** — descarga `HP_UPD_PCL6.zip` desde ftp.hp.com

### menu.sh — TUI Bash
Equivalente a menu.ps1 para Mac/Linux. También funciona en Windows con Git Bash.
La opción "EJECUTAR AHORA" llama a `cmd.exe` y `powershell.exe`, por lo que solo funciona en Windows.

---

## Bugs conocidos / deuda técnica

### Crítico
- `menu.sh` tiene la URL antigua: `https://optimizalo.vercel.app` (debería ser `https://tooloptimizalo.xyz`)

### Medio
- Driver Universal: las 4 opciones de Windows (7/8.1/10/11) descargan **el mismo ZIP** (`upd-pcl6-win10-x64-8.2.0.26778.zip`). Falta URLs específicas por versión.
- NubePrint "Configurar NubePrint" muestra solo "Próximamente..." — no implementado.

### Refactorización pendiente (estábamos en esto)
- **CORS duplicado**: el método `_cors()` y el patrón de cabeceras de error se repiten
  en `auth.py`, `generate.py` y `menu.py`. Se puede extraer a un helper compartido.
- **Navegación PowerShell duplicada**: `Run-Carpeta`, `Run-NubePrint` y `Run-Driver`
  en `menu.ps1` tienen la misma lógica de teclas (38/40/37/39/13/32). Se puede extraer
  a una función `Run-Menu` genérica.
- **Navegación Bash duplicada**: igual en `menu.sh` — `run_nubeprint` y `run_driver`
  repiten el mismo bucle de teclas. Candidato a función genérica `run_submenu`.
- **BAT generation verboso**: cada `elif kind ==` en `generate.py` es largo y repetitivo.

---

## Variables de entorno Vercel

No se usan variables de entorno de Vercel. Las credenciales están hardcodeadas en `api/_auth.py`.
Si se añaden usuarios en el futuro, hay que cambiar `_USERS` en ese archivo y redesplegar.

---

## Comandos útiles

```bash
# Redesplegar tras cambios en menu.ps1 o APIs
bash deploy.sh

# Probar la API de auth localmente (requiere vercel dev)
curl -X POST http://localhost:3000/api/auth \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"RDP57g7P"}'

# Probar generación de BAT
curl -X POST http://localhost:3000/api/generate \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: <token>" \
  -d '{"nombre":"test","steps":[{"type":"visible_red","params":{}}]}' \
  -o test.bat
```

---

## Historial de estado (última sesión)

Estábamos en la **optimización general del código**. Los cambios no llegaron a aplicarse
porque la sesión se cortó. Las áreas pendientes están detalladas en la sección
"Refactorización pendiente" arriba.

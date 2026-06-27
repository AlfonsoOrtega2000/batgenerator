from http.server import BaseHTTPRequestHandler
import json


def build_bat(nombre, steps):
    lines = [
        "@echo off",
        "setlocal EnableDelayedExpansion",
        ":: Requiere ejecutar como Administrador",
        "net session >nul 2>&1",
        "if %errorlevel% neq 0 (",
        "    echo ERROR: Ejecuta este script como Administrador.",
        "    pause",
        "    exit /b 1",
        ")",
        f"title {nombre}",
        "echo ============================================",
        f"echo  {nombre}",
        "echo ============================================",
        "echo.",
    ]

    for step in steps:
        kind = step.get("type", "")
        p = step.get("params", {})

        if kind == "crear_carpeta":
            nombre_c = p.get("nombre", "Nueva Carpeta")
            ruta = p.get("ruta", "C:").rstrip("\\")
            full = f"{ruta}\\{nombre_c}"
            lines += [
                "",
                f":: [PASO] Crear carpeta",
                f'echo Creando carpeta: {full}',
                f'if not exist "{full}" (',
                f'    mkdir "{full}"',
                f'    echo   OK - Carpeta creada',
                f') else (',
                f'    echo   INFO - La carpeta ya existe',
                f')',
            ]

        elif kind == "compartir_red":
            share_name = p.get("nombre_compartido", "Carpeta")
            full = p.get("ruta_completa", "C:\\Carpeta")
            lines += [
                "",
                f":: [PASO] Compartir en red",
                f'echo Compartiendo en red como: {share_name}',
                f'net share "{share_name}"="{full}" /GRANT:Everyone,FULL /REMARK:"Compartido automaticamente" 2>nul',
                f'if %errorlevel%==0 (',
                f'    echo   OK - Recurso compartido: \\\\%%COMPUTERNAME%%\\{share_name}',
                f') else (',
                f'    echo   INFO - El recurso puede ya estar compartido',
                f')',
            ]

        elif kind == "visible_red":
            lines += [
                "",
                ":: [PASO] Habilitar visibilidad en red",
                'echo Habilitando descubrimiento de red...',
                'netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul',
                'netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul',
                'sc config fdphost start=auto >nul 2>&1',
                'net start fdphost >nul 2>&1',
                'sc config FDResPub start=auto >nul 2>&1',
                'net start FDResPub >nul 2>&1',
                'echo   OK - Visibilidad en red habilitada',
            ]

        elif kind == "acceso_directo":
            nombre_a = p.get("nombre", "Carpeta")
            full = p.get("ruta_completa", "C:\\Carpeta")
            nombre_lnk = nombre_a.replace("'", "")
            lines += [
                "",
                f":: [PASO] Acceso directo en escritorio",
                f'echo Creando acceso directo: {nombre_a}',
                (
                    f'powershell -NoProfile -Command '
                    f'"$s=New-Object -ComObject WScript.Shell; '
                    f'$d=[Environment]::GetFolderPath(\'Desktop\'); '
                    f'$sc=$s.CreateShortcut($d+\'\\{nombre_lnk}.lnk\'); '
                    f'$sc.TargetPath=\'{full}\'; '
                    f'$sc.Save()"'
                ),
                f'echo   OK - Acceso directo "{nombre_a}" creado en el escritorio',
            ]

        elif kind == "copiar_archivos":
            origen = p.get("origen", "C:\\origen")
            destino = p.get("destino", "C:\\destino")
            lines += [
                "",
                f":: [PASO] Copiar archivos",
                f'echo Copiando: {origen} -^> {destino}',
                f'xcopy /E /I /Y "{origen}" "{destino}" >nul',
                f'echo   OK - Archivos copiados',
            ]

        elif kind == "ejecutar_comando":
            desc = p.get("descripcion", "Comando personalizado")
            cmd = p.get("comando", "echo.")
            lines += [
                "",
                f":: [PASO] {desc}",
                f'echo Ejecutando: {desc}',
                cmd,
                f'echo   OK',
            ]

    lines += [
        "",
        "echo.",
        "echo ============================================",
        "echo  Proceso completado exitosamente.",
        "echo ============================================",
        "echo.",
        "pause",
    ]

    return "\r\n".join(lines)


class handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS, GET")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self._cors()
        self.end_headers()
        payload = {
            "status": "ok",
            "version": "1.0",
            "pasos": [
                "crear_carpeta",
                "compartir_red",
                "visible_red",
                "acceso_directo",
                "copiar_archivos",
                "ejecutar_comando",
            ],
        }
        self.wfile.write(json.dumps(payload).encode())

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)

        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            self.send_response(400)
            self.send_header("Content-Type", "application/json")
            self._cors()
            self.end_headers()
            self.wfile.write(json.dumps({"error": "JSON invalido"}).encode())
            return

        steps = data.get("steps", [])
        nombre = data.get("nombre", "configuracion").strip() or "configuracion"

        if not steps:
            self.send_response(400)
            self.send_header("Content-Type", "application/json")
            self._cors()
            self.end_headers()
            self.wfile.write(json.dumps({"error": "No hay pasos seleccionados"}).encode())
            return

        try:
            bat = build_bat(nombre, steps)
            filename = nombre.replace(" ", "_") + ".bat"

            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Disposition", f'attachment; filename="{filename}"')
            self._cors()
            self.end_headers()
            self.wfile.write(bat.encode("utf-8"))

        except Exception as e:
            self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self._cors()
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())

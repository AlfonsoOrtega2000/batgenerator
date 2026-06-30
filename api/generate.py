import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _auth import VALID_TOKENS
from _base import BaseHandler


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

        elif kind == "descargar_nubeprint":
            url = "https://zero.nubeprint.com/download/cpms/Nubeprint%20CPM.msi"
            lines += [
                "",
                ":: [PASO] Descargar e instalar NubePrint CPM",
                'echo.',
                'echo [1/2] Descargando NubePrint CPM...',
                f'powershell -Command "Invoke-WebRequest -Uri \'{url}\' -OutFile \'%USERPROFILE%\\Desktop\\Nubeprint CPM.msi\'"',
                'if %errorlevel% neq 0 (',
                '    echo  ERROR: No se pudo descargar el instalador.',
                '    pause & exit /b 1',
                ')',
                'echo.',
                'echo [2/2] Ejecutando instalador...',
                'msiexec /i "%USERPROFILE%\\Desktop\\Nubeprint CPM.msi"',
                'echo.',
                'echo  OK - NubePrint CPM instalado.',
            ]

        elif kind == "instalar_nubeprint":
            proyecto = p.get("nombre_proyecto", "Mi Proyecto")
            url = "https://zero.nubeprint.com/download/cpms/Nubeprint%20CPM.msi"
            lines += [
                "",
                f":: [PASO] Instalar NubePrint – Proyecto: {proyecto}",
                f'echo.',
                f'echo  Proyecto: {proyecto}',
                f'echo.',
                f'echo [1/2] Descargando NubePrint CPM...',
                f'powershell -Command "Invoke-WebRequest -Uri \'{url}\' -OutFile \'%USERPROFILE%\\Desktop\\Nubeprint_CPM.msi\'"',
                f'if %errorlevel% neq 0 (',
                f'    echo  ERROR: No se pudo descargar el instalador.',
                f'    pause & exit /b 1',
                f')',
                f'echo [2/2] Instalando NubePrint CPM...',
                f'msiexec /i "%USERPROFILE%\\Desktop\\Nubeprint_CPM.msi" /qn',
                f'if %errorlevel% neq 0 (',
                f'    echo  ERROR: La instalacion fallo.',
                f'    pause & exit /b 1',
                f')',
                f'echo.',
                f'echo ================================================',
                f'echo  NubePrint CPM instalado correctamente.',
                f'echo  Proyecto: {proyecto}',
                f'echo.',
                f'echo  Abre NubePrint e introduce la licencia desde',
                f'echo  el portal web de NubePrint.',
                f'echo ================================================',
                f'echo.',
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


class handler(BaseHandler):
    def do_GET(self):
        self._json(200, {
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
        })

    def do_POST(self):
        tok = self.headers.get("X-Auth-Token", "")
        if tok not in VALID_TOKENS:
            self._error(401, "No autorizado")
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)

        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            self._error(400, "JSON invalido")
            return

        steps = data.get("steps", [])
        nombre = data.get("nombre", "configuracion").strip() or "configuracion"

        if not steps:
            self._error(400, "No hay pasos seleccionados")
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
            self._error(500, str(e))

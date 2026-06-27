# ================================================
#  GENERADOR DE SCRIPTS .BAT
#  Ejecutar en PowerShell (como Administrador)
# ================================================

# Actualiza esta URL despues de desplegar en Vercel
$API_URL = "https://TU-PROYECTO.vercel.app/api/generate"

$pasos = [System.Collections.ArrayList]@()

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ===========================================" -ForegroundColor Cyan
    Write-Host "        GENERADOR DE SCRIPTS .BAT" -ForegroundColor Cyan
    Write-Host "  ===========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    Show-Header

    Write-Host "  PASOS DISPONIBLES:" -ForegroundColor Yellow
    Write-Host "  ------------------------------------------"
    Write-Host "   [1]  Crear carpeta"
    Write-Host "   [2]  Compartir carpeta en red"
    Write-Host "   [3]  Habilitar visibilidad en red"
    Write-Host "   [4]  Crear acceso directo en escritorio"
    Write-Host "   [5]  Copiar archivos"
    Write-Host "   [6]  Ejecutar comando personalizado"
    Write-Host ""

    if ($pasos.Count -gt 0) {
        Write-Host "  PASOS AGREGADOS ($($pasos.Count)):" -ForegroundColor Green
        Write-Host "  ------------------------------------------"
        $n = 1
        foreach ($p in $pasos) {
            Write-Host "   $n. $($p.descripcion)" -ForegroundColor Green
            $n++
        }
        Write-Host ""
    }

    Write-Host "  ACCIONES:" -ForegroundColor Yellow
    Write-Host "  ------------------------------------------"
    Write-Host "   [G]  Generar y descargar el .BAT"
    Write-Host "   [E]  Eliminar un paso de la lista"
    Write-Host "   [R]  Reiniciar (borrar todos los pasos)"
    Write-Host "   [S]  Salir"
    Write-Host ""
    Write-Host "  ==========================================="
    Write-Host ""
}

function Ask {
    param([string]$prompt, [string]$default = "")
    $val = Read-Host "  $prompt"
    if ($val -eq "" -and $default -ne "") { return $default }
    return $val
}

# ---------- PASOS ----------

function Add-CrearCarpeta {
    Write-Host ""
    Write-Host "  -- CREAR CARPETA --" -ForegroundColor Cyan
    $nombre = Ask "Nombre de la carpeta (ej: Escaner HP)"
    $ruta   = Ask "Ruta base sin barra final (ej: C: o C:\Usuarios\Publico)" "C:"
    $ruta   = $ruta.TrimEnd("\")
    $full   = "$ruta\$nombre"

    $paso = [PSCustomObject]@{
        type        = "crear_carpeta"
        descripcion = "Crear carpeta '$full'"
        params      = @{ nombre = $nombre; ruta = $ruta }
    }
    [void]$pasos.Add($paso)
    Write-Host "  -> Paso agregado." -ForegroundColor Green
    Start-Sleep -Milliseconds 700
}

function Add-CompartirRed {
    Write-Host ""
    Write-Host "  -- COMPARTIR EN RED --" -ForegroundColor Cyan
    $share = Ask "Nombre del recurso compartido (ej: Escaner HP)"
    $full  = Ask "Ruta completa de la carpeta (ej: C:\Escaner HP)"

    $paso = [PSCustomObject]@{
        type        = "compartir_red"
        descripcion = "Compartir '$share' en red"
        params      = @{ nombre_compartido = $share; ruta_completa = $full }
    }
    [void]$pasos.Add($paso)
    Write-Host "  -> Paso agregado." -ForegroundColor Green
    Start-Sleep -Milliseconds 700
}

function Add-VisibleRed {
    Write-Host ""
    Write-Host "  -- VISIBILIDAD EN RED --" -ForegroundColor Cyan
    Write-Host "  Habilitara Descubrimiento de Red y Comparticion de Archivos."
    Write-Host ""

    $paso = [PSCustomObject]@{
        type        = "visible_red"
        descripcion = "Habilitar visibilidad en red"
        params      = @{}
    }
    [void]$pasos.Add($paso)
    Write-Host "  -> Paso agregado." -ForegroundColor Green
    Start-Sleep -Milliseconds 700
}

function Add-AccesoDirecto {
    Write-Host ""
    Write-Host "  -- ACCESO DIRECTO EN ESCRITORIO --" -ForegroundColor Cyan
    $nombre = Ask "Nombre del acceso directo (ej: Escaner HP)"
    $full   = Ask "Ruta completa de la carpeta (ej: C:\Escaner HP)"

    $paso = [PSCustomObject]@{
        type        = "acceso_directo"
        descripcion = "Acceso directo '$nombre' en escritorio"
        params      = @{ nombre = $nombre; ruta_completa = $full }
    }
    [void]$pasos.Add($paso)
    Write-Host "  -> Paso agregado." -ForegroundColor Green
    Start-Sleep -Milliseconds 700
}

function Add-CopiarArchivos {
    Write-Host ""
    Write-Host "  -- COPIAR ARCHIVOS --" -ForegroundColor Cyan
    $origen  = Ask "Ruta origen  (ej: C:\origen)"
    $destino = Ask "Ruta destino (ej: D:\backup)"

    $paso = [PSCustomObject]@{
        type        = "copiar_archivos"
        descripcion = "Copiar '$origen' -> '$destino'"
        params      = @{ origen = $origen; destino = $destino }
    }
    [void]$pasos.Add($paso)
    Write-Host "  -> Paso agregado." -ForegroundColor Green
    Start-Sleep -Milliseconds 700
}

function Add-Comando {
    Write-Host ""
    Write-Host "  -- COMANDO PERSONALIZADO --" -ForegroundColor Cyan
    $desc = Ask "Descripcion del comando"
    $cmd  = Ask "Comando a ejecutar"

    $paso = [PSCustomObject]@{
        type        = "ejecutar_comando"
        descripcion = $desc
        params      = @{ descripcion = $desc; comando = $cmd }
    }
    [void]$pasos.Add($paso)
    Write-Host "  -> Paso agregado." -ForegroundColor Green
    Start-Sleep -Milliseconds 700
}

# ---------- GENERAR ----------

function Generate-Bat {
    if ($pasos.Count -eq 0) {
        Write-Host "  No hay pasos seleccionados." -ForegroundColor Red
        Read-Host "  Presiona Enter para continuar"
        return
    }

    $nombre = Ask "Nombre del script (sin .bat)" "mi_configuracion"
    $nombre = $nombre.Trim()

    Write-Host ""
    Write-Host "  Conectando con el servidor..." -ForegroundColor Yellow

    # Construir array de steps limpio para JSON
    $steps_json = @()
    foreach ($p in $pasos) {
        $steps_json += @{
            type   = $p.type
            params = $p.params
        }
    }

    $body = @{
        nombre = $nombre
        steps  = $steps_json
    } | ConvertTo-Json -Depth 6 -Compress

    $filename = $nombre.Replace(" ", "_") + ".bat"
    $destpath = Join-Path (Get-Location) $filename

    try {
        Invoke-RestMethod `
            -Uri          $API_URL `
            -Method       POST `
            -Body         $body `
            -ContentType  "application/json; charset=utf-8" `
            -OutFile      $destpath

        Write-Host ""
        Write-Host "  ===========================================" -ForegroundColor Green
        Write-Host "   ARCHIVO GENERADO CORRECTAMENTE" -ForegroundColor Green
        Write-Host "   Nombre : $filename" -ForegroundColor Green
        Write-Host "   Ruta   : $destpath" -ForegroundColor Green
        Write-Host "  ===========================================" -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "  ERROR al conectar con el servidor:" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Verifica que API_URL sea correcta al inicio del script." -ForegroundColor Yellow
    }

    Write-Host ""
    Read-Host "  Presiona Enter para continuar"
}

function Remove-Paso {
    if ($pasos.Count -eq 0) {
        Write-Host "  No hay pasos en la lista." -ForegroundColor Red
        Read-Host "  Presiona Enter para continuar"
        return
    }

    Show-Header
    Write-Host "  PASOS ACTUALES:" -ForegroundColor Yellow
    $n = 1
    foreach ($p in $pasos) {
        Write-Host "   [$n] $($p.descripcion)"
        $n++
    }
    Write-Host ""
    $idx = Ask "Numero de paso a eliminar (0 para cancelar)" "0"
    $idx = [int]$idx

    if ($idx -ge 1 -and $idx -le $pasos.Count) {
        $pasos.RemoveAt($idx - 1)
        Write-Host "  -> Paso eliminado." -ForegroundColor Green
        Start-Sleep -Milliseconds 700
    }
}

# ================================================
#  BUCLE PRINCIPAL
# ================================================
while ($true) {
    Show-Menu
    $op = (Read-Host "  Selecciona una opcion").ToUpper().Trim()

    switch ($op) {
        "1" { Add-CrearCarpeta }
        "2" { Add-CompartirRed }
        "3" { Add-VisibleRed }
        "4" { Add-AccesoDirecto }
        "5" { Add-CopiarArchivos }
        "6" { Add-Comando }
        "G" { Generate-Bat }
        "E" { Remove-Paso }
        "R" {
            $pasos.Clear()
            Write-Host "  Lista borrada." -ForegroundColor Yellow
            Start-Sleep -Milliseconds 700
        }
        "S" {
            Write-Host ""
            Write-Host "  Hasta luego." -ForegroundColor Cyan
            Write-Host ""
            exit
        }
        default {
            Write-Host "  Opcion no valida." -ForegroundColor Red
            Start-Sleep -Milliseconds 700
        }
    }
}

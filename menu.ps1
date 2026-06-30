# ── Requisito mínimo ──────────────────────────────────────────
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Host "Este menu requiere PowerShell 3.0+."
    Read-Host "Pulsa Enter para salir"; exit 1
}

# ── Config ────────────────────────────────────────────────────
$API_URL  = "https://tooloptimizalo.xyz/api/generate"
$AUTH_URL = "https://tooloptimizalo.xyz/api/auth"
$script:TOKEN = ""

# ── UTF-8 y ANSI ──────────────────────────────────────────────
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$OutputEncoding = [Text.Encoding]::UTF8
try {
    Add-Type -MemberDefinition '
        [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr h, out uint m);
        [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr h, uint m);
        [DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int n);
    ' -Name K32 -Namespace W32 -EA SilentlyContinue
    $h = [W32.K32]::GetStdHandle(-11); $m = 0
    [W32.K32]::GetConsoleMode($h, [ref]$m) | Out-Null
    [W32.K32]::SetConsoleMode($h, $m -bor 4) | Out-Null
} catch {}

# ── Colores ───────────────────────────────────────────────────
$e  = [char]27
$BG = "$e[44m"; $WH = "$e[97m"; $HL = "$e[104m"
$BD = "$e[1m";  $NC = "$e[0m";  $RE = "$e[31m"

function Cls { [Console]::SetCursorPosition(0, 0); Write-Host -NoNewline "$e[J" }

# ── TUI helpers ───────────────────────────────────────────────
$W = 54

function slen($s) { ($s -replace "\x1b\[[0-9;]*m", '').Length }

function bline($t) {
    $p = $W - (slen $t); if ($p -lt 0) { $p = 0 }
    Write-Host "  $BG$WH|$t$(' '*$p)|$NC"
}

function hline($t) {
    $p = $W - (slen $t); if ($p -lt 0) { $p = 0 }
    Write-Host "  $BG$WH|$HL$WH$BD$t$(' '*$p)$BG$WH|$NC"
}

function Top($title) {
    Cls; Write-Host ""
    Write-Host "  $BG$WH+$('-'*$W)+$NC"
    bline ""; bline $title; bline ""
    Write-Host "  $BG$WH+$('-'*$W)+$NC"
}

function Bot { Write-Host "  $BG$WH+$('-'*$W)+$NC"; Write-Host "" }
function Sep { Write-Host "  $BG$WH+$('-'*$W)+$NC" }
function rkey { $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }

# ── Login ─────────────────────────────────────────────────────
function Draw-Login {
    Cls; Write-Host ""
    Write-Host "  $BG$WH+$('-'*$W)+$NC"
    bline ""; bline "                    OPTIMIZALO"; bline ""
    Sep; bline ""; bline "  Introduce tus credenciales:"; bline ""; Bot
}

function Do-Login {
    while ($true) {
        Draw-Login
        Write-Host -NoNewline "  Usuario:    "; $u = Read-Host
        Write-Host -NoNewline "  Contrasena: "
        $sp = Read-Host -AsSecureString
        $p = [System.Net.NetworkCredential]::new("", $sp).Password
        try {
            $b = "{`"username`":`"$u`",`"password`":`"$p`"}"
            $r = Invoke-RestMethod -Uri $AUTH_URL -Method POST -Body $b -ContentType "application/json" -EA Stop
            $script:TOKEN = $r.token; return
        } catch {
            $msg = "Credenciales incorrectas"
            try { $msg = ($_.ErrorDetails.Message | ConvertFrom-Json).error } catch {}
            Draw-Login; Write-Host "  $RE* $msg$NC`n"
            Read-Host "  Pulsa Enter para reintentar"
        }
    }
}

# ── Descarga simple ───────────────────────────────────────────
function Run-Download($url, $outfile, $titulo) {
    Cls; Write-Host ""
    Write-Host "  $BG$WH+$('-'*$W)+$NC"
    bline ""; bline "  $titulo"; bline ""
    bline "  Descargando, espera..."; bline ""; Bot
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $outfile -UseBasicParsing -TimeoutSec 180
        $ProgressPreference = 'Continue'
        $fname = Split-Path $outfile -Leaf
        Cls; Write-Host ""
        Write-Host "  $BG$WH+$('-'*$W)+$NC"
        bline ""; bline "  [OK]  Archivo listo en el escritorio:"; bline ""
        bline "        $fname"; bline ""; Bot
    } catch {
        Cls; Write-Host ""
        Write-Host "  $BG$WH+$('-'*$W)+$NC"
        bline ""; bline "  $RE[ERROR]  Descarga fallida:$NC"; bline ""
        bline "  $($_.Exception.Message)"; bline ""; Bot
    }
    Read-Host "  Presiona Enter para volver"
}

# ── Generar .bat ──────────────────────────────────────────────
function Do-Generate($stepsJson, $nombre) {
    $outfile = "$([Environment]::GetFolderPath('Desktop'))\$nombre.bat"
    $body = "{`"nombre`":`"$nombre`",`"steps`":[$stepsJson]}"
    Cls; Write-Host ""
    Write-Host "  $BG$WH+$('-'*$W)+$NC"
    bline ""; bline "            GENERADOR DE SCRIPTS .BAT"; bline ""
    bline "  Generando, espera..."; bline ""; Bot
    try {
        $h = @{"X-Auth-Token"=$script:TOKEN}
        Invoke-RestMethod -Uri $API_URL -Method POST -Headers $h -Body $body -ContentType "application/json" -OutFile $outfile
        Cls; Write-Host ""
        Write-Host "  $BG$WH+$('-'*$W)+$NC"
        bline ""; bline "            GENERADOR DE SCRIPTS .BAT"; bline ""; Sep
        bline ""; bline "  [OK]  Archivo listo en el escritorio:"; bline ""
        bline "       $nombre.bat"; bline ""; Bot
    } catch {
        Cls; Write-Host ""
        Write-Host "  $BG$WH+$('-'*$W)+$NC"
        bline ""; bline "  $RE[ERROR]  No se pudo generar el archivo:$NC"; bline ""
        bline "  $($_.Exception.Message)"; bline ""; Bot
    }
    Read-Host "  Presiona Enter para volver al menu"
}

# ── Carpeta compartida ────────────────────────────────────────
$KEYS   = @("crear_carpeta","compartir_red","visible_red","acceso_directo","copiar_archivos","ejecutar_comando")
$LABELS = @("Crear carpeta","Compartir carpeta en red","Habilitar visibilidad en red",
            "Acceso directo en escritorio","Copiar archivos","Ejecutar comando personalizado")
$DESCS  = @("Crea la carpeta en el disco si no existe ya",
            "Comparte la carpeta en la red local con acceso total",
            "Activa el descubrimiento de red y uso compartido",
            "Crea un acceso directo a la carpeta en el escritorio",
            "Copia archivos de una ruta origen a una ruta destino",
            "Ejecuta un comando personalizado de Windows")
$CN = $KEYS.Count
$script:chk = @(1,1,1,1,1,1)
$script:sc  = 0

function Draw-Carpeta {
    $BUTTON=$CN; $BACK=$CN+1; $EXEC=$CN+2
    Cls; Write-Host ""
    Write-Host "  $BG$WH+$('-'*$W)+$NC"
    bline ""; bline "          CONFIGURAR CARPETA COMPARTIDA"; bline ""; Sep; bline ""
    for ($i=0; $i -lt $CN; $i++) {
        $cb = if ($script:chk[$i]) { "[v]" } else { "[ ]" }
        if ($script:sc -eq $i) { hline " >  $cb   $($LABELS[$i])" }
        else { bline "     $cb   $($LABELS[$i])" }
    }
    bline ""; Sep
    if ($script:sc -lt $CN) { bline "  $($DESCS[$script:sc])" } else { bline "" }
    Sep; bline "  Flechas: mover   Espacio: marcar   Q: volver"; bline ""
    if ($script:sc -eq $BUTTON)   { Write-Host "  $BG$WH|  $HL$WH$BD[ CREAR Y DESCARGAR .BAT ]$BG$WH    [ VOLVER AL MENU ]    |$NC" }
    elseif ($script:sc -eq $BACK) { Write-Host "  $BG$WH|  [ CREAR Y DESCARGAR .BAT ]    $HL$WH$BD[ VOLVER AL MENU ]$BG$WH    |$NC" }
    else                          { Write-Host "  $BG$WH|  [ CREAR Y DESCARGAR .BAT ]    [ VOLVER AL MENU ]    |$NC" }
    if ($script:sc -eq $EXEC)     { Write-Host "  $BG$WH|                  $HL$WH$BD[ EJECUTAR AHORA ]$BG$WH                  |$NC" }
    else                          { Write-Host "  $BG$WH|                  [ EJECUTAR AHORA ]                  |$NC" }
    bline ""; Bot
}

function Ask-Form {
    $nc = $script:chk[$KEYS.IndexOf("copiar_archivos")]
    $nk = $script:chk[$KEYS.IndexOf("ejecutar_comando")]
    Top "          CONFIGURAR CARPETA COMPARTIDA"
    bline ""; bline "  Rellena los datos:"; bline ""; Bot
    Write-Host -NoNewline "  Nombre de la carpeta [Escaner]: "; $nom=Read-Host; if(!$nom){$nom="Escaner"}
    Write-Host -NoNewline "  Ruta destino         [C:]:      "; $rut=Read-Host; if(!$rut){$rut="C:"}
    $ori="C:\origen"; $dst="D:\backup"; $cmd=""; $dsc="Comando"
    if ($nc) {
        Write-Host -NoNewline "  Ruta origen archivos:           "; $o=Read-Host; if($o){$ori=$o}
        Write-Host -NoNewline "  Ruta destino archivos:          "; $d=Read-Host; if($d){$dst=$d}
    }
    if ($nk) {
        Write-Host -NoNewline "  Descripcion del comando:        "; $dc=Read-Host; if($dc){$dsc=$dc}
        Write-Host -NoNewline "  Comando a ejecutar:             "; $cm=Read-Host; if($cm){$cmd=$cm}
    }
    [PSCustomObject]@{nombre=$nom;ruta=$rut;origen=$ori;destino=$dst;cmd=$cmd;desc=$dsc}
}

function Build-Steps($f) {
    $full = "$($f.ruta)\$($f.nombre)"
    $steps = for ($i=0; $i -lt $CN; $i++) {
        if (!$script:chk[$i]) { continue }
        $t = $KEYS[$i]
        $p = switch ($t) {
            "crear_carpeta"    {"{`"nombre`":`"$($f.nombre)`",`"ruta`":`"$($f.ruta)`"}"}
            "compartir_red"    {"{`"nombre_compartido`":`"$($f.nombre)`",`"ruta_completa`":`"$full`"}"}
            "visible_red"      {"{}"}
            "acceso_directo"   {"{`"nombre`":`"$($f.nombre)`",`"ruta_completa`":`"$full`"}"}
            "copiar_archivos"  {"{`"origen`":`"$($f.origen)`",`"destino`":`"$($f.destino)`"}"}
            "ejecutar_comando" {"{`"descripcion`":`"$($f.desc)`",`"comando`":`"$($f.cmd)`"}"}
        }
        "{`"type`":`"$t`",`"params`":$p}"
    }
    $steps -join ","
}

function Run-ExecNow {
    $f = Ask-Form; $full = "$($f.ruta)\$($f.nombre)"
    Cls; Write-Host ""
    Write-Host "  $BG$WH+$('-'*$W)+$NC"
    bline ""; bline "          CONFIGURAR CARPETA COMPARTIDA"; bline ""; Sep
    bline ""; bline "  Ejecutando en este PC..."; bline ""
    $err = 0
    for ($i=0; $i -lt $CN; $i++) {
        if (!$script:chk[$i]) { continue }
        switch ($KEYS[$i]) {
            "crear_carpeta" {
                bline "  [ ] Creando carpeta..."
                if (Test-Path $full) { bline "  [·] Ya existia" }
                else {
                    New-Item -ItemType Directory -Path $full -Force -EA SilentlyContinue | Out-Null
                    if (Test-Path $full) { bline "  [OK] Carpeta creada: $full" } else { bline "  [!!] Error"; $err++ }
                }
            }
            "compartir_red" {
                bline "  [ ] Compartiendo en red..."
                net share "$($f.nombre)=$full" /GRANT:Everyone,FULL 2>&1 | Out-Null
                bline "  [OK] \\$env:COMPUTERNAME\$($f.nombre)"
            }
            "visible_red" {
                bline "  [ ] Visibilidad de red..."
                netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes 2>&1 | Out-Null
                netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>&1 | Out-Null
                bline "  [OK] Visibilidad activada"
            }
            "acceso_directo" {
                bline "  [ ] Acceso directo..."
                $sh = New-Object -ComObject WScript.Shell
                $lnk = $sh.CreateShortcut("$env:USERPROFILE\Desktop\$($f.nombre).lnk")
                $lnk.TargetPath = $full; $lnk.Save()
                bline "  [OK] Acceso directo en escritorio"
            }
            "copiar_archivos" {
                bline "  [ ] Copiando archivos..."
                xcopy "$($f.origen)" "$($f.destino)" /E /I /Y 2>&1 | Out-Null
                bline "  [OK] Archivos copiados"
            }
            "ejecutar_comando" {
                bline "  [ ] $($f.desc)..."
                cmd /c $f.cmd 2>&1 | Out-Null
                bline "  [OK] Ejecutado"
            }
        }
    }
    bline ""
    if ($err -eq 0) { bline "  Proceso completado correctamente." } else { bline "  Completado con $err error(es)." }
    bline ""; Bot; Read-Host "  Presiona Enter para volver"
}

function Run-Carpeta {
    $script:sc = 0; $BUTTON=$CN; $BACK=$CN+1; $EXEC=$CN+2
    while ($true) {
        Draw-Carpeta; $k = rkey
        switch ($k.VirtualKeyCode) {
            38 {
                if ($script:sc -eq $EXEC) { $script:sc = $BUTTON }
                elseif ($script:sc -eq $BUTTON -or $script:sc -eq $BACK) { $script:sc = $CN-1 }
                elseif ($script:sc -gt 0) { $script:sc-- }
            }
            40 {
                if ($script:sc -lt ($CN-1)) { $script:sc++ }
                elseif ($script:sc -eq ($CN-1)) { $script:sc = $BUTTON }
                elseif ($script:sc -eq $BUTTON -or $script:sc -eq $BACK) { $script:sc = $EXEC }
            }
            37 { if ($script:sc -eq $BACK)   { $script:sc = $BUTTON } }
            39 { if ($script:sc -eq $BUTTON) { $script:sc = $BACK } }
            32 {
                if ($script:sc -lt $CN) { $script:chk[$script:sc] = 1 - $script:chk[$script:sc] }
                elseif ($script:sc -eq $BACK) { return }
                elseif ($script:sc -eq $EXEC -and ($script:chk -contains 1)) { Run-ExecNow }
                elseif ($script:sc -eq $BUTTON -and ($script:chk -contains 1)) { $f=Ask-Form; Do-Generate (Build-Steps $f) $f.nombre }
            }
            13 {
                if ($script:sc -eq $BACK) { return }
                elseif ($script:sc -eq $EXEC -and ($script:chk -contains 1)) { Run-ExecNow }
                elseif ($script:sc -eq $BUTTON -and ($script:chk -contains 1)) { $f=Ask-Form; Do-Generate (Build-Steps $f) $f.nombre }
            }
        }
        if ($k.Character -eq 'q' -or $k.Character -eq 'Q') { return }
    }
}

# ── Menu simple genérico (sin checkboxes) ────────────────────
function Run-SimpleMenu {
    param([scriptblock]$Draw, [scriptblock[]]$Actions, [ref]$Cursor)
    $Cursor.Value = 0
    $back = $Actions.Count
    while ($true) {
        & $Draw; $k = rkey
        switch ($k.VirtualKeyCode) {
            38 { if ($Cursor.Value -gt 0) { $Cursor.Value-- } }
            40 { if ($Cursor.Value -lt $back) { $Cursor.Value++ } }
            13 {
                if ($Cursor.Value -lt $Actions.Count) { & $Actions[$Cursor.Value] }
                elseif ($Cursor.Value -eq $back) { return }
            }
        }
        if ($k.Character -eq 'q' -or $k.Character -eq 'Q') { return }
    }
}

# ── NubePrint ─────────────────────────────────────────────────
$NP_OPT = @("Instalar NubePrint","Configurar NubePrint")
$script:npc = 0

function Draw-NubePrint {
    $BACK = $NP_OPT.Count
    Cls; Write-Host ""
    Write-Host "  $BG$WH+$('-'*$W)+$NC"
    bline ""; bline "              INSTALADOR NUBEPRINT"; bline ""; Sep; bline ""
    for ($i=0; $i -lt $NP_OPT.Count; $i++) {
        if ($script:npc -eq $i) { hline " >  $($NP_OPT[$i])" } else { bline "     $($NP_OPT[$i])" }
    }
    bline ""; Sep; bline "  Flechas: mover   Enter: seleccionar   Q: volver"; bline ""
    if ($script:npc -eq $BACK) { Write-Host "  $BG$WH|                                $HL$WH$BD[ VOLVER AL MENU ]$BG$WH    |$NC" }
    else                       { Write-Host "  $BG$WH|                                [ VOLVER AL MENU ]    |$NC" }
    bline ""; Bot
}

function Run-NubePrint {
    Run-SimpleMenu -Draw { Draw-NubePrint } -Actions @(
        {
            $desk = [Environment]::GetFolderPath('Desktop')
            Run-Download "https://zero.nubeprint.com/download/cpms/Nubeprint%20CPM.msi" "$desk\Nubeprint CPM.msi" "Descargando NubePrint CPM..."
        },
        {
            Top "              CONFIGURAR NUBEPRINT"
            bline ""; bline "  Proximamente..."; bline ""; Bot
            Read-Host "  Presiona Enter para volver"
        }
    ) -Cursor ([ref]$script:npc)
}

# ── Driver Universal ──────────────────────────────────────────
$DRV_OPT = @("Windows 11","Windows 10","Windows 8.1","Windows 7")
$script:drvc = 0
$DRV_URL = "https://ftp.hp.com/pub/softlib/software13/printers/UPD/upd-pcl6-win10-x64-8.2.0.26778.zip"

function Draw-Driver {
    $BACK = $DRV_OPT.Count
    Cls; Write-Host ""
    Write-Host "  $BG$WH+$('-'*$W)+$NC"
    bline ""; bline "            INSTALAR DRIVER UNIVERSAL"; bline ""; Sep; bline ""
    for ($i=0; $i -lt $DRV_OPT.Count; $i++) {
        if ($script:drvc -eq $i) { hline " >  $($DRV_OPT[$i])" } else { bline "     $($DRV_OPT[$i])" }
    }
    bline ""; Sep; bline "  Flechas: mover   Enter: seleccionar   Q: volver"; bline ""
    if ($script:drvc -eq $BACK) { Write-Host "  $BG$WH|                                $HL$WH$BD[ VOLVER AL MENU ]$BG$WH    |$NC" }
    else                        { Write-Host "  $BG$WH|                                [ VOLVER AL MENU ]    |$NC" }
    bline ""; Bot
}

function Run-Driver {
    $dl = {
        $desk = [Environment]::GetFolderPath('Desktop')
        Run-Download $DRV_URL "$desk\HP_UPD_PCL6.zip" "Descargando Driver Universal HP $($DRV_OPT[$script:drvc])..."
    }
    Run-SimpleMenu -Draw { Draw-Driver } -Actions @($dl, $dl, $dl, $dl) -Cursor ([ref]$script:drvc)
}

# ── Menu principal ────────────────────────────────────────────
$MAIN_OPT = @("Configurar carpeta compartida","Instalador NubePrint","Instalar driver universal")
$script:mc = 0

function Draw-Main {
    Cls; Write-Host ""
    Write-Host "  $BG$WH+$('-'*$W)+$NC"
    bline ""; bline "                MENU PRINCIPAL"; bline ""; Sep; bline ""
    for ($i=0; $i -lt $MAIN_OPT.Count; $i++) {
        if ($script:mc -eq $i) { hline " >  $($MAIN_OPT[$i])" } else { bline "     $($MAIN_OPT[$i])" }
    }
    bline ""; Sep; bline "  Flechas: mover   Enter: seleccionar   Q: salir"; bline ""; Bot
}

# ── Inicio ────────────────────────────────────────────────────
[Console]::CursorVisible = $false
Do-Login

while ($true) {
    Draw-Main; $k = rkey
    switch ($k.VirtualKeyCode) {
        38 { if ($script:mc -gt 0) { $script:mc-- } }
        40 { if ($script:mc -lt $MAIN_OPT.Count-1) { $script:mc++ } }
        13 { switch ($script:mc) { 0{Run-Carpeta} 1{Run-NubePrint} 2{Run-Driver} } }
    }
    if ($k.Character -eq 'q' -or $k.Character -eq 'Q') {
        [Console]::CursorVisible = $true; Cls; exit
    }
}

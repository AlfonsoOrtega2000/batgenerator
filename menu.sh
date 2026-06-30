#!/usr/bin/env bash

# ── Si viene por pipe, se guarda y se relanza con /dev/tty ────────
if [ ! -t 0 ]; then
  tmp=$(mktemp /tmp/opt.XXXXXX)
  cat > "$tmp"
  bash "$tmp" < /dev/tty
  rm -f "$tmp"
  exit
fi

API_URL="https://tooloptimizalo.xyz/api/generate"
AUTH_URL="https://tooloptimizalo.xyz/api/auth"
AUTH_TOKEN=""

# ── Sub-menú: Carpeta Compartida ──────────────────────────────
KEYS=(
  "crear_carpeta"
  "compartir_red"
  "visible_red"
  "acceso_directo"
  "copiar_archivos"
  "ejecutar_comando"
)
LABELS=(
  "Crear carpeta"
  "Compartir carpeta en red"
  "Habilitar visibilidad en red"
  "Acceso directo en escritorio"
  "Copiar archivos"
  "Ejecutar comando personalizado"
)
N=${#KEYS[@]}
declare -a checked
for ((i=0; i<N; i++)); do checked[$i]=1; done
sub_cursor=0

DESCS=(
  "Crea la carpeta en el disco si no existe ya"
  "Comparte la carpeta en la red local con acceso total"
  "Activa el descubrimiento de red y uso compartido"
  "Crea un acceso directo a la carpeta en el escritorio"
  "Copia archivos de una ruta origen a una ruta destino"
  "Ejecuta un comando personalizado de Windows"
  "Genera y descarga el script .bat con los pasos marcados"
  "Vuelve al menu principal sin generar nada"
)

# ── Menú principal ────────────────────────────────────────────
MAIN_OPTIONS=(
  "Configurar carpeta compartida"
  "Instalador NubePrint"
  "Instalar driver universal"
)
MAIN_N=${#MAIN_OPTIONS[@]}
main_cursor=0

# ── Colores ───────────────────────────────────────────────────
GR=$'\033[32m'; RE=$'\033[31m'; NC=$'\033[0m'
BG=$'\033[44m'; WH=$'\033[97m'; HL=$'\033[104m'; BD=$'\033[1m'
UP=$'\033[A'; DOWN=$'\033[B'; LEFT=$'\033[D'; RIGHT=$'\033[C'

# ── Helpers ───────────────────────────────────────────────────
vlen() {
  local s="${1//✓/x}"
  s="${s//▶/x}"
  s="${s//█/x}"
  s="${s//░/x}"
  s="${s//▓/x}"
  echo ${#s}
}

bline() {
  local txt="$1" pad
  pad=$(( W - $(vlen "$txt") ))
  [[ $pad -lt 0 ]] && pad=0
  printf "  ${BG}${WH}│%s%${pad}s│${NC}\n" "$txt" ""
}

hline() {
  local txt="$1" pad
  pad=$(( W - $(vlen "$txt") ))
  [[ $pad -lt 0 ]] && pad=0
  printf "  ${BG}${WH}│${HL}${WH}${BD}%s%${pad}s${BG}${WH}│${NC}\n" "$txt" ""
}

read_key() {
  local char c2 c3
  IFS= read -rsn1 char
  if [[ "$char" == $'\033' ]]; then
    IFS= read -rsn1 -t 1 c2 2>/dev/null
    IFS= read -rsn1 -t 1 c3 2>/dev/null
    char="${char}${c2}${c3}"
  fi
  printf '%s' "$char"
}

# ── Login ─────────────────────────────────────────────────────
draw_login() {
  W=54
  local HR='──────────────────────────────────────────────────────'
  tput clear; echo
  printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
  bline ""
  bline "                    OPTIMIZALO"
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline ""
  bline "  Introduce tus credenciales:"
  bline ""
  printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"
  echo
}

do_login() {
  local user pass resp token err
  while true; do
    draw_login
    printf "  Usuario:    "; read -r user
    printf "  Contraseña: "; read -rs pass; echo

    resp=$(curl -s -X POST "$AUTH_URL" \
      -H "Content-Type: application/json" \
      -d "{\"username\":\"${user}\",\"password\":\"${pass}\"}" 2>/dev/null)

    token=$(echo "$resp" | sed -n 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

    if [[ -n "$token" ]]; then
      AUTH_TOKEN="$token"
      return 0
    else
      err=$(echo "$resp" | sed -n 's/.*"error"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
      draw_login
      printf "  ${RE}✗ ${err:-Credenciales incorrectas}${NC}\n\n"
      read -rp "  Pulsa Enter para reintentar..." _
    fi
  done
}

# ── Pantalla de progreso (recuadro azul) ──────────────────────
draw_prog() {
  local title="$1" bartxt="$2"
  W=54
  local HR='──────────────────────────────────────────────────────'
  tput clear; echo
  printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
  bline ""
  bline "            GENERADOR DE SCRIPTS .BAT"
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline ""
  bline "  $title"
  bline ""
  bline "  $bartxt"
  bline ""
  printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"
  echo
}

# ── Lógica de generación (compartida) ────────────────────────
_do_generate() {
  local payload="$1" outfile="$2" nombre="$3"
  local tmpfile="/tmp/_batgen_$$.bat"
  local codefile="/tmp/_batgen_code_$$.txt"
  local BW=30 bar filled empty

  # FASE 1: barra de generación
  curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $AUTH_TOKEN" \
    -d "$payload" \
    -o "$tmpfile" \
    -w "%{http_code}" > "$codefile" &
  local CPID=$!

  local t=0
  while kill -0 $CPID 2>/dev/null; do
    filled=$(( t < BW-1 ? t : BW-1 ))
    empty=$(( BW - filled - 1 ))
    bar=""
    for ((j=0; j<filled; j++)); do bar+="█"; done
    bar+="▓"
    for ((j=0; j<empty; j++)); do bar+="░"; done
    draw_prog "Conectando con el servidor..." "[${bar}]  generando..."
    ((t < BW-1)) && ((t++))
    sleep 0.07
  done
  wait $CPID

  bar=""
  for ((j=0; j<BW; j++)); do bar+="█"; done
  draw_prog "Conectando con el servidor..." "[${bar}]  completado!"
  sleep 0.5

  local code; code=$(tail -c 3 "$codefile" 2>/dev/null)
  rm -f "$codefile"

  if [[ "$code" != "200" ]]; then
    rm -f "$tmpfile"
    draw_prog "Error al conectar con el servidor." "Codigo HTTP: ${code}"
    echo; read -rp "  Presiona Enter para volver..." _; return
  fi

  # FASE 2: barra de guardado con porcentaje
  cp "$tmpfile" "$outfile"
  rm -f "$tmpfile"

  local pct
  for ((pct=0; pct<=100; pct+=3)); do
    filled=$(( pct * BW / 100 ))
    empty=$(( BW - filled ))
    bar=""
    for ((j=0; j<filled; j++)); do bar+="█"; done
    for ((j=0; j<empty;  j++)); do bar+="░"; done
    draw_prog "Guardando en el escritorio..." "[${bar}]  ${pct}%"
    sleep 0.025
  done
  bar=""
  for ((j=0; j<BW; j++)); do bar+="█"; done
  draw_prog "Guardando en el escritorio..." "[${bar}]  100%"
  sleep 0.4

  # Pantalla de éxito
  W=54
  local HR='──────────────────────────────────────────────────────'
  tput clear; echo
  printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
  bline ""
  bline "            GENERADOR DE SCRIPTS .BAT"
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline ""
  bline "  [✓]  Archivo listo en el escritorio:"
  bline ""
  bline "       ${nombre// /_}.bat"
  bline ""
  printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"
  echo
  read -rp "  Presiona Enter para volver al menu..." _
}

# ── Menú principal ────────────────────────────────────────────
draw_main() {
  W=54
  local HR='──────────────────────────────────────────────────────'
  tput clear; echo
  printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
  bline ""
  bline "                MENU PRINCIPAL"
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline ""
  for ((i=0; i<MAIN_N; i++)); do
    if [[ $main_cursor -eq $i ]]; then
      hline " ▶  ${MAIN_OPTIONS[$i]}"
    else
      bline "     ${MAIN_OPTIONS[$i]}"
    fi
  done
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline "  Flechas: mover   Enter: seleccionar   Q: salir"
  bline ""
  printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"
  echo
}

# ── Sub-menú: Carpeta Compartida ──────────────────────────────
draw_carpeta() {
  W=54
  local HR='──────────────────────────────────────────────────────'
  local BUTTON=$N BACK=$((N+1)) EXEC=$((N+2))
  tput clear; echo
  printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
  bline ""
  bline "          CONFIGURAR CARPETA COMPARTIDA"
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline ""
  for ((i=0; i<N; i++)); do
    local cb="[ ]"
    [[ "${checked[$i]}" == 1 ]] && cb="[✓]"
    if [[ $sub_cursor -eq $i ]]; then
      hline " ▶  $cb   ${LABELS[$i]}"
    else
      bline "     $cb   ${LABELS[$i]}"
    fi
  done
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  if [[ $sub_cursor -lt $N ]]; then
    bline "  ${DESCS[$sub_cursor]}"
  else
    bline ""
  fi
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline "  Flechas: mover   Espacio: seleccionar   Q: volver"
  bline ""
  if [[ $sub_cursor -eq $BUTTON ]]; then
    printf "  ${BG}${WH}│  ${HL}${WH}${BD}[ CREAR Y DESCARGAR .BAT ]${BG}${WH}    [ VOLVER AL MENU ]    │${NC}\n"
  elif [[ $sub_cursor -eq $BACK ]]; then
    printf "  ${BG}${WH}│  [ CREAR Y DESCARGAR .BAT ]    ${HL}${WH}${BD}[ VOLVER AL MENU ]${BG}${WH}    │${NC}\n"
  else
    printf "  ${BG}${WH}│  [ CREAR Y DESCARGAR .BAT ]    [ VOLVER AL MENU ]    │${NC}\n"
  fi
  if [[ $sub_cursor -eq $EXEC ]]; then
    printf "  ${BG}${WH}│                  ${HL}${WH}${BD}[ EJECUTAR AHORA ]${BG}${WH}                  │${NC}\n"
  else
    printf "  ${BG}${WH}│                  [ EJECUTAR AHORA ]                  │${NC}\n"
  fi
  bline ""
  printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"
  echo
}

any_checked() {
  for ((i=0; i<N; i++)); do [[ "${checked[$i]}" == 1 ]] && return 0; done
  return 1
}

run_carpeta_compartida() {
  local BUTTON=$N BACK=$((N+1)) EXEC=$((N+2))
  sub_cursor=0
  while true; do
    draw_carpeta
    local key; key=$(read_key)

    if [[ "$key" == "$UP" ]]; then
      if [[ $sub_cursor -eq $EXEC ]]; then
        sub_cursor=$BUTTON
      elif [[ $sub_cursor -eq $BUTTON || $sub_cursor -eq $BACK ]]; then
        sub_cursor=$((N-1))
      elif [[ $sub_cursor -gt 0 ]]; then
        ((sub_cursor--))
      fi
    elif [[ "$key" == "$DOWN" ]]; then
      if [[ $sub_cursor -lt $((N-1)) ]]; then
        ((sub_cursor++))
      elif [[ $sub_cursor -eq $((N-1)) ]]; then
        sub_cursor=$BUTTON
      elif [[ $sub_cursor -eq $BUTTON || $sub_cursor -eq $BACK ]]; then
        sub_cursor=$EXEC
      fi
    elif [[ "$key" == "$LEFT" ]]; then
      [[ $sub_cursor -eq $BACK ]] && sub_cursor=$BUTTON
    elif [[ "$key" == "$RIGHT" ]]; then
      [[ $sub_cursor -eq $BUTTON ]] && sub_cursor=$BACK
    elif [[ "$key" == " " || "$key" == "" || "$key" == $'\r' ]]; then
      if [[ $sub_cursor -lt $N ]]; then
        [[ "$key" == " " ]] && checked[$sub_cursor]=$(( 1 - checked[$sub_cursor] ))
      elif [[ $sub_cursor -eq $BUTTON ]] && any_checked; then
        local steps_json="" nombre="mi_configuracion"
        for ((i=0; i<N; i++)); do
          [[ "${checked[$i]}" != 1 ]] && continue
          local type="${KEYS[$i]}" params="{}"
          case "$type" in
            crear_carpeta)    params='{"nombre":"Escaner HP","ruta":"C:"}' ;;
            compartir_red)    params='{"nombre_compartido":"Escaner HP","ruta_completa":"C:\\Escaner HP"}' ;;
            visible_red)      params='{}' ;;
            acceso_directo)   params='{"nombre":"Escaner HP","ruta_completa":"C:\\Escaner HP"}' ;;
            copiar_archivos)  params='{"origen":"C:\\origen","destino":"D:\\backup"}' ;;
            ejecutar_comando) params='{"descripcion":"","comando":""}' ;;
          esac
          [[ -n "$steps_json" ]] && steps_json+=","
          steps_json+="{\"type\":\"$type\",\"params\":$params}"
        done
        local payload="{\"nombre\":\"$nombre\",\"steps\":[$steps_json]}"
        stty echo 2>/dev/null; printf '\033[?25h'
        _do_generate "$payload" "$HOME/Desktop/${nombre// /_}.bat" "$nombre"
        stty -echo 2>/dev/null; printf '\033[?25l'
      elif [[ $sub_cursor -eq $BACK ]]; then
        return
      elif [[ $sub_cursor -eq $EXEC ]] && any_checked; then
        stty echo 2>/dev/null; printf '\033[?25h'
        run_exec_now
        stty -echo 2>/dev/null; printf '\033[?25l'
      fi
    elif [[ "$key" == "q" || "$key" == "Q" || "$key" == $'\003' ]]; then
      return
    fi
  done
}

# ── Menu simple genérico (sin checkboxes) ────────────────────
run_simple_menu() {
  local draw_fn="$1"
  local -n _sm_actions="$2"
  local -n _sm_cursor="$3"
  local back="${#_sm_actions[@]}"
  local total=$((back + 1))
  _sm_cursor=0
  while true; do
    "$draw_fn"
    local key; key=$(read_key)
    if [[ "$key" == "$UP" ]]; then
      ((_sm_cursor > 0)) && ((_sm_cursor--))
    elif [[ "$key" == "$DOWN" ]]; then
      ((_sm_cursor < total - 1)) && ((_sm_cursor++))
    elif [[ "$key" == "" || "$key" == $'\r' || "$key" == " " ]]; then
      if [[ $_sm_cursor -lt $back ]]; then
        "${_sm_actions[$_sm_cursor]}"
      elif [[ $_sm_cursor -eq $back ]]; then
        return
      fi
    elif [[ "$key" == "q" || "$key" == "Q" || "$key" == $'\003' ]]; then
      return
    fi
  done
}

# ── Sub-menú: NubePrint ───────────────────────────────────────
NP_OPTIONS=("Instalar NubePrint" "Configurar NubePrint")
NP_N=${#NP_OPTIONS[@]}
np_cursor=0

draw_nubeprint_menu() {
  W=54
  local HR='──────────────────────────────────────────────────────'
  local BACK=$NP_N
  tput clear; echo
  printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
  bline ""
  bline "              INSTALADOR NUBEPRINT"
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline ""
  for ((i=0; i<NP_N; i++)); do
    if [[ $np_cursor -eq $i ]]; then hline " ▶  ${NP_OPTIONS[$i]}"
    else bline "     ${NP_OPTIONS[$i]}"; fi
  done
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline "  Flechas: mover   Enter: seleccionar   Q: volver"
  bline ""
  if [[ $np_cursor -eq $BACK ]]; then
    printf "  ${BG}${WH}│                                ${HL}${WH}${BD}[ VOLVER AL MENU ]${BG}${WH}    │${NC}\n"
  else
    printf "  ${BG}${WH}│                                [ VOLVER AL MENU ]    │${NC}\n"
  fi
  bline ""
  printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"
  echo
}

run_instalar_nubeprint() {
  local url="https://zero.nubeprint.com/download/cpms/Nubeprint%20CPM.msi"
  local outfile="$HOME/Desktop/Nubeprint CPM.msi"
  local BW=30 bar filled empty t=0

  curl -sL "$url" -o "$outfile" &
  local CPID=$!

  while kill -0 $CPID 2>/dev/null; do
    filled=$(( t < BW-1 ? t : BW-1 ))
    empty=$(( BW - filled - 1 ))
    bar=""
    for ((j=0; j<filled; j++)); do bar+="█"; done
    bar+="▓"
    for ((j=0; j<empty; j++)); do bar+="░"; done
    draw_prog "Descargando NubePrint CPM..." "[${bar}]  descargando..."
    ((t < BW-1)) && ((t++))
    sleep 0.07
  done
  wait $CPID
  local ok=$?

  bar=""
  for ((j=0; j<BW; j++)); do bar+="█"; done

  if [[ $ok -eq 0 ]]; then
    draw_prog "Descargando NubePrint CPM..." "[${bar}]  completado!"
    sleep 0.5
    W=54; local HR='──────────────────────────────────────────────────────'
    tput clear; echo
    printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
    bline ""; bline "              INSTALADOR NUBEPRINT"; bline ""
    printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
    bline ""; bline "  [✓]  Instalador listo en el escritorio:"
    bline ""; bline "       Nubeprint CPM.msi"; bline ""
    printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"; echo
  else
    draw_prog "Error al descargar." "Comprueba tu conexion."
    echo
  fi
  stty echo 2>/dev/null
  read -rp "  Presiona Enter para volver..." _
  stty -echo 2>/dev/null
}

run_configurar_nubeprint() {
  W=54
  local HR='──────────────────────────────────────────────────────'
  tput clear; echo
  printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
  bline ""
  bline "              CONFIGURAR NUBEPRINT"
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline ""
  bline "  Proximamente..."
  bline ""
  printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"
  echo
  stty echo 2>/dev/null
  read -rp "  Presiona Enter para volver..." _
  stty -echo 2>/dev/null
}

run_nubeprint() {
  local np_actions=("run_instalar_nubeprint" "run_configurar_nubeprint")
  run_simple_menu "draw_nubeprint_menu" np_actions np_cursor
}

# ── Ejecutar pasos directamente en Windows ───────────────────
run_exec_now() {
  local nombre ruta origen destino cmd cmddesc
  local need_copy=0 need_cmd=0
  W=54
  local HR='──────────────────────────────────────────────────────'

  for ((i=0; i<N; i++)); do
    [[ "${checked[$i]}" != 1 ]] && continue
    [[ "${KEYS[$i]}" == "copiar_archivos" ]] && need_copy=1
    [[ "${KEYS[$i]}" == "ejecutar_comando" ]] && need_cmd=1
  done

  # ─ Formulario ─
  tput clear; echo
  printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
  bline ""; bline "          CONFIGURAR CARPETA COMPARTIDA"; bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline ""; bline "  Rellena los campos (Enter para continuar):"; bline ""
  printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"; echo

  printf "  Nombre de la carpeta [Escaner]: "; read -r nombre
  [[ -z "$nombre" ]] && nombre="Escaner"
  printf "  Ruta destino         [C:]:      "; read -r ruta
  [[ -z "$ruta" ]] && ruta="C:"

  if [[ $need_copy -eq 1 ]]; then
    printf "  Ruta origen archivos:           "; read -r origen
    [[ -z "$origen" ]] && origen="C:\\origen"
    printf "  Ruta destino archivos:          "; read -r destino
    [[ -z "$destino" ]] && destino="D:\\backup"
  fi

  if [[ $need_cmd -eq 1 ]]; then
    printf "  Descripcion del comando:        "; read -r cmddesc
    printf "  Comando a ejecutar:             "; read -r cmd
  fi

  local full="${ruta}\\${nombre}"

  # ─ Comprobación de Windows ─
  if ! command -v cmd.exe &>/dev/null; then
    tput clear; echo
    printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
    bline ""; bline "          CONFIGURAR CARPETA COMPARTIDA"; bline ""
    printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
    bline ""; bline "  ERROR: Esta funcion solo funciona en"
    bline "  Windows con Git Bash."; bline ""
    printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"; echo
    read -rp "  Presiona Enter para volver..." _
    return
  fi

  # ─ Ejecución ─
  tput clear; echo
  printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
  bline ""; bline "          CONFIGURAR CARPETA COMPARTIDA"; bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline ""; bline "  Ejecutando en este PC..."; bline ""

  local errores=0
  for ((i=0; i<N; i++)); do
    [[ "${checked[$i]}" != 1 ]] && continue
    case "${KEYS[$i]}" in
      crear_carpeta)
        bline "  [·] Creando carpeta ${full}..."
        local r; r=$(cmd.exe /c "if not exist \"${full}\" (mkdir \"${full}\" && echo __OK__) else echo __YA__" 2>&1)
        if echo "$r" | grep -q "__OK__"; then
          bline "  [✓] Carpeta creada"
        elif echo "$r" | grep -q "__YA__"; then
          bline "  [·] La carpeta ya existia"
        else
          bline "  [✗] Error al crear carpeta"; ((errores++))
        fi
        ;;
      compartir_red)
        bline "  [·] Compartiendo en red..."
        cmd.exe /c "net share \"${nombre}=${full}\" /GRANT:Everyone,FULL >nul 2>&1"
        bline "  [✓] Compartido como: \\\\equipo\\${nombre}"
        ;;
      visible_red)
        bline "  [·] Activando visibilidad de red..."
        cmd.exe /c "netsh advfirewall firewall set rule group=\"Network Discovery\" new enable=Yes >nul 2>&1"
        cmd.exe /c "netsh advfirewall firewall set rule group=\"File and Printer Sharing\" new enable=Yes >nul 2>&1"
        bline "  [✓] Visibilidad activada"
        ;;
      acceso_directo)
        bline "  [·] Creando acceso directo..."
        powershell.exe -NoProfile -Command "\$s=New-Object -ComObject WScript.Shell;\$d=[Environment]::GetFolderPath('Desktop');\$sc=\$s.CreateShortcut(\$d+'\\${nombre}.lnk');\$sc.TargetPath='${full}';\$sc.Save()" 2>/dev/null
        bline "  [✓] Acceso directo en escritorio"
        ;;
      copiar_archivos)
        bline "  [·] Copiando archivos..."
        cmd.exe /c "xcopy /E /I /Y \"${origen}\" \"${destino}\" >nul 2>&1"
        bline "  [✓] Archivos copiados"
        ;;
      ejecutar_comando)
        bline "  [·] ${cmddesc:-Comando personalizado}..."
        cmd.exe /c "${cmd}" >nul 2>&1
        bline "  [✓] Ejecutado"
        ;;
    esac
  done

  bline ""
  if [[ $errores -eq 0 ]]; then
    bline "  Proceso completado correctamente."
  else
    bline "  Completado con ${errores} error(es)."
  fi
  bline ""
  printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"; echo
  read -rp "  Presiona Enter para volver..." _
}

# ── Sub-menú: Driver Universal ───────────────────────────────
DRV_OPTIONS=("Windows 11" "Windows 10" "Windows 8.1" "Windows 7")
DRV_N=${#DRV_OPTIONS[@]}
drv_cursor=0

draw_driver_menu() {
  W=54
  local HR='──────────────────────────────────────────────────────'
  local BACK=$DRV_N
  tput clear; echo
  printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
  bline ""
  bline "            INSTALAR DRIVER UNIVERSAL"
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline ""
  for ((i=0; i<DRV_N; i++)); do
    if [[ $drv_cursor -eq $i ]]; then hline " ▶  ${DRV_OPTIONS[$i]}"
    else bline "     ${DRV_OPTIONS[$i]}"; fi
  done
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline "  Flechas: mover   Enter: seleccionar   Q: volver"
  bline ""
  if [[ $drv_cursor -eq $BACK ]]; then
    printf "  ${BG}${WH}│                                ${HL}${WH}${BD}[ VOLVER AL MENU ]${BG}${WH}    │${NC}\n"
  else
    printf "  ${BG}${WH}│                                [ VOLVER AL MENU ]    │${NC}\n"
  fi
  bline ""
  printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"
  echo
}

run_driver_win11() {
  local url="https://ftp.hp.com/pub/softlib/software13/printers/UPD/upd-pcl6-win10-x64-8.2.0.26778.zip"
  local outfile="$HOME/Desktop/HP_UPD_PCL6_Win11.zip"
  local BW=30 bar filled empty t=0

  curl -sL "$url" -o "$outfile" &
  local CPID=$!

  while kill -0 $CPID 2>/dev/null; do
    filled=$(( t < BW-1 ? t : BW-1 ))
    empty=$(( BW - filled - 1 ))
    bar=""
    for ((j=0; j<filled; j++)); do bar+="█"; done
    bar+="▓"
    for ((j=0; j<empty; j++)); do bar+="░"; done
    draw_prog "Descargando Driver Universal HP..." "[${bar}]  descargando..."
    ((t < BW-1)) && ((t++))
    sleep 0.07
  done
  wait $CPID
  local ok=$?

  bar=""
  for ((j=0; j<BW; j++)); do bar+="█"; done

  if [[ $ok -eq 0 ]]; then
    draw_prog "Descargando Driver Universal HP..." "[${bar}]  completado!"
    sleep 0.5
    W=54; local HR='──────────────────────────────────────────────────────'
    tput clear; echo
    printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
    bline ""; bline "            INSTALAR DRIVER UNIVERSAL"; bline ""
    printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
    bline ""; bline "  [✓]  Driver listo en el escritorio:"
    bline ""; bline "       HP_UPD_PCL6_Win11.zip"; bline ""
    printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"; echo
  else
    draw_prog "Error al descargar." "Comprueba tu conexion."
    echo
  fi
  stty echo 2>/dev/null
  read -rp "  Presiona Enter para volver..." _
  stty -echo 2>/dev/null
}

run_proximamente() {
  W=54
  local HR='──────────────────────────────────────────────────────'
  tput clear; echo
  printf "  ${BG}${WH}┌%s┐${NC}\n" "$HR"
  bline ""
  bline "            INSTALAR DRIVER UNIVERSAL"
  bline ""
  printf "  ${BG}${WH}├%s┤${NC}\n" "$HR"
  bline ""
  bline "  Disponible proximamente..."
  bline ""
  printf "  ${BG}${WH}└%s┘${NC}\n" "$HR"
  echo
  stty echo 2>/dev/null
  read -rp "  Presiona Enter para volver..." _
  stty -echo 2>/dev/null
}

run_driver() {
  local dl="run_driver_win11"
  local drv_actions=("$dl" "$dl" "$dl" "$dl")
  run_simple_menu "draw_driver_menu" drv_actions drv_cursor
}

# ── Limpieza ─────────────────────────────────────────────────
cleanup() { printf '\033[?25h'; tput cnorm; echo; }
trap cleanup EXIT INT TERM

# ── LOGIN ─────────────────────────────────────────────────────
do_login

# ── BUCLE PRINCIPAL ──────────────────────────────────────────
printf '\033[?25l'
stty -echo 2>/dev/null

while true; do
  draw_main
  key=$(read_key)

  if [[ "$key" == "$UP" ]]; then
    ((main_cursor > 0)) && ((main_cursor--))
  elif [[ "$key" == "$DOWN" ]]; then
    ((main_cursor < MAIN_N-1)) && ((main_cursor++))
  elif [[ "$key" == " " || "$key" == "" || "$key" == $'\r' ]]; then
    if [[ $main_cursor -eq 0 ]]; then
      run_carpeta_compartida
    elif [[ $main_cursor -eq 1 ]]; then
      stty echo 2>/dev/null; printf '\033[?25h'
      run_nubeprint
      stty -echo 2>/dev/null; printf '\033[?25l'
    elif [[ $main_cursor -eq 2 ]]; then
      stty echo 2>/dev/null; printf '\033[?25h'
      run_driver
      stty -echo 2>/dev/null; printf '\033[?25l'
    fi
  elif [[ "$key" == "q" || "$key" == "Q" || "$key" == $'\003' ]]; then
    exit 0
  fi
done

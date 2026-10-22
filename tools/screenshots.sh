#!/usr/bin/env bash
# Saca capturas de la escena principal en varias situaciones (pantallas,
# paneles, zoom, joystick, cada paso del ciclo de pedidos y las de arte) y las
# deja en build/screenshots/, con manifest.txt (las capturas que se pidieron)
# y budget.csv (lo que costó dibujar el mundo en cada una).
#
# Sirve para revisar la interfaz y el arte sin un teléfono. Necesita xvfb-run
# (una pantalla virtual): en modo headless Godot no dibuja nada.
#
# Uso: tools/screenshots.sh [--only=all|art|char] [--resolution=ANCHOxALTO]
#                           [--quality=auto|high|low] [--locale=en]
#   --only        all (todas, por defecto), art (solo las de arte, con las del
#                 personaje) o char (solo las del personaje).
#   --resolution  tamaño de la ventana, por defecto 720x1280.
#   --quality     nivel de calidad gráfica pedido; queda anotado en budget.csv.
#
# Falla si Godot termina con error, si el registro tiene un error (de script,
# de sombreador o del ejecutor, que avisa con "Capturas:") o si falta alguna
# de las capturas de manifest.txt.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_godot

if ! command -v xvfb-run > /dev/null; then
	echo "Falta xvfb-run (paquete xvfb)." >&2
	exit 1
fi

resolution="720x1280"
runner_args=()
while [[ $# -gt 0 ]]; do
	case "$1" in
		--resolution=*) resolution="${1#--resolution=}" ;;
		--resolution)
			if [[ $# -lt 2 ]]; then
				echo "--resolution necesita un tamaño, por ejemplo 1080x2400." >&2
				exit 1
			fi
			shift
			resolution="$1"
			;;
		--only=* | --quality=* | --locale=*) runner_args+=("$1") ;;
		*)
			echo "Opción desconocida: $1" >&2
			exit 1
			;;
	esac
	shift
done
if [[ ! "$resolution" =~ ^([0-9]+)x([0-9]+)$ ]]; then
	echo "--resolution debe ser ANCHOxALTO, por ejemplo 1080x2400." >&2
	exit 1
fi
# La pantalla virtual tiene que ser más grande que la ventana.
screen="$((BASH_REMATCH[1] + 80))x$((BASH_REMATCH[2] + 120))x24"

out_dir="$ROOT_DIR/build/screenshots"
rm -rf "${out_dir:?}"
mkdir -p "$out_dir"
# Godot no debe importar lo que se genera aquí (capturas, archivos de la web).
touch "$ROOT_DIR/build/.gdignore"
log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT

import_project > /dev/null
set +e
timeout 600 xvfb-run -a -s "-screen 0 $screen" "$GODOT_BIN" --path "$ROOT_DIR" \
	--resolution "$resolution" --rendering-driver opengl3 --audio-driver Dummy \
	-s res://tools/screenshots.gd -- --out="$out_dir" "${runner_args[@]}" 2>&1 | tee "$log_file"
status="${PIPESTATUS[0]}"
set -e

failed=0
if [[ "$status" -ne 0 ]]; then
	echo "screenshots.sh: Godot terminó con el código $status." >&2
	failed=1
fi
# Un error dentro de un escenario no detiene a Godot: se salta el resto de ese
# escenario y el programa termina bien, con menos capturas.
if grep -qE 'SCRIPT ERROR|SHADER ERROR|ERROR:|Capturas:' "$log_file"; then
	echo "screenshots.sh: hay errores en el registro (revisa la salida de arriba)." >&2
	failed=1
fi
manifest="$out_dir/manifest.txt"
expected=0
if [[ ! -s "$manifest" ]]; then
	echo "screenshots.sh: no se escribió manifest.txt." >&2
	failed=1
else
	missing=()
	while IFS= read -r name; do
		[[ -z "$name" ]] && continue
		expected=$((expected + 1))
		[[ -f "$out_dir/$name.png" ]] || missing+=("$name")
	done < "$manifest"
	if [[ ${#missing[@]} -gt 0 ]]; then
		echo "screenshots.sh: faltan capturas: ${missing[*]}" >&2
		failed=1
	fi
	rows=0
	if [[ -f "$out_dir/budget.csv" ]]; then
		rows="$(($(wc -l < "$out_dir/budget.csv") - 1))"
	fi
	if [[ "$rows" -ne "$expected" ]]; then
		echo "screenshots.sh: budget.csv tiene $rows filas y se esperaban $expected." >&2
		failed=1
	fi
fi
count="$(find "$out_dir" -name '*.png' | wc -l)"
if [[ "$failed" -ne 0 ]]; then
	exit 1
fi
echo "Capturas en build/screenshots/ ($count de $expected en manifest.txt, con budget.csv)."

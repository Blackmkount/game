#!/usr/bin/env bash
# Importa el proyecto en modo headless y falla si hay errores en scripts,
# escenas o recursos.
#
# Godot no siempre devuelve un código de error cuando algo falla al importar,
# así que además de revisar el código de salida buscamos líneas de error en la
# salida.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_godot

log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT

# Quita los colores y las líneas de progreso de la importación para que la
# salida sea legible.
filter_output() {
	sed -e 's/\x1b\[[0-9;]*m//g' | grep -vE '^\s*$|^\[ *[0-9]+% \]|^\[ DONE \]' || true
}

set +e
echo "== Importando el proyecto =="
import_project | filter_output | tee "$log_file"
import_status="${PIPESTATUS[0]}"

echo "== Cargando scripts y escenas =="
"$GODOT_BIN" --headless --path "$ROOT_DIR" -s res://tools/check_project.gd 2>&1 \
	| filter_output | tee -a "$log_file"
load_status="${PIPESTATUS[0]}"
set -e

if [[ "$import_status" -ne 0 || "$load_status" -ne 0 ]] \
	|| grep -qE 'SCRIPT ERROR|ERROR:|Parse Error' "$log_file"; then
	echo "check.sh: se encontraron errores (revisa la salida de arriba)." >&2
	exit 1
fi
echo "check.sh: todo en orden."

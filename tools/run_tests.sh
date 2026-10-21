#!/usr/bin/env bash
# Corre todas las pruebas GUT (tests/unit y tests/integration) en modo headless.
# La configuración de GUT está en .gutconfig.json.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_godot

log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT

# GUT necesita el proyecto importado y al día para conocer los class_name.
# Si ya está importado, este paso tarda pocos segundos.
import_project > /dev/null

set +e
"$GODOT_BIN" --headless --path "$ROOT_DIR" -s res://addons/gut/gut_cmdln.gd \
	-gconfig=res://.gutconfig.json 2>&1 | tee "$log_file"
status="${PIPESTATUS[0]}"
set -e

# GUT se salta en silencio los archivos de prueba que no compilan, así que
# también buscamos errores de carga en la salida.
if grep -qE 'SCRIPT ERROR|Parse Error|Failed to load script' "$log_file"; then
	echo "run_tests.sh: hay archivos de prueba con errores (revisa la salida de arriba)." >&2
	exit 1
fi
# Si algo cierra el programa a mitad de las pruebas, GUT no llega a imprimir
# el resumen y el código de salida puede ser 0: sin resumen, es un fallo.
if ! grep -qE '^Totals' "$log_file"; then
	echo "run_tests.sh: las pruebas no terminaron (falta el resumen de GUT)." >&2
	exit 1
fi
exit "$status"

#!/usr/bin/env bash
# Saca capturas de la escena principal en varias situaciones (pantallas,
# paneles, zoom, joystick y cada paso del ciclo de pedidos) y las deja en
# build/screenshots/.
#
# Sirve para revisar la interfaz sin un teléfono. Necesita xvfb-run (una
# pantalla virtual): en modo headless Godot no dibuja nada.
#
# Uso: tools/screenshots.sh [--locale=en]
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_godot

if ! command -v xvfb-run > /dev/null; then
	echo "Falta xvfb-run (paquete xvfb)." >&2
	exit 1
fi

out_dir="$ROOT_DIR/build/screenshots"
rm -rf "${out_dir:?}"
mkdir -p "$out_dir"

import_project > /dev/null
timeout 300 xvfb-run -a -s "-screen 0 800x1400x24" "$GODOT_BIN" --path "$ROOT_DIR" \
	--resolution 720x1280 --rendering-driver opengl3 --audio-driver Dummy \
	-s res://tools/screenshots.gd -- --out="$out_dir" "$@"

count="$(find "$out_dir" -name '*.png' | wc -l)"
if [[ "$count" -eq 0 ]]; then
	echo "No se generó ninguna captura." >&2
	exit 1
fi
echo "Capturas en build/screenshots/ ($count archivos)."

#!/usr/bin/env bash
# Exporta la versión web (preset "Web" de export_presets.cfg) a build/web/.
# Necesita las plantillas web: tools/setup_godot.sh --web-templates
#
# Se exporta sin soporte de hilos para que funcione en GitHub Pages, que no
# permite configurar las cabeceras especiales que exigen los hilos.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_godot

if [[ ! -f "$GODOT_TEMPLATES_DIR/web_nothreads_release.zip" ]]; then
	echo "Faltan las plantillas web. Ejecuta: tools/setup_godot.sh --web-templates" >&2
	exit 1
fi

out_dir="$ROOT_DIR/build/web"
rm -rf "${out_dir:?}"
mkdir -p "$out_dir"

import_project > /dev/null
"$GODOT_BIN" --headless --path "$ROOT_DIR" --export-release "Web" "$out_dir/index.html"

for file in index.html index.js index.wasm index.pck; do
	if [[ ! -f "$out_dir/$file" ]]; then
		echo "La exportación no generó $file" >&2
		exit 1
	fi
done
echo "Versión web exportada en build/web/"

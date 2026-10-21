#!/usr/bin/env bash
# Descarga el Godot oficial para Linux de la versión indicada en .godot-version
# y lo deja en .tools/ (ignorado por git). Si ya está descargado, no hace nada.
#
# Uso:
#   tools/setup_godot.sh                 Solo el ejecutable de Godot.
#   tools/setup_godot.sh --web-templates Además, las plantillas para exportar a web.
#
# Godot queda en "modo autocontenido" (archivo _sc_ junto al ejecutable): su
# configuración y plantillas se guardan dentro de .tools/ y no en la carpeta
# personal del usuario.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

want_templates=false
for arg in "$@"; do
	case "$arg" in
		--web-templates) want_templates=true ;;
		*) echo "Opción desconocida: $arg" >&2; exit 2 ;;
	esac
done

download_dir="$ROOT_DIR/.tools/downloads"
sums_file="$download_dir/SHA512-SUMS-$GODOT_VERSION.txt"

# Descarga un archivo del release y verifica su suma SHA-512 publicada.
download_verified() {
	local name="$1"
	local dest="$download_dir/$name"
	mkdir -p "$download_dir"
	if [[ ! -f "$sums_file" ]]; then
		curl -fsSL --retry 3 -o "$sums_file" "$GODOT_RELEASE_URL/SHA512-SUMS.txt"
	fi
	echo "Descargando $name..."
	curl -fsSL --retry 3 -o "$dest" "$GODOT_RELEASE_URL/$name"
	local expected
	expected="$(awk -v n="$name" '$2 == n || $2 == "*" n { print $1 }' "$sums_file")"
	if [[ -z "$expected" ]]; then
		echo "No encuentro la suma de verificación de $name" >&2
		exit 1
	fi
	if ! echo "$expected  $dest" | sha512sum --check --status; then
		rm -f "$dest"
		echo "La suma de verificación de $name no coincide. Descarga corrupta." >&2
		exit 1
	fi
}

if [[ -x "$GODOT_BIN" ]]; then
	echo "Godot $GODOT_VERSION ya está instalado."
else
	zip_name="Godot_v${GODOT_VERSION}_linux.x86_64.zip"
	download_verified "$zip_name"
	mkdir -p "$GODOT_DIR"
	unzip -q -o "$download_dir/$zip_name" -d "$GODOT_DIR"
	chmod +x "$GODOT_BIN"
	touch "$GODOT_DIR/_sc_"
	rm -f "$download_dir/$zip_name"
	echo "Godot $GODOT_VERSION instalado en ${GODOT_BIN#"$ROOT_DIR"/}"
fi

if [[ "$want_templates" == true ]]; then
	if [[ -f "$GODOT_TEMPLATES_DIR/web_nothreads_release.zip" ]]; then
		echo "Las plantillas web ya están instaladas."
	else
		tpz_name="Godot_v${GODOT_VERSION}_export_templates.tpz"
		download_verified "$tpz_name"
		mkdir -p "$GODOT_TEMPLATES_DIR"
		# Solo extraemos lo necesario para web sin hilos; el paquete completo
		# pesa más de 1 GB.
		unzip -q -o -j "$download_dir/$tpz_name" \
			"templates/version.txt" \
			"templates/web_nothreads_debug.zip" \
			"templates/web_nothreads_release.zip" \
			-d "$GODOT_TEMPLATES_DIR"
		rm -f "$download_dir/$tpz_name"
		echo "Plantillas web instaladas."
	fi
fi

rm -f "$sums_file"
"$GODOT_BIN" --headless --version

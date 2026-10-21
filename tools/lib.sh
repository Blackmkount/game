# Funciones y rutas compartidas por los scripts de tools/.
# No se ejecuta solo: los demás scripts lo cargan con `source`.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/.godot-version")"
GODOT_DIR="$ROOT_DIR/.tools/godot/$GODOT_VERSION"
GODOT_BIN="$GODOT_DIR/Godot_v${GODOT_VERSION}_linux.x86_64"
# Godot busca las plantillas de exportación en una carpeta con la versión
# escrita con punto en lugar de guion: "4.7.2-stable" -> "4.7.2.stable".
GODOT_TEMPLATES_DIR="$GODOT_DIR/editor_data/export_templates/${GODOT_VERSION//-/.}"
GODOT_RELEASE_URL="https://github.com/godotengine/godot-builds/releases/download/$GODOT_VERSION"

require_godot() {
	if [[ ! -x "$GODOT_BIN" ]]; then
		echo "No encuentro Godot $GODOT_VERSION. Ejecuta primero tools/setup_godot.sh" >&2
		exit 1
	fi
}

# Importa el proyecto (crea la carpeta .godot/). Hace falta antes de correr
# scripts o pruebas, porque Godot necesita conocer los class_name del proyecto.
import_project() {
	"$GODOT_BIN" --headless --path "$ROOT_DIR" --import 2>&1
}

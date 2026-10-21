# Decisiones técnicas

Registro de decisiones técnicas importantes: fecha, decisión y motivo. Las más recientes van al final.

---

## 2026-10-21 — Fase 0

### Godot 4.7.2 estable
**Decisión:** usar Godot 4.7.2-stable, fijada en `.godot-version`.
**Motivo:** es la última versión estable publicada en `godotengine/godot-builds` (la 4.8 sigue en beta). Solo se cambia de versión si el dueño lo aprueba.

### GUT 9.7.1 para las pruebas
**Decisión:** GUT 9.7.1 copiado en `addons/gut/` y activado como plugin del editor.
**Motivo:** es la versión de GUT hecha para Godot 4.7.x. Licencia MIT, registrada en `assets/CREDITS.md`. La configuración de las pruebas está en `.gutconfig.json`.

### Godot "autocontenido" dentro de `.tools/`
**Decisión:** `tools/setup_godot.sh` descarga el Godot oficial, verifica su suma SHA-512 contra la publicada en el release y crea un archivo `_sc_` junto al ejecutable.
**Motivo:** con `_sc_`, Godot guarda su configuración y las plantillas de exportación dentro de `.tools/` en lugar de la carpeta personal. Así todo lo descargado vive en una carpeta ignorada por git y la integración continua la puede guardar en caché.

### `check.sh` revisa cada script y escena uno por uno
**Decisión:** `check.sh` importa el proyecto y luego ejecuta `tools/check_project.gd`, que carga cada `.gd`, `.tscn` y `.tres` (excepto `addons/`) y falla si alguno no compila o no se puede instanciar. Además busca líneas `ERROR` en la salida.
**Motivo:** `godot --import` devuelve código de salida 0 aunque haya scripts con errores, así que no basta con mirar el código de salida. `tools/` tiene `.gdignore`, por lo que el script de revisión no entra en el juego exportado.

### `run_tests.sh` falla si un archivo de prueba no compila
**Decisión:** además del resultado de GUT, `run_tests.sh` busca errores de carga de scripts en la salida.
**Motivo:** GUT 9.7.1 se salta en silencio los archivos de prueba con errores de sintaxis y reporta "todo pasó".

### Advertencia de declaraciones sin tipo como error
**Decisión:** `debug/gdscript/warnings/untyped_declaration = Error`. Se mantiene la opción por defecto que excluye `addons/`.
**Motivo:** lo pide `CLAUDE.md`. Se excluye `addons/` porque GUT no está escrito con tipado estático completo y no es código nuestro. `var x := 5` (tipo inferido) sí está permitido.

### Pantalla vertical de 720×1280 con escalado `canvas_items` + `expand`
**Decisión:** resolución base 720×1280, orientación vertical, estiramiento `canvas_items` con aspecto `expand`. La cámara de la escena es ortográfica con `keep_aspect = KEEP_WIDTH`.
**Motivo:** `expand` aprovecha toda la pantalla en teléfonos más altos o más anchos sin bandas negras. Mantener el ancho fijo en la cámara asegura que el cuarto siempre quepa de lado a lado en pantallas verticales.

### Traducciones: archivos `.translation` en el repositorio e idioma de respaldo español
**Decisión:** se suben a git los `localization/*.translation` que Godot genera desde `translations.csv`. El idioma de respaldo es `es`.
**Motivo:** sin ellos, la primera importación en una copia nueva (por ejemplo en la integración continua) muestra errores de "archivo no encontrado" antes de generarlos. Godot los regenera solo cuando cambia el CSV. El idioma del juego se elige según el del dispositivo; si no hay traducción para ese idioma, se usa español, que es el idioma principal.

### Exportación web sin hilos y con compresión de texturas para móvil
**Decisión:** preset "Web" con `thread_support = false` y compresión de texturas activada para escritorio (S3TC/BPTC) y para móvil (ETC2/ASTC). Se excluyen `tests/` y `addons/gut/` del paquete.
**Motivo:** sin hilos no hacen falta las cabeceras especiales (COOP/COEP) que GitHub Pages no permite configurar. La versión web se abrirá desde teléfonos, que necesitan ETC2/ASTC. Excluir las pruebas reduce el tamaño de la descarga.

### Publicación en GitHub Pages condicionada
**Decisión:** el workflow web siempre exporta, pero solo publica si GitHub Pages está activado en el repositorio. Si no lo está, deja un aviso en el resumen de la ejecución en lugar de fallar.
**Motivo:** el repositorio es privado y, en el plan gratuito de GitHub, Pages solo funciona en repositorios públicos. Así `main` no se pone en rojo mientras se decide cómo publicar.

### Actions fijadas por hash de commit
**Decisión:** todas las actions de los workflows (también las oficiales `actions/*`) se fijan por el hash del commit, con la versión en un comentario.
**Motivo:** `CLAUDE.md` lo exige para las de terceros; aplicarlo a todas es más seguro y evita cambios inesperados. Para actualizar una action hay que cambiar el hash a mano.

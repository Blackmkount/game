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

### Repositorio público
**Decisión:** el dueño hizo público el repositorio.
**Motivo:** es la forma gratuita de publicar la versión web en GitHub Pages.
**Consecuencias:**
- Todo lo que se sube es visible para cualquiera. Ya era regla no subir secretos; ahora es aún más importante.
- Sin un archivo `LICENSE`, el código queda con "todos los derechos reservados": se puede ver, pero nadie puede reutilizarlo legalmente sin permiso.
- Cualquiera puede abrir un PR desde un fork. El workflow de validación corre esos PR sin acceso a secretos (comportamiento por defecto de `pull_request`). Cuando haya secretos (Fase 4), los workflows que los usen no deben ejecutarse con `pull_request_target` ni con código de forks.

---

## 2026-10-21 — Fase 1, tarea 1: diseño v2 y datos de balance

### Nombres ficticios inspirados en productos reales
**Decisión:** el dueño pidió impresoras como "Bambu Lab A1, P1S" y "Ender 3", y paneles "SKÅDIS". En el juego se usan nombres ficticios (Rayo X1, Bóveda P1, Cubo Uno, panel perforado...) con los precios y características de esos productos. La correspondencia está en `docs/REFERENCIAS.md`.
**Motivo:** `CLAUDE.md` y el GDD prohíben marcas reales, y con razón: Google Play y la App Store pueden rechazar o retirar un juego si el dueño de una marca reclama. Los datos de `data/` solo contienen nombres ficticios porque se incluyen en el juego exportado.

### Calendario de juego: 1 día = 1 hora real
**Decisión:** el tiempo del juego corre 24 veces más rápido que el real (`config.time.game_seconds_per_real_second = 24`). Las duraciones de `data/` están en minutos y días de juego.
**Motivo:** el dueño pidió envíos de 3 a 7 días. Con días reales serían esperas de una semana; con este calendario son de 3 a 7 horas reales, y llegan entre una sesión y la siguiente. Además, las duraciones de impresión pueden ser realistas: un llavero tarda 20 minutos de juego, es decir, 50 segundos reales. El valor se ajustará con el simulador.

### Formato de los datos
**Decisión:** un archivo JSON por tipo de dato (`config`, `levels`, `materials`, `printers`, `accessories`, `furniture`, `spaces`, `clients`, `orders`). Los nombres de los campos están en inglés, como el código. Los ids de contenido siguen los del GDD (`cubo_uno`, `llavero`...). Cada elemento tiene una `name_key` para su nombre traducido.
**Motivo:** archivos pequeños y fáciles de editar a mano. Godot lee todos los números de JSON como decimales, así que el código los convierte a entero donde corresponde.

### Validación de datos en `core/data/`
**Decisión:** `DataCatalog` lee los archivos y `DataValidator` revisa campos obligatorios, tipos, rangos y referencias entre archivos. También revisa que cada `name_key` exista en `translations.csv` y que cada pedido lo pueda imprimir alguna impresora. Las pruebas `test_data_files.gd` y `test_data_validator.gd` lo cubren.
**Motivo:** `CLAUDE.md` exige una prueba que valide todos los JSON. Hacer el validador una clase de `core/` permite usarlo también al iniciar el juego.

### Los datos se incluyen explícitamente en la exportación
**Decisión:** el preset Web tiene `include_filter = "data/*.json"`.
**Motivo:** garantiza que los JSON viajen en el paquete del juego aunque Godot no los considere recursos. Se verificó que `index.pck` los contiene.

---

## 2026-10-21 — Adelanto de la Fase 2: estilo visual y escena inicial

### Pixel art hecho con 3D a media resolución
**Decisión:** el estilo pixel art de la imagen de referencia se logra con el mismo mundo 3D de formas básicas, dibujado en un `SubViewport` a la mitad de la resolución con filtro `NEAREST`, sombreado por bandas (`DIFFUSE_TOON`), sombras duras y un contorno de 1 píxel.
**Motivo:** pasar a pixel art 2D dibujado a mano obligaría a dibujar cada objeto en varias poses y ángulos, sin un artista en el equipo. Con esta técnica, cualquier objeto nuevo armado con `PropBuilder` sale automáticamente en el mismo estilo, se puede animar (la pieza que "crece" capa a capa) y se conserva la arquitectura 3D de `CLAUDE.md`. Además, dibujar a media resolución es más liviano para los teléfonos de gama baja.

### Contorno con "inverted hull"
**Decisión:** el contorno se dibuja con una segunda pasada de material (`outline.gdshader`) que agranda la forma y pinta solo su cara trasera.
**Motivo:** un contorno por posprocesado necesitaría texturas de profundidad y de normales que el renderizador Compatibility no ofrece completas. Esta técnica funciona en web y en móviles de gama baja. A cambio, cada objeto se dibuja dos veces; para una habitación de unas 100 piezas es aceptable. Más adelante se puede usar `MultiMesh` si hace falta.

### Texturas pixel art generadas por código
**Decisión:** madera, ladrillo, ventana y pantallas se generan en `PixelTextures` con una paleta fija y azar con semilla fija.
**Motivo:** no hacen falta archivos de imagen ni licencias, todas siguen la misma paleta y salen idénticas en cada ejecución.

### Interfaz armada por código con un tema común
**Decisión:** la interfaz se construye por código con `UiTheme` (colores, paneles, botones, barras) y `UiKit` (atajos). No se usan escenas `.tscn` para cada pantalla.
**Motivo:** garantiza que todas las pantallas usen exactamente el mismo estilo, es más fácil de revisar en un PR y se puede probar con GUT. La escena principal (`main.tscn`) solo define la estructura: la vista 3D y el HUD.

### Tipografía Nunito
**Decisión:** se usa Nunito (SIL Open Font License 1.1), una sola familia con dos pesos.
**Motivo:** es redondeada y muy legible en pantallas pequeñas, parecida a la de la referencia, y su licencia permite incluirla en un juego comercial. Está registrada en `assets/CREDITS.md`.

### Sin gemas
**Decisión:** el lugar que en la referencia ocupan las gemas lo ocupa la fecha del calendario del juego.
**Motivo:** el GDD (sección 11) descarta la moneda premium. La fecha además es útil, porque los envíos se cuentan en días.

### Dinero en centavos
**Decisión:** `GameState.money_cents` guarda el dinero como entero en centavos.
**Motivo:** con multiplicadores como "50% del pago por entrega tardía" o "ferretería 50% más cara" aparecen centavos. Los enteros evitan errores de redondeo acumulados.

### Estado mínimo de la partida adelantado
**Decisión:** se adelantó parte de la tarea 2 de la Fase 1 (`GameState`, `GameClock`, `LevelTable`, `Simulation` solo con el reloj, `WorkshopRules`) para que la interfaz muestre datos reales y no inventados.
**Motivo:** la interfaz lee siempre del autoload `Game`, como pide la arquitectura. Cuando lleguen la tienda y los pedidos, la interfaz no tendrá que cambiar de fuente.

### La escena principal reemplaza a la de prueba
**Decisión:** se borró la escena de prueba de la Fase 0 (`test_scene`) y su prueba. La escena principal ahora es `game/scenes/main.tscn`.
**Motivo:** la escena de prueba solo servía para comprobar la versión web, y ya cumplió su función.

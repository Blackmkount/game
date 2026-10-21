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

---

## 2026-10-21 — Ruta de desarrollo y Fase 1, tarea 2: controles del mundo

### Ruta de desarrollo aprobada
**Decisión:** el orden de trabajo vive en `docs/RUTA.md`, con 8 fases (0 a 7). La sección 15 del GDD solo resume y apunta ahí.
**Motivo:** el dueño la aprobó. La ruta reorganiza la Fase 1 para que cada tarea traiga lógica, interfaz y respuesta visual juntas, y se pueda probar en el teléfono después de cada PR.

### Joystick, con la regla de que caminar nunca es obligatorio
**Decisión:** el personaje se maneja con un joystick flotante (elección del dueño). Tocar un objeto abre su panel al instante, tocar el piso hace caminar al personaje y toda la información y las decisiones se pueden tomar sin caminar.
**Motivo:** el joystick da vida, pero en un juego de gestión de sesiones cortas, obligar a caminar para leer o decidir sería tedioso con muchas impresoras. También chocaría con el progreso fuera del juego. Tres críticos independientes (ergonomía móvil, juegos con joystick y técnica en Godot) coincidieron. La regla quedó en el GDD (sección 7.1).

### La entrada del mundo es un Control entre la vista y el HUD
**Decisión:** `WorldControls` es un Control de pantalla completa con `MOUSE_FILTER_STOP`, puesto entre la vista del mundo y el HUD. Recibe los toques en `_gui_input`.
**Motivo:**
- Con `_unhandled_input`, los arrastres se pierden cuando el dedo pasa sobre un botón del HUD (comprobado en Godot 4.7.2).
- Con un Control, Godot sigue mandando los arrastres de cada dedo al Control donde empezó.
- El HUD, que va encima, se queda con los toques sobre sus botones.

### Eventos de mouse inventados al tocar
**Decisión:** `WorldControls` ignora los eventos de mouse con `device == InputEvent.DEVICE_ID_EMULATION` y trata al mouse real como un dedo más (índice reservado).
**Motivo:** al tocar la pantalla, el sistema también genera un clic de mouse. Sin el filtro, cada toque contaría dos veces. Una prueba de integración lo verifica con `Input.parse_input_event`, que sí genera esos clics (`Viewport.push_input` no los genera).

### Sin motor de física
**Decisión:** el personaje es un círculo que se empuja fuera de los rectángulos de los muebles (`WalkGrid`). Los caminos se buscan con `AStarGrid2D` y se seleccionan objetos con un rayo contra cajas (`AABB.intersects_ray`, ver "Qué objeto se toca").
**Motivo:**
- En un cuarto de 6×6 m con pocos objetos es simple, rápido y se puede probar con GUT.
- Empujar desde el punto más cercano hace que las esquinas se comporten como redondeadas, así que el personaje no se traba.
- El movimiento se reparte en pasos cortos, para que un cuadro largo (pestaña del navegador en segundo plano) no atraviese nada.

### Cajas de los modelos calculadas con las medidas de las formas
**Decisión:** `PropBounds` calcula la caja de cada modelo con `BoxMesh.size`, `CylinderMesh.radius`, etc., y no con `get_aabb()`.
**Motivo:** sin pantalla (pruebas en modo headless) las mallas no tienen tamaño y `get_aabb()` devuelve cajas vacías.

### Cámara que sigue, con tres niveles de zoom
**Decisión:** `CameraRig` sigue al personaje con suavizado exponencial y no se sale del cuarto. Los niveles de zoom son 0,68×, 1× y 2×.
**Motivo:**
- La vista normal (6,8 m de ancho) no muestra el cuarto entero de lado a lado: mide 8,5 m en diagonal. En teléfonos alargados la puerta quedaba fuera de la pantalla.
- El nivel "lejos" (unos 10 m) muestra todo el cuarto.
- Se mantuvo la vista normal de siempre porque el personaje se lee mejor así.

### Píxeles enteros para la cámara y el personaje, y la imagen se corre lo que falta
**Decisión:**
- La cámara y el personaje se colocan en píxeles enteros del dibujo a media resolución. El personaje se corre a lo largo de la mirada de la cámara para seguir apoyado en el piso.
- La fracción de píxel que falta para la posición exacta se compensa corriendo la imagen de la vista del mundo, que es 4 px más grande que la pantalla por cada lado. El corrimiento usa el desplazamiento solo visual de Godot 4.7 (`offset_transform_position` con `offset_transform_visual_only`), porque Godot redondea a píxeles enteros la posición de los Controls.
**Motivo:** si solo la cámara se ajusta a los píxeles, el personaje tiembla un píxel contra la habitación. Si nada se ajusta, los bordes del pixel art "titilan" al moverse. Así no hay temblor y el movimiento se ve suave.

### Sombra ortogonal
**Decisión:** la luz del sol usa `SHADOW_ORTHOGONAL` con 20 m de alcance.
**Motivo:** con la cámara en movimiento, el modo por defecto (4 divisiones) recalcula sus divisiones cada cuadro y los bordes de las sombras tiemblan. Además, dibuja las sombras cuatro veces.

### Valores de sensación en código, no en `data/`
**Decisión:** velocidades, distancias del joystick y suavidad de la cámara viven en `ControlsTuning` (`game/world/input/`). El dueño los probó en su teléfono con unos deslizadores temporales en Ajustes y fijó: caminar a 2,2 m/s, recorrido del joystick de 60 px, suavidad de la cámara de 0,10 s y distancia para resaltar de 0,60 m. Después los deslizadores se quitaron.
**Motivo:** no son números de balance: no cambian la simulación ni la economía. Claude no puede jugar, así que el dueño los ajusta en el teléfono y avisa qué valores se sienten mejor. Esos valores pasan después al código.

### Panel inferior que crece hacia arriba
**Decisión:**
- `BottomSheet` se ancla abajo y crece hacia arriba desde su borde inferior (`grow_vertical = GROW_DIRECTION_BEGIN`), con el borde de arriba igual al de abajo. Así su alto siempre es el que pide su contenido.
- La entrada, la salida y el arrastre para cerrarlo solo mueven el dibujo (desplazamiento visual) y lo funden.
**Motivo:** en Godot, el alto de un texto con salto de línea depende de su ancho, que vale 0 hasta que los contenedores se acomodan. Ese acomodo puede llegar después del primer cuadro; en los teléfonos de 90 o 120 Hz pasa a menudo. Medir el alto una sola vez dejaba a veces un panel de miles de píxeles.

### Qué objeto se toca
**Decisión:** se busca en tres pasos, y el primero que encuentra algo gana:
1. Un rayo contra la caja de cada objeto, girada con el modelo (no la caja alineada con el mundo, que en un objeto girado es más grande).
2. El mismo rayo con 8 cm de margen alrededor de cada caja.
3. Los objetos que en la pantalla miden menos de 88 px (de la interfaz) se agrandan hasta esa medida alrededor de su centro. Las marcas de lugares libres del piso y los objetos grandes no se agrandan.

**Motivo:**
- En la partida nueva, la impresora del suelo está girada 25° delante del lugar libre 2. Con su caja alineada al mundo y el margen, tocar ese lugar abría casi siempre la impresora. Ahora gana lo que está justo bajo el dedo, y el margen solo ayuda cuando el dedo no cae sobre nada. Una prueba toca cientos de puntos de los lugares libres.
- 88 px es más o menos la yema del pulgar en un teléfono; el personaje y la puerta, vistos de lejos, son más chicos que eso.
- Las marcas del piso son planas y anchas: su rectángulo en la pantalla cubría mucho piso vacío, y tocar el piso para caminar abría el panel del lugar libre.

### Preferencias del jugador aparte de la partida
**Decisión:** qué pistas ya vio el jugador se guarda en `user://settings.cfg` (`UserSettings`), no en la partida.
**Motivo:** no es estado del juego y no debe cambiar la simulación ni sus migraciones.

### Botón "atrás" de Android
**Decisión:** `get_tree().quit_on_go_back = false`. "Atrás" cierra el panel abierto, después la sección abierta, y recién entonces sale del juego.
**Motivo:** por defecto, Godot cierra la app con "atrás".

### `JoystickRing` y no el `VirtualJoystick` de Godot
**Decisión:** el joystick se dibuja con un Control propio (`JoystickRing`) y los gestos los interpreta `TouchTracker`.
**Motivo:** Godot 4.7 trae una clase `VirtualJoystick`, por eso el nombre. Se usa una propia porque el mismo dedo puede ser un toque, el joystick o parte de un pellizco, y eso lo decide `TouchTracker` en un solo lugar, con pruebas. Además, el aro sigue al dedo y respeta el estilo de `docs/ESTILO.md`.

### Capturas automáticas en dos pasos
**Decisión:** `tools/screenshots.gd` solo arranca y carga `tools/screenshot_runner.gd`, que arma la escena y saca las capturas.
**Motivo:** el guion que se pasa con `-s` se compila antes de que existan los autoloads (`Game`, `Events`), y las clases del juego que los usan no compilan en ese momento.

### `run_tests.sh` exige el resumen de GUT
**Decisión:** además del código de salida, `run_tests.sh` falla si el registro de GUT no trae la línea `Totals`.
**Motivo:** si una prueba cierra el juego antes de tiempo (por ejemplo, el botón "atrás" en la última pantalla), Godot sale con código 0 y nadie se entera de las pruebas que no corrieron. Por eso el cierre del juego en `WorldControls` pasa por `quit_game`, que las pruebas reemplazan.

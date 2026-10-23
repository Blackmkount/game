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

---

## 2026-10-22 — Ciclo de pedidos: del mensaje a la puerta

### El ciclo de pedidos antes que la navegación, el guardado y la tienda
**Decisión:** se hizo el ciclo completo (tareas 6 y 7 de la Fase 1) antes de las tareas 3 a 5. Se adelantaron solo las partes necesarias: el guardado automático y el azar guardado (de la tarea 4) y la ferretería (de la tarea 5).
**Motivo:** lo pidió el dueño. Sin guardado, el ciclo se perdería en cada recarga de la página. Sin la ferretería, el jugador se quedaría sin material antes de que exista la tienda.

### Reloj de segundos de juego enteros
**Decisión:** la partida cuenta segundos de juego enteros (`game_seconds`) y, aparte, los segundos que pasaron con el juego abierto (`live_seconds`), que se usan para los plazos. `game_minutes` queda como lectura para el HUD y `GameClock`. La fracción de segundo que sobra en cada cuadro no se guarda.
**Motivo:** con enteros, avanzar 8 horas de un golpe da exactamente lo mismo que en miles de pasos pequeños. Una prueba lo comprueba comparando el estado completo, con fallos, piezas terminadas, modelos y mensajes en el medio. Con números decimales, una diferencia mínima podía cambiar el orden de dos eventos.

### Dos flujos de azar y cuántos números se sacan
**Decisión:** el tablero de pedidos y los fallos usan dos generadores distintos, los dos con la semilla de la partida. Cada vez que toca un mensaje nuevo se saca exactamente 1 número del primero, y al empezar cada pieza, exactamente 2 del segundo (si falla y en qué punto), aunque sea una pieza de regalo. Los comandos del jugador no sacan ninguno. El estado de los generadores se guarda como texto.
**Motivo:** así aceptar o rechazar mensajes nunca cambia si una pieza va a fallar (no se puede "volver a tirar los dados"), y el resultado no depende de en qué orden se tocaron las cosas. Se guarda como texto porque es un número de 64 bits que el JSON no guarda exacto.

### Simulación por eventos
**Decisión:** `Simulation` busca el próximo evento (una pieza que termina o falla, un modelo listo, un mensaje nuevo) y salta hasta él. Los eventos del mismo segundo se procesan en orden fijo: impresoras por uid, después el computador y después el tablero. Cada evento programa el siguiente desde su propia hora, no desde "ahora". Si no hay evento en el cuadro, el avance es una suma.
**Motivo:** así es exacto y rápido: 8 horas con 40 impresoras tardan unos 6 ms en una computadora, y la prueba pide menos de 20 ms. `SimRules` convierte los datos a enteros una sola vez para que el avance no arme diccionarios.

### Material apartado al empezar a imprimir
**Decisión:** al empezar un pedido se aparta del carrete el material de todas sus piezas. Si una pieza falla, vuelve al carrete lo que no se llegó a imprimir. Por ahora no se puede empezar sin material suficiente.
**Motivo:** ninguna impresión puede quedarse esperando material, y una prueba verifica que los gramos nunca aparecen ni desaparecen. Quedarse sin filamento a mitad de pieza, con el sensor, llega con la tarea 8.

### Se cobra al despachar
**Decisión:** el pago y la experiencia llegan al tocar Despachar, sin tiempo de viaje. El plazo se revisa en ese momento. La forma de entrega de cada cliente es solo texto.
**Motivo:** cobrar debe sentirse muy bien y al instante (GDD 7.2). Un viaje con tiempo agregaría una espera que no se decide ni se juega.

### Modelar empieza solo
**Decisión:** al aceptar, el computador empieza a modelar el pedido, uno a la vez y en fila, mientras las impresoras imprimen. "Concentrarse" es opcional y se puede apagar en los datos (`design.focus_multiplier = 1.0`).
**Motivo:** modelar no tiene una decisión que tomar, así que no pide un toque. Así el paso existe y se ve, pero no frena.

### Rincón de despacho fijo
**Decisión:** el rincón de despacho es un objeto propio del cuarto (`WorldInteractable.Kind.DISPATCH`, `RoomLayout.dispatch_spot`), no un mueble que ocupa un lugar. Embalar y despachar pasan ahí para todos los pedidos a la vez.
**Motivo:** no le quita lugares al jugador y deja libres el paso por la puerta y el lugar donde llegarán las cajas de la tienda (tarea 5).

### Guardado mínimo
**Decisión:** `SaveManager` guarda en `user://save.json` un sobre con `version`, un número de guardado (`save_seq`) y la partida. Escribe primero un archivo temporal y lo renombra; al cargar elige el más nuevo entre los dos. Un archivo roto se renombra a `.bad`; uno de una versión más nueva no se carga ni se pisa. Guarda después de cada comando, cada 10 segundos y al perder el foco o cerrar. Mientras el juego está cerrado el tiempo no pasa, y un cuadro largo (pestaña escondida) avanza como mucho 1 segundo.
**Motivo:** son las reglas de `CLAUDE.md` para el guardado. El progreso fuera del juego, con la protección contra cambios de reloj, es la tarea 9. Al cargar, `SaveCodec` revisa cada valor (`SaveReader`) y repara o descarta lo que no cuadra en lugar de fallar.

### El guardado nunca corre en las pruebas ni en las herramientas
**Decisión:** `RunMode.is_tool_run()` reconoce cuándo Godot se abrió para una herramienta: con `-s` o `--script` (`run_tests.sh`, `check.sh` y capturas) o con una escena de `res://addons/gut/` (el panel de GUT del editor). En ese caso `SaveManager` no guarda ni carga, y las preferencias van a `user://tool_settings.cfg` en lugar de `user://settings.cfg`. Las pruebas de integración reinician la partida con `Game.reset_game(<semilla>)` antes de cada prueba.
**Motivo:** así ninguna prueba toca la partida ni las preferencias reales del jugador, y todas empiezan igual. GUT no acepta argumentos propios, por eso se miran los argumentos con que se abrió Godot. Mirar solo `-s` dejaba afuera al panel del editor, que habría pisado la partida del dueño al correr las pruebas desde ahí.

### Las señales se avisan desde una copia
**Decisión:** `Game` junta los cambios de cada comando o avance en `SimChanges` y los avisa en un orden fijo. Antes de avisar, cambia el acumulador por uno nuevo.
**Motivo:** si algo que escucha una señal ejecuta otro comando (por ejemplo, encadenar paneles), sus cambios van al acumulador nuevo y no se avisan dos veces.

### Los botones usan la misma revisión que los comandos
**Decisión:** cada comando tiene una función que revisa si se puede hacer (`OrderBoard.check_accept`, `PrintRules.check`, `PrintFlow.check_retry`...). La interfaz la usa para apagar el botón y mostrar el motivo exacto, y el comando usa la misma antes de cambiar nada.
**Motivo:** nunca hay un botón encendido que falle al tocarlo, y una prueba compara que el plan y el comando den el mismo motivo.

### Los paneles se rearman al final del cuadro
**Decisión:** cuando cambia la partida, el panel o la pantalla abierta (Pedidos, Inventario...) se rearma una sola vez al final del cuadro, nunca dentro del botón que se tocó. Si hay un dedo sobre uno de sus botones (`UiKit.held_button`), espera a que lo suelte. Las barras y cuentas regresivas se actualizan en su lugar, una vez por segundo.
**Motivo:** rearmar dentro del botón tocado lo borraría mientras Godot lo usa, y rearmar con el dedo encima perdería el toque.

### Burbujas de estado oscuras
**Decisión:** las burbujas sobre las impresoras, el computador y el rincón son oscuras (`PillPanel`), no de papel claro.
**Motivo:** `docs/ESTILO.md` reserva el papel claro para cuando habla alguien, y los iconos cian, verdes y dorados casi no se ven sobre papel claro.

### Pieza más grande que la real
**Decisión:** la pieza que crece en la impresora es un bloque de 0,12 a 0,24 m según el tamaño del pedido, y crece en escalones de un píxel de pantalla.
**Motivo:** un llavero real mide unos 4 cm y se vería como un punto (en `docs/ESTILO.md`, 1 píxel son unos 3 cm). Se agrandó el modelo cambiando el tamaño de la malla, no la escala del nodo, para que el contorno no se deforme.

### La ferretería cobra por gramo
**Decisión:** la ferretería cobra el precio del material por gramo, un 50% más caro.
**Motivo:** así lo dice el GDD (5.6). Hoy vende carretes de 1 kg, así que da $27 por PLA y $30 por PETG, pero si cambia el tamaño en los datos, el precio sigue siendo justo.

### El material apartado ocupa lugar en el almacén
**Decisión:** el espacio usado del almacén suma el material de los carretes y el que está apartado para las piezas que faltan imprimir (`WorkshopRules.reserved_grams`). La ferretería y la barra de Inventario usan esa suma.
**Motivo:** el material apartado vuelve al carrete si una pieza falla. Si no contara, se podía comprar hasta llenar el almacén y después, con un fallo, pasarse del límite.

### Guardar antes de salir con "atrás"
**Decisión:** el botón "atrás" de Android guarda la partida antes de cerrar el juego.
**Motivo:** cerrar desde el juego (`get_tree().quit()`) no avisa a `SaveManager` como cuando el sistema cierra la app, y se podían perder hasta los últimos 10 segundos de partida (el guardado automático).

## 2026-10-22 — Arte 2.0, paso 1: guardas antes de tocar el arte

### Prueba de presupuesto de dibujo
**Decisión:** `tests/integration/test_scene_budget.gd` arma la escena principal (semilla 1234, `Game.set_process(false)`) y mide `Main/WorldView/SubViewport/Room` con `tests/helpers/scene_budget.gd` en dos cuartos: el de la partida nueva y el más cargado de hoy (`tests/helpers/full_room.gd`: escritorio, impresora del piso y 5 estanterías metálicas con 3 impresoras cada una, de todas las familias del catálogo). Revisa llamadas de dibujo, triángulos de la pasada de color y con la pasada de sombra, materiales distintos, mallas que dan sombra, superficies transparentes, que haya exactamente 1 `DirectionalLight3D` (la única luz, y la única con sombra), 0 `OmniLight3D` y 0 `SpotLight3D`, y que no haya nada visible que la medida no sepa contar (`Label3D`, partículas, `material_overlay`, `transparency` en una malla, un `SubViewport` anidado...). Las luces y lo que no se sabe medir se revisan en todo el `SubViewport`, no solo en `Room`, y lo que se dibuja en el `SubViewport` tiene que ser lo mismo que lo medido en `Room` (así nada escapa a los topes poniéndolo al lado de `Room`). Imprime con `gut.p()` un desglose por cada hijo de `Room`.
**Medido hoy:** cuarto inicial 334 llamadas (188 de color y 146 de sombra), 4.266 triángulos en color y 8.028 con la sombra, 35 materiales, 75 mallas con sombra y 34 transparentes. Cuarto lleno: 1.042 llamadas, 11.384 / 22.624 triángulos, 41 materiales, 269 mallas con sombra y 4 transparentes.
**Topes:** llamadas 345 (inicio, el tope del plan) y 1.146 (lleno: lo medido más 10 %, por debajo de los 1.240 del plan, que se calcularon con las impresoras más pesadas); materiales, mallas con sombra y transparentes del inicio, lo medido más 10 %. Los de triángulos ya son los finales de la biblia de arte (45.000 / 60.000 en color, 80.000 / menos de 100.000 con la sombra), y el de transparentes del cuarto lleno es el final del inicial (12), porque sin lugares libres no hay marcas. Cada paso de Arte 2.0 baja los topes a lo medido más un 10 %, nunca por encima del tope anterior.
**Motivo:** las llamadas de dibujo son el límite real en un teléfono de gama baja y en WebGL2, no los triángulos (hoy hay 8 a 20 veces margen). Medir antes de cambiar el arte deja comparar cada paso. La medida corre sin pantalla en 1 ms y coincide con lo que cuenta OpenGL: con todo el cuarto a la vista, 334 y 1.042 llamadas en los dos casos (`build/screenshots/budget.csv`, capturas 30 y 37). Una prueba aparte (`tests/unit/test_scene_budget_helper.gd`) fija las reglas con las que cuenta: cada `next_pass` es otra llamada, lo transparente no da sombra, un `MultiMesh` es una llamada, cada corte de la sombra del sol dibuja otra vez lo que da sombra, los sombreadores se leen con sus `#include` (todos sus `render_mode`) y un `BaseMaterial3D` con refracción, desvanecer por cercanía o desvanecer por distancia con alfa va a la pasada transparente (recorte, hash y tramado siguen opacos).
**Nota:** el contador de OpenGL de "primitivas de sombra" también suma las superficies transparentes que no dibuja (408 triángulos de más en el cuarto inicial: las 5 marcas de lugar libre y el marco de resalte). Las llamadas coinciden exactas, por eso la prueba cuenta solo lo que de verdad se dibuja.

### Las capturas fallan cuando algo sale mal
**Decisión:** `tools/screenshot_runner.gd` escribe `manifest.txt` con los nombres de las capturas pedidas antes de empezar, y una fila de `budget.csv` por captura (llamadas y primitivas de OpenGL del mundo, la estimación sin pantalla y el total del cuadro con la interfaz). `tools/screenshots.sh` falla si Godot termina con error, si el registro tiene `SCRIPT ERROR`, `SHADER ERROR`, `ERROR:` o `Capturas:`, si falta alguna captura del manifiesto o si `budget.csv` no tiene una fila por captura. Opciones nuevas: `--only=all|art|char`, `--resolution=ANCHOxALTO` (se pasa al motor; la pantalla virtual crece con ella) y `--quality=auto|high|low` (por ahora solo queda anotada en `budget.csv`: el juego tiene un solo nivel de calidad).
**Motivo:** un error dentro de un escenario no detenía a Godot: se saltaba el resto del escenario y la herramienta terminaba "bien" con menos capturas (se comprobó: con un error puesto a propósito ahora falla y nombra las que faltan). Además, los errores de los sombreadores en OpenGL solo aparecen al dibujar de verdad, y desde el paso 3 el arte usa sombreadores propios: buscar `ERROR:` en el registro los atrapa.

### Las capturas mueven el mundo con paso fijo
**Decisión:** el ejecutor de capturas apaga `WorldControls.set_process(false)` y llama él mismo a `_process(1.0 / 60.0)` en cada cuadro, sin cambiar el código del juego. En las capturas de arte, la cámara sigue un punto fijo y el ejecutor llama a `RoomView.step(1.0 / 60.0)`.
**Motivo:** con llvmpipe un cuadro tarda mucho más que en un teléfono, así que con el tiempo real el personaje caminaba de más: en 04 a 06 terminaba contra la pared del fondo, lejos de la impresora. Con paso fijo camina lo mismo en cada corrida y queda junto a la impresora. Para 04 y 05 el personaje empieza en (−1,1; 0,35) y camina en línea recta 1,27 m hasta (−1,1; −0,92), junto a la impresora: más que el metro que pide la primera pista ("Arrastra el dedo para caminar"), así 05 muestra la segunda ("Toca un objeto para verlo") y las capturas siguientes salen sin pistas, como antes. Lo que todavía cambia unos píxeles entre corridas son animaciones con tiempo real (el latido de las marcas de lugar libre, el marco de resalte y las de la interfaz); el personaje y la cámara salen iguales.

### Ninguna prueba existente cambió
**Decisión:** este paso solo agrega pruebas (15). Las 505 de antes siguen igual.

## 2026-10-22 — Arte 2.0, paso 2: adiós al pixel art

### El mundo se dibuja a resolución alta, con MSAA y sin ajuste a píxeles
**Decisión:** el dueño aprobó dejar el pixel art por "Mundo Impreso" (D1: "puedes cambiar el estilo gráfico... total libertad"). `Main/WorldView` tiene el script nuevo `WorldViewport` (`game/world/world_viewport.gd`): el dibujo del mundo tiene el ancho físico de la pantalla, con un tope de 1.080 px (nivel Alto; los niveles de calidad llegan en el paso 15). Con k = ancho interno / 720, el contenedor mide la pantalla × k, se dibuja con escala 1/k y filtro lineal, `stretch_shrink = 1`, y el `SubViewport` lleva MSAA 4× (no hereda el del proyecto). En un teléfono de 1.080 px un píxel del mundo es un píxel físico; en uno de 1.440 se dibuja a 1.080 y se estira. Las cuentas de `WorldControls` entre la interfaz y el dibujo pasan por `view_per_ui` (k), `WorldViewport.ui_to_view()` y `view_to_ui()`. Se borraron el ajuste a píxeles de la cámara (`CameraRig._apply` redondeaba y guardaba `pixel_remainder`), el del personaje (`RoomView._snap_to_pixels`), el corrimiento de la imagen (`WorldControls._apply_pixel_shift` y el desplazamiento visual del contenedor) y los 4 px de margen de `main.tscn`. Las vistas 3D de la interfaz (`ModelPreview`) también se dibujan sin achicar, con filtro lineal y MSAA 4×.
**Motivo:** a la mitad de la resolución, estirado con píxeles nítidos, el mundo nunca iba a verse "como un juego caro": las columnas de píxeles salían desparejas (3; 3,25; 3,57 veces según el teléfono) y no había suavizado de bordes. Un ancho interno fijo por nivel deja el costo controlado aunque el teléfono tenga 1.440 px. MSAA es el único suavizado que existe en el renderizador Compatibility (FXAA solo da un aviso).

### Sombras suaves y más finas
**Decisión:** `project.godot`: sombra del sol con filtro suave de calidad 2 (también en móvil), mapa de 2.048 en todas las plataformas y sin mapa de sombras para luces de punto o de foco (`positional_shadow/atlas_size = 0`; el `SubViewport` del mundo y los de las vistas previas también lo ponen en 0, porque no heredan el ajuste del proyecto). La cámara ve de 11 a 30 m (`CameraRig.NEAR` / `FAR`, antes 5 y 35): el cuarto queda entre unos 15,5 y 28,5 m. La cámara publica `meters_per_pixel()` (lo usará el sombreador desde el paso 3).
**Motivo:** con la cámara ortográfica el mapa de sombra cubre de `near` a `far`; acotarlo al cuarto deja cada texel de sombra ~1,6 veces más chico. A resolución alta, las sombras duras se veían escalonadas.

### Energías provisorias del sol y del ambiente
**Decisión:** sol 0,45 (antes 0,75) y ambiente 0,45 (antes 0,5), hasta que el paso 3 traiga el modelo de color nuevo (luces calculadas en el sombreador).
**Motivo:** el piso salía casi quemado (234, 143, 72 en la captura 01); ahora sale (210, 121, 59) y se siguen leyendo las sombras.

### La pieza crece de a 1 cm
**Decisión:** `PieceModel.LAYER_STEP = 0.01`: la pieza que se imprime sube de a una capa de 1 cm y nunca baja. Antes subía de a "un píxel de pantalla" con el zoom de ese momento (`RoomView.vertical_pixel_meters`, borrado), así que al cambiar el zoom el escalón cambiaba. `PrinterView` ya no necesita al `RoomView`.
**Motivo:** sin pixel art, "un píxel" deja de tener sentido; una capa fija se ve igual con cualquier zoom y en cualquier teléfono, y es la idea del título (biblia de arte §9.5).

### Pruebas adaptadas (misma intención, no más débiles)
- `tests/unit/test_camera_rig.gd`: `test_camera_sits_on_whole_pixels_and_reports_the_rest` → `test_camera_reaches_its_goal_exactly`. Antes: la cámara quedaba en un píxel entero y el resto reconstruía la posición exacta. Ahora: el centro de la vista es justo el punto que persigue (±0,00001 m, sin resto), y al llegar, el punto seguido queda centrado de lado a lado y a la altura de `ANCHOR` medida en píxeles de la vista (±0,001 px). Se cambió el punto seguido a (0,2; 1,5; −0,3) porque el de antes, con el zoom cerca, choca con el borde del cuarto y no se podía comprobar la altura.
- `tests/integration/test_world_views.gd`: `test_the_piece_grows_one_screen_pixel_at_a_time_while_the_head_swings` → `test_the_piece_grows_one_layer_at_a_time_and_never_shrinks`. Antes revisaba una sola vez, a la mitad, que el alto fuera un múltiplo del píxel de pantalla. Ahora revisa cada segundo hasta la mitad (con un cambio de zoom en el medio) que el alto sea un múltiplo de `LAYER_STEP` (±0,0001 m; antes de la primera capa la caja mide `MIN_HEIGHT`) y que nunca baje; sigue revisando que a la mitad esté entre una capa y el alto final menos una capa, que siga creciendo con el reloj y que el cabezal se mueva en 0,2 s.
- `tests/integration/test_world_controls.gd` (ayuda `_pick_under`): el lado mínimo del toque pasa de `MIN_TOUCH_PX / stretch_shrink` a `MIN_TOUCH_PX * view_per_ui`, la misma cuenta que hace `WorldControls.tap`.

### Pruebas nuevas
- `tests/unit/test_world_viewport.gd` (3): k para ventanas de 405, 720, 1.080 y 1.440 px con el tope; el dibujo tiene ese ancho y llena la pantalla; ida y vuelta interfaz ↔ dibujo y mundo → interfaz → dibujo, con el rayo pasando por el punto.
- `tests/integration/test_world_controls.gd`: `test_taps_hit_the_same_object_at_any_phone_width` (con 1.080 × 2.400 y 1.440 × 3.200 el toque sobre la impresora la elige y abre su panel).

## 2026-10-22 — Arte 2.0, paso 3: kit de materiales, modelo de color y entorno

### Modelo de color en el espacio de la pantalla, medido con ColorProbe
**Decisión:** todo el mundo se pinta y se ilumina en el espacio de la pantalla: un color `#rrggbb` bajo luz neutra 1,0 se ve exactamente así (`color = albedo × (ambiente + relleno + luces + parche) × oclusión + albedo × sol + luz propia`, biblia de arte §2.4). Los sombreadores terminan con `cc_out()` (pasada base) y `cc_sun_out()` (el sol, dentro de `light()`), en `game/world/look/look_globals.gdshaderinc`. `ColorProbe` (`game/world/look/color_probe.gd`) dibuja al arrancar dos cuadritos de 8 × 8 (0,25 de pasada base; 0,5 de sol con sombra), lee el píxel y pone los globales `cc_base_fix` y `cc_sun_fix`; si la lectura sale fuera de ±0,06 de las dos opciones quedan los valores de llvmpipe (base 0, sol 1). Sin pantalla (pruebas) no mide nada.
**Lo que se midió en Compatibility (Godot 4.7.2, llvmpipe):**
1. La pasada base pasa `EMISSION` (y el `ALBEDO` de lo que no tiene luz) a lineal con el cúbico aproximado de Godot y al final todo vuelve a sRGB con su potencia aproximada. La ida y vuelta no es exacta en lo oscuro: 0,05 se veía 0,027 y 0,02 se veía negro.
2. Lo que suma `light()` ya es lineal y se pasa a sRGB al final: 0,5 se ve 0,737.
3. El sol con sombra se dibuja en otra pasada que se pasa a sRGB por su cuenta y se suma en el espacio de la pantalla. Sin sombra se suma en lineal dentro de la pasada base.
4. En la pasada del sol, `light()` recibe el `ALBEDO` ya pasado a lineal (el gris salía a menos de la mitad).
**Por eso:** `cc_out()` entrega el valor que, después del cúbico y la potencia del motor, da exactamente el color pedido (tres pasos de Newton); `cc_sun_out()` deshace la potencia (con sombra) o suma en lineal sobre lo que ya puso la pasada base (sin sombra, el nivel Bajo del paso 15); y el color del objeto llega a `light()` por un `varying`, no por `ALBEDO`. La captura `00_calibracion` lo comprueba sola (falla `screenshots.sh` si no): blanco 64 / 128 / 191 con ambiente 0,25, sol 0,5 y los dos; gris la mitad; el sol sin sombra igual que con sombra; vértice y uniform iguales. Hoy da exacto (gris 32/64/96, blanco 64/128/191).
**Motivo:** es la cuenta más fácil de ajustar mirando capturas, y hace que los niveles de calidad, la tienda y los retratos se vean igual. Nada queda escrito a mano sin medir: si una versión de Godot o un teléfono cambia el camino del color, `ColorProbe` y la captura de calibración lo muestran.

### Tonemap lineal y entorno del motor apagado
**Decisión:** `RoomView` y las vistas de la tienda (`ModelPreview`): ambiente y reflejos del motor apagados, tonemap lineal, sin glow, SSAO ni niebla. El ambiente (dos colores), el relleno desde el lado de la cámara, cuatro luces del sombreador, la tira LED, el parche de sol de la ventana (con rejas y lo que lo tapa) y la oclusión (rincones, mapa del piso y mancha del personaje) los calcula el sombreador del mundo (`world_light.gdshaderinc`) con globales (`[shader_globals]` de `project.godot`, 33 en total) que pone `DayCycle`. El sol: `shadow_bias 0,04`, `normal_bias 1,2`, `opacity 0,9` (biblia §2.6). La cáscara del cuarto (piso, paredes, ventana, puerta) no da sombra. Fondo degradado pegado a la cámara y sombra suave bajo la base.
**Motivo:** un tonemap curvo rompe la suma de las dos pasadas; el glow multiplica el fondo ×4 y cuesta +104 %; las luces del motor extra no se agregan (D2: no).

### Luces en el sombreador, día en "mañana"
**Decisión:** `DayCycle` (`game/world/look/day_cycle.gd`, hijo de `Room`) tiene por ahora solo la mañana de la biblia §6.2 (sol (0,707; −0,566; −0,424) `#fff0dc` × 0,48, ambiente `#bfcdf0` × 0,62 / `#e6bb92` × 0,50, ventana igual que el sol `#ffe2b0` × 0,85, relleno `#fff4ea` × 0,22 + 0,25 del personaje, factores de las luces). `sample(hora)` es puro. Los demás momentos, la mezcla y el reloj llegan en el paso 13. El brillo del monitor y el LED de la cama de la impresora del piso se ubican por ahora con los modelos viejos (`Monitor/Screen` y `Bed`); los pasos 6 y 7 traen sus marcadores.

### Sin contorno en el mundo
**Decisión:** se borró `game/world/pixel/outline.gdshader` (el casco invertido de todos los materiales) y `PixelTextures`: las texturas pixel art pasan a superficies del sombreador (baldosa con junta y bisel, pintura, madera, cartón, metal, tela, PEI) y las pantallas y la vista de la ventana se dibujan en sus sombreadores (`screen.gdshader`, `window_view.gdshader`), animados con `cc_anim_time` para que las capturas salgan iguales.
**Motivo:** el casco duplicaba las llamadas de color y de sombra (334 → 177 llamadas en el cuarto inicial) y no sirve en mallas unidas. Las siluetas salen del valor, del borde de luz y de la oclusión. El personaje tendrá su contorno fino propio en el paso 10.

### `WorldPalette` se muda a `game/world/look/` con la misma interfaz
**Decisión:** `git mv` con su `.uid`. Misma caché e identidad: `solid(hex)` es plástico impreso (capas de 1 cm), `glow("ffffff", estado)` una pantalla por estado, `glow(hex)` un color del kit con luz propia, `glow_transparent` una marca (`marker.gdshader`, latido en el sombreador en vez de `Tween`), `textured(nombre)` una superficie. Nuevas: `kit()`, `paint(hex, superficie, brillo)` (lo que no fue impreso: los modelos de cajas de antes ya no muestran capas en la cara del personaje), `printing(hex)` (la pieza que se imprime, con la capa caliente) y `halo()`. Los colores con nombre salen de `LookPalette` (biblia §4); el buzo pasa a gris carbón `#3e4250` (D3).

### Solo la pieza que se imprime usa un "instance uniform"
**Decisión:** la capa caliente vive en una variante aparte (`kit_printing.gdshader`, `instance uniform hot_top`), que solo usan las piezas mientras crecen; `kit` y `kit_tinted` no tienen ninguno. `project.godot`: `limits/global_shader_variables/buffer_size = 1024`.
**Motivo:** medido: cada instancia que usa un material con un "instance uniform" ocupa 16 lugares del búfer de globales, aunque no lo cambie. Con la capa caliente en el kit, el cuarto lleno (279 mallas) llenó el búfer de llvmpipe (4.096) y salieron 107 errores. En la web y en muchos teléfonos el búfer tiene 1.024 lugares (16 KB): fijarlo en 1.024 hace que las capturas fallen aquí si alguna vez se pasa.

### Prueba de presupuesto ajustada
Topes nuevos (medido + 10 %, nunca por encima del anterior): inicio 194 llamadas (medido 177), 38 materiales (37), 68 mallas con sombra (62), 37 transparentes (35); lleno 588 llamadas (535), 45 materiales (44), 281 mallas con sombra (256), 12 transparentes (5).

### Pruebas adaptadas (misma intención, no más débiles)
- `tests/integration/test_world_views.gd`: en `test_finished_pieces_of_a_longer_order_wait_on_the_tray` y `test_the_dispatch_corner_shows_a_box_then_a_package_that_leaves`, el tipo de las variables `red` y `white` pasa de `StandardMaterial3D` a `Material` (los materiales ahora son del sombreador del kit). La comparación por identidad con `WorldPalette.solid(...)` es la misma.

### Pruebas nuevas
- `tests/unit/test_world_palette.gd` (7): misma instancia por clave; pedidos distintos, materiales distintos; `solid` lleva su color y las capas de la pieza; `paint` y `textured` su superficie; `glow(hex)` tiene luz propia; cada estado de pantalla es un material propio y estable; las marcas son transparentes.
- `tests/unit/test_color_probe.gd` (6): `ColorProbe.decide` con las lecturas de llvmpipe (64/255; 0,68 y 0,251; 0,737 → base 0, sol 1), las dos convertidas (137/255; 0,735 → 1, 1), ninguna, fuera de rango (valores de llvmpipe), la tolerancia de ±0,06 y que sin pantalla no se arma nada.
- `tests/unit/test_day_cycle.gd` (4): la mañana coincide con la tabla de la biblia §6.2 de 07:00 a 10:30, `sample()` es puro, el sol del cuarto la toma y cada luz del sombreador tiene su global.
- `tests/integration/test_look_shaders.gd` (3): cada sombreador de `look/` se arma sin errores y expone sus parámetros; cada material de `WorldPalette` (y cada superficie) se dibuja sobre una malla; la pieza que se imprime lleva la capa caliente arriba y, terminada, vuelve a `solid`.

## 2026-10-22 — Arte 2.0, paso 4: kit de formas, caché y mapa de oclusión del piso

### `KitMesh`: una malla por objeto, armada por código
**Decisión:** los modelos nuevos se arman con `KitMesh` (`game/world/look/kit_mesh.gd`): cajas con bisel, cilindros con canto, tornos (perfil girado), superelipsoides con estrechamiento, cápsulas, tubos por una curva, toroides con arco, discos, rectángulos y triángulos, todo junto en **una** `ArrayMesh` con el material `WorldPalette.kit()`. Cada vértice lleva lo que lee el sombreador del kit (biblia de arte §3.3): color en `COLOR.rgb`, oclusión horneada en `COLOR.a`, superficie + brillo en `UV.x`, balanceo en `UV.y`, alto de capa en `UV2.x` y luz propia en `UV2.y`. La interfaz es la del prototipo ganador (`paint`, `printed`, `glowing`, `night_glow`, `box`, `cylinder`, `blob`, `capsule`, `torus`, `quad`, `disc`, `triangle`, `origin`, `ao_base`, `ao_enabled`), así los pasos 5 a 14 copian sus modelos casi tal cual; las superficies salen de `WorldPalette.Surface` (una sola lista).
**Cómo está hecho:**
- Escribe directo en arreglos (`PackedVector3Array`...) con índices, sin `SurfaceTool` y sin un `Callable` por vértice. Las formas redondas calculan sus potencias y senos una vez por fila y por columna (la forma redonda pasó de 5,2 a 0,8 µs por triángulo; sin pantalla, cada forma arma entre 0,7 y 1,9 µs por triángulo).
- El frente de cada triángulo se decide por sus normales (Godot dibuja el frente en sentido horario); los triángulos de menos de 1e−9 m² no se agregan (polos, puntos repetidos).
- El cilindro es un torno con las esquinas repetidas: un punto repetido en el perfil deja un canto vivo (normales distintas a cada lado).
- El tubo suaviza los puntos con Catmull-Rom y gira cada anillo por transporte paralelo (doble reflexión): no se retuerce en las curvas.
- `detail` multiplica los lados de lo redondo (mínimo 6 alrededor y 4 en la otra dirección).
- Oclusión horneada: −35 % en el contacto (`ao_base`, por defecto y = 0), que se aclara en 14 cm; las caras que miran hacia abajo, −25 %.
- `KitMesh.cached(clave, constructor)`: diccionario estático. La clave dice todo lo que cambia la malla (modelo, variante, detalle, color). Lo comparten el cuarto, la tienda, los retratos y las pruebas.
**Motivo:** biblia §5. Una malla y un material por objeto es lo que baja las llamadas de dibujo (meta 70 en el cuarto inicial). Las piezas que se mueven o cambian de material siguen aparte (son contratos).

### Mapa de oclusión del piso (`FloorAO`)
**Decisión:** `game/world/look/floor_ao.gd` pinta una textura de 96 × 96 (una por cuarto, 6,25 cm por texel) con una mancha bajo cada obstáculo del piso: −45 % adentro y un borde suave de 0,20 m centrado en el borde del obstáculo; donde dos manchas se tocan queda la más oscura (una impresora sobre un mueble no oscurece el doble). Cada obstáculo pinta solo los texeles que alcanza (nunca se recorren todos los obstáculos por cada texel). `RoomView` la pinta después de registrar los obstáculos con los de `WalkGrid.obstacles()` y la publica en el global `cc_floor_ao`; la guarda en `RoomView.floor_ao`.
**Motivo:** las manchas de contacto bajo el escritorio, la impresora y el rincón asientan las cosas en el piso sin luces ni llamadas extra. Usar los mismos obstáculos por los que no se camina hace que la decoración del paso 12 tenga su mancha sola.
**Detalle:** se crea una textura nueva cada vez (9 KB, una vez por distribución) en vez de actualizar la anterior: sin pantalla, el motor no actualiza el contenido de una textura ya creada y la prueba no podría leer lo pintado.

### Tiempo de armado de la escena principal
**Decisión:** `tests/integration/test_scene_budget.gd` arma la escena principal 5 veces con las cachés llenas (instanciar y meterla en el árbol, con todos sus `_ready`) y exige la mediana ≤ 120 ms (tope duro contra regresiones grandes); imprime la meta de la biblia (≤ 40 ms). Hoy: ~19–21 ms sin pantalla.
**Motivo:** biblia §13; con los modelos del kit el armado crece, y esta prueba avisa antes de que el arranque en el teléfono se ponga lento (D4: si pasa de 1 s, armar durante la pantalla de carga).

### Prueba de presupuesto
Sin cambios: este paso no cambia lo que se dibuja (177 llamadas el cuarto inicial y 535 el lleno; los topes siguen en 194 y 588).

### Pruebas adaptadas
Ninguna.

### Pruebas nuevas
- `tests/unit/test_kit_mesh.gd` (12): la caja con bisel mide exactamente su tamaño (un bisel enorme se limita); el giro y el grupo (`origin`) ubican las formas; en 10 formas convexas las normales y el frente de cada triángulo miran hacia afuera; en todas las formas el frente coincide con las normales; ningún triángulo degenerado (área > 1e−10) ni valores no finitos; `detail` cambia la cantidad de vértices (y no la de una caja); oclusión de contacto en y = 0, sobre una mesa, apagada, y caras de abajo; color, superficie, brillo, capas, luz propia y balanceo en cada vértice; la caché arma una sola vez; el tubo pasa por sus puntos, sus anillos son redondos y de frente a la curva y no se retuerce; un punto repetido del torno deja un canto vivo; un kit vacío da una malla vacía.
- `tests/unit/test_floor_ao.gd` (6): 96 × 96 en un canal y blanco sin obstáculos; más oscuro bajo un obstáculo que en el piso libre; borde suave centrado y sin saltos; dos obstáculos encimados no suman; lo que cae fuera del cuarto se recorta; la textura publicada lleva lo último pintado.
- `tests/integration/test_main_scene.gd`: `test_the_floor_darkens_under_the_desk_the_printer_and_the_dispatch_corner` (y no donde empieza el personaje ni en los lugares libres).
- `tests/integration/test_scene_budget.gd`: `test_the_main_scene_builds_fast_with_cached_meshes`.
- `tests/unit/test_prop_bounds.gd`: `test_bounds_cover_a_kit_mesh_placed_with_prop_builder` (`PropBounds` mide una `ArrayMesh` del kit puesta con `PropBuilder.kit`, girada y movida, también sin pantalla).
- La captura `00_calibracion` arma ahora sus tarjetas "por vértice" con `KitMesh`: comprueba con los píxeles que el kit pinta el color exacto.

## 2026-10-22 — Arte 2.0, paso 5: el cuarto (cáscara, ventana con vista y parche de sol, base impresa, marcas)

### El cuarto es una maqueta impresa, en una malla
**Decisión:** `RoomShell` se arma con `KitMesh`: la base impresa (losa de 0,30 m de plástico `#56689a` con capas de 2,4 cm y un borde de primera capa de 4 cm), la losa de baldosa del piso (la grilla de baldosas empieza en el rincón: 15 enteras por lado), la pared de la ventana verde salvia con un **hueco de verdad**, la pared del fondo crema, los cortes de arriba y de las puntas impresos (capas de 1,2 cm), zócalos, la ventana corrediza de aluminio (dos hojas que se cruzan en el parante del medio), el alféizar de baldosa, las rejas de hierro por fuera con el travesaño y el adorno de sol (dos aros), la barra y la cortina mostaza recogida a los lados (se balancea más abajo que arriba: `KitMesh.hanging()`), el interruptor con su canaleta hasta el borde y el enchufe de la impresora. Todo eso es **una** malla y una llamada de dibujo. Aparte van la vista del barrio (otro sombreador), el haz de luz (suma luz) y la puerta (se toca). El cuarto entero cuesta 5 llamadas y 2.160 triángulos (biblia §5.2: ≤ 5 y ≤ 2.500), y nada de él da sombra.
**Puerta:** `RoomShell/Door` con una malla del kit (dos tableros, marco crema, manija de palanca de latón) cuya caja es exactamente la de antes (x −3,0…−2,855; z 1,6…2,6; y 0…2,0).
**Motivo:** biblia §8.1–8.6 y §12.3 ("mundo impreso"); presupuesto §5.2.

### `WindowSpec`: una sola medida para la ventana y su parche
**Decisión:** `game/world/look/window_spec.gd` guarda el hueco, las rejas (cada 0,20 m a media separación de los bordes, 9 mm de medio grosor), el travesaño, el parante central y el adorno de sol. La geometría de `RoomShell` y los globales del parche (`cc_window_rect`, `cc_window_x`, `cc_window_bars` y el nuevo `cc_window_sun`, con los dos aros) salen de ahí; `RoomView` los publica. El parche del sombreador ahora también dibuja la sombra de los aros del adorno.
**Motivo:** biblia §6.3: las rayas del piso tienen que salir de las mismas rejas que se ven.

### La vista del barrio, recortada al hueco
**Decisión:** `window_view.gdshader` se pinta en un cuadro de frente a la cámara, detrás del hueco; cada fragmento se proyecta hacia atrás por la mirada (fija) de la cámara hasta la pared y se descarta si no cae en el hueco (nada se asoma por encima de la pared). Lo lejano (cielo, cordillera, cerro con casitas y torre) va con el horizonte derecho en la pantalla; lo cercano (azotea, tanque de agua negro sin marca, varillas "para el segundo piso", ropa tendida, buganvilla, poste y cables enredados) va paralelo a la pared, como los objetos del cuarto. Las figuras tienen borde suavizado (sin escalones).
**Motivo:** biblia §8.5 (idea del recorte: prototipo "Diorama"; cables: "Juguete").

### Haz de luz de la ventana
**Decisión:** `window_shaft.gdshader`: dos hojas que salen de los bordes de arriba y de abajo del hueco y que el sombreador estira hasta el piso en la dirección de la luz de la ventana; suman un brillo tenue con las rayas de las rejas. Una llamada, sin sombra. La fuerza la pone `DayCycle` (0,22 × el factor "window_shaft" de la hora; en la mañana 1). Se anima con `cc_anim_time` (capturas iguales en cada corrida).

### La luz de la ventana de la mañana gira 10° hacia la pared de la ventana
**Decisión:** en la mañana el sol sigue exactamente como dice la biblia (0,707; −0,566; −0,424), pero la luz de la ventana (la del parche y el haz) va hacia (0,774; −0,559; −0,297): la misma altura (34°) y 10° menos de giro.
**Motivo:** la biblia (§6.2) describe el parche "en el piso delante del escritorio, cruzando la impresora del piso y subiendo por la pared del fondo cerca del rincón", pero con sus números el parche cae 0,3 m detrás de la impresora (lo medí en el piso: no toca la impresora en ningún punto). Con el hueco y la impresora del piso fijos, "cruzar la impresora" y "subir por la pared del fondo" no pueden pasar juntos con ninguna dirección (para cruzar la impresora la luz tiene que ir casi derecho desde la pared; para subir por la pared del fondo, bien de costado). Elegí cruzar la impresora: es la estrella del juego y queda en el centro de la imagen. Girar también el sol lo probé y no sirve: la pared del fondo, la superficie más grande del cuarto, queda a contraluz y se ve marrón. Con 10° de diferencia las rayas y las sombras se ven casi paralelas. Probé también subir la fuerza de la ventana (1,05) y bajar el sol y el ambiente (0,40 y 0,55): el parche apenas gana y el cuarto se apaga; quedan los valores de la biblia.

### El escritorio tapa el parche
**Decisión:** la caja que tapa el parche (`cc_occ_a`) es el tablero del mueble del lugar 0 (el escritorio, que está bajo la ventana): `ComputerDeskModel.TABLE_SIZE` puesto donde está el mueble (`RoomView.window_occluder`). No toda su huella (con la caja de cartón que hace de silla y el monitor), porque esa caja apagaba casi todo el parche aunque la luz pasa por encima de la caja de cartón. La de la cama (`cc_occ_b`) queda en cero hasta el paso 12.
**Motivo:** biblia §6.3 (lo pidieron los jueces): el sol no atraviesa los muebles.

### Marcas del piso en esquinas, con dos intensidades
**Decisión:** las marcas de lugar libre son cuatro esquinas en L (brazos de 0,18 m, 3 cm de ancho) y un "+" de 0,14 m, planas, en **una malla compartida** (antes 6 cajas por marca); ningún rectángulo se encima con otro, así el alfa queda parejo. Su zona de toque sigue midiendo 1,24 × 0,60. Laten suave (alfa 0,22 ↔ 0,35) y se encienden (0,55 ↔ 0,85) cuando el personaje está a 1,2 m o menos de la marca o la tienda está abierta: `RoomView` cambia el material (dos materiales de la caché) solo cuando hace falta, sin memoria nueva por cuadro, y `WorldControls` le avisa `markers_emphasis` al abrir la tienda. El marco de cercanía también es de esquinas (una malla por tamaño de huella, guardada) y el destino al tocar el piso es un aro.
**Motivo:** biblia §8.7; además bajan las llamadas (de 177 a 136 en el cuarto inicial) y las superficies transparentes (de 35 a 8).

### `KitMesh.hanging()`
**Decisión:** lo que cuelga (cortina; después hojas y la cobija) se balancea con peso 0 donde cuelga y crece hacia abajo. `paint()` lo apaga.

### Limpieza
`WorldPalette.textured("floor_planks")` y `textured("brick_wall")` se borraron: el piso y las paredes ya son del kit (queda `"cardboard"`, que usan los modelos de cajas).

### Prueba de presupuesto
Medido: cuarto inicial 136 llamadas, 32 materiales, 62 mallas con sombra y 8 transparentes; cuarto lleno 519 llamadas y 39 materiales. Topes (medido + 10 %, nunca por encima del anterior): inicio 149 llamadas, 35 materiales, 68 mallas con sombra y 9 transparentes; lleno 570 llamadas y 42 materiales. Armar la escena principal con caché: ~11,5 ms (antes ~20).

### Pruebas adaptadas (misma intención, no más débiles)
- `tests/unit/test_day_cycle.gd`, `test_the_morning_matches_the_art_bible`: "la ventana va como el sol" pasa a "la ventana va hacia `WINDOW_DIRECTION`" (la tabla de la mañana, con el cambio de arriba) y además exige que tenga la misma altura que el sol (±0,01) y que gire como mucho 10,5° respecto del sol en el piso (las rayas casi paralelas a las sombras). Sigue comparando todos los demás valores con la tabla.
- `tests/unit/test_world_palette.gd`: el ejemplo suelto de `textured()` usa `"cardboard"` (cartón) en vez de `"floor_planks"`, que ya no existe; el recorrido de todas las texturas con nombre sigue igual.
- `tests/integration/test_look_shaders.gd`: la vista de la ventana tiene además el parámetro `view_dir`; se agregan el sombreador y el material del haz (más cobertura).

### Pruebas nuevas
- `tests/integration/test_room_shell.gd` (9): la zona de toque de la puerta exacta; el hueco de la malla coincide con `WindowSpec` (por adentro no hay pared, 2 cm afuera sí) y los globales del parche salen de `WindowSpec`, con cada reja en la malla; al menos 6 rayas, a media separación de los bordes y sin tapar el parante; nada del cuarto da sombra y el cuarto cabe en 5 llamadas y 2.500 triángulos; la sombra de la base va debajo de la base; las 5 marcas comparten la malla y su zona de toque mide 1,24 × 0,60; las marcas se encienden con el personaje cerca y con la tienda abierta; la caja que tapa el parche es el tablero del escritorio; el marco de cercanía rodea la huella + 0,12 m y reusa su malla.
- `tests/unit/test_kit_mesh.gd`: `test_what_hangs_sways_more_the_lower_it_is`.

## 2026-10-22 — Arte 2.0, paso 6: impresora estrella, pieza, espagueti y carrete

### Cubo Uno del kit, con marcadores
**Decisión:** la Cubo Uno (`PrinterModel._cubo_uno`, biblia §9.3) es una malla del kit para todo lo fijo (`Body`: base de perfil negro con ranuras, caja de control con la pantallita abajo a la derecha y su perilla, fuente de poder, riel, carro, perillas amarillas, placa y lámina PEI, postes Z y barra de arriba, motor Z y tornillo de latón, barra LED, portacarrete impreso azul, eje y las tapas del carrete) y aparte solo lo que se mueve o cambia: `Gantry` (barra X con las placas, el motor X y la polea), `PrintHead/Carriage`, `Display` (sin sombra) y `Spool/Filament`. Mide 0,446 m de ancho y 0,706 m de alto con el carrete (`PrinterModel.MAX_HEIGHT` = 0,72), 2.386 triángulos y 9 llamadas con la sombra (biblia §5.2: ≤ 2.400 y 9). Las mallas van en caché (las comparten el cuarto, la tienda y las pruebas).
**Marcadores** (`Marker3D`) que `PrinterView` lee en vez de números fijos: `Bed` (sigue marcando "abierta"), `PieceAnchor`, `HeadRest`, `HeadPark`, `TrayAnchor` y `BedLight`. En la Cubo Uno valen lo mismo que `BED_TOP`, `PIECE_Z`, `HEAD_REST_Y`, `HEAD_PARK_X` y la bandeja (`TRAY_*`) de `PrinterView`; los modelos de cajas que quedan (paso 8) no tienen marcadores y la vista usa esas constantes × su escala, como antes.
**Cambios de lugar (no fijados por pruebas):** el cabezal quieto queda centrado sobre la cama (x 0, antes −0,05) y su origen en z 0 (antes −0,02), así la boquilla cae justo sobre el centro de la pieza (z = `PIECE_Z`); la barra X pasa a z −0,04 (antes −0,06) y la punta de la boquilla queda 2 mm sobre la capa de arriba (`HEAD_CLEARANCE` 0,045, punta en −0,043).
**Motivo:** biblia §5.1, §5.2, §9.1 y §9.3.

### Extrusor directo y tubo PTFE en arco
**Decisión:** el extrusor va en el cabezal (como las impresoras tipo Ender más nuevas) y el tubo PTFE sale de arriba y sube en arco hacia el carrete, como parte de la malla del cabezal.
**Motivo:** la biblia pide "tubo PTFE en arco". Con un extrusor fijo en el marco (tipo Bowden), un tubo que se mueve con el cabezal se despegaba del extrusor hasta 15 cm (al estacionarse) y 17 cm (con la pieza alta): con un tubo que solo va unido al cabezal no hay nada que se despegue.

### Las capas siguen el eje del objeto
**Decisión:** en `kit_body.gdshaderinc` las capas de lo impreso se miden a lo largo del "arriba" del objeto (su eje Y en el mundo, `v_up`/`v_layer`, calculados en el vértice) y no del arriba del mundo. Para todo lo que está derecho (pieza, bandeja, base, cortes de pared) da exactamente lo mismo que antes.
**Motivo:** el bobinado del carrete usa `WorldPalette.solid(color)` (contrato de las pruebas) y está acostado: con capas del mundo se veían rayas horizontales a lo largo del eje; ahora dibujan los surcos del enrollado alrededor del eje (biblia §9.4: "bobinado con surcos de enrollado (capas)"). De paso, la pieza despegada (warping) muestra sus capas torcidas con ella, y los carretes de los estantes también se ven bien.

### Carrete de tapas abiertas
**Decisión:** `SpoolModel` (misma firma, con `flanges` opcional): tapas gris claro de aro y cuatro rayos un 10 % más grandes que el bobinado, centro gris y el bobinado (`Filament`, malla del kit a lo largo de Y con el nodo acostado). En las impresoras las tapas van dentro de la malla de la impresora (`SpoolModel.add_flanges`), así el carrete cuesta una sola malla más. Los carretes de los muebles (estantería y repisa) también cambian.
**Motivo:** biblia §9.4 (idea del prototipo "Diorama").

### Espagueti
**Decisión:** `PieceSpot/Spaghetti` (`PieceModel.build_spaghetti`): un nido de 11 rulos y 2 hebras que suben hasta la boquilla, una malla con semilla fija, escondida si no se usa. Va sobre la pieza fallida (oscura) y el cabezal se queda encima del nido, con la boquilla donde terminan las hebras (`SPAGHETTI_RISE`). Material `PieceModel.spaghetti_material(hex)`: el color del filamento × 1,1 con brillo, sin capas. Solo se ve en un fallo de espagueti; en warping no, y se esconde al limpiar.
**Desvío:** hilo de **6 mm** en vez de los 4 mm de la biblia. Con 4 mm, en la captura 23 (zoom cerca) cada hilo medía menos de un píxel y el nido se leía como unas rayitas; con 6 mm se lee como una maraña blanca sin abrir el panel (la aceptación del paso).

### Warping: se levanta una esquina
**Decisión:** la pieza despegada se inclina 12° hacia atrás (como antes; lo prueba `rotation_degrees.x`) y además 7° de lado, así una esquina queda bien levantada; `PieceSpot` sube lo justo para que la esquina más baja quede apoyada en la cama (antes la mitad de la pieza se hundía en la cama). Al limpiar vuelve a su lugar.
**Motivo:** biblia §9.5.

### Destellos de "pieza lista" y halos sin "instance uniform"
**Decisión:** `game/world/look/ready_sparkles.gd` (`ReadySparkles`, hijo `PieceSpot/Sparkles`): un `MultiMeshInstance3D` con 3 estrellitas de cuatro puntas (dos rectángulos cruzados con el halo estirado) que crecen y se apagan una tras otra en 0,6 s; miran a la cámara (se orientan al empezar: la cámara no gira); escondido el resto del tiempo. Salen solo cuando la pieza termina mientras se mira (no al cargar una partida). `halo.gdshader`: `intensity` pasa de "instance uniform" a uniform del material, y `WorldPalette.halo(hex, aspect, intensity)` la recibe (en la clave de la caché). Los destellos usan intensidad 2,2: sobre el piso claro, con 1 casi no se veían.
**Motivo:** biblia §5.3 y §9.5. Un "instance uniform" le cuesta 16 lugares del búfer de globales (1.024 en la web) a cada instancia que tenga el material, aunque esté escondida: con un `Sparkles` por impresora, 16 impresoras habrían ocupado 256 lugares sin dibujar nada. Nadie usaba todavía `intensity`.

### Baldosa de concreto y cable al enchufe
**Decisión:** la impresora del piso se apoya en una baldosa de concreto (0,54 × 0,50 × 0,035 m, `#cfcac0` con granitos `#b9b3a8` solo en el borde que se ve) y su cable negro (4 mm en el piso, biblia §5.4) baja por detrás de la baldosa, cruza el piso entre los lugares 2 y 3 sin pisarlos y sube a una clavija en el enchufe de la pared del fondo (`PaverModel`, una malla sin sombra en `Room/Decor`, que no se toca ni es obstáculo). `RoomLayout.FLOOR_PRINTER_RAISE` (0,035) sube el lugar de la impresora del piso. `RoomView.decor` es el nodo `Decor` (lo usará la decoración del paso 12). La luz LED de la cama (`cc_pl3`) sale del marcador `BedLight` (la barra LED); los modelos sin marcador siguen con "sobre la cama".
**Motivo:** biblia §9.3 ("en el piso: sobre la baldosa de concreto, con su cable al enchufe"), §5.4 y §4.3.

### Captura nueva
`36_impresora_cerca` (grupos `all` y `art`): la impresora del piso imprimiendo, de muy cerca y sin interfaz (capas, capa caliente, cabezal, carrete).

### Prueba de presupuesto
Medido: cuarto inicial 120 llamadas, 27 materiales, 53 mallas con sombra y 8 transparentes; cuarto lleno 440 llamadas, 37 materiales y 214 mallas con sombra (la Cubo Uno de cajas tenía 12 mallas con sombra; la del kit, 4). Topes (medido + 10 %, nunca por encima del anterior): inicio 132 llamadas, 29 materiales, 58 mallas con sombra y 9 transparentes; lleno 484 llamadas, 40 materiales y 235 mallas con sombra. Armar la escena principal con caché: ~12–14 ms.

### Pruebas adaptadas (misma intención, no más débiles)
- `tests/integration/test_world_views.gd` (`_height`), `test_main_scene.gd`, `test_order_loop.gd` y `test_player_touches.gd`: el alto de la pieza se lee con `PieceModel.shown_height(piece)` en vez de `(piece.mesh as BoxMesh).size.y` (la pieza sigue siendo un `BoxMesh`; así sirve cuando las piezas tengan forma). Son 4 lugares (el plan decía 6: en `test_world_views.gd` todos pasan por `_height`). Mismos límites.

### Pruebas nuevas
- `tests/unit/test_printer_model.gd` (9): la Cubo Uno mide 0,40–0,50 m de ancho, apoya en y = 0 y no pasa de 0,72 m; tiene todos los nodos del contrato (mallas y marcadores; `Body` con el material del kit, `Display` sin sombra, el cabezal empieza en `HeadRest` y la barra X a su altura); sus marcadores valen las constantes de `PrinterView`; la lámina de la cama está justo bajo la pieza y la punta de la boquilla a ≤ 4 mm de la capa de arriba, sobre el centro de la pieza; ≤ 2.400 triángulos y ≤ 9 llamadas con la sombra; dos impresoras comparten sus mallas; el carrete está acostado (las capas alrededor del eje), con tapas un 10 % más grandes que el bobinado y abiertas (entre los rayos no hay tapa); el nido de espagueti está escondido, encima de la pieza, sus hebras llegan a la boquilla y su color es el del filamento × 1,1; los destellos se encienden y se apagan solos.
- `tests/integration/test_world_views.gd` (5): la capa caliente va en el borde de arriba de la pieza mientras crece (en la malla y en el mundo) y desaparece al terminar; un fallo de espagueti muestra el nido del color del filamento sobre la pieza oscura con el cabezal encima, y se esconde al limpiar; el warping no hace espagueti, la esquina más baja queda en la cama y otra se levanta; la pieza lista suelta destellos que se apagan solos, y al cargar una partida con la pieza lista no salen; la impresora del piso pone la pieza, la bandeja y la luz LED donde dicen sus marcadores.
- `tests/integration/test_main_scene.gd` (1): la impresora del piso está sobre la baldosa (`Decor/Paver`, sin sombra, fuera de la zona de toque) y el cable llega al enchufe, mide 4 mm de alto en el piso y no cruza ningún lugar de muebles.

## 2026-10-22 — Arte 2.0, paso 7: escritorio, despacho y paquetes

### Escritorio del kit, con marcadores de luz
**Decisión:** `ComputerDeskModel` (misma fachada `build(parent, nombre)`) es una malla del kit para todo lo fijo (`Body`, detalle 0,8): tablero de madera, cajonera de 3 cajones con tiradores de bronce (el del medio entreabierto 3 cm), patas, travesaño y faldones; monitor de tubo beige (pie giratorio, cuerpo que se angosta hacia atrás, cola, marco con el vidrio oscuro, papelito amarillo, botón y LED verde); torre con dos bahías, disquetera, botón, LED y rejilla; teclado con 46 teclas; ratón sobre su alfombrilla con su cable; lámpara articulada amarilla (base, dos brazos, uniones y pantalla cónica con la ampolleta asomando por la boca, `night_glow`: de noche brilla); taza roja con café; portalápices impreso morado (capas de 4,5 mm) con tres lápices; dos papeles con un croquis azul, el cuaderno y el calibrador; una regleta en el piso bajo la mesa con su LED y los cables del monitor, la torre y la lámpara que bajan por detrás del tablero; y la caja de cartón cerrada con cinta, etiqueta (ícono, sin texto) y un cojín como silla. Aparte va solo `Monitor/Screen` (sin sombra; `DeskView` le cambia el material como antes). Marcadores (`Marker3D`): `LampBulb` (la ampolleta) y `ScreenGlow` (0,12 m delante del centro de la pantalla). Medido: **3.871 triángulos, 3 llamadas** con la sombra (biblia §5.2: ≤ 4.000 y 3). La caja que se toca es **exactamente la de antes** (x ±0,65, z −0,41…0,81, alto 1,15): siguen igual el obstáculo, el resalte a 0,25 m de su borde y la caminata. `table_box()` sigue siendo el tablero (`TABLE_SIZE`); el tablero mide ahora 5 cm de grueso (`TABLE_THICKNESS`, antes 6 cm), su cara de arriba no cambia.
**Colores:** todos de la biblia (§4.3 madera, beige del computador, metal, latón; los acentos de textiles y filamentos: cojín `#2f8f8a`, cuaderno y alfombrilla `#2f3a57`, lámpara `#e0a43a`, taza roja y portalápices morado de los filamentos).
**La lámpara mira al frente y un poco hacia la cámara:** con la boca hacia el teclado (como en el prototipo) la ampolleta quedaba de espaldas a la cámara y de noche no se veía encendida (probado en el laboratorio con una noche puesta a mano). Ahora mira al borde de la mesa, donde se sienta el personaje, y la ampolleta se ve. La luz del sombreador (`cc_pl0`) es un punto: no depende de hacia dónde mire la pantalla.
**Desvío:** la regleta va **bajo el escritorio** (dentro de su malla y de su caja). La biblia §8.8 pone "el cable del escritorio a la regleta, a lo largo de la pared izquierda hasta F5" en la decoración (paso 12): ese cable puede salir de esta regleta hacia la pared. Así el escritorio se ve completo desde ya.
**Motivo:** biblia §5.1, §5.2, §6.2 y §10.

### Luces del escritorio desde sus marcadores
**Decisión:** `RoomView._place_desk_lights` pone `cc_pl0` (lámpara) en `LampBulb` y `cc_pl1` (monitor) en `ScreenGlow`. Se borra `RoomView.MONITOR_GLOW_AHEAD` (ahora es `ComputerDeskModel.SCREEN_GLOW_AHEAD`, mismo valor). En la mañana la lámpara está apagada (factor 0) y el monitor a 0,12, como dice la biblia §6.2; el paso 13 las enciende de noche.
**Motivo:** biblia §6.2 ("`cc_pl0` en el marcador `LampBulb`; `cc_pl1` en el marcador `ScreenGlow` frente a `Monitor/Screen`").

### Rincón de despacho del kit: guacal y mesa de embalar
**Decisión:** `DispatchCornerModel` es una malla del kit (`Body`): mesita de madera clara con patas, repisa con tres cartones planos y un rollo de plástico de burbujas; encima, un dispensador de cinta, un taco de etiquetas, un marcador y un cúter, fuera de los lugares de las cajas abiertas; y un guacal de listones (esquineros, cuatro filas de listones con espacios, el de adelante con bisel) con relleno de papel triturado y 10 tiras que asoman (semilla fija). Medido: **1.432 triángulos, 2 llamadas** (biblia §5.2, mueble: ≤ 1.500 y 2). Marcadores iguales que antes (`PackSpot0..2` sobre la mesa, `OutSpot0..2` apilados sobre el guacal); los `OutSpot1` y `OutSpot2` van girados 6° y −5° (paquetes apilados a mano). Caja que se toca, contando los paquetes escondidos: **x −0,435…0,45, z −0,2…0,2** (la de siempre).
**Motivo:** biblia §10 (idea del prototipo "Diorama").

### Paquetes y cajas abiertas
**Decisión:** `PackageModel.package`: cartón corrugado de 0,18 × 0,14 × 0,16 m con la cinta del cierre (arriba y bajando por los costados) y una etiqueta blanca al frente con un ícono azul oscuro y dos rayas que no se leen (sin texto). `open_box`: caja hueca de 0,15 × 0,08 × 0,14 m (fondo y cuatro paredes), relleno de papel, solapas largas abiertas 30° hacia afuera y las cortas colgando a los lados; `Piece` es una caja con bisel del kit, con `WorldPalette.solid(color)` (la tiñe `DispatchView` como antes), con su centro a 0,09 m: queda adentro y asoma 4 cm (antes se apoyaba encima de la caja). Cada tipo es una malla compartida (`KitMesh.cached`).
**Desvío:** la caja abierta mide 0,15 m de ancho (antes 0,16) para que las solapas que cuelgan no agranden la caja del rincón (la tercera caja llega justo al borde de la mesa, x 0,45).
**Motivo:** biblia §10.

### Se borran `WorldPalette.textured()` y tres alias sin uso
**Decisión:** con el escritorio, el rincón y los paquetes del kit, `textured("cardboard")` (el último nombre que quedaba) y los alias `WOOD_DARK`, `PLASTIC_BEIGE_DARK` y `TAPE` de `WorldPalette` ya no los usa nadie fuera de las pruebas: se borran (`CLAUDE.md`, sin código muerto; mismo criterio que el paso 5 con `floor_planks` y `brick_wall`). Los modelos nuevos usan `LookPalette` directamente.

### Prueba de presupuesto
Medido: cuarto inicial **75 llamadas** (antes 120), 18 materiales (antes 27), 30 mallas con sombra (antes 53) y 8 transparentes; cuarto lleno **395 llamadas** (antes 440), 29 materiales (antes 37) y 191 mallas con sombra (antes 214). Topes (medido + 10 %, nunca por encima del anterior): inicio 82 llamadas, 19 materiales, 33 mallas con sombra y 9 transparentes; lleno 434 llamadas, 31 materiales y 210 mallas con sombra. OpenGL (`budget.csv`) da lo mismo que la estimación con todo a la vista (01 y 30: 75; 37: 395). Armar la escena principal con caché: ~11–18 ms.

### Pruebas adaptadas (misma intención, no más débiles)
- `tests/unit/test_world_palette.gd`: `textured()` ya no existe. En `test_the_same_request_gives_the_same_material` se quita su línea (las demás funciones siguen probadas); `test_paint_and_textures_carry_their_color_and_surface` pasa a `test_paint_carries_its_color_and_surface` y, en vez de recorrer las texturas con nombre (quedaba una), recorre **todas** las superficies con `paint()` y revisa sombreador, color y superficie de cada una (más cobertura).
- `tests/integration/test_look_shaders.gd` (`test_every_palette_material_can_be_drawn_on_a_mesh`): se quita el recorrido de `TEXTURES`; cada superficie ya se dibuja con `paint()` en la misma prueba.
- `tests/integration/test_scene_budget.gd`: topes bajados (regla A.10, no cambia la intención).

### Pruebas nuevas
- `tests/unit/test_desk_and_dispatch_models.gd` (8): el escritorio mide lo de siempre (x ±0,65, z −0,41…0,81, alto 1,15, nada bajo el piso); tiene `Body` (material del kit), `Monitor/Screen` (`crt_screen`, sin sombra) y los marcadores `LampBulb` y `ScreenGlow`, y nada más aparte; la ampolleta está sobre el tablero y `ScreenGlow` 0,12 m delante del centro de la pantalla; un rayo hacia abajo donde no hay nada toca el tablero a la altura de `table_box()` (la caja que tapa el parche de sol es la de verdad); ≤ 4.000 triángulos y ≤ 3 llamadas, una malla en caché; el rincón cabe en ≤ 1.500 triángulos y 2 llamadas, con sus marcadores a la altura de la mesa y del guacal; con todas las cajas y los paquetes (escondidos) mide x −0,435…0,45 y z −0,2…0,2 (±0,01); los paquetes comparten la malla y miden lo que se apila (`PACKAGE_HEIGHT`), y la caja abierta tiene sus solapas hacia afuera y la pieza (`solid`) adentro, asomando.
- `tests/integration/test_main_scene.gd` (2): en el cuarto, el rincón empieza vacío y su caja (con los paquetes escondidos) mide x −0,435…0,45 y z −0,2…0,2; la lámpara (`cc_pl0`) y el monitor (`cc_pl1`) están en `LampBulb` y `ScreenGlow` del escritorio.

## 2026-10-22 — Arte 2.0, paso 8: las otras seis familias y el estado de noche por impresora

### Siete familias del kit, cada una en su archivo
**Decisión:** `PrinterModel.build(parent, nombre, id, color)` sigue igual (fachada) y suma un parámetro opcional `detail`. Cada familia vive en `game/world/props/printers/`: `CuboUnoModel` (lo del paso 6, mudado tal cual), `RayoModel` (Rayo Mini, Rayo X1 y Prisma MC, de voladizo), `EnclosedPrinterModel` (Bóveda P1 y Titán Pro, cerradas) y `ResinPrinterModel` (Gota R1); lo que comparten (marcadores, pantallita, carrete, patas, boquilla, reglas del detalle) está en `PrinterParts`. Se borran los modelos de cajas (`_open_frame`, `_enclosed`, `_color_box`, `_resin`). Las siluetas, de la biblia §9.3: la Mini achatada con el carrete en un soporte aparte a la derecha y cabezal redondo con aro verde que brilla; la X1 con la columna alta, barra LED, carrete arriba y pantalla táctil en un brazo; la Prisma con la caja de color (4 carretes a la vista bajo el marco de su tapa) sobre la columna, 4 tubos que se juntan y la rampa de purga con 4 colores; la Bóveda, cubo grafito de esquinas redondeadas; la Titán, más grande, con dos boquillas, pantalla ancha y la caja de colores integrada arriba; la Gota, base negra y tapa ámbar transparente. Todas ≤ 0,72 m de alto, ≤ 0,6 m de ancho y ≤ 0,55 m de fondo.
**Motivo:** biblia §9.2–9.3; `CLAUDE.md` (archivos pequeños, una responsabilidad).

### Detalle según dónde está la impresora
**Decisión:** la del piso va con detalle 1,0 (`PrinterParts.FLOOR_DETAIL`) y las de los muebles con 0,6 (`FURNITURE_DETAIL`; `RoomView` lo elige). Con 0,6: menos lados en lo redondo, sin los biseles de menos de 9 mm (nuevo `KitMesh.bevel_cutoff`, 0 por defecto: no cambia nada de lo que ya existía), carretes con tapas simples (`SpoolModel.add_flanges(..., lean)`: centro sin agujero y dos rayos cruzados), los de las cajas de color sin tapas, patas de cubitos, curvas con menos tramos, sin los tubos de la caja de color, y **solo `Body` da sombra** (las partes que se mueven, el bobinado y lo de adentro de las cerradas no). Medido (triángulos con detalle 1,0 / 0,6): Cubo Uno 2.386 / 1.118, Rayo Mini 2.138 / 1.109, Rayo X1 1.938 / 1.098, Prisma MC 2.286 / 1.006, Bóveda P1 2.150 / 966, Titán Pro 2.306 / 1.122, Gota R1 940 / 456. Llamadas con la sombra: abiertas 9 en el piso y 6 en un mueble; cerradas 6 y 6; resina 7 y 6 (biblia §5.2: ≤ 9 y ≤ 6). La tienda y los paneles usan el detalle 1,0.
**Nuevo en el kit:** `SpoolModel.add_winding` (bobinado fijo dentro de una malla) y `SpoolModel.add_small` (carrete chico y simple, para las cajas de color); `SpoolModel.build` y `winding_mesh` aceptan `detail`.
**Motivo:** biblia §5.1–5.2 ("impresora de mueble (0,6): ≤ 1.200 triángulos, 6 llamadas, solo `Body` da sombra").

### Cerradas: la cama baja y el techo es de vidrio
**Decisión:** en la Bóveda y la Titán el cabezal (`PrintHead/Carriage`) corre arriba y nunca sube; la cama (`Platform`) baja de a una capa para que la pieza termine siempre bajo la boquilla (con espagueti baja además lo que suben las hebras, sin pasar de `PlatformLow`). Sin trabajo la cama está abajo. **Desvío:** además de la puerta, el **techo es de vidrio** (solo su marco y un reflejo; en la Titán, delante de la caja de colores). Con la cámara del juego (desde arriba, ~35°) por la puerta solo se veía el piso de adentro: el cabezal, la parte de arriba de la pieza y la luz del fondo quedaban tapados por el techo. Con el techo de vidrio se ven el cabezal, la pieza y la luz de adentro.
**Desvío:** el carrete de las cerradas es **parte de `Body`** (no cambia de color con el trabajo: tiene el del primer carrete de la partida), para que la impresora cueste 6 llamadas también en un mueble. Se ve poco (atrás, asomando; o dentro de la caja de colores) y la pieza ya muestra el color del trabajo.
**Luz de adentro por estado** (`Interior`: el fondo y la tira LED del techo; sin sombra): apagada (gris, material del kit) sin trabajo; `WorldPalette.glow(#ffd58a)` (Bóveda) o `glow(#fff1d6)` (Titán) imprimiendo; verde `#4cbf5a` lista; roja `#e0453a` con falla (biblia §9.3: "el interior pasa a rojo").
**Motivo:** biblia §9.2–9.3 (la pieza crece adentro y se ve por la puerta; la falla muestra el espagueti adentro y el interior pasa a rojo).

### Resina: la pieza cuelga de la placa que sube
**Decisión:** en la Gota R1 la placa (`Plate`) sube con la pieza: imprimiendo, la cara de abajo de la placa queda a `PieceAnchor` + el alto de la pieza, y la pieza va de la resina a la placa (su borde de arriba pegado a la placa). La malla de la pieza va girada 180°: la **capa caliente queda abajo**, sobre la resina, donde crece la capa nueva. Lista, la placa sube a `PlateTop` con la pieza colgando (sin saltito). Si falla (cualquier tipo de falla), la placa sube vacía y la pieza **cae a la tina** (`VatFloor`), inclinada y apoyada en su esquina más baja; la resina no hace espagueti. La resina de la tina (`Resin`) toma el color del trabajo, como el filamento.
**Tapa ámbar:** nuevo material `WorldPalette.glass(hex, alfa)` (`kit_glass.gdshader`: el kit con color por uniform, transparente, de los dos lados y sin sombra). Es la única superficie transparente de una impresora (una llamada más).
**Motivo:** biblia §9.3 ("la pieza cuelga bajo la placa y crece hacia abajo mientras la placa sube; en la falla la pieza cae a la tina inclinada").

### Halos de noche: un MultiMesh para todas
**Decisión:** `HaloField` (`game/world/look/halo_field.gd`, nodo `Room/Halos`): un `MultiMeshInstance3D` con un cuadro acostado por impresora, del color de su estado en el color de cada copia (`use_colors`); `halo_field.gdshader` suma luz con un degradé redondo × `cc_night`. Cada `PrinterView` pide su halo al armarse (bajo la huella de `Body`, apoyado donde apoya la impresora, 1,5 veces más grande) y le cambia el color en cada cambio: apagado sin trabajo, cálido `#ffb35c` imprimiendo, verde `#4cbf5a` lista, rojo `#e0453a` con falla (`LookPalette.STATE_*`). `DayCycle` lo muestra solo cuando `cc_night` > 0: **de día no se dibuja** (no cuesta ni una llamada); de noche es una sola llamada para todas. Probado con una noche puesta a mano en el laboratorio (el juego todavía no tiene noche: paso 13).
**Motivo:** biblia §9.2 y §5.3.

### PrinterView reconoce el modo por las partes del modelo
**Decisión:** `Bed` → abierta (como antes), `Platform` → cerrada, `Plate` → resina. Todas arman `PieceSpot` (con `Piece`, `Spaghetti` y `Sparkles`) y `Tray0..5`; ya no hay impresoras "solo con pantallita". Se borra el camino "sin marcador" de `PrinterView._marker` y de `RoomView._place_printer_led` (todas las familias tienen sus marcadores; lo pedía el paso 6). `PrinterView.new(uid, printer_id)` (antes recibía la escala): saca de ahí la escala y el color de la luz de adentro. Las medidas de la Cubo Uno (`CuboUnoModel.BED_TOP`, `HEAD_REST`, `TRAY_ANCHOR`...) se definen desde las constantes de `PrinterView` (`BED_TOP`, `PIECE_Z`, `HEAD_REST_Y`, `HEAD_PARK_X`, `TRAY_*`), que siguen siendo el contrato que revisan las pruebas: un solo lugar para cada número.
**Se borran** (sin uso): los alias `WorldPalette.PLASTIC_BLACK`, `ACCENT_BLUE` y `PRINT_BED` (los usaban los modelos de cajas) y `RoomView.PRINTER_LED_ABOVE_BED`.

### Prueba de presupuesto
Medido: cuarto inicial igual que en el paso 7 (75 llamadas, 18 materiales, 30 mallas con sombra, 8 transparentes); cuarto lleno **230 llamadas** (antes 395), **20 materiales** (antes 29), **80 mallas con sombra** (antes 191) y 5 transparentes (las 2 tapas ámbar). Topes (medido + 10 %, nunca por encima del anterior): lleno 253 llamadas, 22 materiales y 88 mallas con sombra; el inicio no cambia.

### Herramienta de presupuesto: respeta #ifdef (más exacta)
`tests/helpers/scene_budget.gd` decide si un sombreador es transparente leyendo su código. Ahora aplica `#define`, `#ifdef`, `#ifndef`, `#else` y `#endif` antes de buscar `ALPHA` (como hace Godot). Sin esto, el `ALPHA = alpha;` que solo existe en la variante `KIT_GLASS` de `kit_body.gdshaderinc` marcaba como transparentes (y sin sombra) a todos los materiales del kit, y la prueba de presupuesto medía mal. No cambia ningún tope ni ninguna intención: mide lo mismo que dibuja el motor.

### Pruebas adaptadas (misma intención, no más débiles)
- `tests/integration/test_scene_budget.gd`: topes del cuarto lleno bajados (regla A.10).

### Pruebas nuevas
- `tests/integration/test_printer_families.gd` (10): el catálogo tiene estas siete familias; cada una se arma con los dos detalles, apoyada en y = 0, ≤ 0,72 m de alto, ≤ 0,6 × 0,55 m, con `Display` (material de la pantallita, sin sombra), `Body` del kit y `PieceAnchor`, `TrayAnchor` y `BedLight`; las abiertas con `Gantry`, `PrintHead/Carriage`, `Spool/Filament`, `Bed`, `HeadRest` y `HeadPark`; las cerradas con `Platform`, `Interior`, `PrintHead/Carriage` y `PlatformLow` (la cama empieza a `HEAD_CLEARANCE` de la boquilla y baja más que la pieza más alta); la de resina con `Plate`, `Resin`, `Lid` (transparente, sin sombra), `PlateTop` y `VatFloor`; presupuesto de cada una en el piso (≤ 2.400 triángulos, ≤ 9 llamadas) y en un mueble (≤ 1.200, ≤ 6, solo una malla con sombra); las siete siluetas difieren; en el cuarto, la del mueble tiene menos detalle y sus partes que se mueven no dan sombra; la Rayo Mini (escala 0,82) hace crecer la pieza y sube el cabezal y su brazo; en las cerradas la pieza crece (nunca baja), termina bajo la boquilla, la cama baja con ella, la luz de adentro pasa a la de imprimir, con espagueti el nido se ve del color del filamento y la luz pasa a roja, y al limpiar vuelve; en la de resina la pieza crece hacia abajo con su borde de arriba pegado a la placa que sube, la capa caliente abajo y la resina del color del trabajo, y al fallar cae a la tina inclinada, sin espagueti; cada impresora tiene su halo (apagado sin trabajo, cálido imprimiendo, verde lista, y el interior verde), bajo la impresora, visible solo de noche.
- `tests/unit/test_kit_mesh.gd` (1): `bevel_cutoff` quita solo los biseles más chicos que el corte (una caja con bisel de 5 mm pasa de 44 a 12 triángulos; una de 20 mm sigue con 44) y las cajas miden lo mismo.

## 2026-10-22 — Arte 2.0, paso 9: muebles y estantería arreglada

### Seis muebles del kit, una malla cada uno
**Decisión:** `FurnitureModel.build(parent, nombre, id)` sigue igual (fachada) y suma el parámetro opcional `wall_gap` (biblia §10). Cada mueble que se compra es UNA malla del kit (`Body`, en caché por tipo y variante, detalle 0,8) más sus `PrinterSpotN` (`Marker3D`, tantos como `printer_slots` en `data/furniture.json`): 2 llamadas con su sombra y ≤ 1.500 triángulos (medido: mesa auxiliar 416, mesa de trabajo 620, estantería 1.122, repisa 1.360 en la pared y 1.480 con su pie, cubos 1.208, tablero 1.118 y 1.238; con los arreglos de la ronda 1). Los modelos viven en `game/world/props/furniture/`: `TableModels` (mesa auxiliar y mesa de trabajo), `MetalRackModel`, `FilamentStorageModels` (repisa y cubos), `PegboardModel` y lo común en `FurnitureParts` (detalle, lugares, pie propio, escuadras impresas, cajas de filamento). En los muebles no se hacen los biseles de menos de 5 mm (`KitMesh.bevel_cutoff`, como en las impresoras de mueble): en piezas chicas no se ven y cuestan 32 triángulos por caja.
**Motivo:** biblia §10, §5.1–5.2 (mueble ≤ 1.500 triángulos, 2 llamadas); antes eran 4 a 13 cajas por mueble (la estantería vieja: 7 mallas y 14 llamadas).

### Estantería de 2,40 m con 0,74 m libres en cada piso (desvío de 2 cm)
**Decisión:** postes de 2,40 m y cuatro tablas con su cara de arriba en **0,075 / 0,845 / 1,615 m** (las impresoras) y 2,385 m (el techo): 0,74 m libres en los tres pisos. **Desvío:** la biblia y el plan dan las tablas en 0,08 / 0,85 / 1,62 / 2,37 (`PrinterSpot` en 0,095 / 0,865 / 1,635), pero así el piso de arriba deja solo 0,72 m (2,37 − 0,015 − 1,635), no los 0,74 que la misma biblia promete: una Rayo X1 (0,718 m) quedaba a 2 mm de la tabla. Bajé las tres tablas de abajo 2 cm y dejé el techo en 2,37 y el alto en 2,40. Las tablas van dentro de su marco de ángulo (más anchas: 1,22 × 0,57 m, la Titán Pro de 0,52 m de fondo entra con holgura).
**Motivo:** biblia §10 ("0,74 m libres por nivel, todas las familias caben"); la prueba nueva lo revisa con la geometría de cada familia en cada piso.

### Lo que se cuelga: pegado a la pared o sobre su pie (D5, se informa)
**Decisión:** `RoomLayout.wall_gaps` da la distancia del centro de cada lugar a la pared que tiene detrás: 0,45 m (lugar 1, pared de la ventana), 0,40 m (lugares 2, 3 y 4, pared del fondo) y `FurnitureModel.NO_WALL` (−1) en el lugar 5 (en medio del cuarto) **y también en el 0**, que está bajo la ventana (una repisa o un tablero ahí taparían el hueco; hoy el lugar 0 es siempre el escritorio, que no se vende). `RoomView` la pasa a `FurnitureModel.build`. La repisa de filamento y el tablero de herramientas tienen dos mallas: colgados (su espalda en la pared, a 1,5 cm) o sobre un **pie propio** (dos parantes negros con pies en T y tapones, dos travesaños). El mueble de cubos se arrima a la pared si la hay, contra el zócalo (centrado si no). Lo demás va centrado en su lugar, como antes. Las vistas de la tienda usan la variante con pie (no hay pared).
**Motivo:** biblia §10 y decisión D5 (arregla que la repisa y el tablero flotaban a 0,12–0,25 m de la pared).

### A 1,5 cm de la pared, no a 5 mm
**Decisión:** lo que se cuelga queda a 1,5 cm de la pared (`FurnitureParts.WALL_CLEARANCE`); lo que va en el piso contra la pared (el mueble de cubos), a 3 cm (`FurnitureParts.FLOOR_WALL_GAP`, ver la ronda de arreglos 1). A 5 mm, el borde de la sombra de su canto de arriba caía sobre la pared justo al lado del canto y se veían los dientes del mapa de sombras (un texel ≈ 1 cm) con zoom cerca; a 1,5 cm ese borde queda detrás del mueble y no se ve (con zoom normal no se ven en ningún caso). Sigue "pegado" (la prueba exige ≤ 2 cm).

### Mueble de cubos de 2 × 4 huecos
**Decisión:** 0,80 × 1,50 × 0,40 m, blanco, **2 columnas × 4 huecos** de 0,36 × 0,35 m (un mueble de cubos de 0,80 × 1,50 m de verdad es así). **Desvío:** la biblia dice "2×2 cubos" con esas medidas: quedaban 4 huecos de 0,70 m de alto, medio vacíos con carretes de 0,2 m. Adentro: 4 pilas de 3 carretes acostados (12 kg, lo que guarda el mueble en los datos), una caja de filamento, dos tarros impresos y un florero impreso; corridos hacia adelante y un poco a la izquierda para que el costado no los tape con la cámara del juego. El fondo de los huecos es un tono más oscuro (`LookPalette.MELAMINE_SHADE`) y hace de sombra adentro. El fondo del mueble es de 0,40 m (la biblia da 0,55: era lo que medía el viejo con los carretes que sobresalían).

### Carretes dentro de la malla del mueble (no un MultiMesh)
**Decisión:** los carretes de la repisa (6), del mueble de cubos (12) y los de arriba de la estantería (2, de canto desde la ronda 1) van **dentro de la malla del mueble**: no cambian de color, así que no hace falta que vayan aparte, y no suman llamadas (un `MultiMesh` sumaría 1 más su sombra). El plan pedía `MultiMesh` "si pasan de 8"; con todo en una malla no hay carretes sueltos que juntar, y los triángulos son los mismos. Para que quepan en ≤ 1.500 triángulos hay dos formas baratas nuevas en `SpoolModel`: `add_on_shelf` (de canto, eje paralelo a la pared: bobinado, aro de la tapa con su canto y dos rayos cruzados, sin las caras que tapa el bobinado; ~170 triángulos) y `add_stack` (pila acostada: los cantos de dos tapas que se tocan en uno solo y la tapa abierta arriba; ~190 triángulos por 3 carretes). Por el aro de las tapas se ve el color del filamento (biblia §9.4).
**Motivo:** biblia §5.1 (una malla por objeto), §5.3 y §13 (menos llamadas).

### Nuevo en la paleta
`LookPalette`: los 9 filamentos con nombre (`FILAMENT_WHITE` … `FILAMENT_PURPLE`, los de `config.filament_colors`), `MELAMINE` (= `TRIM`), `MELAMINE_SHADE` (`#d9d2c4`, de la tabla del personaje) y `PEGBOARD` (= madera clara). Ningún color nuevo fuera de la biblia.

### Se borra `PropBuilder.cylinder`
No lo usaba nadie. Quedan `box` (la pieza que crece, un `BoxMesh` por contrato, y la bandeja), `quad` (pantallas y la vista de la ventana) y `sphere` (el personaje de cajas, hasta el paso 10). `PixelTextures` y `WorldPalette.PIXEL_WORLD_SIZE` ya no existían (pasos 3 y 7).

### Prueba de presupuesto
Medido: cuarto inicial igual (75 llamadas, 18 materiales, 30 mallas con sombra, 8 transparentes); cuarto lleno **170 llamadas** (antes 230; el plan pedía ≤ 240 y la biblia ≤ 200 al final), **18 materiales** (antes 20; = final de la biblia), **50 mallas con sombra** (antes 80), 5 transparentes; triángulos 29.655 en color y 51.740 con la sombra. OpenGL en las capturas: 37 → 170 = estimación. Topes (medido + 10 %): lleno 187 llamadas, 19 materiales, 55 mallas con sombra; el inicio no cambia.

### Pruebas adaptadas (misma intención, no más débiles)
- `tests/integration/test_scene_budget.gd`: topes del cuarto lleno bajados (regla A.10).

### Pruebas nuevas
- `tests/integration/test_furniture_models.gd` (8): cada mueble del catálogo se arma, con y sin pared, apoyado en y = 0 y con tantos `PrinterSpot` (`Marker3D`, en orden) como `printer_slots`; los comprables son una sola malla con el material del kit (carretes incluidos); cada uno cuesta ≤ 1.500 triángulos y ≤ 2 llamadas con su sombra y su malla se arma una vez; la estantería tiene sus postes de 2,40 m, los lugares en 0,075 / 0,845 / 1,615 y 0,74 m libres en cada piso (más que el alto máximo de una impresora); **cada familia cabe en cada piso** (con su geometría de mueble, el borde de arriba bajo la tabla siguiente y sin salirse por delante ni por detrás); en el cuarto lleno ninguna de las 15 impresoras de las estanterías atraviesa una tabla; las distancias de `RoomLayout.wall_gaps` llegan justo a la pared, el lugar 5 y el 0 (bajo la ventana) no tienen dónde colgar; la repisa y el tablero quedan a ≤ 2 cm de la pared en los lugares 1–4 y, en el 5, sobre su pie (dos parantes que suben sin cortes del piso hasta más arriba de su tabla o tablero) y lejos de las paredes; el mueble de cubos se arrima a la pared contra el zócalo (sin atravesarlo) y va centrado sin ella. La prueba de tocar lugares libres (> 300 puntos) sigue igual y pasa.

### Ronda de arreglos 1 (revisión del paso 9)
**Decisión:** se arregla lo que encontró la revisión:
- **Código muerto fuera:** `SpoolModel.stack_height` (nadie la usaba), las copias `WorldPalette.WOOD_LIGHT`, `METAL_DARK` y `METAL_MID` (sus últimos usuarios eran los muebles viejos; los modelos usan `LookPalette`) y la rama `flanges` de `SpoolModel.build` (el único que la llamaba de verdad, `PrinterParts.spool`, pasaba `false`: las tapas van dentro de la malla de la impresora). `SpoolModel.build(parent, nombre, posición, color, radio, detalle)` arma solo el nodo con su bobinado.
- **El mueble de cubos no corta el zócalo:** estaba a 1,5 cm de la pared y el zócalo sobresale 1,8 cm, así que su espalda lo atravesaba 3 mm. Ahora lo que va en el piso contra la pared queda a `FurnitureParts.FLOOR_WALL_GAP` (3 cm, la misma que las cajas bajo la repisa y el tablero). El zócalo pasa a ser una constante con nombre, `RoomShell.BASEBOARD` (las mismas medidas: 0,1 × 0,018 m).
- **Cajas organizadoras abiertas de verdad** (`FurnitureParts.open_bin`: fondo y cuatro paredes finas): las de la mesa de trabajo y los tarros del mueble de cubos eran cajas cerradas con una tapa oscura pintada y de cerca se leían como cajas con tapa negra. Ahora se ve el canto de las paredes y adentro, más oscuro por la oclusión del kit. Mesa de trabajo 578 → 620 triángulos; cubos 1.180 → 1.208.
- **Arriba de la estantería, dos carretes de canto** (`SpoolModel.add_on_shelf`) en vez de la pila de dos: vista desde arriba, la pila se leía como una lata con una cruz. Estantería 940 → 1.122 triángulos (sigue en 2 llamadas); cuarto lleno +910 triángulos (31.935 en OpenGL en la captura 37; llamadas iguales: 170).
**Motivo:** CLAUDE.md (sin código muerto), plan paso 9 ("borrar … si ya nadie las usa") y las notas de la revisión.

**Pruebas adaptadas (misma intención, no más débiles):**
- `tests/unit/test_printer_model.gd`, `test_the_spool_lies_on_its_side_with_open_flanges_ten_percent_bigger`: las tapas ya no salen de `SpoolModel.build`; la prueba las arma con `SpoolModel.add_flanges` (lo mismo que usan las impresoras) y revisa lo mismo: un 10 % más grandes que el bobinado, el bobinado entre las dos, abiertas entre los rayos y cerradas en un rayo.
- `tests/integration/test_furniture_models.gd` (prueba nueva de este mismo paso), `test_the_cube_shelf_stands_against_the_wall`: antes pedía 0–2 cm de la pared; ahora pide **más que el zócalo** (no lo atraviesa, lo nuevo) y hasta `FLOOR_WALL_GAP` (3 cm). El tope sube 1 cm porque el mueble va contra el zócalo; la parte nueva es más estricta.
- Misma prueba, `_assert_stand_holds_it_up` **más estricta**: antes bastaban los pies y las puntas de los travesaños y de las escuadras (caen en la misma x que los parantes) para pasar, aunque no hubiera parantes. Ahora cuentan solo las caras que caben en el ancho del parante (x y z) y tienen que cubrir **sin cortes** desde el piso hasta más arriba de la tabla o el tablero de abajo. Comprobado a mano: sin parantes, o con parantes de 0,5 m, falla.

## 2026-10-22 — Arte 2.0, paso 10: el personaje nuevo (modelo, piel, cara, pelo y retratos)

### Personaje rediseñado (D3, aprobada por el dueño)
**Decisión:** `CharacterModel.build(parent, nombre)` sigue siendo la fachada y arma al personaje de la biblia §7: 1,40 m y unas 3,2 cabezas (caderas en 0,50 m, rodillas 0,27, hombros 0,90, codos 0,70, centro del cráneo 1,15, mentón 0,96), buzo gris carbón `#3e4250` con la capucha enrollada y su forro mostaza, cordones crema con puntas mostaza, bolsillo canguro, borde y puños acanalados, el logo de tres capas cian; jeans `#3d5c96` con la basta doblada; zapatillas blancas gorditas con suela y franja cian; mentón levantado 6° (`Body/Head.rotation.x = −0,10`). `HEIGHT` pasa de 1,25 a 1,40. Todos los colores salen de `LookPalette` (ya estaban desde el paso 3).
**Motivo:** biblia §7.1–7.6; D3 (el GDD decía "buzo negro"; el dueño aprobó el gris carbón con acento mostaza, que se lee mejor sobre el piso).

### Una malla con piel para el cuerpo (no el plan B)
**Decisión:** el cuerpo es UNA `ArrayMesh` con huesos y pesos (`Rig/Mesh`) sobre un `Skeleton3D` nuevo, `CharacterRig` (`game/world/character/character_rig.gd`), con un hueso por pivote y la misma jerarquía (Body; HipL/R y sus rodillas; ShoulderL/R y sus codos; Head). **Los pivotes `Node3D` siguen siendo el contrato** (controlador y pruebas); `CharacterRig.follow()` copia cada cuadro la posición, el giro y la escala de cada pivote a su hueso (sin memoria nueva) y `RoomView.step()` lo llama justo después del controlador (el paso 11 pondrá el animador en medio). Pesos: cada parte rígida a su hueso, con un anillo de mezcla de ±4 cm (`CharacterRig.BLEND`) en caderas, rodillas, hombros y codos (y el cuello entre el cuerpo y la cabeza). Piernas y brazos son un solo tubo (torno con más anillos en la rodilla y el codo, cerrado arriba): se doblan sin cortes ni "hombreras". La cabeza es una malla rígida hija de `Body/Head` (cráneo, orejas y pelo juntos). `extra_cull_margin = 0,3` porque la caja de una malla con piel es la de reposo.
**Detalle técnico:** la malla con piel es hija del `Skeleton3D` (en la identidad), no de `Body` como dice la biblia: así su transformación no se suma dos veces a la de los huesos. La piel (`Skin`, una para todos) usa como pose de enlace la inversa del reposo de cada hueso.
**Motivo:** biblia §7.2–7.3. Se probó en la sesión: dobla bien rodillas y codos (laboratorio con poses de caminar y agacharse); el plan B (segmentos rígidos) no hizo falta.

### Seis llamadas: dos mallas, su sombra y dos contornos
**Decisión:** materiales nuevos de `WorldPalette`: `kit_character()` (el kit con `toon` 0,8, borde 0,35 y el refuerzo de relleno del personaje, `cc_fill.w`), `kit_head()` (lo mismo con la cara) y `outline_character()` (casco invertido por normales, 1,5 píxeles del mundo con `cc_px_m`, tinta `#1a1830` y café `#2e180c` en el pelo, que el contorno reconoce por la superficie del vértice). Cada contorno es una `MeshInstance3D` aparte ("Outline") que comparte la malla (y el esqueleto) y tiene `cast_shadow = OFF`. Medido: **6 llamadas** (antes 48), **6.775 triángulos** (cuerpo 3.232, cabeza con pelo 3.543; biblia ≤ 8.000), 3 materiales.
**Motivo:** biblia §3.7, §5.2 y §7.3.

### Superficies nuevas del kit: piel y pelo
**Decisión:** `WorldPalette.Surface` suma `SKIN` (8) y `HAIR` (9). En la piel de la cabeza se pinta la cara; el pelo no la recibe aunque esté delante de la frente, y su contorno es café. El personaje no usa superficies con dibujo del mundo (tela, madera): esas se dibujan en coordenadas del mundo y se moverían sobre él al caminar.

### La cara: atlas por código y proyección cilíndrica
**Decisión:** `FacePainter` (`game/world/look/face_painter.gd`) pinta 8 expresiones en celdas de 128 × 128 (`Face`: normal, parpadeo, feliz, preocupado, hablar A y B, concentrado, sorpresa) con ojos de 4,9 × 6,0 cm (contorno, iris que se aclara hacia abajo, pupila y dos brillos), cejas gruesas, nariz apenas marcada, boca chica y rubor. El alfa es la máscara de los ojos abiertos. **Desvío:** la biblia dice "pintado a 4× y reducido"; se pinta a tamaño final con el borde suavizado por cuenta (cobertura según la distancia al borde): se ve igual de suave y cuesta 16 veces menos (≈ 60 ms una vez, en vez de ~1 s). `kit_head.gdshader` la proyecta alrededor del eje vertical de la cabeza (120° de ancho, 0,30 m de alto, centrada en la línea de los ojos 3 cm bajo el ecuador del cráneo): a 3/4 los dos ojos siguen la curva. `instance uniform int expression` y `vec2 gaze`: dentro de la máscara, el iris y la pupila se corren hasta ±3 % del ancho de la cara; lo que queda atrás es la tinta del ojo. El enum se llama `Face` porque `Expression` es una clase de Godot.

### La mirada: la cabeza gira como mucho 20°, el resto lo hacen las pupilas
**Decisión:** `CharacterController.MAX_GLANCE` 55° → **20°** (lo pide el plan); para no perder el gesto de mirar lo que tiene cerca, las pupilas siguen hasta 35° más (`GAZE_REACH`, `MAX_GAZE` 0,03). El controlador cambia el `gaze` de la cabeza solo cuando se mueve más de 0,0005 (sin memoria nueva). Es lo que pide la biblia §7.5; el paso 11 lo pasará al animador.
**Motivo:** a más de ~30° la cámara alta deja de verle la cara.

### El pelo: una sola superficie
**Decisión:** `HairKit` (`game/world/look/hair_kit.gd`) arma el pelo como una lámina continua (`KitMesh.sheet`, nuevo: una grilla de puntos con su normal y su color) sobre un casquete un poco más grande que el cráneo: 14 mechones alrededor (6 atrás, uno sobre cada oreja, uno en cada sien y las 4 lenguas redondeadas del flequillo, torcidas hacia un lado), con su lomo abombado y un pliegue suave entre ellos que se enrosca hacia la coronilla; patillas, nuca y el borde metido hacia la cabeza. Color por vértice: base, brillo en lo alto de cada mechón, pliegues oscuros y el borde de abajo en sombra. Más 3 mechoncitos sueltos acostados en la coronilla. Se revisó de frente, de perfil, de espaldas y desde arriba (laboratorio): con mechoncitos parados se leía "corona de puntas" y con bolitas, "piedras"; quedaron mechones finos acostados con la punta apenas levantada. El flequillo termina más de 1 cm sobre las cejas (prueba).
**Motivo:** biblia §7.6.

### El globo de diálogo se ancla a la cabeza
**Decisión:** `Body/Head/SpeechAnchor` (`Marker3D`, sobre el pelo); `RoomView.speech_point()` da su posición y `WorldControls` coloca el globo ahí (antes, a `HEIGHT` sobre los pies). Sigue saltos y gestos.

### Zancada de 0,75 m
**Decisión:** `ControlsTuning.stride_length` 0,55 → 0,75 (no lo fijó el dueño; la velocidad sigue en 2,2 m/s): las piernas del personaje nuevo son más largas y a 0,55 daba 4 pasos dobles por segundo.

### Retratos con luz de estudio y la cara que cambia
**Decisión:** `ModelPreview` pone en cada malla del modelo `preview_light = 1` (en los sombreadores del personaje cambia la luz del cuarto por una luz de estudio fija: ambiente, llave cálida desde arriba a la izquierda, relleno frío desde la derecha y borde) y `px_m_override` (los metros por píxel de la vista, para el grosor del contorno); en los modelos del kit (tienda) no hace nada todavía (el paso 16 lo extiende). El sol de la vista sigue con sombra, como el del mundo en Alta. Nuevo `ModelPreview.redraw()`. Tarjeta del HUD: encuadre (0; 1,15; 0) y 0,62 m (la cabeza); cambia de cara en los momentos importantes de la biblia §7.8 (feliz 2,6 s al cobrar a tiempo; preocupado 3,2 s si falla una impresión; sorpresa 0,6 s y feliz hasta 3 s al subir de nivel) y solo entonces se vuelve a dibujar. Pantalla de Perfil: cuerpo entero, (0; 0,72; 0) y 1,65 m.
**Nota:** "instance uniform" cuesta 16 lugares del búfer de globales por instancia; el personaje usa 4 mallas con ellos (×3 personajes como máximo: el cuarto, la tarjeta y el perfil) = 192 de 1.024. Las mallas del kit no los declaran y no gastan nada (se comprobó que ponerles el valor no da errores).

### Prueba de presupuesto
Medido: cuarto inicial **33 llamadas** (antes 75), **13 materiales** (antes 18), **8 mallas con sombra** (antes 30), 8 transparentes; 24.205 triángulos en color y 38.667 con la sombra. Cuarto lleno **128 llamadas** (antes 170), 13 materiales, 28 mallas con sombra, 5 transparentes; 44.573 / 74.801 triángulos. Topes (medido + 10 %, redondeado hacia arriba, nunca por encima del anterior): inicio 37 llamadas, 15 materiales, 9 mallas con sombra, 9 transparentes; lleno 141, 15, 31 y 12. Nuevo: el personaje ≤ 6 llamadas y ≤ 8.000 triángulos. **Para el paso 12:** la decoración (≤ 7 llamadas, con sombra) no cabe en los topes nuevos del inicio; según la regla de la prueba, habrá que subirlos anotando el motivo (la meta final de la biblia es ≤ 70 llamadas y ≤ 15 mallas con sombra).

### Se borran
`PropBuilder.sphere` (solo la usaba el personaje de cajas) y las copias de colores del personaje en `WorldPalette` (`SKIN`, `HAIR`, `HAIR_LIGHT`, `HOODIE`, `JEANS`, `SHOES`, `EYES`): el modelo usa `LookPalette`.

### Pruebas adaptadas (misma intención, no más débiles)
- `tests/integration/test_scene_budget.gd`: topes bajados (regla A.10) y dos topes nuevos del personaje.
- `tests/integration/test_look_shaders.gd`: los tres sombreadores nuevos se compilan con sus parámetros y sus tres materiales se dibujan sobre una malla (más cobertura; el recorrido de todas las superficies suma `SKIN` y `HAIR`).
- `tests/unit/test_character_controller.gd`: no cambia ninguna prueba; se suma una (la cabeza gira hasta 20° y las pupilas siguen).

### Pruebas nuevas
- `tests/unit/test_character_model.gd` (8): los pivotes del contrato, rodillas, codos y `SpeechAnchor` a las alturas de la biblia (y el cráneo, el mentón y el alto total); cada hueso con el reposo de su pivote, la misma jerarquía y, después de `follow()`, la pose (giro, lugar y escala) de su pivote; el cuerpo es una malla con piel, pesos que suman 1, las zapatillas con la rodilla, el pecho con el cuerpo y vértices mezclados en la rodilla; los contornos comparten la malla, no dan sombra y el del cuerpo se dobla con la piel; el pelo es una superficie entera con normales finitas y unitarias y el flequillo termina más de 1 cm sobre las cejas; el atlas tiene 8 celdas de 128 px, la máscara de los ojos abiertos (y ninguna con los ojos cerrados), expresiones distintas y ojos de más de 6 px con el zoom normal; mallas, piel y materiales compartidos entre dos personajes; cada personaje con su propia expresión.
- `tests/unit/test_scene_budget_helper.gd`: `child_geometry` cuenta una vez la malla que comparten dos instancias (el contorno).
- `tests/integration/test_hud.gd`: el retrato cambia de cara en los momentos importantes y vuelve a la normal.

## 2026-10-22 — Arte 2.0, paso 10, ronda de arreglos 1: hombros, capucha, cara de lejos y pelo arriba

### El hombro es una cúpula del mismo brazo, con el pivote adentro (arregla un defecto que bloqueaba)
**Problema:** la revisión encontró un corte y una "hombrera" en los dos hombros (biblia §7.2 pide "sin cortes ni hombreras"): la manga era un torno centrado 5 cm por fuera del pivote, con la punta cónica, y encima una bola aparte corrida hacia adentro; la punta del tubo asomaba por fuera de la bola (muesca oscura y facetas) y la bola sobre el tubo se leía como hombrera. Además, al revisar con el brazo levantado de costado apareció otro defecto: como el pivote estaba en el borde de arriba del brazo, al levantarlo 0,9 rad la punta de la manga se despegaba 8,5 cm del buzo (quedaba flotando), y 4 cm al balancearlo caminando.
**Decisión:** sin bola: la punta de la manga es una **cúpula lisa del mismo torno** (media elipse de 5,2 × 6,7 cm con 8 anillos, `CharacterModel.ARM_DOME`, `arm_profile()`), cerrada en horizontal (su normal es el eje: sin pellizco de luz). El **pivote del hombro baja a y 0,86 y sale a x ±0,195**, dentro de la cúpula y en el eje del brazo (`ARM_OFFSET` desaparece; `ELBOW_DROP` 0,20 → 0,16, así el codo sigue en y 0,70). El brazo cuelga un poco abierto (`SHOULDER_ROLL` 0,06 → 0,11) y su punta queda metida bajo la esquina del buzo, que arriba ya no se angosta (taper 0,95 → 1,0; el pecho sigue en 0,34 m). Medido con la piel calculada a mano: levantando el brazo de costado 0,9 rad la punta de la manga se mueve en promedio 0,2 cm (antes 3,7) y como mucho 1,5 cm (antes 8,5); balanceándolo, como mucho 1,3 cm (antes 4,1).
**Desvío de la biblia §7.1:** los pivotes de los hombros pasan de (±0,17; 0,90) a (±0,195; 0,86). El alto del hombro que se ve (la punta de la manga, y 0,89) no cambia; cambia dónde gira: en el centro de la cúpula, como una articulación de verdad. Los nombres del contrato (A.7) no cambian.
**Motivo:** biblia §7.2, y que los gestos del paso 11 (puño arriba, estirarse, saludar) no dejen el brazo flotando.

### Brazos más delgados que las piernas y más redondos
**Decisión:** el brazo baja de 4,6–5,4 cm de radio a 4,2–5,2 (la pierna va de 5,2 a 6,6), y el puño se achica con él. Las piernas y los brazos pasan de 10 a 13 lados (`LIMB_SIDES` 12 → 16 con el detalle 0,8), las manos y los puños tienen más filas y los cordones son octogonales: de cerca (32a, 33 y retratos) ya no se ven prismas.
**Motivo:** nota de la revisión (brazos tan gruesos como las piernas y facetas de cerca).

### La capucha enrollada con puntas redondeadas
**Decisión:** `KitMesh.torus` tiene una opción nueva, `round_ends`: un arco termina en media esfera del grosor del tubo (sin costura con el tubo) en vez de una tapa plana. La capucha (280°, antes 300°, porque las puntas redondas sobresalen) y su forro mostaza (272°) la usan, con más segmentos (26 × 10 y 24 × 6).
**Motivo:** nota de la revisión: en 33 el rollo y el forro se veían en bloques y con las puntas cortadas en plano.

### La cara de lejos: más nítida y ojos de tinta
**Decisión:** `kit_head` lee el atlas de la cara con `textureLod` y el nivel de detalle que corresponde menos uno (`CC_FACE_LOD_BIAS`), calculado con los texeles de la celda por píxel. Con 2,5 a 5 texeles por píxel (`CC_FACE_FAR`; el zoom normal anda por 4 y el lejos por 8) los ojos pasan de pintados a **puntos de tinta con borde firme** (la máscara de los ojos se afila), conservando el brillo blanco donde todavía se ve. De cerca y en los retratos no cambia nada.
**Motivo:** nota de la revisión: con el zoom lejos (02, 24, 30, 37) y aun con el normal, el promedio de contorno, iris y brillos dejaba manchas café grisáceas con un anillo gris ("ojos morados"). El paso 9 tenía puntos nítidos; ahora vuelven, más grandes.

### El pelo visto desde arriba
**Decisión:** el remolino se suaviza (`SWIRL` 0,32 → 0,2) y los mechones (lomo, pliegue y las vetas de brillo) se apagan antes hacia la coronilla (`CROWN_FADE`, latitud 0,6 → 1,1 rad; antes 0,8 → 1,4 y las vetas hasta 1,3): arriba queda un casco liso. Los 6 mechones de atrás tienen anchos y largos distintos (antes iguales y simétricos). De frente, de perfil y de 3/4 no cambia.
**Motivo:** nota de la revisión: desde arriba los pliegues se juntaban en un molinillo marcado ("empanada" o "ajo"; la biblia §7.6 pide revisar que no parezca alcachofa) y la espalda se veía pareja.

### Captura 36
**Decisión:** `tools/screenshot_runner.gd` aleja al personaje (`AWAY_FROM_PRINTER_SPOT`) antes de 36: la manga del personaje (más alto desde el paso 10) asomaba como una barra oscura en el borde.

### Presupuesto
Personaje: **7.831 triángulos** (cuerpo 4.288, cabeza 3.543; antes 6.775; tope 8.000) y las mismas 6 llamadas. El resto del cuarto no cambia.

### Prueba adaptada (misma intención)
- `tests/unit/test_character_model.gd`, `PIVOT_HEIGHTS`: los hombros a 0,86 (antes 0,90), por el desvío de arriba. Sigue comprobando que cada pivote está a su altura; el codo sigue en 0,70.

### Pruebas nuevas
- `test_character_model.gd`: `test_the_top_of_the_sleeve_is_one_round_dome_without_seams` (el brazo cierra arriba en una cúpula lisa: sin ensancharse, sin quiebres de más de 25° y con la punta casi horizontal; el perfil viejo fallaba con un quiebre de 57°) y `test_the_top_of_the_sleeve_stays_on_the_shoulder_when_the_arm_moves` (con la piel calculada a mano, la punta de la manga se mueve menos de 2,5 cm, 5 cm con los brazos arriba, y en promedio menos de 1 cm al levantar el brazo de costado, adelante, atrás y arriba; el modelo anterior fallaba con 8,5 cm).
- `test_kit_mesh.gd`: `test_an_arc_can_close_with_round_ends` (las puntas son medias esferas del grosor del tubo, sin costura) y el arco con puntas redondas entra en la malla con todas las formas (caras, normales y valores finitos).
- `test_world_palette.gd`: `test_the_shaders_number_the_surfaces_like_the_palette` (las constantes `CC_*` de `kit_body.gdshaderinc` y de `outline_character.gdshader` valen lo mismo que `WorldPalette.Surface`; antes nada ataba el `CC_HAIR` del contorno).

## 2026-10-22 — Arte 2.0, paso 11: el personaje vivo (animación, expresiones y reacciones)

### Un animador por capas, el único que mueve las articulaciones (D8, aprobada)
**Decisión:** `CharacterAnimator` (`game/world/character/character_animator.gd`, `RefCounted`) escribe los giros, lugares y escalas de todos los pivotes de `CharacterModel`, la cara (`expression`, `gaze`) y el movimiento secundario (`swing`). Capas: locomoción (trote suave a 2,2 m/s: piernas ±0,40 rad, rodilla hasta ~1,0 rad en el paso con un adelanto de fase para que el pie de atrás se levante, codos 1,1 rad, brazos ±0,5, balanceo de cadera 0,05, giro de hombros 0,08 con la cabeza que lo compensa, inclinación 0,12 con un resorte que se asienta al frenar en seco, anticipo al arrancar con un aplastado de 0,1 s y pasitos al girar en el lugar); quieto (respiración por escala del pecho 1 → 1,015 a 0,35 Hz, cambio de peso solo en `Body`, mirada de hasta 20° más las pupilas, gestos sueltos con semilla después de 8 s); gestos; expresiones (`CharacterFace`); movimiento secundario; estirar y aplastar con la escala de `Body` (sin cambiar el volumen). D8 se aplica solo en lo visual: ningún cambio de juego.
**Detalle:** `CharacterController` crea su animador en `setup()` y lo avanza al final de `step()` (después de moverse); `RoomView.step()` sigue con `CharacterRig.follow()`. Así el orden es controlador → animador → `RigFollower`, como pide el plan, y las pruebas del controlador (quieto, chocar, caminar > 0,2 rad) siguen igual: el controlador ya no anima nada (sus constantes de animación y de mirada se borraron).
**Los pies se apoyan solos:** el cuerpo y las caderas bajan lo que suben las piernas abiertas o dobladas (con los giros de cadera y rodilla se calcula dónde queda la planta más baja). Eso da el rebote del paso (≈ 5 cm al trotar, la biblia pide 0,04) y deja los pies en el piso al agacharse; lo que un gesto despega (el salto) se suma encima.
**Motivo:** biblia §7.7; el paso 10 dejó el esqueleto y los pivotes nuevos (rodillas, codos) listos para esto.

### Los gestos son datos, con las manos puestas por cinemática inversa al cargar
**Decisión:** `CharacterGestures` (`character_gestures.gd`) tiene 12 gestos como poses clave en una constante (`DATA`): puño arriba, manos a la cabeza, salto, celular, pulgar arriba, saludo, encogerse de hombros, embalar, rascarse la cabeza, estirarse, bostezar y mirar la impresora con las manos en la cintura. Cada pose dice solo lo que mueve: el giro de un hueso, o **dónde va el centro de una mano** (`hand_l`/`hand_r`: punto y polo del codo), que `solve_arm` resuelve una vez al cargar con dos huesos y el codo de bisagra; el celular se orienta solo hacia los ojos (`phone_at`). Todo se arma en arreglos planos de cuaterniones (interpolación esférica cúbica entre poses, en el mismo hemisferio) y `sample()` no crea memoria. Mezcla de 0,12 s al entrar y al salir; al cortar o cambiar un gesto, la pose sale de la que tenía (otra mezcla de 0,12 s). Caminar los corta y no deja empezar otros; nunca bloquean nada.
**Motivo:** biblia §7.7 ("datos de cada gesto en arreglos"). Con ángulos de Euler a mano las manos no llegaban a la cabeza ni a la boca; con los puntos, el gesto se escribe como se piensa ("las manos en las sienes") y una prueba comprueba que llegan.

### Las reacciones (biblia §7.8)
**Decisión:** `CharacterAnimator.react(reacción, punto)`. `RoomView` escucha `Events` y se las pasa: `order_delivered` → feliz 2,6 s y puño arriba (atrasado: se rasca la cabeza, sin festejo); `print_failed` → preocupado 3,2 s, manos a la cabeza y mira esa impresora (solo la cabeza y los ojos: si se diera vuelta la cara preocupada no se vería); `level_up` → sorpresa 0,6 s y feliz hasta 3 s, con un salto que se aplasta al agacharse y al caer y se estira al despegar; `offer_arrived` → saca el celular (solo quieto y sin panel abierto); `printer_changed` a "lista" a 1,2 m o menos → pulgar arriba y feliz 1,5 s; `computer_changed` → cara concentrada mientras modela si está a 1,2 m o menos del escritorio; `time_changed` → de noche (22:00 a 5:00) el primer gesto suelto es bostezar, una vez por hora de juego; `game_loaded` → sin reacciones pendientes. `WorldControls`: tocar al personaje → se da vuelta hacia la cámara y saluda (feliz 1,2 s); cada cuadro le dice si se ve el globo (la boca alterna las dos celdas de hablar 8 veces por segundo) y si hay un panel abierto. `OrderLoopController`: una acción rápida que no se pudo, o un botón de un panel que no se pudo → se encoge de hombros; embalar o despachar a 1,2 m o menos del rincón → gesto de embalar (desde lejos no: caminar nunca es obligatorio). Las duraciones de las caras están en `CharacterFace` y las usa también el retrato del HUD (`ProfileCard`).
**Prioridades:** las reacciones a la partida reemplazan al gesto que esté haciendo; el celular y los gestos sueltos esperan su turno (no interrumpen).
**Desvío:** el plan pide encogerse de hombros solo con la acción rápida que falla; también se hace con los botones de los paneles que fallan (el panel muestra el motivo en rojo y el personaje se encoge), porque hoy la acción rápida casi nunca puede fallar.

### Quieto y sin nada que mirar, se gira a 3/4 hacia la cámara
**Decisión:** `CharacterController.camera_yaw` (lo pone `RoomView` con `CameraRig.YAW`): después de 2 s quieto, sin objeto cercano y sin algo que mirar (`face`), gira despacio (160°/s, con pasitos) hasta quedar a 15° de mirar la cámara de frente, del lado hacia donde ya miraba. **Interpretación:** la biblia dice "gira a 3/4 hacia la cámara (giro 45° ± 20°)"; 45° es el giro de la cámara, así que el personaje termina en 45° ± 15° (prueba: ≤ 20° de la cámara y no de frente plano). Se eligió 15° porque la cara se lee hasta unos 30° y así nunca queda de frente plano.

### Movimiento secundario en los sombreadores, sin llamadas nuevas
**Decisión:** el pelo, los cordones y el bulto de la capucha usan el peso de balanceo de los vértices (`UV.y`, `KitMesh.hanging`, el mismo de las plantas): en el pelo crece desde la coronilla hacia las puntas; en los cordones, desde donde salen; en la capucha es 0,35. Un `instance uniform vec3 swing` nuevo (cabeza, cuerpo y sus dos contornos) los mueve: en el cuerpo es un corrimiento (m), en el pelo un giro chico alrededor del centro del casquete (`hair_pivot`), así el pelo no se mete en la cabeza. En el personaje reemplaza al viento de las plantas. El animador los mueve con resortes empujados por la aceleración, el giro y el rebote (pelo ≤ 6°, cordones ≤ 2,5 cm) y solo los manda cuando cambian. No cuesta lugares nuevos del búfer de instance uniforms (esas mallas ya tenían uno).
**Motivo:** biblia §7.7.5; el plan A.7 fija `Body/Head/Mesh` y una malla de pelo aparte costaría 3 llamadas.

### El celular: un hueso que se achica a nada
**Decisión:** pivote nuevo `Body/ShoulderR/ElbowR/Phone` (`CharacterModel.Bone.PHONE`): el celular (funda mostaza `#e09a34`, pantalla `#8fd0ff`, 46 triángulos) es parte de la malla con piel y va con ese hueso; guardado, el pivote tiene escala 0,001 (sus triángulos quedan en un punto). Cero llamadas nuevas; el personaje queda en 7.877 triángulos (tope 8.000). Los colores van en `LookPalette` (la pantalla no es cian: no se toca).

### Capturas: el personaje con semilla fija, en pausa mientras se espera en tiempo real
**Decisión:** `tools/screenshot_runner.gd` pone `CharacterAnimator.reseed(1234)` y `freeze_idle` (sin respirar, parpadear ni gestos sueltos). Como el mundo avanza un paso fijo por cuadro pero algunas esperas son en tiempo real (los avisos, el globo), mientras dura una de esas esperas el animador queda en pausa (`paused`) y el personaje no gira hacia la cámara: así cada corrida da la misma pose sin importar lo rápido que dibuje la máquina. Para 19 y 22 el ejecutor adelanta la animación hasta el punto alto del gesto (pulgar arriba, puño arriba) sin dibujar, y después espera en tiempo real lo cobrado que vuela. Capturas nuevas: **48** (puño arriba, feliz) y **49** (manos a la cabeza, preocupado), con `hold()` en su punto alto.
**Motivo:** plan, sección C y paso 11 ("`freeze_idle` y semilla fija").

### Lo que no se hizo
- "Respeta reducir movimiento cuando exista": el ajuste todavía no existe (RUTA Fase 2); estirar y aplastar está en un solo lugar (`SHAPE.x` en `_write`) para apagarlo cuando llegue.

### Prueba adaptada (misma intención)
- `tests/unit/test_character_controller.gd`, `test_the_head_turns_at_most_20_degrees_and_the_pupils_do_the_rest`: las constantes `GLANCE_DELAY`, `MAX_GLANCE` y `MAX_GAZE` se leen de `CharacterAnimator` (antes de `CharacterController`), porque la mirada pasó al animador. Comprueba lo mismo, con los mismos números.

### Pruebas nuevas
- `tests/unit/test_character_animator.gd` (16): una falla → preocupado y las manos subiendo en ≤ 0,2 s, en las sienes en su punto alto y mirando la impresora; cobrar a tiempo → feliz y el puño arriba, atrasado → se rasca sin festejo; subir de nivel → salto de más de 12 cm con los pies en el aire, se aplasta y se estira, sorpresa y después feliz; la misma semilla parpadea igual (y otra no), cada 2,4–5 s y unos 0,12 s; quieto 3 s sin objetivo → a 45° ± 20° de la cámara (y no antes de 2 s, ni con algo que mirar); caminar corta el gesto y no deja empezar otro; la rodilla se dobla más de 0,4 rad en el paso, los codos más de 0,9, y el pie de apoyo ni se hunde ni flota; quieto 30 s (con respiración y gestos sueltos) `HipL.rotation.x` sigue en 0; `freeze_idle` deja todo quieto; el celular sale solo con un mensaje, quieto y sin panel, delante de la cara y con la pantalla hacia los ojos, y se guarda; hablar alterna dos bocas 8 veces por segundo; cara concentrada al modelar cerca del escritorio; el pelo y los cordones se mecen al frenar (≤ 6°, el contorno igual) y se asientan; `hold()` congela el punto alto; las manos llegan a los puntos de los gestos (y si no alcanzan se estiran hacia ellos); los datos de los 12 gestos están bien formados y solo el salto mueve las piernas.
- `tests/integration/test_character_reactions.gd` (9): las señales de `Events` llegan al personaje en la escena principal (falla, nivel, cobro a tiempo y atrasado, partida nueva); el celular no sale con un panel abierto; tocarlo lo da vuelta y saluda; la boca se mueve con el globo; pulgar arriba si la impresora termina cerca y nada si está lejos; embalar junto al rincón hace el gesto y un botón que no se pudo lo hace encogerse; embalar desde lejos no; el animador conoce el escritorio, los cabezales, la cámara, si se modela y la hora.


## 2026-10-22 — Arte 2.0, paso 11, ronda de arreglos 1: código muerto, pulgar, celular y capturas

### Código muerto borrado (arregla un defecto que bloqueaba)
**Decisión:** se borraron `CharacterAnimator.gesture_time()` y `CharacterFace.is_blinking()`: nadie las llamaba (CLAUDE.md: "no quedan... código muerto"). `_gesture_pose` usa `CharacterGestures.ADDITIVE` en vez de repetir qué huesos se suman.

### Empujar contra una pared no es estar quieto
**Decisión:** `CharacterController.idle_time()` vuelve a 0 mientras el joystick empuja, aunque no avance. Antes contaba "no se movió": empujando una pared más de 2 s se giraba hacia la cámara (quedaba ~3° torcido respecto del joystick) y a los 8 s hacía gestos sueltos mientras el jugador seguía empujando. La mirada a lo cercano también espera a que suelte.

### Las duraciones de la biblia
**Decisión:** encogerse de hombros dura 0,7 s (antes 0,8) y embalar 0,6 s (antes 0,7), como dice la biblia §7.8; las poses clave se acortaron en proporción.

### El pulgar arriba es para el jugador
**Decisión:** si una impresora termina cerca y empieza el pulgar arriba, `RoomView` gira al personaje hacia la cámara (`face_camera()`, como al saludar) y él mira la impresora de reojo (cabeza y ojos). Con un panel abierto no se da vuelta: sigue mirando el objeto del panel. La mano va bien afuera del cuerpo (x 0,33) y el codo hacia abajo, así el pulgar queda hacia arriba.
**El pulgar del mitón:** apuntaba a lo largo de la mano (un bulto al costado del puño) y en el "pulgar arriba" no se veía. Ahora sale hacia adelante y un poco hacia abajo con la mano suelta (como una mano relajada) y un poco más grande (1,6 × 3 cm), así con el antebrazo hacia adelante queda hacia arriba. Mismos triángulos.
**Motivo:** nota de la revisión: en 19 se lo veía de espaldas con la mano junto a la cabeza y se leía "se rasca la cabeza" (en la biblia, la reacción a un pedido atrasado: lo contrario).

### El celular, con las dos manos delante del pecho
**Decisión:** el celular ya no va delante del mentón (de frente se leía "se tapa la boca" o "come algo"): lo sostiene con las dos manos a la altura del pecho, con la cabeza gacha, y la pantalla sigue mirando sus ojos (la prueba de siempre, sin cambiarla). De frente se lee "mira el celular" por la pose; de perfil y de 3/4 se ve la pantalla encendida.

### Manos a la cabeza que tocan el pelo
**Decisión:** las manos van a x ±0,218 (antes ±0,235) y un poco más abajo: se apoyan en los costados del pelo en vez de quedar al lado.

### Capturas: lo que ya pasó, termina
**Decisión:** `tools/screenshot_runner.gd` tiene `_settle_character()`: avanza 4 s el tiempo del personaje sin dibujar (más que la reacción más larga, preocupado 3,2 s). Se usa al final de `_wait_quiet()` (en el juego, mientras uno lee el globo o el aviso, la reacción termina; el retrato del HUD también cuenta en tiempo real), después de aceptar el primer pedido (antes de 16) y después de que la impresora termina en la primera venta (antes de 20). `_advance_character` avanza también al controlador (su giro), así el giro hacia la cámara del pulgar arriba no depende de lo rápido que dibuje la máquina. 13 muestra el celular en su punto alto (llegó el mensaje). Antes de 19 se espera un cuadro sin el panel (el personaje lo sabe en cada cuadro). `_pause_character(true)` dos veces seguidas ya no pierde el giro guardado.
**Motivo:** notas de la revisión: el celular de 13 seguía en 16 y 17 (de espaldas parecía rascarse la cabeza o atender una llamada), en 23 las manos seguían en la cabeza mientras el retrato ya estaba normal, y en 20 y 21 la cara feliz que quedaba se leía "dormido".
**Efecto en el presupuesto:** 36 vuelve a 18 llamadas y 6.267 primitivas de sombra (en el paso 11 eran 19 y 10.601 porque el personaje tenía el brazo levantado con el celular y entraba en la sombra de esa toma). Nada más cambia.

### Prueba adaptada (más estricta, misma intención)
- `tests/unit/test_character_animator.gd`, `test_a_failed_print_puts_the_hands_on_the_head_and_a_worried_face_quickly`: en el punto alto, cada mano a menos de `HAIR_RADII.x + 0,06` m (0,258) del centro del cráneo; antes 0,3. Sigue pidiendo "manos a la cabeza", ahora tocando el pelo (con la pose anterior no pasaba: 0,2583 m).

### Pruebas nuevas
- `test_character_animator.gd`: `test_pushing_against_a_wall_is_not_standing_idle` (11 s empujando la pared: sigue mirando hacia donde empuja, `idle_time()` en 0 y sin gestos sueltos; antes fallaba con ~2,7° y 10,9 s) y `test_the_reactions_last_what_the_art_bible_says` (largo de los 7 gestos de reacción según la biblia §7.8; antes fallaba con el encogerse y el embalar).
- `test_character_reactions.gd`: `test_the_thumbs_up_turns_to_the_player` (de espaldas a la cámara, la impresora termina y queda de frente) y `test_with_a_panel_open_the_thumbs_up_keeps_facing_the_printer`.


## 2026-10-22 — Arte 2.0, paso 11, ronda de arreglos 2: nada de memoria en el primer gesto

### La tabla de gestos se arma al crear el animador (arregla un defecto que bloqueaba)
**Decisión:** `CharacterGestures.prepare()` (público, no hace nada si ya está) arma la tabla de gestos de `DATA` y lo llama `CharacterAnimator._init`, que corre mientras se arma el cuarto. Las funciones que leen la tabla (`length_of`, `peak_of`, `drives`, `face_at`, `sample`) ya no la arman solas: suponen que está. `_build()` empieza desde arreglos vacíos (así armarla de nuevo da lo mismo). Además, el animador escribe al armarse los tres instance uniforms del personaje (`swing` en las cuatro mallas, `expression` y `gaze` en la cabeza) con lo que se ve al empezar: cada malla los guarda en un mapa y el primero que se escribe crea su lugar (728 bytes la primera vez).
**Motivo:** la biblia §7.7 ("nada de memoria en _process"), CLAUDE.md y la regla A.5 del plan. Antes la tabla se armaba con el primer gesto de la partida (casi siempre el celular cuando llega el primer mensaje, o la primera reacción), dentro de un cuadro: unos 26 KB y 1,5–2,3 ms de golpe en escritorio (la IK de todas las poses), probablemente un cuadro perdido en un teléfono de gama baja o en la web. Medido después del arreglo (sin pantalla, escritorio): armar la tabla tarda ~1,5–2 ms y ~25 KB una sola vez, al armar el cuarto, y la primera reacción de cada tipo suma 0 bytes en su primer cuadro y en sus 4 s siguientes.

### El empujón al frenar, solo al soltar el joystick
**Decisión:** el empujón hacia adelante al frenar en seco (`STOP_PITCH`) se da si pasa de correr (`RUNNING`) a parado (`STOPPED`) en menos de `STOP_WINDOW` (0,15 s) y el joystick **no** está empujado (`CharacterController.is_pushed()`, que también usa el controlador). Contra una pared no hay empujón: el cuerpo solo se endereza.
**Motivo:** nota de la revisión: chocando contra una pared a toda velocidad, el empujón sumaba inclinación (pico ~0,107 rad) y la biblia pide no inclinarse al chocar. Al medirlo apareció lo contrario también: con la condición de antes (de correr a parado en un solo cuadro) soltar el joystick nunca daba el empujón, porque frenar tarda ~5 cuadros (`deceleration_time` 0,08 s); solo podía darse al chocar. Ahora se asienta al soltar (lo que decía ESTILO y la biblia §7.7.1) y no al chocar. Al chocar sigue la inclinación que traía (0,12 a toda velocidad) y baja de 0,05 en ~4 cuadros, sin subir.

### Pasitos al girar con el tiempo del personaje
**Decisión:** los pasitos al girar en el lugar se mezclan con `dt` (el tiempo del personaje, que se detiene en pausa o con `hold()`) y la constante `SHUFFLE_RATE` (6 por segundo), como el resto del archivo.

### Estirarse en V y codos del celular más cerca del cuerpo
**Decisión:** en el punto alto de estirarse las manos van arriba y afuera (x ±0,40 y ±0,42, por encima de los hombros): de frente los brazos forman una V estirada en vez de apoyar las manos sobre el pelo (se leía "manos a la cabeza"). Al mirar el celular los codos apuntan más hacia abajo (polo (±0,35; −1; −0,25), antes (±1; −1; −0,3)): de frente y de espaldas quedan más pegados al cuerpo. La pantalla sigue mirando los ojos (prueba de siempre sin tocar).

### Captura nueva: 23a, la reacción a la falla
**Decisión:** `tools/screenshot_runner.gd` saca **23a_fallo_reaccion** justo cuando falla la pieza (antes de 23): las manos a la cabeza en su punto alto, el globo "¡Nooo! Un espagueti." y el retrato del HUD preocupado, con la cámara ya en el zoom de 23 (`snap_to_goal`). 23 queda como estaba (el panel de la falla, con el personaje ya tranquilo).
**Motivo:** nota de la revisión: desde la ronda 1, 23 ya no mostraba la reacción (con razón: en el juego termina mientras uno lee) y la reacción solo se veía aislada en 49; faltaba verla en contexto.

### Pruebas nuevas
- `tests/unit/test_character_animator.gd`, `test_the_first_reaction_of_a_game_needs_no_new_memory`: suelta la tabla de gestos (como al abrir el juego; otra prueba pudo haberla armado), arma un personaje y, para cada una de las 9 reacciones, la primera `react()` + `step()` suma 0 bytes de memoria estática, y también los 4 s que siguen (gesto, cara y mirada). Con la tabla armada en el primer gesto falla (25.600 bytes); sin escribir los instance uniforms al armarse, también (728).
- `test_character_animator.gd`, `test_a_sudden_stop_settles_but_a_wall_does_not_tip_the_body_forward`: soltar el joystick corriendo inclina un poco más hacia adelante en el cuadro en que para; contra la pared, la inclinación solo baja cuadro a cuadro y termina por debajo de 0,05. Falla con la condición de antes (al soltar no se asienta) y sin mirar el joystick (en la pared sube).

## 2026-10-22 — Arte 2.0, paso 12: la decoración del dormitorio (D6, se informa)

### La decoración vive en Room/Decor y no se toca
**Decisión:** `RoomDecor` (`game/world/decor/room_decor.gd`) es el nodo `Room/Decor`: lo sólido del piso (`DecorItems`: cama con cobija de tigre, puf con control y zapatillas, librero, costilla de Adán, basurero de impresiones fallidas, cajas de filamento), lo de las paredes y estantes (`DecorWall`: tres pósters, guirnalda de 14 focos, bufanda, reloj, calendario, diploma, corcho, foto familiar, plano, guitarra, repisa de las primeras impresiones, banderín, enchufe de F5, alféizar) y lo plano (tapete andino, felpudo, cable del escritorio, un barquito fallido). Ningún `WorldInteractable` sale de ahí y ningún nodo se llama `Printer*`, `Furniture*` ni `FreeSlot*`. La baldosa de la impresora del piso (`PaverModel`) sigue como `Decor/Paver`.
**Motivo:** biblia §5.4 y §8.8 y los contratos A.7 del plan (zonas de toque intactas).

### Mallas y presupuesto
**Decisión:** con el material del kit, `FloorN` (sólido, con sombra: 2 llamadas), `WallN` (pared, estantes y lo que cambia con el nivel, sin sombra: 1), `Flat` (≤ 4 mm, sin sombra: 1), `Paver` (1) y `Dust` (MultiMesh, solo de día: 1) = **6 llamadas** de día; de noche el polvo se esconde y sus luces van en el MultiMesh de los halos. Medido: 7.745 / 8.333 / 8.643 triángulos en los niveles 1 / 3 / 5 (biblia: ≤ 7 llamadas y ≤ 9.000; la prueba de presupuesto lo exige en los tres niveles). Lo redondo con detalle 0,6 (biblia §5.1) y sin biseles de menos de 4 mm, salvo el reloj y el puf (detalle 1,0: grandes y redondos).
**Motivo:** biblia §5.2.

### El tope de llamadas del cuarto inicial sube de 37 a 41
**Decisión:** `START_MAX_DRAW_CALLS` pasa de 37 a 41 (medido 38 + 10 %). Los demás topes no cambian: materiales 14 ≤ 15, mallas con sombra 9 ≤ 9, transparentes 9 ≤ 9 (el polvo suma una), y en el cuarto lleno todo queda bajo los topes del paso 10 (133 llamadas ≤ 141).
**Motivo:** la regla A.10 dice "nunca por encima del tope anterior", pero la decoración que pide la biblia (≤ 7 llamadas) no cabía en 37: el informe del paso 10 ya lo había avisado. La meta final de la biblia (≤ 70) sigue lejos.

### Lo que está en el piso: su rectángulo entero es obstáculo y queda lejos de los lugares
**Decisión:** cada cosa del piso tiene en `RoomDecor.FLOOR` el rectángulo que ocupa **entero** (con las hojas de la planta, la cobija que cae, la lámpara de la cabecera) y su alto. Ese rectángulo, agrandado 5 cm como los muebles, se registra en la grilla **antes** de `grid.build()` (así también deja su mancha en `FloorAO`). Está a ≥ 0,15 m de la huella de todos los lugares de muebles (≥ 0,30 m si mide más de 0,6 m), fuera del paso de la puerta y a ≥ 0,5 m de los puntos que usan las pruebas y las capturas. La huella de un lugar es la de todo lo que puede ir ahí (cada mueble de la tienda, con su pared, y su marca; en el lugar 0, el escritorio que no se vende).
**Motivo:** biblia §5.4 y §8.8. Para cumplirlo con las medidas reales de los muebles, algunas cosas se corrieron de lo que dice la biblia:
- Costilla de Adán: centro (−2,70; −2,40) y no (−2,70; −2,25): a −2,25 quedaba a 0,20 m de la huella del lugar 0 (mide 1,35 m: pide 0,30).
- Basurero: centro (−2,80; −0,25), Ø 0,27 (biblia (−2,80; −0,30), Ø 0,30): el hueco entre los lugares 0 y 1 mide 0,597 m; con 0,30 de ancho no quedan 0,15 m a cada lado.
- Cajas de filamento (F4): x 2,755…2,995 (biblia 2,75…2,97): a 2,75 quedaban a 0,147 m del lugar 4.
- Corcho: z −2,55…−2,05 (biblia −2,85…−2,00): el librero del rincón (x −2,95…−2,45 contra la pared del fondo) tapaba la mitad.
- Guitarra: centro z −0,22 (biblia −0,25) y 0,32 m de ancho: así no toca los pliegues de la cortina (z ≥ −0,40) ni el interruptor.
- Repisa de las primeras impresiones: 0,14 m de fondo (biblia 0,16): con 0,16 chocaba con los postes de la estantería metálica si va en el lugar 1.
- Lugares que la biblia no da: el billete enmarcado (nivel 3+) sobre el librero (x −2,70, y 2,15), la placa del taller (nivel 5+) sobre el diploma (x 2,82, y 1,95) y un enchufe nuevo bajo el interruptor (z 0,0, y 0,30) para el cable del escritorio.

### Crece con el nivel sin cambiar la grilla y sin armar nada al subir
**Decisión:** tres niveles de decoración (`RoomDecor.TIER_LEVELS` = niveles 1, 3 y 5 del juego: "recién empiezo", "ya vendo", "taller"). Cambian la repisa (2 piezas → 5: el gatito que brilla, un dragón y un jarrón), el corcho (2 notas → 5 notas y 3 fotos), el billete enmarcado, la placa, la tira LED, lo que hay en el basurero (medio lleno → desbordado) y las cajas de filamento de F4 (1 → 2 → 4). Las cajas y el basurero están en el piso, pero siempre dentro de su mismo rectángulo: los obstáculos son iguales en todos los niveles (la prueba lo exige). Las tres variantes de `FloorN` y `WallN` se arman y se ponen al armar el cuarto: lo que no cambia se arma una vez y se copia (`KitMesh.copy()`, nuevo); subir de nivel (`Events.level_up`, y al cargar una partida) solo cambia cuál se ve. Medido: cambiar de nivel pide 0 bytes y no arma ninguna malla. Armar las tres variantes de piso y pared la primera vez tarda ~19 ms sin pantalla (paso 15: medirlo en el teléfono). Los niveles son números de presentación (como los de `DayCycle`), no de balance: no cambian nada del juego.
**Motivo:** biblia §8.8 ("la decoración crece con el nivel, solo con cosas de pared y estante, para que la grilla de caminar nunca cambie") y la regla de no armar nada dentro de un cuadro (la subida de nivel llega dentro del `_process` de `Game`). El plan pedía "solo pared y estante"; el basurero y las cajas también crecen porque no tocan la grilla.

### La tira LED solo existe en el taller
**Decisión:** `DayCycle.led_strip_on` (nuevo): la luz del sombreador de la tira LED solo alumbra si la tira está puesta (`RoomDecor.has_led_strip()`, nivel 5+). RoomView lo actualiza al subir de nivel y al cargar.
**Motivo:** biblia §8.8 (nivel 5+: "tira LED encendida de noche"). De día no cambia nada (factor 0 en la mañana); el paso 13 la usa de noche.

### La cama tapa el parche de sol y lleva la lámpara de cc_pl2
**Decisión:** `cc_occ_b` = `RoomDecor.BED_BOX` (el colchón con la cobija: x 1,95…2,92, y 0…0,5, z −1,85…0,17), expuesto como `RoomView.bed_occluder`. `cc_pl2` ("bed_lamp") sale del foco de la lámpara de hongo impresa de la cabecera, `DecorItems.BED_LAMP_BULB` = (2,45; 0,85; −1,80) (biblia §6.2).
**Motivo:** biblia §6.3. En la mañana el parche no llega a la cama (cae en x −1,4…−0,2); en la tarde dorada (paso 13) sí.

### Las luces de noche de la decoración van en el MultiMesh de los halos
**Decisión:** `HaloField.add_glow(at, size, color)` (nuevo; `add()` lo usa): un halo en cualquier plano. La decoración pone 17 (los 14 focos de la guirnalda sobre la pared, el gatito de la repisa, el celular de la cabecera y la lámpara de la cama) **después** de los de las impresoras, apagados los de un nivel que no se ve. Los focos, el gatito, el celular, la pantalla de la lámpara y la tira LED tienen además luz propia de noche (`night_glow`). De día no se ve nada de esto.
**Motivo:** biblia §5.3 (un MultiMesh para todos los halos: 0 llamadas más). Los valores de noche los calibra el paso 13.

### Polvo del haz de la ventana
**Decisión:** `DustField` (`game/world/look/dust_field.gd`, `MultiMesh` de 40 cuadritos, 1 llamada, 80 triángulos) con `dust.gdshader`: cada mota trae en `INSTANCE_CUSTOM` dónde está dentro del haz (u, v en el hueco y t a lo largo de la luz) y su fase, salidos de una semilla (`DustField.motes(seed)`, puro; `RoomDecor.DUST_SEED`). El sombreador las pone en la dirección de la ventana de esa hora (`cc_window_dir`, como el haz), las mueve con `cc_anim_time`, las hace mirar a la cámara y suma la luz de la ventana. `DayCycle` le pone la fuerza del factor "haz y polvo" de la hora; en 0 el nodo se esconde.
**Motivo:** biblia §8.9. Siguen al haz cuando cambie la hora (paso 13) sin moverlas por código. "Solo nivel Alto" llega con los niveles de calidad (paso 15).

### Balanceo de lo que crece de una maceta
**Decisión:** `KitMesh.rooted(peso, abajo, largo)` (nuevo, como `hanging` pero al revés): el balanceo es 0 en la maceta y crece hacia arriba. Lo usan los tallos y las hojas de la costilla de Adán; las guías del potus cuelgan (`hanging`).
**Motivo:** con un balanceo parejo las hojas se despegaban de los tallos y los tallos de la tierra.

### Prueba adaptada (misma intención)
- `tests/integration/test_printer_families.gd`, `test_each_printer_has_a_night_halo_of_its_state_color`: "un halo por impresora" cuenta ahora `2 + DecorWall.night_lights().size()` (los de la decoración van detrás, en el mismo MultiMesh). Lo demás (colores por estado en los halos 0 y 1, dónde queda el de la impresora del piso, solo de noche) igual.
- `tests/integration/test_scene_budget.gd`: tope de llamadas del cuarto inicial 37 → 41 (ver arriba) y pruebas nuevas de la decoración.

### Pruebas nuevas
- `tests/integration/test_room_decor.gd` (9): cada cosa del piso, armada sola en cada nivel, cabe en su rectángulo, no se mete bajo el piso ni pasa de su alto, y su rectángulo queda a ≥ 0,15 m (≥ 0,30 m si mide más de 0,6 m) de la huella de cada lugar de muebles; deja libre el paso de la puerta y queda a ≥ 0,5 m de los puntos de las pruebas y las capturas (y de la caminata de 04–05), que siguen libres en la grilla; es obstáculo registrado antes de armar la grilla (el camino de A* no la atraviesa); la decoración no suma nada que se toque (10 objetos en una partida nueva, ninguno donde está la decoración; tocar la cama o el puf no abre nada) y no tiene nodos `Printer*`, `Furniture*` ni `FreeSlot*`; lo plano mide ≤ 4 mm y el cable del escritorio no pisa ningún lugar libre y llega a la pared; subir a los niveles 3 y 5 no cambia los obstáculos ni los 5 lugares libres, muestra solo la variante de su nivel, con más cosas cada vez, y enciende la tira LED en el taller; cambiar de nivel no pide memoria ni arma mallas; el polvo es el mismo con la misma semilla (y otro con otra), está dentro del haz, se ve de mañana y se esconde sin luz; la cama es la caja `cc_occ_b` y `cc_pl2` está en su lámpara.
- `tests/integration/test_scene_budget.gd`, `test_the_decor_fits_its_budget_at_every_level` y dos asserts en el cuarto inicial: la decoración ≤ 7 llamadas y ≤ 9.000 triángulos en los tres niveles.
- `tests/unit/test_kit_mesh.gd`: `test_what_grows_from_a_pot_sways_more_the_higher_it_is` y `test_a_copy_goes_on_by_itself`.
- `tests/unit/test_day_cycle.gd`, `test_the_dust_of_the_window_shaft_follows_the_hour`.
- `tests/integration/test_look_shaders.gd`: `dust.gdshader` compila y expone sus parámetros.

## 2026-10-22 — Arte 2.0, paso 13: el día y la noche completos (D2: no; D8: solo lo visual)

### Seis momentos mezclados con smoothstep
**Decisión:** `DayCycle` (`game/world/look/day_cycle.gd`) tiene los seis momentos de la biblia §6.2 (`MOMENTS`: alba, mañana, mediodía, tarde dorada, atardecer y noche) con sus valores exactos (la mañana conserva la ventana girada 10° del paso 5) y sus horas de §6.1 (`KEYS`: la mañana de 07:00 a 10:30, la tarde dorada de 16:30 a 18:00 y la noche de 20:15 a 05:00 se mantienen; el alba a las 05:45, el mediodía a las 12:30 y el atardecer a las 19:15 son un instante). Entre dos claves se mezcla con `smoothstep`, así la luz es una función continua de la hora (`sample(hora)`, puro). Lo que la biblia no dice y se decidió aquí: `cc_night` (cuánta noche es, con lo que se encienden los focos, las ampolletas, las pantallas de noche y los halos) es el factor de la guirnalda de cada momento (0,3 / 0 / 0 / 0,2 / 0,6 / 1), porque la guirnalda es justamente luz de noche; lo que se ve por la ventana mezcla día, tarde y noche (alba 0,35/0,35/0,3; atardecer 0/0,45/0,55); y el resplandor del fondo del alba y del atardecer es el de la tarde (`#5a3d6a`), el único de los tres de §4.1 con su tono rosado.
**Motivo:** biblia §6 y plan, paso 13. Son números de presentación (no de balance): no cambian nada del juego (D8: solo lo visual).

### El reloj mueve la luz mezclándose; al cargar, de una vez
**Decisión:** `RoomView` le pasa a `DayCycle` cada minuto de juego (`Events.time_changed` → `go_to_hour`) y la luz llega a esa hora mezclándose en `BLEND_SECONDS` = 2 s reales, avanzada en cada cuadro por `RoomView.step()` (un minuto de juego dura hoy 2,5 s: cada paso termina antes del siguiente y la luz avanza pareja). Un salto grande del reloj se ve como un lapso acelerado de 2 s. Si la hora de destino se ve igual que la de ahora (en medio de un momento), no se mezcla nada; si el reloj vuelve atrás, va de una vez. Al cargar una partida (`Events.game_loaded`) y al armar el cuarto, `set_hour()` pone la hora sin mezcla; las capturas lo usan igual. Mezclar no pide memoria: los momentos se convierten una vez en objetos `DayCycle.Light` y la mezcla se escribe sobre el mismo objeto (una prueba lo mide: 0 bytes).
**Motivo:** biblia §6.4 ("transiciones siempre mezcladas, nunca de golpe; al cargar una partida, la hora sin mezcla") y §13 (nada de memoria en `_process`). Con solo el minuto, la luz daría un saltito de hasta 3 % cada 2,5 s en los cambios de momento.

### D2: sin luces del motor de noche
**Decisión:** el dueño no aprobó D2. La lámpara del escritorio, el monitor, la lámpara de la cama, el LED de la impresora del piso y la tira LED siguen siendo luces del sombreador (`cc_pl0..3`, `cc_strip`), que alumbran también al personaje y a las impresoras. La prueba de presupuesto sigue exigiendo 1 sol con sombra y 0 omni / 0 spot, ahora también de noche.
**Motivo:** CLAUDE.md ("una luz direccional más luz ambiental") y la opción por defecto del plan.

### Halos del escritorio y halos de las impresoras más fuertes
**Decisión:** el escritorio deja dos halos de noche en el `MultiMesh` de los halos (`ComputerDeskModel.night_lights()`): la mancha cálida de la lámpara sobre la mesa (`#ffb35c`) y el resplandor alrededor de la pantalla del monitor (`#6fd3ff`), los colores de halo de la biblia §4.7. Van después de los de las impresoras y antes de los de la decoración. Para que los estados de las impresoras se lean de noche con el zoom lejos (captura 43), `HaloField.INTENSITY` sube de 2,2 a 3,0 y `SPREAD` de 1,5 a 1,9; los colores de los halos de la decoración y del escritorio bajan en la misma proporción (×0,73), así se ven igual que antes.
**Motivo:** biblia §4.7, §6.4 ("el taller lleno de noche se lee por las pantallas, LEDs, halos...") y §9.2. Con la noche real, en la captura 43 los halos de 2,2 apenas se veían bajo las impresoras de las estanterías.

### La guirnalda parpadea suave
**Decisión:** los focos de la guirnalda y sus halos parpadean entre 62 % y 100 %, cada uno a su ritmo según dónde está a lo largo de la pared (`cc_twinkle(x)` en `look_globals.gdshaderinc`, con `cc_anim_time`). En las mallas del kit lo marca un balanceo negativo (`KitMesh.night_glow(hex, energía, true)` → `UV.y = KitMesh.TWINKLE`, que no mueve nada); en el `MultiMesh` de los halos, el alfa de la copia (`HaloField.add_glow(..., twinkle = true)`). Foco y halo usan la misma cuenta, así parpadean juntos. Las capturas congelan `cc_anim_time`: salen siempre iguales.
**Motivo:** biblia §8.9 ("guirnalda que parpadea suave de noche"), sin llamadas ni materiales nuevos.

### El borde de la base apenas brilla de noche, con su azul
**Decisión:** el borde de primera capa (brim) tiene luz propia solo de noche (`RoomShell.BRIM_NIGHT_GLOW` = 0,45) de su mismo azul `#4a6f9e`, no cian.
**Motivo:** biblia §4.1 y §4.8 ("apenas brilla de noche"). La luz propia del kit es del color del vértice; un cian aparte pediría otro atributo o material. Con 0,45 suma más o menos lo mismo que `#38d6ff` × 0,25.

### El atardecer queda como dice la biblia, aunque es lo más oscuro del día
**Decisión:** no se tocan los valores del atardecer. Con la cuenta del sombreador, un gris medio del piso al sol da 72/255 de noche (la regla de §6.4 pide ≥ 70) y 49/255 en el atardecer (19:15), el momento más oscuro; la baldosa del piso de verdad da 77/255 ahí y más de 100 de noche. La prueba nueva exige la regla de la noche y, además, que la baldosa nunca baje de 70/255 a ninguna hora.
**Motivo:** el atardecer es un momento corto de transición, con las lámparas ya encendidas (0,75); subirlo cambiaría el carácter de la tabla de la biblia. Si al dueño le parece oscuro en el teléfono, la palanca es la energía del ambiente del atardecer (0,52).

### Capturas de las horas
**Decisión:** el ejecutor de capturas tiene `_advance_to_hour(h)`: adelanta la partida de verdad hasta la próxima vez que el reloj marque esa hora (en el camino llegan mensajes) y pone la luz de una vez con `set_hour`. Capturas nuevas (grupos `all` y `art`): `42_tarde_sin_hud` y `41_tarde_con_hud` (17:15), `35_noche_sin_hud` y `36b_noche` (22:00, con la interfaz y el personaje junto al escritorio) y `44_alba_sin_hud` (05:45 del día siguiente); `43_taller_lleno_noche` es el cuarto lleno de 37 guardado a las 22:00, en el nivel del taller (con la tira LED) y con impresoras imprimiendo, listas, con falla y sin trabajo, cargado como una partida (prueba de paso que al cargar la hora va sin mezcla). Las capturas del ciclo de pedidos (01–24) llegan hasta las 10:27: siguen en la mañana y no cambian.
**Motivo:** plan, sección C y paso 13.

### Pruebas adaptadas (misma intención)
- `tests/unit/test_day_cycle.gd`: `test_the_sun_of_the_room_takes_the_morning` y `test_the_dust_of_the_window_shaft_follows_the_hour` llaman `set_hour(8.0)` en vez de `apply_hour(8.0)` (se renombró: ahora existe también `go_to_hour`, que mezcla). Lo que comprueban es igual; la segunda además comprueba que de noche el polvo se esconde. `test_the_morning_matches_the_art_bible` además comprueba el resplandor del fondo y lo que se ve por la ventana.
- `tests/integration/test_printer_families.gd`, `test_each_printer_has_a_night_halo_of_its_state_color`: la cuenta de halos suma los dos del escritorio (`2 + ComputerDeskModel.night_lights().size() + DecorWall.night_lights().size()`). Los colores por estado (halos 0 y 1), su lugar y "solo de noche" siguen igual.

### Pruebas nuevas
- `tests/unit/test_day_cycle.gd` (8 nuevas): los otros cinco momentos coinciden con la tabla de la biblia (sol, ambiente, ventana, relleno y refuerzo, los siete factores, haz, fondo y resplandor) en sus horas; la luz no salta de un minuto al siguiente en todo el día (lo más: 0,033 por canal y 1,5° de giro) y las 24:00 son la medianoche; la mezcla es `smoothstep`; la lámpara del escritorio está en 0 a las 10:00 y en 1 a las 22:00; el piso de noche (la cuenta del sombreador) da ≥ 70/255 con un gris medio y la baldosa nunca baja de eso; lo que se ve por la ventana, el fondo y el haz siguen al momento; el reloj mezcla la luz (sin saltos, ni en un salto grande), en medio de un momento no mezcla, y al cargar o si el reloj vuelve atrás va de una vez; mezclar no pide memoria.
- `tests/integration/test_day_night.gd` (5): una partida guardada a las 22:00 se ve de noche al cargar, sin mezcla (halos, sin polvo, la luna, la noche por la ventana) y una nueva vuelve a la mañana de una vez; el reloj del juego mueve la luz mezclándose hasta llegar a su hora; la mancha de la lámpara cae sobre la mesa bajo la ampolleta y el resplandor del monitor queda delante de la pantalla, mirando hacia donde mira ella; solo los focos de la guirnalda parpadean (un halo por foco, y en la malla de la pared solo los focos tienen la marca, como luz de noche); el borde de la base tiene luz propia solo de noche.
- `tests/integration/test_scene_budget.gd`, `test_the_night_fits_the_same_budget`: el cuarto inicial y el lleno a las 22:00 caben en los mismos topes (medido: 38 y 133 llamadas, como de día: los halos suman una y el polvo se apaga), con un solo sol y nada sin medir.
- `tests/unit/test_kit_mesh.gd`: el foco que parpadea lleva la marca y `paint()` la quita.

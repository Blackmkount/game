# Guía de estilo visual

Esta guía mantiene el juego **coherente y consistente** de principio a fin. Toda escena, modelo, pantalla o icono nuevo debe seguirla. Si algo nuevo no encaja aquí, se discute y se actualiza esta guía antes de hacerlo.

**Referencia:** `docs/referencias/taller_final.webp`, la imagen que entregó el dueño. Muestra cómo puede verse la habitación al final del juego, llena de impresoras, muebles y carretes. El juego empieza con la misma habitación casi vacía.

## 1. Idea general

> **En transición a Arte 2.0 ("Mundo Impreso").** El dueño aprobó dejar el pixel art (2026-10-22, ver `docs/DECISIONES.md`). Desde el paso 2 el mundo ya se dibuja a resolución alta y con bordes suavizados (sección "Render"); desde el paso 3 usa el kit de materiales nuevo, sin contorno ni texturas pixel art (secciones "Luz", "Materiales" y "Paleta"); desde el paso 4 tiene el kit de formas (`KitMesh`) y las manchas de oclusión del piso (secciones "Luz" y "Modelos"); desde el paso 5 el cuarto es una maqueta impresa con la ventana de verdad y las marcas en esquinas (secciones "Luz", "Paleta" e "Interacción"); desde el paso 6 la impresora del piso (Cubo Uno) es del kit, sobre su baldosa de concreto, y la pieza, el carrete y los fallos se ven como en la biblia (secciones "Materiales" y "Modelos"); desde el paso 7 el escritorio, el rincón de despacho y los paquetes también son del kit (secciones "Luz" y "Modelos"); desde el paso 8 las siete familias de impresoras son del kit, todas muestran la pieza que crece y su falla, y de noche cada una tiene un halo del color de su estado (secciones "Paleta" y "Modelos"); desde el paso 9 los seis muebles que se compran son del kit, la estantería metálica mide 2,40 m con 0,74 m libres por piso, y la repisa y el tablero se cuelgan de la pared (o van sobre su pie donde no hay pared) (sección "Modelos"); desde el paso 10 el personaje es el nuevo: 1,40 m, una malla con piel, la cara pintada con 8 expresiones, el pelo en una sola superficie y un contorno fino propio (secciones "Contorno", "Superficies" y "Modelos"). El resto de esta guía se reescribe con la biblia de arte al terminar los 16 pasos. Mientras tanto, lo que aquí dice "pixel art" describe los modelos de cajas que todavía no se cambiaron.

**Pixel art isométrico cálido, con interfaz oscura de bordes cian.**

- El mundo es 3D, armado con formas básicas (por ahora las cajas de antes) y se dibuja a **resolución alta con bordes suavizados**, sin contorno. Se puede animar, mover y ampliar como 3D.
- La interfaz se dibuja a resolución completa: texto nítido sobre paneles azul marino con bordes y brillos cian.
- Ambiente: cálido y acogedor adentro (madera, luz de tarde), frío y oscuro afuera (fondo azul marino).

## 2. Mundo 3D

### Render
- La escena va dentro de `Main/WorldView` (`WorldViewport`, `game/world/world_viewport.gd`): se dibuja con el ancho físico de la pantalla hasta un tope de 1.080 px, con MSAA 4× y filtro lineal. En un teléfono de 1.080 px, un píxel del mundo es un píxel de la pantalla.
- Cámara ortográfica (`CameraRig`), inclinada −30° y girada 45°: la vista isométrica clásica 2:1. Su tamaño base se adapta a pantallas más altas (`RoomView._fitted_camera_size`).
- **Sigue al personaje** y tiene tres niveles de zoom: lejos (0,68×, entra todo el cuarto), normal (1×) y cerca (2×).
- Sin ajuste a píxeles: la cámara y el personaje se mueven sin redondeo. Ve de 11 a 30 m de profundidad (`CameraRig.NEAR` / `FAR`), lo justo para el cuarto, así la sombra del sol es más fina.
- Con zoom normal y 1.080 px de ancho, un píxel equivale a unos **6 mm** del mundo (`CameraRig.meters_per_pixel()`). Lo menor a 1 cm no se modela.

### Luz
- **Modelo de color: lo que dice el hex es lo que se ve.** Todo se pinta e ilumina en el espacio de la pantalla: un color bajo luz neutra 1,0 se ve tal cual. `ColorProbe` mide al arrancar cómo escribe el motor cada pasada y la captura `00_calibracion` lo comprueba (ver `docs/DECISIONES.md`, paso 3).
- **Una sola luz direccional del motor** (el sol, con sombra), orientada por `DayCycle` según la hora (por ahora solo la mañana: `#fff0dc` × 0,48, entrando por la ventana). Ambiente, relleno desde el lado de la cámara, lámpara, monitor, LED de la impresora, tira LED y el parche de sol de la ventana (con las rejas) los calcula el sombreador del mundo con globales (`[shader_globals]` de `project.godot`): cero luces extra, cero llamadas extra. Tonemap lineal; ambiente, reflejos, glow y SSAO del motor apagados.
- Sombras **suaves**: filtro de calidad 2 y mapa de 2.048 en `project.godot`, también en móvil.
- Sombra **ortogonal** de una sola pieza (`SHADOW_ORTHOGONAL`; con la cámara ortográfica cubre de `near` a `far` de la cámara): con la cámara en movimiento no tiembla y cuesta menos que el modo por defecto.
- El cuarto (piso, paredes, ventana, puerta) no proyecta sombra: la luz general "pasa" por arriba y la ventana se lee por el parche de sol y un haz de luz suave. Las medidas del hueco, las rejas, el travesaño, el parante y el adorno de sol están en `WindowSpec`: de ahí salen la geometría y las rayas del parche. En la mañana la luz de la ventana tiene la altura del sol y gira 10° hacia la pared de la ventana, así el parche cruza la impresora del piso; el tablero del escritorio y el personaje lo tapan. La lámpara del escritorio y el brillo del monitor salen de los marcadores del escritorio (`LampBulb`, `ScreenGlow`).
- Pantallas y marcas brillan con su propio color. Las luces de las cosas (un LED, un interior iluminado) son luz propia del material.
- **Oclusión** (siempre teñida hacia índigo, nunca gris): manchas suaves en el piso bajo cada obstáculo (muebles, impresoras, el rincón; `FloorAO`, una textura de 96 × 96 pintada una vez por distribución), uniones piso-pared y rincón en el sombreador, y en las mallas del kit una sombra de contacto horneada (−35 % donde tocan, −25 % en las caras de abajo).

### Materiales
Siempre se usan los de `WorldPalette` (`game/world/look/world_palette.gd`), sobre los sombreadores del kit (`game/world/look/`). Así se reutilizan los materiales y el estilo no se rompe:

| Función | Para qué |
|---|---|
| `kit()` | Las mallas del kit: color, superficie, capas y luz propia en los vértices (desde el paso 4) |
| `solid(hex)` | Plástico impreso: la pieza, la bandeja, el filamento (capas de 1 cm) |
| `printing(hex)` | La pieza mientras se imprime, con la capa caliente naranja arriba |
| `paint(hex, superficie, brillo)` | Lo que no fue impreso: pintura, madera, metal, tela, PEI... |
| `glow(hex, estado)` | Pantallas dibujadas en el sombreador (`crt_screen`, `crt_modeling`, `printer_display*`) y la vista de la ventana; sin estado, un color con luz propia |
| `glow_transparent(hex, alfa)` | Marcas del piso (lugares libres, cercanía, destino); laten en el sombreador |
| `halo(hex)` | Halos de luz que suman (lámparas, pantallas) |

- Un "instance uniform" le cuesta a cada instancia 16 lugares de un búfer de 1.024. Los usan la pieza que se imprime y el personaje: `preview_light` (cuerpo y cabeza) y `px_m_override` (contornos) para las vistas 3D, y `expression` y `gaze` (la cara). Son 4 mallas por personaje y hay tres (el cuarto, la tarjeta del HUD y el perfil): 192 lugares.

### Contorno
- **El mundo no lleva contorno.** Las siluetas salen del valor (fondos claros, objetos más oscuros), del borde de luz, de los biseles y de la oclusión.
- **El personaje sí:** un contorno fino de 1,5 píxeles en cualquier zoom (casco por las normales, `outline_character.gdshader`), tinta índigo `#1a1830` y café oscuro `#2e180c` en el pelo. Lo dibuja una malla aparte que comparte la del personaje y no da sombra.

### Paleta del mundo

La paleta completa es la de la biblia de arte §4, en `LookPalette` (`game/world/look/look_palette.gd`); todo color nuevo sale de ahí. Lo principal hoy:

| Uso | Color |
|---|---|
| Fondo exterior | degradado `#26335c` → `#141b2d` (mañana) |
| Piso de baldosa | `#e8c49c` / `#e2bb91`, junta clara `#f2e2cb` |
| Paredes | fondo crema `#f2dcbc`, ventana verde salvia `#bfd8c2`; zócalos, marco de la puerta y canaleta `#f4ede2` |
| Base impresa y cortes de pared | `#56689a` (capas de 2,4 cm y 1,2 cm), borde de primera capa `#4a6f9e` |
| Ventana | aluminio `#dfe4ea`, rejas `#2a2e3a`, alféizar `#efe7da`, cortina `#e2a93b` / `#c98f2c` |
| Puerta | madera `#a8693a`, tableros `#b77a47`, manija `#e0b44a` |
| Madera de muebles | clara `#d9a066`, media `#b97a48`, oscura `#7a4b2e` |
| Metal | oscuro `#2b2f3a`, medio `#5a6274` |
| Computador viejo | beige `#e6dcc4` / `#c9bb9a` |
| Acentos de impresoras | azul `#3f86e0`, verde `#4cbf5a`, morado `#9b5de5`, naranja `#f28c28` |
| Cuerpos de impresoras | Cubo Uno `#2c2f3d`; Rayo y Prisma blanco `#eceef2`; Bóveda grafito `#2c2d36`; Titán grafito `#34363f`; Gota base `#2b2f3a` y tapa ámbar `#f28c28` al 55 % |
| Luz de adentro (cerradas, imprimiendo) | Bóveda `#ffd58a`, Titán `#fff1d6` |
| Estado de noche (halo y luz de adentro) | imprimiendo cálido `#ffb35c`, lista verde `#4cbf5a`, falla rojo `#e0453a` |
| Marcas de lugar libre | cian `#38d6ff` |
| Cama de impresión | PEI dorado `#c99a4e` |
| Cinta de embalar | `#d8b97a` |
| Pieza fallida | gris oscuro `#3b3b45` |
| Personaje | piel `#e9b48e`, pelo `#5c341d`, buzo gris carbón `#3e4250`, jeans `#3d5c96` |
| Filamentos | los 9 colores de `config.filament_colors` |

### Superficies
- No hay archivos de imagen: las superficies las dibuja el sombreador del kit (biblia §3.3): lisa, baldosa (junta, variación por baldosa y bisel que atrapa la luz), madera (tablas y veta), pintura, tela, cartón, metal cepillado y PEI dorado. Lo que mide menos de un píxel se apaga solo (nunca centellea).
- Lo impreso muestra sus **capas** (la pieza, la bandeja, el filamento): crestas, bandas claras y surcos, que se apagan cuando una capa mide menos de 1,3 píxeles. Las capas siguen el "arriba" del objeto (su eje Y), no el del mundo: en un carrete acostado dibujan los surcos del bobinado alrededor de su eje, y una pieza despegada muestra sus capas torcidas.
- El personaje tiene dos superficies propias: **piel** (en la de la cabeza se pinta la cara) y **pelo** (lleva el contorno café). No usa superficies con dibujo del mundo (tela, madera): se moverían sobre él al caminar.
- En pantallas y ventanas se usa `PropBuilder.quad` (un plano), no una caja.
- Pantallas que cambian con el estado: el monitor del computador muestra un cubo de alambre cian mientras modela (`crt_modeling`), y la pantalla de la impresora tiene una barra cian que avanza al imprimir, un ✓ verde al terminar y un "!" rojo al fallar (`printer_display_busy`, `_done` y `_error`). Cada estado es un material compartido: se cambia cuál usa cada objeto, nunca el material en sí.

### Modelos
- Formas básicas a **escala real**: una impresora tipo Ender mide unos 0,45 m y una mesa 0,75 m de alto. El frente mira hacia **+Z** y la base queda en y = 0.
- **Kit de formas** (`KitMesh`, `game/world/look/kit_mesh.gd`): los modelos nuevos son **una malla por objeto** con el material `WorldPalette.kit()` (color, superficie, capas y luz propia en los vértices), puesta con `PropBuilder.kit`. Formas: caja con bisel (las aristas atrapan la luz), cilindro con canto, torno, forma redonda, cápsula, tubo por una curva, aro, disco, rectángulo y triángulo. `detail` baja los lados de lo redondo en lo que se repite; cada malla se arma una vez (`KitMesh.cached`, con una clave que diga modelo, variante, detalle y color). Van aparte solo las piezas que se mueven o cambian de material.
- **Las siete familias se distinguen por la silueta** antes que por el color (`PrinterModel`; cada familia en `game/world/props/printers/`). Todas tienen `Body` (una malla del kit), `Display` y los marcadores `PieceAnchor`, `TrayAnchor` y `BedLight`; miden 0,72 m o menos con su carrete y caben en 0,6 × 0,55 m. En el piso van con detalle 1,0 (≤ 2.400 triángulos, ≤ 9 llamadas); en un mueble con detalle 0,6 (≤ 1.200 triángulos, ≤ 6 llamadas): sin biseles chicos, carretes con tapas simples y **solo `Body` da sombra**.
  - **Rayo Mini** ("la compacta", ×0,82): blanca, de voladizo (una columna a la izquierda), achatada, cama chica, cabezal redondo con un aro verde que brilla y el carrete en un soporte aparte a la derecha.
  - **Rayo X1** ("la rápida"): blanca, columna alta con una barra de luz LED, cama grande, el carrete arriba de la columna y la pantalla táctil en un brazo al frente a la derecha; franja verde.
  - **Prisma MC** ("la multicolor"): el cuerpo de la X1 con acento morado y, arriba de la columna, una caja de color con 4 carretes a la vista bajo el marco de su tapa (el del trabajo es `Spool/Filament`), 4 tubos que se juntan y una rampa de purga atrás con un montoncito de purga de 4 colores.
  - **Bóveda P1** ("la cerrada"): cubo grafito de esquinas redondeadas, puerta y techo de vidrio (solo el marco y un reflejo en diagonal: sin transparencia), luz de estado verde al frente y el carrete atrás, asomando por encima. Adentro, el cabezal corre arriba y **la cama baja** mientras la pieza crece (la pieza siempre termina bajo la boquilla).
  - **Titán Pro** ("la grande"): gabinete grafito más grande con franjas y manija naranjas, dos boquillas, pantalla ancha y la caja de colores con 4 carretes integrada sobre el techo, detrás del vidrio.
  - **Gota R1** ("la de resina"): base negra con la pantallita y una franja ámbar, tina de aluminio con la resina (del color del trabajo), riel Z atrás y la placa que sube, todo bajo una **tapa ámbar transparente** (la única transparencia: una llamada más, sin sombra).
  - Las cerradas tienen la **luz de adentro por estado** (`Interior`): apagada (gris) sin trabajo, cálida imprimiendo, verde lista, roja con falla.
- **Cubo Uno** (la del piso, ya del kit): marco negro `#2c2f3d` de perfil con ranura, cama PEI dorada con perillas amarillas, cabezal con el ventilador azul `#3f86e0`, boquilla de latón y un tubo PTFE blanco en arco, barra LED bajo el travesaño, caja de control con la pantallita abajo a la derecha y el carrete arriba en un portacarrete impreso azul. Lo fijo es una malla (`Body`); aparte van la barra X (`Gantry`), el cabezal (`PrintHead/Carriage`), la pantallita (`Display`) y el bobinado (`Spool/Filament`). Marcadores para la vista: `Bed`, `PieceAnchor`, `HeadRest`, `HeadPark`, `TrayAnchor` y `BedLight`. Mide 0,45 m de ancho y 0,71 m de alto con el carrete (tope de toda impresora: 0,72 m), unos 2.400 triángulos y 9 llamadas con la sombra.
- **En el piso**, la impresora se apoya en una baldosa de concreto claro con granitos (0,54 × 0,50 × 0,035 m), con su cable negro de 4 mm que cruza el piso entre los lugares de muebles hasta el enchufe de la pared del fondo (`PaverModel`, en `Room/Decor`: no se toca ni da sombra).
- **Carrete** (`SpoolModel`): tapas abiertas gris claro `#d9dde3` (un aro y cuatro rayos) un 10 % más grandes que el bobinado, centro gris `#8a8f9c`, y el bobinado del color del filamento con los surcos del enrollado. Siempre acostado, con el eje paralelo al frente.
- **Muebles** (`FurnitureModel`, cada tipo en `game/world/props/furniture/`): UNA malla del kit cada uno (`Body`, detalle 0,8, ≤ 1.500 triángulos, 2 llamadas con su sombra; sin los biseles de menos de 5 mm). Los carretes que guardan van dentro de esa malla, de canto o en pilas acostadas, siempre con el eje paralelo a la pared (se ve la banda de color y, por el aro de la tapa, el color también) y de los 9 colores de filamento. Lo impreso de la historia (escuadras, ganchos, tarros, un florero) lleva capas y es naranja `#f28c28` o de los colores del tapete. Marcan con nodos `PrinterSpot0`, `PrinterSpot1`... dónde va cada impresora.
  - **Mesa auxiliar** (0,60 × 0,50 × 0,55 m): melamina blanca `#f4ede2` con el canto de madera clara a la vista, patas cuadradas y una repisa abajo con un tarro impreso y el atomizador de alcohol.
  - **Mesa de trabajo** (1,30 × 0,80 × 0,60 m): tablero grueso de madera clara con vetas, patas y faldones de madera media, una cajonera metálica de tres cajones colgada a la derecha (tiradores de aluminio y etiquetas blancas) y una repisa baja con tres cajas organizadoras abiertas de paredes finas (verde azulado, mostaza y azul oscuro; se ve adentro).
  - **Estantería metálica** (2,40 m): cuatro postes negros de ángulo sobre tapones de goma, cuatro tablas de madera clara dentro de su marco de ángulo (caras de arriba en 0,075 / 0,845 / 1,615 m para las impresoras y 2,385 m el techo): **0,74 m libres en cada piso**, cabe cualquier impresora. Cruces atrás y a los lados, una regleta blanca con su luz roja en el poste de atrás a la derecha, el atado de cables que sube con amarras blancas y, arriba, dos cajas de filamento y dos carretes de canto.
  - **Repisa de filamento**: dos tablas de madera con 6 carretes de canto, escuadras impresas naranjas y dos cajas de filamento en el piso. **Pegada a la pared** (a 1,5 cm) donde la hay; en el lugar del medio del cuarto y bajo la ventana va sobre un **pie propio** (dos parantes negros con pies en T).
  - **Estantería de cubos** (0,80 × 1,50 × 0,40 m): melamina blanca de 2 columnas × 4 huecos (el fondo de los huecos un tono más oscuro, `#d9d2c4`), con 4 pilas de 3 carretes (12 kg, los 9 colores), una caja de filamento, dos tarros impresos y un florero impreso morado; lo de adentro va corrido hacia adelante para que el costado no lo tape. Se arrima a la pared donde la hay, contra el zócalo (a 3 cm).
  - **Tablero de herramientas**: tablero perforado de madera clara con marco de madera media, ganchos impresos naranjas, alicate rojo, cortafríos amarillo, espátula azul, calibrador, llaves Allen en su soporte impreso, un rollo de cinta, una repisita impresa con el pegamento y el atomizador, y una caja de herramientas metálica en el piso. Pegado a la pared o sobre su pie, como la repisa.
  - La distancia de cada lugar a la pared la da `RoomLayout.wall_gaps` (sin pared: `FurnitureModel.NO_WALL`). En la tienda se ven sobre su pie.
- **Personaje** (`CharacterModel`): un joven maker de 1,40 m y unas 3,2 cabezas (el escritorio le llega a la cintura). Pelo café en una sola superficie: 14 mechones redondos que bajan de la coronilla (6 grandes atrás, de anchos distintos, uno sobre cada oreja, uno en cada sien y las 4 lenguas del flequillo barrido hacia un lado, que termina más de 1 cm sobre las cejas), patillas, nuca y 3 mechoncitos sueltos acostados en la coronilla; arriba los mechones se suavizan en un casco liso (sin remolino marcado visto desde arriba). Cara pintada por código (`FacePainter`, 8 expresiones: normal, parpadeo, feliz, preocupado, hablar A y B, concentrado, sorpresa): ojos grandes con dos brillos, cejas gruesas y amables, rubor (con el zoom lejos y el normal la cara se lee más nítida y los ojos pasan a ser puntos de tinta con su brillo, nunca manchas grises); las pupilas siguen lo que mira más allá de lo que gira la cabeza (como mucho 20°). Buzo gris carbón `#3e4250` con la capucha enrollada y su forro mostaza, cordones crema con puntas mostaza, bolsillo canguro, puños y borde acanalados y el logo de tres capas cian; jeans `#3d5c96` con la basta doblada; zapatillas blancas gorditas con suela y franja cian. Mentón un poco levantado: la cámara alta le ve la cara. El cuerpo es una malla con piel (`CharacterRig`): rodillas y codos se doblan sin cortes. Brazos más delgados que las piernas, un poco abiertos (en A), con el hombro redondo: la punta de cada manga es una cúpula lisa del mismo torno, sin bola aparte, metida bajo la esquina del buzo, y el pivote del hombro está en su centro (y 0,86): al levantar o balancear el brazo la manga no se despega del buzo. La capucha enrollada y su forro tienen las puntas redondeadas. Respira y mira de vez en cuando su impresora.
- **Lugares libres:** cuatro esquinas cian en L y un "+" en el piso (una malla compartida), que laten suavemente (alfa 0,22 ↔ 0,35) y se encienden (0,55 ↔ 0,85) con el personaje a 1,2 m o menos o con la tienda abierta. Invitan a comprar muebles (pilar 1).
- **Objeto cercano** (`HighlightFrame`): cuatro esquinas cian más brillantes (0,8 ↔ 0,45) alrededor de la huella del objeto que el personaje tiene al lado, más 0,12 m. Mismo estilo que los lugares libres, para que se lea como "esto se puede usar".
- **Destino al tocar el piso:** un aro cian que se agranda y se desvanece en medio segundo.
- **Pieza impresa** (`PieceModel`): un bloque del color del carrete, más grande que la pieza real para que se vea (tamaño S de 0,12 m, M de 0,18 m y L de 0,24 m). Crece sobre la cama de a una capa de 1 cm (`PieceModel.LAYER_STEP`) y nunca baja, con la capa caliente naranja `#ff8a3d` arriba (se ve aun con el zoom lejos). Al terminar da un saltito y suelta tres destellos dorados que duran 0,6 s (`ReadySparkles`, un MultiMesh). Si falla, queda detenida en gris oscuro: con **warping** se inclina y se le levanta una esquina (la otra queda apoyada) y el cabezal se aparta; con **espagueti** aparece encima un nido de 11 rulos del color del filamento, un poco más claro, y dos hebras que suben hasta la boquilla, que se queda sobre el nido. En pedidos de varias piezas, las terminadas esperan en una bandeja (al frente de las abiertas y de la de resina, sobre el marco del techo de las cerradas). En las **cerradas** la pieza crece sobre la cama que baja y se ve por la puerta y el techo; en la **de resina** cuelga de la placa y crece hacia abajo (la capa caliente queda abajo, sobre la resina) mientras la placa sube; si falla, cae a la tina inclinada (la resina no hace espagueti).
- **Estado de noche por impresora:** la pantallita brilla, las abiertas tienen su LED y las cerradas su luz de adentro, y bajo cada impresora hay un **halo** del color de su estado (cálido imprimiendo, verde lista, rojo con falla; apagado sin trabajo). Todos los halos son un solo `MultiMesh` (`HaloField`, `Room/Halos`), multiplicado por `cc_night`: de día no se dibujan.
- **Escritorio del comienzo** (`ComputerDeskModel`, del kit): mesa vieja de madera con cajonera de tres cajones (el del medio entreabierto) y tiradores de bronce; monitor de tubo beige con un papelito amarillo y su LED verde; torre con bahías; teclado con teclas; ratón sobre su alfombrilla; lámpara articulada amarilla con la ampolleta asomando (de noche brilla); taza roja; portalápices impreso morado; papeles con un croquis azul, cuaderno y calibrador; cables que bajan a una regleta en el piso, y una caja de cartón cerrada con cinta y un cojín verde azulado como silla. Lo fijo es una malla (`Body`, detalle 0,8, unos 3.900 triángulos, 3 llamadas con la pantalla); aparte va `Monitor/Screen`. Marcadores para las luces del sombreador: `LampBulb` (lámpara, `cc_pl0`) y `ScreenGlow` (monitor, `cc_pl1`). La caja que se toca es la de siempre (x ±0,65, z −0,41…0,81, 1,15 de alto).
- **Rincón de despacho** (`DispatchCornerModel`, del kit): una mesita de madera clara para embalar (dispensador de cinta, cúter, etiquetas y un marcador encima; cartones planos y un rollo de plástico de burbujas abajo) y un guacal de listones con relleno de papel triturado como cajón de salida, casi tan alto como la mesa. Una malla (`Body`, unos 1.400 triángulos). Va fijo junto a la puerta, sin ocupar un lugar de muebles. Encima de la mesa aparecen las cajas abiertas con las solapas hacia afuera y la pieza del color del pedido asomando; sobre el guacal se apilan (un poco girados, como a mano) los paquetes de cartón corrugado con cinta y una etiqueta blanca con un ícono azul oscuro, sin texto (`PackageModel`, una malla compartida por tipo). Al despachar, el paquete se desliza hacia la puerta y desaparece.
- El personaje tiene articulaciones en caderas, rodillas, hombros, codos y cabeza (`HipL`, `HipR` con `KneeL`/`KneeR`, `Body`, `Body/ShoulderL`, `Body/ShoulderR` con `ElbowL`/`ElbowR`, `Body/Head`) para la animación, que se hace por código; un esqueleto copia cada cuadro la pose de esas articulaciones a la malla con piel. El globo de diálogo se ancla a `Body/Head/SpeechAnchor`.

## 3. Interfaz

### Base
- Diseño vertical de **720×1280**, con escalado `canvas_items` y `expand`. Márgenes laterales de 16 px.
- Botones táctiles de al menos 88 px. La navegación principal va abajo, al alcance del pulgar.

### Colores (`UiPalette`)

| Uso | Color |
|---|---|
| Panel | `#121a2c` al 94% |
| Tarjeta | `#18223a`, borde `#263a58` |
| Borde normal | `#2b5f80` |
| Acento y brillo | cian `#38d6ff` |
| Texto | `#eef3ff`; secundario `#91a4c6`; desactivado `#5f6d88` |
| Experiencia | verde `#4fdc7a` |
| Moneda | dorado `#f5b82e` |
| Aviso o burbuja | rojo `#e5484d` |
| Bloqueado por nivel | naranja `#f2a541` |

### Componentes
Todo sale del tema común `UiTheme`; no se crean estilos sueltos.

- **Paneles:** esquinas redondeadas de 18 px, borde de 2 px y brillo cian suave. Las tarjetas internas tienen esquinas de 14 px.
- **Activo o seleccionado:** borde cian brillante, fondo `#0f2a40` y más brillo.
- **Tipografía:** solo **Nunito** (`assets/fonts`), regular (peso 650) y negrita (peso 850). Tamaños: títulos 32, normal 24, secundario 21 y pequeño 19.
- **Iconos:** SVG de 48×48 en `assets/icons`, de trazo blanco de 4 px con puntas redondeadas, teñidos por código. La moneda es el único icono a color. Para el ciclo de pedidos se agregaron `design` (lápiz) y `warning` (triángulo).
- **Vistas 3D en la interfaz** (`ModelPreview`): el retrato del personaje y las impresoras y muebles de la tienda usan los mismos materiales y la misma cuenta de color del mundo (tonemap lineal, un sol con sombra). El personaje, en los retratos, cambia la luz del cuarto por una luz de estudio (llave cálida arriba a la izquierda, relleno frío, borde): la cara nunca queda oscura. El retrato del HUD muestra la cabeza y cambia de cara en los momentos importantes (feliz al cobrar a tiempo, preocupado si falla una impresión, sorpresa y después feliz al subir de nivel); el de la pantalla de Perfil, el cuerpo entero.
- **Panel inferior** (`BottomSheet`): la información de un objeto del mundo. Sube desde abajo en 0,18 s y tapa la barra de secciones. Arriba tiene una rayita para deslizar, la vista del objeto, el título y la X; en el medio, filas de icono y texto y un consejo destacado; abajo, botones de 96 px de alto a todo lo ancho, el principal en cian. Como máximo debería tapar la mitad de la pantalla.
- **Joystick** (`JoystickRing`): un aro de 90 px de radio, azul marino al 35% con borde cian, y una perilla cian. Se dibuja sobre todo el HUD, solo mientras el dedo arrastra.
- **Burbuja de cercanía** (`InteractBubble`): botón cuadrado de 88 px con el estilo `IconButton` y el icono del objeto, sobre el objeto cercano. Aparece con un pequeño rebote.
- **Globo de diálogo** (`SpeechBubble`, variación `BubblePanel`): papel claro `#f4f1e8` con borde oscuro de 3 px, como el contorno del mundo, y texto oscuro (`BubbleLabel`). Es lo único claro de la interfaz, para que se lea como "habla alguien": el personaje, o un cliente en su mensaje de Pedidos. Nunca tapa la burbuja de cercanía: se corre al costado o arriba.
- **Pista para jugadores nuevos** (`MoveHint`): texto en negrita con contorno oscuro y un joystick fantasma que se mueve solo, en la zona del pulgar.
- **Botón de zoom:** `IconButton` de 96×104 px abajo a la izquierda, con la lupa y el nivel actual ("Normal", "Cerca", "Lejos").
- **Burbujas de estado** (`StatusBubble`): oscuras (`PillPanel`), de al menos 72 px, con un icono de 36 px y un texto corto debajo; se tocan en un área de 88 px. Cian para lo que avanza (imprimiendo, modelando, lista para imprimir), verde con latido para "lista" (✓), roja con latido para un fallo (⚠) y dorada para el rincón de despacho. Siempre icono y texto, nunca solo color. Se esconden sobre las secciones y para el objeto que muestra la burbuja de cercanía.
- **Celebraciones** (`FeedbackLayer`): "+$6" en dorado y "+5 XP" en verde vuelan desde el rincón de despacho hasta el dinero y la barra de experiencia. El agradecimiento del cliente es un aviso oscuro que aparece unos 2 segundos debajo de los objetivos, sin tapar el HUD; los textos que vuelan pasan por encima.
- **Tarjetas de Pedidos:** un mensaje nuevo (`OfferCard`) tiene el icono del cliente en su color, el mensaje en papel claro, el nombre del pedido, los requisitos como píldoras con icono y texto, la estimación y el pago, y abajo Rechazar y Aceptar. Un pedido en curso (`OrderCard`) muestra el paso con 6 iconos (`StepTracker`: mensaje, lápiz, impresora, ✓, caja y camión; verde lo hecho, cian el paso actual y gris lo que falta), el estado con su barra y un botón para el siguiente paso.
- **Panel inferior, extras:** opciones como botones de 64 px (la elegida en cian; son la única excepción a los 88 px, porque son anchas, van en una sola fila y solo eligen, sin hacer nada todavía), filas con barra de avance, notas grises bajo un botón apagado que dicen por qué no se puede, y una línea roja arriba cuando algo falla.
- **Número en un botón:** el círculo rojo de Pedidos da un saltito cuando el número sube.

### Estructura del HUD (imagen de referencia)

```
┌──────────────────────────┐ ┌──────────┐ ┌──┐
│[retrato] Nivel 1          │ │ $ 250     │ │⚙ │
│          ▓▓▓░░░░░░        │ ├──────────┤ └──┘
│          0 / 100 XP       │ │ Día 1 08:00│
└──────────────────────────┘ └──────────┘
┌──────┐                  ┌────────────────────┐
│Pedidos│                  │ Objetivos          │
├──────┤                  │ ○ Entrega 3 llaveros│
│Tareas②│                  │ ○ Saca la impresora │
├──────┤                  └────────────────────┘
│ Mapa  │        (habitación en 3D)
└──────┘
┌──────────────────────────────────────────────┐
│ Inicio │ Taller │ Inventario │ Tienda │ Perfil│
└──────────────────────────────────────────────┘
```

- Las secciones se abren como un panel grande sobre la habitación (`ScreenBase`), con encabezado de icono, título y botón para cerrar.
- **No hay moneda premium:** donde la referencia muestra gemas, el juego muestra la fecha del calendario (GDD, sección 11).

## 4. Textos y tono

- Español cercano y con humor amable (pilar 3): "Don Ernesto todavía está armando la caja registradora".
- Todo texto visible pasa por `tr()` y `localization/translations.csv`, en español y en inglés.
- No va texto dentro del mundo 3D: a esta resolución no se lee.

## 5. Qué evitar

- Texturas realistas o fotográficas y efectos de posprocesado borrosos (el único degradado es el fondo del diorama).
- Luces del motor además del sol (las lámparas, pantallas y LEDs se calculan en el sombreador del mundo).
- Tipografías o estilos de iconos distintos.
- Marcas o productos reales (GDD, sección 3).
- Estilos de interfaz sueltos fuera de `UiTheme`.

## 6. Lista para agregar algo nuevo

1. ¿Usa `PropBuilder` (lo nuevo, una malla de `KitMesh` con `PropBuilder.kit`) y los materiales de `WorldPalette`?
2. ¿Está a escala real, mira hacia +Z y se distingue de lo que ya existe?
3. ¿Se ve bien con zoom lejos y cerca, sin contorno y sin detalles de menos de 1 cm? ¿Sus colores salen de `LookPalette`?
4. ¿La interfaz usa `UiTheme`, `UiKit` e iconos de `assets/icons`?
5. ¿Los textos usan `tr()`?

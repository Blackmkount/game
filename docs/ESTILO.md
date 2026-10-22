# Guía de estilo visual

Esta guía mantiene el juego **coherente y consistente** de principio a fin. Toda escena, modelo, pantalla o icono nuevo debe seguirla. Si algo nuevo no encaja aquí, se discute y se actualiza esta guía antes de hacerlo.

**Referencia:** `docs/referencias/taller_final.webp`, la imagen que entregó el dueño. Muestra cómo puede verse la habitación al final del juego, llena de impresoras, muebles y carretes. El juego empieza con la misma habitación casi vacía.

## 1. Idea general

**Pixel art isométrico cálido, con interfaz oscura de bordes cian.**

- El mundo es 3D, armado con formas básicas, y se dibuja a **la mitad de la resolución** con píxeles nítidos. El resultado parece pixel art, pero se puede animar, mover y ampliar como 3D.
- La interfaz se dibuja a resolución completa: texto nítido sobre paneles azul marino con bordes y brillos cian.
- Ambiente: cálido y acogedor adentro (madera, luz de tarde), frío y oscuro afuera (fondo azul marino).

## 2. Mundo 3D

### Render
- La escena va dentro de un `SubViewportContainer` con `stretch_shrink = 2`, filtro `NEAREST` y sin antialiasing (`game/scenes/main.tscn`).
- Cámara ortográfica (`CameraRig`), inclinada −30° y girada 45°: la vista isométrica clásica 2:1. Su tamaño base se adapta a pantallas más altas (`RoomView._fitted_camera_size`).
- **Sigue al personaje** y tiene tres niveles de zoom: lejos (0,68×, entra todo el cuarto), normal (1×) y cerca (2×).
- **Sin temblor:** la cámara y el personaje se colocan en píxeles enteros del dibujo, y la fracción que falta se compensa corriendo la imagen (`WorldControls._apply_pixel_shift`). Por eso la vista del mundo es 4 px más grande que la pantalla por cada lado.
- Un píxel de pantalla equivale a unos **0,028 m** del mundo (`WorldPalette.PIXEL_WORLD_SIZE`). Los detalles de menos de 3 cm no se ven.

### Luz
- **Una sola luz direccional** cálida (`#fff1dc`, energía 0,75), entrando por el lado de la ventana, más luz ambiental (`#ffe6c7`, 0,5).
- Sombras **duras**: la calidad de sombra suave está en 0 en `project.godot`.
- Sombra **ortogonal** de una sola pieza (`SHADOW_ORTHOGONAL`, hasta 20 m): con la cámara en movimiento no tiembla y cuesta menos que el modo por defecto.
- Las paredes no proyectan sombra, para que la luz "entre" a la habitación.
- Pantallas, ventanas y marcas no se iluminan: brillan con su propio color (materiales `glow`). No se agregan luces extra.

### Materiales
Siempre se usan los de `WorldPalette` (`game/world/pixel/world_palette.gd`). Así se reutilizan los materiales y el estilo no se rompe:

| Función | Para qué |
|---|---|
| `solid(hex)` | Color liso con sombreado en bandas (toon) y contorno |
| `textured(nombre)` | Textura pixel art proyectada según el mundo: 1 píxel de textura ≈ 1 píxel de pantalla |
| `glow(hex, textura)` | Brilla sin sombreado ni contorno: pantallas, ventanas, luces |
| `glow_transparent(hex, alfa)` | Marcas del piso (lugares libres) |

### Contorno
- Todos los objetos sólidos llevan un **contorno oscuro de 1 píxel** (`#1a1320`) con la técnica "inverted hull" (`outline.gdshader`).
- Por eso cada forma debe estar **centrada en su origen**: usa siempre `PropBuilder` (`box`, `cylinder`, `sphere`, `quad`).

### Paleta del mundo

| Uso | Color |
|---|---|
| Contorno | `#1a1320` |
| Fondo exterior | `#141b2d` |
| Piso de madera | `#a86d43`, `#9c643c`, `#b3764a`, juntas `#6a3f22` |
| Ladrillo de las paredes | `#4b4150`, `#52475a`, `#463c4c`, mortero `#2c2532` |
| Madera de muebles | clara `#c98b4f`, media `#a86b3c`, oscura `#6e4426` |
| Metal | oscuro `#2b2f3a`, medio `#4a5163` |
| Plástico | negro `#23242b`, beige viejo `#d8ccb0` / `#b3a585` |
| Acentos de impresoras | azul `#3a7bd5`, verde `#4cbf5a`, morado `#9b5de5` |
| Marcas de lugar libre | cian `#38d6ff` |
| Cama de impresión | gris `#737b8c`, para que se vean las piezas oscuras |
| Cinta de embalar | `#c9b48a` |
| Pieza fallida | gris oscuro `#3b3b45` |
| Filamentos | los 9 colores de `config.filament_colors` |

### Texturas
- Se generan por código en `PixelTextures` (no hay archivos de imagen). Tamaño de 8 a 48 píxeles.
- De 3 a 4 tonos por material, juntas o mortero más oscuros y poco ruido. Nada de texturas realistas ni fotográficas.
- En pantallas y ventanas se usa `PropBuilder.quad` (un plano), no una caja, para que la textura se vea completa.
- Pantallas que cambian con el estado: el monitor del computador muestra un cubo de alambre cian mientras modela (`crt_modeling`), y la pantalla de la impresora tiene barras cian al imprimir, un ✓ verde al terminar y un "!" rojo al fallar (`printer_display_busy`, `_done` y `_error`). Las texturas son compartidas: se cambia cuál usa cada objeto, nunca la textura en sí.

### Modelos
- Formas básicas a **escala real**: una impresora tipo Ender mide unos 0,45 m y una mesa 0,75 m de alto. El frente mira hacia **+Z** y la base queda en y = 0.
- Cada impresora se ve distinta según su familia (`PrinterModel`): abiertas de cama móvil, cerradas tipo caja, multicolor con caja de colores encima y de resina con tapa ámbar.
- Los muebles marcan con nodos `PrinterSpot0`, `PrinterSpot1`... dónde va cada impresora (`FurnitureModel`).
- **Personaje** (`CharacterModel`): chibi de 1,25 m con cabeza grande, pelo café en puntas, buzo negro con capucha y cordones blancos, jeans azules y zapatillas blancas. Respira y mira de vez en cuando su impresora.
- **Lugares libres:** un marco cian semitransparente con un "+" en el piso, que late suavemente. Invita a comprar muebles (pilar 1).
- **Objeto cercano** (`HighlightFrame`): un marco cian más brillante en el piso alrededor del objeto que el personaje tiene al lado. Mismo estilo que los lugares libres, para que se lea como "esto se puede usar".
- **Destino al tocar el piso:** un círculo cian que se agranda y se desvanece en medio segundo.
- **Pieza impresa** (`PieceModel`): un bloque del color del carrete, más grande que la pieza real para que se vea (tamaño S de 0,12 m, M de 0,18 m y L de 0,24 m). Crece sobre la cama en escalones de un píxel de pantalla. Al terminar da un saltito; si falla, queda detenida en gris oscuro (el warping además se inclina). En pedidos de varias piezas, las terminadas esperan en una bandeja al frente de la impresora.
- **Rincón de despacho** (`DispatchCornerModel`): una mesita de madera para embalar, con cartones planos y un rollo de cinta, y un cajón de salida casi tan alto como la mesa. Va fijo junto a la puerta, sin ocupar un lugar de muebles. Encima de la mesa aparecen las cajas abiertas con la pieza; sobre el cajón, los paquetes con cinta (`PackageModel`). Al despachar, el paquete se desliza hacia la puerta y desaparece.
- El personaje tiene articulaciones en caderas y hombros (`HipL`, `HipR`, `Body/ShoulderL`, `Body/ShoulderR`) para la animación de caminar, que se hace por código.

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
- **Vistas 3D en la interfaz** (`ModelPreview`): el retrato del personaje y las impresoras y muebles de la tienda usan el mismo pixel art del mundo.
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

- Texturas realistas, degradados suaves en el mundo o efectos de posprocesado borrosos.
- Más de una luz con sombras o luces de colores.
- Tipografías o estilos de iconos distintos.
- Marcas o productos reales (GDD, sección 3).
- Estilos de interfaz sueltos fuera de `UiTheme`.

## 6. Lista para agregar algo nuevo

1. ¿Usa `PropBuilder` y los materiales de `WorldPalette`?
2. ¿Está a escala real, mira hacia +Z y se distingue de lo que ya existe?
3. ¿Se ve bien en una captura a la mitad de la resolución, con contorno y sin detalles de menos de 3 cm?
4. ¿La interfaz usa `UiTheme`, `UiKit` e iconos de `assets/icons`?
5. ¿Los textos usan `tr()`?

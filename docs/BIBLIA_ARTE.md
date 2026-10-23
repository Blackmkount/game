# Arte 2.0 — "Mundo Impreso": biblia de arte del mundo

> **Estado (2026-10-23):** aprobada por el dueño e implementada en 16 pasos (ver `docs/PROGRESO.md`). Se guarda aquí como referencia: el código y los documentos la citan como "biblia de arte §N". La guía vigente es `docs/ESTILO.md` (sus secciones 1, 2, 5 y 6 salen de este documento; la interfaz, §3, solo cambió en lo que dice §11) y lo que quedó distinto al implementarla, con su motivo, está en `docs/DECISIONES.md`. Decisiones del dueño (§16): D1 sí, D2 no (la opción por defecto: luces del sombreador), D3 sí, D4 no hizo falta hasta ahora (falta medir el primer arranque en el teléfono), D5 y D6 aplicadas, D7 sí, D8 sí (solo lo visual). Los prototipos y documentos de trabajo que nombra (`design_impreso`, `understand_models.md`...) no están en el repositorio.
>
> Documento final de dirección de arte. Reemplaza la sección "Mundo 3D" de `docs/ESTILO.md` (y sus secciones 1, 5 y 6) cuando el dueño lo apruebe. La interfaz (`docs/ESTILO.md` §3) no cambia salvo lo que dice §11 de este documento.
>
> Viene de una competencia de cuatro prototipos hechos dentro de copias del juego real, evaluados por cuatro jueces (director de arte, jugador, líder técnico y diseñador de juego). Ganó **"Mundo Impreso + Día y Noche"** (29,5 puntos; Pixel HD 28,5; Diorama 28; Juguete 26). Esta biblia toma su base y le injerta lo mejor de los otros tres, y corrige todo lo que los jueces marcaron como obligatorio.

---

## 0. En una frase

**Un diorama 3D suave y cálido del cuarto de un joven maker en una ciudad de valle latinoamericana, presentado como una maqueta impresa capa a capa: lo que compras se imprime en su sitio, la pieza crece con su capa caliente y el reloj del juego lleva la luz de una mañana con sol entre rejas a una noche "lo-fi" de lámpara y monitor.**

### De dónde sale cada parte

| Tomado de | Qué |
|---|---|
| **Mundo Impreso** (base) | Material único "kit" con luces calculadas en el sombreador, ciclo de día y noche atado al reloj, compras que se imprimen, pieza con capas y capa caliente, base impresa del diorama, vista del barrio por la ventana, cuarto con decoración solo en zonas libres |
| **Diorama Acogedor** | Fuerza y nitidez del sol de la mañana con rayas de las rejas, impresora del piso sobre una baldosa clara con su cable al enchufe, carrete de tapas abiertas, marcas de lugar libre en esquinas, biseles que atrapan la luz, vetas por tabla, arreglo de la estantería metálica, guacal en el despacho, tapete andino, cobija de tigre |
| **Juguete** | Diseño de la cara (ojos grandes con dos brillos, cejas amables, rubor), relleno de luz desde el lado de la cámara, sombras de contacto teñidas de índigo, cabeza más grande |
| **Pixel HD** | Pelo de una sola superficie continua, densidad de objetos con historia, nido de "espagueti" en los fallos, noche que se lee en el teléfono, cara siempre en la banda de luz |

---

## 1. Pilares visuales

1. **Legible antes que detallado.** Piso y paredes claros y cálidos; máquinas, personaje y muebles con valores más oscuros o más saturados encima. Formas grandes con bisel. Cada cosa se reconoce con zoom lejos.
2. **"Capa a capa" se ve.** En la pieza que crece, en las compras que se imprimen, en la base del diorama y en todo lo que en la historia fue impreso. Es la firma del juego y el título.
3. **La hora se siente.** El reloj del juego mueve el sol, la ventana, las lámparas y el barrio. La jugabilidad no cambia.
4. **Un hogar de verdad.** Un cuarto común de una ciudad de valle inventada y un maker de verdad: rejas, tanques de agua, varillas "para el segundo piso", cobija de tigre, carretes, espaguetis fallidos. Sin estereotipos, sin marcas reales, sin texto legible en el mundo.
5. **Barato en el teléfono.** Una malla por objeto, un material para casi todo, un solo sol con sombra, cero luces extra del motor, y una prueba automática que vigila el presupuesto.

---

## 2. Render

### 2.1 Resolución

El mundo deja de ser pixel art. Se dibuja a resolución alta con bordes suavizados, y su costo se fija con un **ancho interno** que no depende del teléfono.

- Nodos que se mantienen (pruebas y herramientas los usan): `Main/WorldView` (`SubViewportContainer`) y `Main/WorldView/SubViewport/Room`.
- `WorldView` recibe el script nuevo `WorldViewport` (`game/world/world_viewport.gd`):
  - `ancho_interno = min(ancho_físico_de_la_ventana, tope_del_nivel)`; `k = ancho_interno / 720`.
  - El contenedor mide `pantalla_virtual × k`, con `scale = 1/k`, `stretch = true`, `stretch_shrink = 1` y filtro `LINEAR`. Así el `SubViewport` tiene exactamente `ancho_interno` píxeles y se ve del tamaño de la pantalla.
  - Expone `view_per_ui: float = k`. Todas las conversiones de `WorldControls` que hoy dividen o multiplican por `stretch_shrink` usan `view_per_ui`.
  - Márgenes de ±4 px: se quitan (ya no hay corrimiento de píxel).
- En un teléfono de 1080 px con nivel Alto, 1 píxel del mundo = 1 píxel físico. En uno de 1440 px se dibuja a 1080 y se estira 1,33× (lineal).
- Medidas con zoom normal y nivel Alto: 1 píxel ≈ 6,4 mm del mundo (6,87 m / 1080). Nivel Bajo: ≈ 9,5 mm. **Lo menor a 1 cm no se modela.**

### 2.2 Niveles de calidad

| | **Alta** (por defecto) | **Baja** |
|---|---|---|
| Tope de ancho interno | 1080 px | 720 px |
| MSAA (`SubViewport.msaa_3d`; el `SubViewport` no hereda el ajuste del proyecto) | 4× | 2× |
| Sombra del sol | Sí: `SHADOW_ORTHOGONAL`, filtro suave calidad 2, mapa 2048 | No (el sol pasa a la pasada base, sin llamadas extra) |
| Motas de polvo | Sí | No |
| Halos, parche de ventana, luces del sombreador, contorno del personaje | Sí | Sí |
| Mapa de oclusión del piso | Fuerza 1,0 | Fuerza 1,2 (compensa que no hay sombras) |

- **Automático:** arranca en Alta. Si el promedio de los primeros 3 s después de cargar pasa de 24 ms por cuadro, baja a Baja una sola vez y lo recuerda en `UserSettings`.
- Con el modelo de color de §2.4, **los dos niveles se ven iguales salvo las sombras**: no hay que calibrar dos juegos de energías.
- La opción visible en Ajustes ("Calidad gráfica: Automática / Alta / Baja") necesita el visto bueno del dueño (ver §16). Sin él, queda solo la automática.

### 2.3 Cámara

- Igual que hoy: ortográfica, inclinación −30°, giro 45°, `KEEP_WIDTH`, zoom 0,68 / 1 / 2, sigue al personaje.
- **Sin ajuste a píxeles.** Se borran `CameraRig._apply` (redondeo), `pixel_remainder`, `RoomView._snap_to_pixels` y `WorldControls._apply_pixel_shift`.
- `NEAR = 11`, `FAR = 30` (antes 5 y 35). Con cámara ortográfica el mapa de sombras cubre de near a far; acotarlo al cuarto da sombras ~1,6× más finas.
- La cámara publica cada cuadro el global `cc_px_m` = metros por píxel interno (`size / ancho_interno`).

### 2.4 Modelo de color: "lo que dice el hex es lo que se ve"

- Todo se pinta e ilumina **en el espacio de la pantalla**: un color `#rrggbb` bajo luz neutra 1,0 se ve exactamente así. La cuenta es:

  `color = albedo × (ambiente + relleno + luces del sombreador + parche de ventana) × oclusión + albedo × sol + luz propia`

- Por qué: es la cuenta más fácil de ajustar mirando capturas, y hace que Alta, Baja, la tienda y los retratos se vean igual.
- **El riesgo que marcó el líder técnico:** en Compatibility el sol con sombra se dibuja en otra pasada que se mezcla en sRGB (está en el manual), y el prototipo midió además que la pasada base se escribe sin convertir. Eso se verificó solo en llvmpipe. Por eso **no se deja escrita a mano ninguna compensación**:
  - `ColorProbe` (`game/world/look/color_probe.gd`) dibuja una vez al arrancar dos cuadritos de 8×8 (ambiente 0,25 solo; sol 0,5 con sombra solo), con el mismo MSAA del nivel, lee el píxel y decide si cada pasada se convierte a sRGB.
  - Pone dos globales, `cc_base_fix` y `cc_sun_fix` (0 = la pasada no se convierte; 1 = sí). Todos los sombreadores terminan con `cc_out()` (pasada base) y `cc_sun_out()` (dentro de `light()`), que aplican la conversión inversa solo cuando hace falta.
  - Si la lectura falla o da valores fuera de rango (±0,06 de lo esperado), se usan los valores medidos en llvmpipe (`cc_base_fix = 0`, `cc_sun_fix = 1`) y el panel de depuración lo muestra.
  - Sin pantalla (pruebas) no se mide nada y se usan los valores por defecto.
  - La captura `00_calibracion` muestra tarjetas gris, blanca y de la paleta en las tres combinaciones (ambiente, sol, ambos). Es la guardia ante una actualización de Godot y la prueba que el dueño mira en su teléfono.
- **Tonemap lineal**, exposición 1,0. Un tonemap curvo (AgX, Filmic) rompe la suma de las dos pasadas. Los brillos fuertes (parche de sol, capa caliente) se pueden quemar un poco hacia el blanco cálido: está bien.
- Colores por vértice y colores por uniform deben verse iguales; la captura de calibración lo comprueba y el include lo normaliza.

### 2.5 Entorno

| Ajuste | Valor |
|---|---|
| Fondo | `BG_COLOR #141b2d` (lo tapa el fondo degradado de §8.10) |
| Ambiente del motor | Apagado (`AMBIENT_SOURCE_COLOR` negro, energía 0). El ambiente se calcula en el sombreador |
| Reflejos del motor | Apagados |
| Tonemap | Lineal |
| Glow, ajustes, SSAO, niebla | Apagados (el glow cuesta +104 %, multiplica el fondo ×4 y rompe mezclas) |
| `project.godot` | `soft_shadow_filter_quality = 2` y `.mobile = 2`; `directional_shadow/size = 2048` y `.mobile = 2048`; `positional_shadow/atlas_size = 0`; bloque `[shader_globals]` con los `cc_*` de §3.2 |

### 2.6 El sol y las sombras

- **Un solo `DirectionalLight3D`** ("Sun"). Dirección, color y energía los pone `DayCycle` según la hora (§6).
- Sombra: `shadow_bias 0.04`, `shadow_normal_bias 1.2`, `shadow_opacity 0.9`.
- **Proyectan sombra:** muebles, impresoras (solo `Body` en las de estante), personaje, decoración sólida del piso.
- **No proyectan:** paredes, piso, base, decoración de pared, alfombras, cables, halos, marcas, pantallas, piezas chicas (< 5 cm), el contorno del personaje.
- Las paredes no dan sombra: la luz general del cuarto "pasa" por arriba. La ventana se lee como fuente de luz gracias al parche calculado (§6.3).

---

## 3. Kit de materiales

### 3.1 Sombreadores (`game/world/look/`)

| Archivo | Para qué |
|---|---|
| `look_globals.gdshaderinc` | Los `cc_*`, `cc_out()`, `cc_sun_out()`, ruido |
| `world_light.gdshaderinc` | Ambiente de dos colores, relleno de cámara, luces del sombreador, parche de ventana con oclusores, oclusión del piso y de los rincones |
| `kit_body.gdshaderinc` | Atributos de vértice, superficies procedurales, capas impresas, capa caliente y `light()` |
| `kit.gdshader` | **El material de casi todo** (lee los atributos de vértice) |
| `kit_tinted.gdshader` | Igual, con color y superficie por uniform. Lo usa `WorldPalette.solid(hex)`: filamento, pieza, bandeja |
| `kit_character.gdshader` | Kit con terminador más marcado (`toon 0.8`), refuerzo del relleno y piel del personaje |
| `kit_head.gdshader` | Kit + cara pintada (atlas) con proyección cilíndrica (§7.5) |
| `kit_reveal.gdshader` | Compras que se imprimen (§12.2). Solo mientras dura el efecto |
| `outline_character.gdshader` | Contorno por normales del personaje (§3.7) |
| `screen.gdshader` | Pantallas procedurales: monitor CRT y pantallitas de impresora por estado |
| `window_view.gdshader` | El barrio por la ventana, con estado de ánimo por hora |
| `halo.gdshader` | Halos sumados (redondos o cápsula), para un `MultiMesh` |
| `window_shaft.gdshader` | Haz de luz de la ventana con rayas de las rejas |
| `backdrop.gdshader`, `base_shadow.gdshader` | Fondo degradado y sombra suave bajo la base |
| `marker.gdshader` | Marcas de lugar libre, marco de cercanía y destino (alfa por parámetro) |

Todos se cargan con `preload` desde un script, para que `check.sh` los compile sin pantalla.

### 3.2 Globales (`[shader_globals]`, los pone `DayCycle`, `RoomView` y la cámara)

| Global | Tipo | Qué es |
|---|---|---|
| `cc_amb_sky`, `cc_amb_ground` | color | Ambiente de arriba y rebote de abajo (ya multiplicados por su energía) |
| `cc_fill_dir`, `cc_fill` | vec3, vec4 | Relleno desde el lado de la cámara: dirección (0,61; 0,5; 0,61) normalizada; rgb × energía y, en `w`, el refuerzo extra para el personaje |
| `cc_window_dir`, `cc_window_color` | vec3, color | Hacia dónde viaja la luz de la ventana; color × fuerza |
| `cc_window_rect`, `cc_window_x` | vec4, float | Hueco: z0, z1, y0, y1; plano de la pared (x = −3,0) |
| `cc_window_bars` | vec4 | Separación de rejas, medio grosor, altura del travesaño, medio ancho del parante central |
| `cc_occ_a_c`, `cc_occ_a_h`, `cc_occ_b_c`, `cc_occ_b_h` | vec4 | Dos cajas que tapan el parche (centro y medias medidas): escritorio y cama |
| `cc_char_pos` | vec4 | Personaje: xyz y radio de su mancha. También es la cápsula que tapa el parche |
| `cc_pl0`…`cc_pl3`, `cc_pl0_col`…`cc_pl3_col` | vec4 | Cuatro luces del sombreador: posición y alcance; color × intensidad |
| `cc_strip_a`, `cc_strip_b`, `cc_strip_col` | vec3, vec3, vec4 | Tira LED (segmento) y su color × intensidad, alcance en `w` |
| `cc_night` | float | 0 de día, 1 de noche |
| `cc_px_m` | float | Metros por píxel interno |
| `cc_room` | vec4 | x0, z0, lado, alto de pared |
| `cc_floor_ao` | sampler2D | Mapa de oclusión del piso 96×96 |
| `cc_base_fix`, `cc_sun_fix`, `cc_sun_shadowed` | float | Modelo de color (§2.4) y si el sol del nivel actual tiene sombra |
| `cc_anim_time` | float | Tiempo de animación (polvo, cortina, plantas). Lo avanza `RoomView.step()`; las capturas lo congelan |

Son unos 35 globales (el límite web es 1024). En las vistas de la tienda y los retratos, que tienen su propio mundo, un `instance uniform float preview_light` cambia el ambiente por una luz de estudio fija y `instance uniform float px_m_override` fija el grosor del contorno.

### 3.3 Atributos de vértice (mallas del kit)

| Atributo | Contenido |
|---|---|
| `COLOR.rgb` | Color (hex de la paleta, espacio de pantalla) |
| `COLOR.a` | Oclusión horneada (1 = nada) |
| `UV.x` | Parte entera: tipo de superficie. Parte decimal: brillo (0–0,99) |
| `UV.y` | Peso de balanceo (plantas, cortina, cobija colgando) |
| `UV2.x` | Alto de capa si es impreso, en metros (0 = no impreso) |
| `UV2.y` | Luz propia: > 0 siempre (LED, foco), < 0 solo de noche. El valor es la intensidad |

**Superficies (`UV.x` entero):** 0 lisa · 1 baldosa del piso (junta, variación por baldosa, bisel de 6 mm) · 2 madera (variación de ±6 % por tabla, veta) · 3 pintura de pared (ruido de 3,5 %) · 4 tela (tejido que se apaga bajo 1 px) · 5 cartón (corrugado) · 6 metal cepillado · 7 PEI dorado texturizado.

### 3.4 `light()` y el sombreado

- Terminador suave: envoltura 0,35, luego `smoothstep(0,5 ± 0,18)`; personaje ± 0,06 (`toon 0.8`).
- Sombra recibida: `smoothstep(0,1; 0,9; ATTENUATION)`.
- Brillo Blinn: exponente 8 → 60 según brillo, × 0,45.
- Luz de borde: `(1 − N·V)^4 × 0,28`, solo del lado iluminado, teñida con el color del objeto. Personaje 0,35.
- **Paredes a contraluz:** `wall_wrap` 0,35. La pared de la ventana (cara +X) recibe al menos 35 % del sol aunque quede a contraluz. Así las dos paredes se leen como pintura, no como gris.
- Todo lo del sol sale por `cc_sun_out()`.

### 3.5 Capas impresas, capa caliente y oclusión

- **Capas** (solo en lo que fue impreso en la historia: pieza, bandeja, base del diorama, cortes de pared, figuritas, macetas y portalápices impresos): crestas que inclinan la normal `sin(2π·y/capa) × 0,38`, bandas claras y surcos oscuros con fuerza `clamp(capa × 14; 0,07; 0,36)`. **Se apagan cuando una capa mide menos de 1,3 px** (`fwidth`): nunca centellean.
  - Altos de capa: base 2,4 cm, cortes de pared 1,2 cm, pieza/bandeja/filamento 1 cm, figuritas 3–4,5 mm.
- **Capa caliente:** `instance uniform float hot_y` (alto en el mundo del borde de arriba). Banda de grosor `max(PieceModel.LAYER_STEP; 2 × cc_px_m)`, color `#ff8a3d`, luz propia 1,4. Con zoom lejos sigue midiendo 2 px: **el crecimiento se ve en cualquier zoom**.
- **Oclusión** (todo multiplicado y teñido hacia índigo: `mix(blanco, #c7ccff, 1 − ao) × ao`, nunca gris):
  - Horneada en los vértices: −35 % en el contacto, se desvanece en 12–16 cm; caras que miran hacia abajo −25 %.
  - Uniones piso-pared y rincón: −40 % dentro de 0,35 m.
  - Mapa del piso `FloorAO` (96×96): manchas bajo cada mueble, impresora y decoración, pintado **una vez por distribución** desde los obstáculos registrados (nada de recorrer rectángulos por píxel).
  - Mancha del personaje: −50 %, radio 0,36 m, se mueve con `cc_char_pos`.

### 3.6 Caché e identidad de materiales

- `WorldPalette` (se muda de `game/world/pixel/` a `game/world/look/`, con sus `.uid`) **mantiene la misma interfaz con caché**: `solid(hex)`, `glow(hex, textura)`, `glow_transparent(hex, alfa)`, `textured(nombre)`. Las 14 comparaciones por identidad de las pruebas siguen pasando; solo cambian dos anotaciones de tipo (`StandardMaterial3D` → `Material`).
  - `solid(hex)` → `kit_tinted` con ese color (y capas de 1 cm, brillo 0,25).
  - `glow("ffffff", estado)` → `screen.gdshader` con ese estado (`crt_screen`, `crt_modeling`, `printer_display`, `_busy`, `_done`, `_error`). Una instancia por estado.
  - `textured(nombre)` → `kit_tinted` con la superficie correspondiente (sirve mientras quedan modelos viejos).
- Nuevas: `kit()`, `kit_character()`, `kit_head()`, `halo()`, `marker(alfa)`, `reveal_of(material)`.
- **Meta:** ≤ 16 materiales distintos en el cuarto inicial (hoy 35).

### 3.7 Contorno

- **Mundo: sin contorno.** El casco invertido duplicaba las llamadas de color y de sombra y no sirve en mallas unidas. Las siluetas salen del valor (fondos claros, objetos oscuros), del borde de luz, de los biseles y de la oclusión.
- **Personaje: contorno fino y constante.** Casco por normales (`VERTEX += NORMAL × grosor`, `cull_front`, sin sombreado), **dibujado por una `MeshInstance3D` aparte** que comparte la malla (y el esqueleto) con `cast_shadow = OFF`: no entra a la pasada de sombra.
  - Grosor = 1,5 × `cc_px_m` (1,5 px internos en cualquier zoom). Color `#1a1830`; pelo `#2e180c`.
- Selección e interacción: marcos cian del piso (§8.9), no contornos.

---

## 4. Paleta

Regla: todo color nuevo sale de estas tablas. Lo saturado se reserva para filamentos, textiles y luces. Nada es negro puro: lo oscuro es tinta índigo o grafito.

### 4.1 Entorno y diorama

| Uso | Hex |
|---|---|
| Fondo degradado (centro → borde), por hora | mañana `#26335c` → `#141b2d`; mediodía `#28365f` → `#151c30`; tarde `#2c2450` → `#17142e`; atardecer `#231f4a` → `#121230`; noche `#121a33` → `#070a16`; alba `#202750` → `#11152b` |
| Resplandor detrás del diorama (×0,55) | día `#3a4a7a`; tarde `#5a3d6a`; noche `#1c2a55` |
| Base impresa (capas de 2,4 cm) y cortes de pared (1,2 cm) | `#56689a` |
| Borde de primera capa ("brim") | día `#4a6f9e` (sin brillo); noche el mismo con luz propia cian `#38d6ff` × 0,25 |
| Sombra bajo la base | `#05070f` al 60 % |

### 4.2 Cuarto

| Uso | Hex |
|---|---|
| Baldosa de piso (0,40 m, damero suave) | A `#e8c49c`, B `#e2bb91`, junta `#f2e2cb` |
| Pared de la ventana (verde salvia claro) | `#bfd8c2` |
| Pared del fondo (crema cálida) | `#f2dcbc` |
| Zócalo, marco de puerta, interruptor y canaleta | `#f4ede2` |
| Puerta / tableros / manija | `#a8693a` / `#b77a47` / latón `#e0b44a` |
| Ventana: aluminio / rejas de hierro / alféizar | `#dfe4ea` / `#2a2e3a` / `#efe7da` |
| Cortina mostaza | `#e2a93b`, pliegues `#c98f2c` |

### 4.3 Materiales de los objetos

| Uso | Hex |
|---|---|
| Madera de muebles | clara `#d9a066`, media `#b97a48`, oscura `#7a4b2e` |
| Metal | oscuro `#2b2f3a`, medio `#5a6274`, aluminio `#cfd5dd`, latón `#e0aa45` |
| Computador viejo | beige `#e6dcc4`, beige gastado `#c9bb9a` |
| Cartón / cinta | `#c99a62`, `#a87a48` / `#d8b97a` |
| Guacal (madera de cajón) | `#dca05a`, `#a8703a` |
| Baldosa bajo la impresora (concreto) | `#cfcac0` con granitos `#b9b3a8` |
| Pieza fallida | `#3b3b45` |

### 4.4 Textiles, plantas y decoración

| Uso | Hex |
|---|---|
| Cobija de tigre (desaturada a propósito) | base `#d08a48`, rayas `#3a2a26`, vientre y doblez `#f0d2a0` |
| Sábana / almohada | `#f4efe6` / `#cfe1f2` |
| Tapete andino tejido | fondo `#e9dcc0`; rombos y franjas `#2f8f8a`, `#c4553b`, `#2f3a57`, `#e0a43a` |
| Felpudo / puf | `#8a6a4a` / `#3f9e8e` |
| Plantas | `#3f8f4f`, `#4fa65a`, `#2f7a45`, brote `#5bb866`; maceta de barro `#c2683f`; lata `#c9ced6`; balde de pintura `#f2f0ea` con franja `#2f8f8f` |
| Pósters (sin letras ni marcas) | cerros al atardecer `#f28c28` `#c4553b` `#2f3a57`; boquilla y barquito `#38d6ff` sobre `#2f3a57`; teleférico `#e0a43a` `#3f8f4f` `#cfe1f2` |

### 4.5 Impresoras

| Familia | Cuerpo / acento |
|---|---|
| Cubo Uno | marco `#2c2f3d`, acento `#3f86e0`, cama PEI `#c99a4e`, perillas `#f0c419`, boquilla `#e0aa45` |
| Rayo Mini y Rayo X1 | blanco `#eceef2`, verde `#4cbf5a` |
| Prisma MC | blanco `#eceef2`, morado `#9b5de5` |
| Bóveda P1 | grafito `#2c2d36`, interior iluminado `#ffd58a`, acento `#4cbf5a` |
| Gota R1 (resina) | base `#2b2f3a`, tapa ámbar `#f28c28` (transparente al 55 %) |
| Titán Pro | grafito `#34363f`, naranja `#f28c28`, interior `#fff1d6` |
| Carrete | tapas `#d9dde3`, centro `#8a8f9c`, hilo = color del filamento |

**Filamentos** (los 9 de `config.filament_colors`, no se inventan otros): blanco `#f2efe6`, negro `#2b2b33`, gris `#8a8f9c`, rojo `#e0453a`, naranja `#f28c28`, amarillo `#f5cf3c`, verde `#4cbf5a`, azul `#3b7fe0`, morado `#9b5de5`.

### 4.6 Personaje

| Parte | Hex |
|---|---|
| Piel / sombra de piel (orejas, nariz) | `#e9b48e` / `#dc9f7c` |
| Pelo | base `#5c341d`, medio `#7d4b2a`, pliegue `#3e2414`, brillo `#9a6238` |
| Buzo (gris carbón, no negro: ver §16) / puños y borde | `#3e4250` / `#2f323d` |
| Forro de la capucha y puntas de los cordones (acento cálido) | `#f0a63a` |
| Cordones | `#f4efe4` |
| Logo de tres capas en el pecho (sin marca) | `#38d6ff`, `#2fb3c9`, `#1f8fae` |
| Jeans / basta doblada | `#3d5c96` / `#5876b0` |
| Zapatillas / suela / franja | `#f4f1ea` / `#d9d2c4` / `#38d6ff` |
| Ojos: contorno / iris arriba → abajo / pupila / brillos | `#2a1a22` / `#5b3226` → `#c07a3e` / `#1d1226` / `#ffffff` |
| Cejas / boca / rubor | `#4a2a18` / `#7d3346` / `#ff8599` al 40 % |
| Contorno / contorno del pelo | `#1a1830` / `#2e180c` |

### 4.7 Luces y efectos

| Uso | Hex |
|---|---|
| Lámpara del escritorio | `#ffb05a` (halo `#ffb35c`) |
| Monitor | `#8fd0ff` (halo `#6fd3ff`) |
| Tira LED (solo de noche) | `#38d6ff` |
| LED de la cama de la impresora | `#cfeeff` |
| Guirnalda de focos | `#ffd27a` |
| Luna | `#9db4ff` |
| Capa caliente / corte de compra que se imprime | `#ff8a3d` / `#ff8030` |
| Vista previa de capas (compras que se imprimen) | `#38d0ff` |

### 4.8 Disciplina del cian

El cian `#38d6ff` es el color de la interfaz y significa **"esto se toca o se está construyendo"**.

1. **Cian saturado sobre el plano del piso = interacción.** Solo marcas de lugar libre, marco de cercanía, destino y las capas de vista previa de una compra que se imprime.
2. Acentos chicos fuera del piso, permitidos: logo y franja del personaje, pantallitas de impresora, tira LED de noche (arriba en la pared).
3. Nada de decoración cian cerca del piso. El borde de la base es azul apagado de día y apenas brilla de noche.

---

## 5. Geometría

### 5.1 Reglas

- **Una malla por objeto** (`KitMesh`), con color, oclusión y atributos por vértice, y **un solo material** (`kit`). Van aparte solo las partes que se mueven o cambian de material, porque son contratos: `Gantry`, `PrintHead/Carriage`, `Display`, `Spool/Filament`, `Monitor/Screen`, `PieceSpot/Piece`, `PieceSpot/Spaghetti`, `Tray0..5`, cajas y paquetes del despacho, puerta, y el cuerpo y la cabeza del personaje.
- **Biseles:** 15–25 % del lado menor, entre 4 y 30 mm. Plástico chico 3–8 mm, muebles 10–20 mm, cosas blandas 30–60 mm o superelipsoides. Paredes y piso planos (sus bordes, en el sombreador).
- **Cilindros:** 8 a 24 lados según el tamaño. Lo redondo que se ve de frente (tapas de carrete, ventiladores) lleva más lados y un perfil corto.
- **Escala real**, origen en la base y centrado, frente hacia **+Z**.
- **Detalle mínimo:** 1 cm. Lo más chico no se modela; se pinta o se omite.
- **Detalle según cuánto se repite** (`KitMesh.detail` multiplica los lados): impresora del piso 1,0; impresoras de mueble 0,6; versión lejana 0,35; escritorio 0,8; decoración 0,6; cuerpo del personaje 0,8; cabeza y pelo 1,1.
- **Formas del kit** (`game/world/look/kit_mesh.gd`): caja con bisel, cilindro con canto, torno (perfil girado), superelipsoide con estrechamiento, cápsula, tubo por curva (Catmull-Rom, para cables, filamento, cordones, espagueti), toroide con arco, disco, triángulo, planos (alfombras, marcas). Normales hacia afuera, sin triángulos degenerados ni valores no finitos.
- **Caché estática** por clave (modelo, variante, detalle, color): la comparten el cuarto, la tienda, los retratos y las pruebas. Nada se arma dentro de `_process`.
- **Si el primer armado en el teléfono pasa de 1 s**, las mallas se hornean a `.res` (§16) o se arman durante la pantalla de carga.

### 5.2 Presupuesto por objeto

| Objeto | Triángulos | Llamadas (con sombra) |
|---|---|---|
| Impresora del piso (detalle 1,0) | ≤ 2.400 | 9 |
| Impresora de mueble (0,6) | ≤ 1.200 | 6 (solo `Body` da sombra) |
| Impresora lejana (0,35, piezas móviles ocultas) | ≤ 450 | 3 |
| Escritorio completo | ≤ 4.000 | 3 |
| Mueble | ≤ 1.500 | 2 |
| Personaje (cuerpo + cabeza con pelo) | ≤ 8.000 | 6 (2 de color, 2 de sombra, 2 de contorno) |
| Cuarto (cáscara, ventana, puerta, base) | ≤ 2.500 | 5 |
| Toda la decoración | ≤ 9.000 | ≤ 7 |

### 5.3 MultiMesh

Un `MultiMeshInstance3D` (1 llamada) para: todos los halos, las motas de polvo, los destellos de "pieza lista", y los carretes de los estantes cuando pasan de 8. En el garaje (Fase 4): marcos de impresoras por familia a zoom lejos.

### 5.4 Decoración

- Vive en `Room/Decor`, **nunca** dentro de `Printer*`, `Furniture*`, `DispatchCorner` ni `RoomShell/Door` (agrandaría su zona de toque). Ningún nodo de decoración se llama `Printer*`, `Furniture*` ni `FreeSlot*`.
- Lo sólido del piso: solo en las zonas libres de §8.8, registrado como obstáculo (`grid.add_obstacle(rect.grow(0.05))`) **antes** de `grid.build()`.
- Distancia a la huella de un lugar de muebles: ≥ 0,15 m, y ≥ 0,30 m si mide más de 0,6 m de alto.
- Lo plano del piso (alfombra, felpudo, cables): ≤ 4 mm de alto; los cables nunca cruzan un lugar de muebles.
- Nada de decoración que parezca tocable: sin cian, sin brillo cerca del piso.

---

## 6. Luz y hora del día

### 6.1 Momentos

`DayCycle` (`game/world/look/day_cycle.gd`, nodo hijo de `Room`) escucha `Events.time_changed`, mezcla los dos momentos vecinos con `smoothstep` y empuja todo con `RenderingServer.global_shader_parameter_set`. Expone `sample(hora) -> Dictionary` (puro, con pruebas) y `set_hour(h)` para las capturas.

| Momento | Hora clave (se mantiene) |
|---|---|
| Alba | 05:45 |
| **Mañana (el inicio del juego)** | 07:00–10:30 |
| Mediodía | 12:30 |
| Tarde dorada | 16:30–18:00 |
| Atardecer | 19:15 |
| Noche | 20:15–05:00 |

### 6.2 Valores (espacio de pantalla; los dos niveles de calidad usan los mismos)

"Dirección" es hacia dónde **viaja** la luz.

| | Sol: dirección | Sol: color × energía | Ambiente arriba / abajo | Ventana: dirección | Ventana: color × fuerza | Relleno (+ personaje) |
|---|---|---|---|---|---|---|
| Alba | (0,60; −0,40; −0,70) | `#ffc4a6` × 0,28 | `#9490cc`×0,52 / `#b08a80`×0,40 | (0,74; −0,45; −0,50) | `#ffc4a0` × 0,35 | `#ffe8e0`×0,16 (+0,25) |
| **Mañana** | **(0,707; −0,566; −0,424)** | **`#fff0dc` × 0,48** | **`#bfcdf0`×0,62 / `#e6bb92`×0,50** | **igual que el sol** | **`#ffe2b0` × 0,85** | **`#fff4ea`×0,22 (+0,25)** |
| Mediodía | (0,22; −0,88; −0,42) | `#fff8ee` × 0,52 | `#bccaea`×0,68 / `#dcb594`×0,52 | (0,55; −0,80; −0,24) | `#fff6e6` × 0,45 | `#fff4ea`×0,18 (+0,25) |
| Tarde dorada | (0,60; −0,44; −0,66) | `#ffb874` × 0,56 | `#a597d0`×0,58 / `#e8a070`×0,52 | (0,86; −0,34; 0,38) | `#ffad5c` × 0,75 | `#ffe0c8`×0,16 (+0,25) |
| Atardecer | (0,66; −0,30; −0,69) | `#ff9078` × 0,22 | `#7c74b8`×0,52 / `#a2706a`×0,40 | (0,80; −0,30; 0,52) | `#ff8a7a` × 0,25 | `#e0d0ff`×0,18 (+0,35) |
| Noche (luna) | (0,50; −0,70; −0,50) | `#9ab0ff` × 0,18 | `#6a7ad0`×0,74 / `#5e4c78`×0,46 | (0,70; −0,62; −0,35) | `#9db4ff` × 0,30 | `#b8c4ff`×0,20 (+0,45) |

- **Mañana:** sol y ventana van en la misma dirección (elevación ~34°), así las sombras de los objetos corren paralelas a las rayas de las rejas. El parche cae en el piso delante del escritorio, cruza la impresora del piso y sube un poco por la pared del fondo cerca del rincón.
- **Tarde dorada:** se mantiene la del prototipo ganador a propósito: el sol tira las sombras de la planta sobre la pared del fondo y la ventana manda los rayos hacia la cámara. Es la mejor imagen de la competencia.

**Luces del sombreador por momento** (factor que multiplica a cada una):

| | Lámpara del escritorio | Monitor | Lámpara de la cama | Tira LED | LED de la impresora del piso | Guirnalda | Haz y polvo |
|---|---|---|---|---|---|---|---|
| Alba | 0,4 | 0,3 | 0,3 | 0 | 1 | 0,3 | 0,3 |
| Mañana | 0 | 0,12 | 0 | 0 | 1 | 0 | 1 |
| Mediodía | 0 | 0,12 | 0 | 0 | 1 | 0 | 0,6 |
| Tarde dorada | 0,25 | 0,3 | 0,2 | 0 | 1 | 0,2 | 1 |
| Atardecer | 0,75 | 0,4 | 0,6 | 0,6 | 1 | 0,6 | 0,2 |
| Noche | 1 | 0,5 | 1 | 1 | 1 | 1 | 0 |

**Valores base de cada luz** (con factor 1):

| Luz | Dónde | Color × intensidad | Alcance |
|---|---|---|---|
| `cc_pl0` lámpara del escritorio | marcador `LampBulb` del escritorio | `#ffb05a` × 1,4 | 3,3 m |
| `cc_pl1` monitor | marcador `ScreenGlow` frente a `Monitor/Screen` | `#8fd0ff` × 0,6 | 1,8 m |
| `cc_pl2` lámpara de la cama | marcador de la decoración (§8.8) | `#ffc070` × 1,0 | 2,6 m |
| `cc_pl3` LED de la impresora del piso | marcador `BedLight` de esa impresora | `#cfeeff` × 0,55 | 0,75 m |
| Tira LED | segmento (−2,1; 2,72; −2,96) → (2,6; 2,72; −2,96) | `#38d6ff` × 0,85 | 2,1 m |

Caída cuadrática, envoltura 0,3. Las luces del sombreador **alumbran todo lo que usa el kit, incluido el personaje y las impresoras**. Las otras impresoras no tienen luz propia sobre el entorno: tienen pantalla, LED y halo por estado (§9.2).

### 6.3 Parche de la ventana

- Se sigue el rayo desde el punto hacia la luz hasta el plano de la pared (x = −3,0). Si pasa por el hueco y no por una reja, el punto se ilumina. La penumbra crece con la distancia: `0,004 + t × 0,012` (más nítido que el prototipo).
- Hueco: z −1,80…−0,60, y 1,15…2,05. Rejas verticales cada 0,20 m (medio grosor 9 mm), un travesaño a media altura, el parante central de la ventana corrediza y el adorno de sol. **Las medidas salen de una sola constante (`WindowSpec`)** que usan la geometría y el sombreador.
- **Oclusión del parche** (lo pidieron los jueces): dos cajas (escritorio, a partir de las medidas del mueble del lugar 0, y la cama) y la cápsula del personaje (radio 0,22 m, alto 1,40 m). Si el rayo choca, el parche queda al 15 %. Primero se descarta el punto si el rayo no pasa por el hueco: casi todos los píxeles salen antes de probar las cajas.
- El haz de luz (`window_shaft`, 1 llamada) acompaña al parche con las mismas rayas.

### 6.4 Reglas de lectura

- **Noche en el teléfono con brillo bajo:** un gris medio (albedo 0,5) lejos de las luces debe verse ≥ 70/255 de luminancia. La captura de noche lo mide.
- **Personaje siempre legible:** el relleno de cámara tiene un refuerzo propio para el personaje (columna "+"), así nunca queda a contraluz ni se pierde de noche, y el contorno lo separa del piso.
- **El taller lleno de noche** se lee por las pantallas, LEDs, halos e interiores iluminados de cada impresora según su estado.
- **Transiciones** siempre mezcladas, nunca de golpe. Al cargar una partida, se aplica la hora sin mezcla.

---

## 7. Personaje

### 7.1 Proporciones (~3,2 cabezas, joven adulto lindo, no infantil)

| Medida | Valor |
|---|---|
| Alto total (punta del pelo) | 1,40 m |
| Cabeza con pelo | 0,44 m de alto; cráneo 0,36 × 0,38 × 0,34 m, centro a 1,15 m, mentón a 0,96 m |
| Hombros (pivotes) | y 0,90, x ±0,17 |
| Codo / muñeca | y 0,70 / 0,52 |
| Cadera (pivotes) | y 0,50, x ±0,08 |
| Rodilla / tobillo | y 0,27 / 0,075; suela gruesa de 2,5 cm |
| Torso | 0,34 de ancho en el pecho, 0,36 en el borde del buzo, 0,22 de fondo |

- El escritorio (0,75 m) le llega a la cintura, como en la referencia del dueño. La puerta (2,0 m) mide 1,4 veces el personaje.
- Mentón levantado 6° en reposo (`Head.rotation.x = −0,10`) para que la cámara alta vea la cara.
- `CharacterModel.HEIGHT = 1.40`. El globo de diálogo se ancla a un `Marker3D` nuevo `Body/Head/SpeechAnchor` (sigue saltos y gestos).

### 7.2 Esqueleto y contrato

- **Se mantienen los pivotes `Node3D` de hoy**, que son el contrato del controlador y de las pruebas: `HipL`, `HipR`, `Body`, `Body/Head`, `Body/ShoulderL`, `Body/ShoulderR`. Se agregan `HipX/KneeX` y `Body/ShoulderX/ElbowX`.
- El cuerpo es **una sola malla con piel** (`Skeleton3D`; verificado que funciona en Compatibility con `light()` propio y contorno). `RigFollower` copia cada cuadro la rotación de cada pivote al hueso correspondiente, después del animador, sin crear memoria. Las pruebas siguen leyendo los pivotes: **cero cambios en las pruebas del personaje**.
- Pesos: rígidos por parte, con anillos de mezcla de ±4 cm en rodillas, codos, hombros y caderas. Sin cortes ni "hombreras".
- El AABB de una malla con piel es el de reposo: la zona de toque no cambia con la pose (está bien). `extra_cull_margin = 0,3`.
- **Plan B** si la piel no queda bien en una sesión: segmentos rígidos con tapas en las articulaciones (ya probado), sin tocar el contrato.

### 7.3 Mallas

| Malla | Contenido | Material |
|---|---|---|
| `Body/Mesh` (con piel) | Piernas, zapatillas, torso con buzo, brazos, manos de mitón con pulgar | `kit_character` |
| `Body/Head/Mesh` (rígida, hija del pivote `Body/Head`) | Cráneo, orejas y pelo en la misma malla; el pelo va marcado por vértice para que no reciba la cara | `kit_head` |
| Contornos | Una `MeshInstance3D` por malla, misma malla, sin sombra | `outline_character` |

Total: 2 de color + 2 de sombra + 2 de contorno = **6 llamadas** (hoy 96).

### 7.4 Ropa

- **Buzo gris carbón** con capucha enrollada (toroide de 300°) y bulto atrás, **forro mostaza visible en el rollo**, cordones crema con puntas mostaza, bolsillo canguro, borde y puños acanalados, logo de tres capas cian en el pecho (sin marca).
- Jeans de azul medio con basta doblada. Zapatillas blancas gorditas con suela y franja cian.
- **Contraste de valores:** la luminancia de los jeans es ≥ 1,6 veces la del buzo; las zapatillas son lo más claro. Nunca azul marino sobre azul marino.

### 7.5 Cara

- Atlas pintado por código (`FacePainter`), pintado a 4× y reducido, **celdas de 128×128**, 8 expresiones: 0 normal, 1 parpadeo, 2 feliz (^ ^ y boca abierta), 3 preocupado (cejas arriba, boca "o"), 4 hablar A, 5 hablar B, 6 concentrado (ojos un poco entrecerrados, boca recta), 7 sorpresa y alegría (ojos grandes, sonrisa abierta). Canal alfa = máscara de los ojos.
- **Ojos grandes:** cada ojo ocupa 13 % × 20 % de la celda ≈ **4,9 × 6,0 cm**: ≥ 6 px de alto con zoom normal. Contorno tinta, iris que se aclara hacia abajo, pupila, **dos brillos blancos** fijos. Cejas gruesas y amables 2 cm sobre los ojos, nariz apenas marcada, boca chica, rubor.
- **Proyección cilíndrica** alrededor del eje vertical de la cabeza (`u = 0,5 + atan(x, z) / 120°`), centrada a media altura del cráneo, un poco bajo el ecuador. A 3/4 los ojos siguen la curva de la cabeza: **nunca un solo ojo en el borde**.
- **Mirada:** la cabeza gira como mucho 20°; el resto lo hacen las pupilas (`instance uniform vec2 gaze`, hasta ±3 % del ancho de la cara dentro de la máscara de los ojos).
- El flequillo termina ≥ 1 cm sobre las cejas. La cara queda siempre en la banda de luz gracias al relleno de cámara.

### 7.6 Pelo

- **Una sola superficie continua** (`HairKit`, idea de Pixel HD): un casquete deformado con **6 a 8 mechones grandes y redondos**, un flequillo de 4 lenguas redondeadas barrido hacia un lado, 3 mechoncitos sueltos en la coronilla (nada de corona de puntas), patillas y nuca.
- Color por vértice: base, brillo pintado en lo alto de cada mechón, pliegues oscuros, borde inferior en sombra.
- Se revisa **de frente, de perfil, de espalda y desde arriba** (capturas 32a–32d): nunca "piña", "alcachofa", "piedras" ni "coliflor".
- Sin normales nulas ni puntos no finitos (prueba).

### 7.7 Animación por capas

`CharacterAnimator` (nuevo, `game/world/character/character_animator.gd`) es el **único que escribe** las rotaciones de los pivotes, justo después del controlador en `RoomView.step()`. Todo con arreglos reservados al inicio (nada de memoria en `_process`), azar con semilla propia y `freeze_idle` para las capturas.

1. **Locomoción** (a 2,2 m/s es un trote suave): zancada 0,75 m (`ControlsTuning.stride_length` 0,55 → 0,75), piernas ±0,40 rad, rodilla hasta 1,0 rad en el paso, codos ~1,1 rad, brazos ±0,5, balanceo de cadera 0,05, giro de hombros 0,08, rebote 0,04, inclinación 0,12 × velocidad (y ≤ 0,05 cuando choca: prueba existente), anticipo al arrancar y asentarse al frenar (0,1 s).
2. **Quieto:** respiración por escala del pecho (1 → 1,015, 0,35 Hz); cambio de peso solo en `Body` (`HipL.rotation.x` queda en 0 exacto: prueba existente); parpadeo cada 2,4–5 s (0,12 s); **después de 2 s quieto y sin objetivo, gira a 3/4 hacia la cámara** (giro 45° ± 20°); mirada a lo cercano ≤ 20° más pupilas; tras 8 s, gestos sueltos con semilla (mirar el celular, estirarse, rascarse la cabeza, mirar el cabezal de la impresora).
3. **Gestos** (de una vez, mezcla 0,12 s, nunca bloquean nada, se cancelan al caminar).
4. **Expresiones:** celda del atlas y temporizadores. Hablar alterna 4/5 a 8 Hz mientras se ve el globo.
5. **Movimiento secundario:** resorte en el pelo (≤ 6°), cordones, rebote de capucha.
6. **Estirar y aplastar** con la escala del hueso raíz al saltar y aterrizar. Respeta "reducir movimiento" cuando exista.

### 7.8 Reacciones a eventos

| Evento | Reacción (siempre cosmética, nunca obligatoria) |
|---|---|
| `order_delivered` | Feliz 2,6 s + puño arriba 0,8 s. Si llegó tarde: se rasca la cabeza, cara normal |
| `print_failed` | Mira a esa impresora, manos a la cabeza 1,2 s, preocupado 3,2 s (lo pide RUTA §6) |
| `level_up` | Salta con estirar y aplastar 0,9 s, sorpresa → feliz 3 s |
| `offer_arrived` | Saca el celular y lo mira 1,6 s (solo si está quieto y sin panel abierto) |
| `printer_changed` → lista, a ≤ 1,2 m | Pulgar arriba 0,8 s, feliz 1,5 s |
| Empieza a modelar y está a ≤ 1,2 m del escritorio | Cara concentrada mientras modela |
| Toque sobre el personaje | Saluda con la mano, feliz 1,2 s |
| Acción rápida que falla | Se encoge de hombros 0,7 s |
| Embalar o despachar cerca del rincón | Gesto de embalar 0,6 s |
| De noche (≥ 22:00), quieto > 8 s | Bosteza (máximo una vez por hora de juego) |

### 7.9 Retratos

- **Tarjeta del HUD** (`profile_card`): objetivo (0; 1,15; 0), tamaño 0,62, giro 20°. **Tiene su propia luz** de estudio (llave cálida arriba-izquierda, relleno frío, borde): la cara nunca queda oscura ni tapada. Se vuelve a dibujar cuando cambia la expresión importante (feliz al cobrar, preocupado al fallar).
- **Pantalla de perfil:** cuerpo entero, objetivo (0; 0,72; 0), tamaño 1,65.

---

## 8. El cuarto

### 8.1 Medidas que no cambian

Piso 6 × 6 m (x y z de −3 a +3), paredes de 2,8 m y 0,2 m de grosor, solo dos paredes (izquierda x = −3 y fondo z = −3), lados +X y +Z abiertos, sin techo. Lugares de muebles, lugar de la impresora del piso, rincón de despacho, punto de partida, paso de la puerta y llegada de cajas: **idénticos** (ver `understand_models.md` §2 y §6.2).

### 8.2 Base impresa

- La sala se apoya en una losa de 0,30 m de grosor **impresa en PLA** `#56689a`, con capas de 2,4 cm a la vista y un borde de primera capa ("brim") de 4 cm alrededor. Los cortes de las paredes (arriba) muestran capas de 1,2 cm.
- Sombra suave bajo la base sobre el fondo (1 llamada).

### 8.3 Piso

- Baldosa cerámica cálida de 0,40 m en damero muy suave, junta clara, variación por baldosa, bisel de 6 mm: todo en el sombreador sobre un plano (una malla, ninguna baldosa inflada).
- El piso es claro a propósito: impresoras, muebles y personaje se recortan encima.

### 8.4 Paredes

- Pared de la ventana verde salvia claro, pared del fondo crema cálida, pintura con ruido muy leve.
- Zócalos crema de 0,10 m con bisel. Interruptor con canaleta blanca a la vista que sube hasta el borde, enchufe con regleta en el piso.

### 8.5 Ventana y vista

- **Hueco real** en la pared (z −1,80…−0,60; y 1,15…2,05), marco de **aluminio corredizo de dos hojas**, alféizar de baldosa, **rejas de hierro por fuera con un adorno de sol** (círculos), cortina mostaza recogida a los lados con balanceo leve.
- La vista (`window_view.gdshader`) es una pintura procedural **recortada al hueco** (cada fragmento se proyecta hacia atrás por la vista; nada se sale por encima de la pared): cielo y nubes, cerros verdes con casitas de colores que trepan, una torre de iglesia, edificios bajos, y en primer plano **la azotea del vecino con un tanque de agua negro sin logo, varillas "para el segundo piso", ropa tendida, una buganvilla magenta y un poste con cables enredados** que cruzan la vista. De noche: estrellas, luna y ventanas encendidas.
- En el alféizar: suculenta en una lata, barquito de prueba naranja, maceta impresa y una alcancía de monedas.

### 8.6 Puerta

- Puerta de madera de dos tableros con manija de latón y marco crema. Sigue siendo `RoomShell/Door` con **la misma zona de toque** (x −3,0…−2,855; z 1,6…2,6; y 0…2,0).
- Felpudo dentro del paso de la puerta (plano).

### 8.7 Marcas del piso

| Marca | Forma | Material |
|---|---|---|
| Lugar libre (`FreeSlot0..5`, exactamente 5 en una partida nueva) | **Cuatro esquinas** en L (brazos de 0,18 m, 3 cm de ancho) y un "+" de 0,14 m, una malla compartida | Cian, alfa 0,22 ↔ 0,35 latiendo cada 1,2 s. **Se encienden (0,55 ↔ 0,85)** cuando el personaje está a ≤ 1,2 m o la tienda está abierta |
| Objeto cercano (`HighlightFrame`) | Marco de esquinas de 3 cm alrededor de la huella + 0,12 m | Cian 0,8 ↔ 0,45 cada 0,6 s |
| Destino al tocar el piso | Aro de 0,18 m | Cian 0,6, crece y se desvanece en 0,45 s |

Alturas de siempre (0,006–0,018 m). La zona de toque de cada lugar libre no cambia.

### 8.8 Decoración (todo en `Room/Decor`)

**Piso, sólido (obstáculo):**

| Objeto | Dónde (x, z en m) | Alto | Notas |
|---|---|---|---|
| Librero alto contra la pared del fondo | x −2,95…−2,45, z −3,00…−2,66 (rincón F1) | 1,80 | Libros, cajas con etiqueta sin letras, jarrón en espiral impreso, dragón articulado, potus colgando arriba |
| Costilla de Adán en maceta de barro | centro (−2,70; −2,25), maceta Ø 0,40 (F1) | 1,35 | Hojas con balanceo |
| Basurero de impresiones fallidas | centro (−2,80; −0,30), Ø 0,30 (F5) | 0,40 | Espaguetis de colores saliendo y un barquito a medias en el piso al lado (plano) |
| Pila de cajas de filamento (nivel 5+) | x 2,75…2,97, z −2,95…−2,60 (F4) | 0,45 | — |
| **Cama** de una plaza | x 1,95…2,90, z −1,85…0,15 (borde +X, cabecera hacia el fondo) | 0,45 (cabecera 0,75) | **Cobija de tigre desaturada** doblada sobre el 60 %, sábana, almohada, dragón articulado morado impreso, repisa en la cabecera con la **lámpara de la cama** (`cc_pl2`, foco en (2,45; 0,85; −1,80)) y un celular que brilla de noche |
| Puf con un control de videojuegos | centro (2,50; 0,75), Ø 0,65 | 0,45 | Zapatillas sueltas al lado |

La cama y el puf están fuera de las zonas F1–F5 de la tabla original, pero en el borde abierto +X, a más de 0,3 m de los lugares 4 y 5 y lejos de todos los puntos que usan las pruebas (0,8; 0,2), (1,0; 1,6), (0,3; 0,2), el punto de partida y el camino del joystick. Así el cuarto se llena sin quitar piso de crecimiento.

**Piso, plano (sin obstáculo, ≤ 4 mm):**

| Objeto | Dónde |
|---|---|
| Tapete andino tejido con flecos | centro (−0,10; −0,05), 2,4 × 1,2 m |
| Felpudo | (−2,55; 2,10), 0,6 × 0,4 |
| Cable de la impresora del piso al enchufe | por el hueco F2 (x −0,60) hasta la pared del fondo |
| Cable del escritorio a la regleta | a lo largo de la pared izquierda hasta F5 |
| Baldosa de concreto bajo la impresora del piso | 0,54 × 0,50 × 0,035 m, sigue al lugar de la impresora del piso (25°). La impresora se apoya encima (el lugar sube 0,035 m) |

**Pared del fondo (z = −3,0):**

| Objeto | Dónde |
|---|---|
| Tres pósters inventados (atardecer en los cerros; boquilla imprimiendo un barquito; teleférico sobre el valle), 0,42 × 0,58 m | friso, y 1,98…2,56, en x −1,45 / 0,25 / 1,95 |
| Guirnalda de focos (14 focos, con halos de noche) | friso, y ≈ 2,55, colgando entre 5 anclajes |
| Tira LED | y 2,72, de x −2,1 a 2,6 (solo se enciende de noche) |
| Bufanda de un club de fútbol inventado | friso, centro x 1,10, y 2,30, 0,9 × 0,16 |
| Reloj de pared verde azulado Ø 0,26 | hueco 2|3 (x −0,60), y 1,55 |
| Enchufe para la impresora | hueco 2|3, y 0,30 |
| Calendario de la tienda del barrio | hueco 3|4 (x 1,10), y 1,45 |
| Diploma enmarcado | extremo derecho (x 2,82), y 1,55 |

**Pared de la ventana (x = −3,0):**

| Objeto | Dónde |
|---|---|
| Corcho con fotos y notitas; foto familiar enmarcada encima | sobre F1: z −2,85…−2,00, y 1,35…1,85; foto y 2,10…2,45 |
| Barra y cortina | y 2,20, de z −2,00 a −0,40 |
| Plano de una impresora (dibujo técnico) | sobre la barra, y 2,30…2,62 |
| **Guitarra colgada** | hueco 0|1: centro z −0,25, y 1,0…2,05 |
| Interruptor y canaleta | hueco 0|1, y 1,15 |
| **Repisa de las primeras impresiones**: barquito de prueba, cubo de calibración con X/Y/Z en relieve, **gatito que brilla en la oscuridad** (halo de noche), dragón articulado, jarrón en espiral | sobre el lugar 1, y 2,05, 0,9 × 0,16 |
| Banderín de un club inventado | sobre la puerta, y 2,35 |

**La decoración crece con el nivel** (pilar 1), solo con cosas de pared y estante, para que la grilla de caminar nunca cambie:

| Nivel | Qué cambia |
|---|---|
| 1–2 "Recién empiezo" | Silla de caja de cartón con cojín; repisa de primeras impresiones con 2 piezas; corcho con 2 notas; basurero medio lleno |
| 3–4 "Ya vendo" | Repisa completa (5 piezas); más notas y fotos; billete enmarcado de la primera venta (rectángulo verde, sin texto) |
| 5+ "Taller" | Pila de cajas de filamento en F4; placa enmarcada; tira LED encendida de noche |

### 8.9 Vida

- Motas de polvo en el haz de la ventana de día (40, `MultiMesh`, fases con semilla, movidas por `cc_anim_time`; solo nivel Alto).
- Balanceo de plantas y cortina por vértice. Pantallas animadas. Guirnalda que parpadea suave de noche.

### 8.10 Fondo

Un cuadro pegado a la cámara (1 llamada) con el degradado de §4.1, un resplandor detrás del diorama (viñeta suave incluida, sin pasada de pantalla completa) y ruido contra bandas.

---

## 9. Impresoras

### 9.1 Contrato común

- `PrinterModel.build(parent, nombre, id, spool_hex)` igual que hoy.
- Hijos: `Body` (malla unida), `Display` (pantallita; su material lo cambia la vista con `WorldPalette.glow("ffffff", estado)`), y los que crea `PrinterView`: `PieceSpot` con `Piece` (`BoxMesh`) y `Spaghetti` (oculto), `Tray0..5`.
- Abiertas: `Bed` (marca el modo abierto), `Gantry`, `PrintHead` (con `Carriage`), `Spool/Filament`.
- **Marcadores nuevos** que `PrinterView` lee en vez de números fijos: `PieceAnchor`, `HeadRest`, `HeadPark`, `TrayAnchor`, `BedLight`. En Cubo Uno valen exactamente lo que hoy dicen `BED_TOP`, `PIECE_Z`, `HEAD_REST_Y`, `HEAD_PARK_X` (las pruebas comparan con esas constantes).
- **Alto máximo de toda impresora: 0,72 m** (con su carrete), para que quepa en la estantería (§10). Ancho de Cubo Uno entre 0,40 y 0,50 m (prueba).
- Pantallita por estado (procedural): libre cian tenue, imprimiendo cian con barra animada, lista verde con ✓, falla roja con "!" que parpadea a 1 Hz.

### 9.2 Estado de noche por impresora

Pantallita brillante + LED de la cama (abiertas) o interior iluminado (cerradas) + **halo en el piso** del color del estado (`MultiMesh` compartido, × `cc_night`): imprimiendo cálido, lista verde, falla rojo. Así se lee el taller lleno de noche.

### 9.3 Las siete familias (la silueta las distingue antes que el color)

| Familia | Silueta y detalles | Cómo se ve la pieza y la falla |
|---|---|---|
| **Cubo Uno** "la clásica" (tipo Ender) | Cama móvil con dos postes Z de perfil de aluminio con ranura; cama PEI dorada con perillas amarillas; boquilla de latón; tubo PTFE en arco; caja de control con pantallita abajo a la derecha; acento azul en el ventilador; carrete de tapas abiertas arriba. **En el piso:** sobre la baldosa de concreto, con su cable al enchufe | Pieza en la cama, cabezal que va y viene y sube con la pieza; espagueti sobre la cama |
| **Rayo Mini** "la compacta" (×0,82) | Voladizo: una columna Z a la izquierda, cama cuadrada chica, cabezal redondo con aro verde, **carrete en un soporte aparte a la derecha**; achatada | Igual que Cubo Uno |
| **Rayo X1** "la rápida" | Voladizo más alto, cama grande, barra de luz LED en la columna, **carrete arriba de la columna**, pantalla táctil en un brazo al frente a la derecha | Igual |
| **Prisma MC** "la multicolor" | Cuerpo de Rayo X1 con acento morado + **caja de color con 4 carretes** visibles bajo tapa, en un soporte a la izquierda (sin chocar con nada), 4 tubos que se juntan, rampa de purga con un montoncito de purga de 4 colores | Igual |
| **Bóveda P1** "la cerrada" | Cubo grafito de esquinas redondeadas, puerta de vidrio (solo marco y un reflejo diagonal, sin transparencia), **interior iluminado cálido**, cabezal arriba adentro, carrete atrás | **La pieza crece adentro y se ve por la puerta**; la falla muestra el espagueti adentro y el interior pasa a rojo |
| **Gota R1** "la de resina" | Base negra con pantallita, **tapa ámbar transparente** (1 llamada extra, sin sombra), placa en un riel Z, tina abajo | **La pieza cuelga bajo la placa y crece hacia abajo** mientras la placa sube; en la falla la pieza cae a la tina inclinada |
| **Titán Pro** "la grande" (×1,3) | Gabinete grande grafito con naranja, **dos boquillas** visibles por la ventana, caja de colores integrada arriba (escalada con el cuerpo), pantalla ancha | Pieza adentro, como Bóveda |

### 9.4 Carrete

Tapas abiertas (aro + 4 rayos) gris claro un 10 % más grandes que el bobinado; el bobinado es del color del filamento con surcos de enrollado (capas). `Spool/Filament` va aparte (su material cambia). En los estantes, el eje paralelo a la pared: siempre se ve la banda de color, nunca un "disco negro".

### 9.5 Pieza, bandeja y fallos

- `PieceModel.SIZES` de hoy (S 0,12 × 0,14 × 0,12; M 0,18 × 0,20 × 0,18; L 0,24 × 0,26 × 0,24). Sigue siendo `BoxMesh` (contrato de 6 pruebas), con capas de 1 cm y capa caliente.
- **Crece de a `PieceModel.LAYER_STEP` = 0,01 m** y nunca baja (reemplaza "un píxel de pantalla").
- **Lista:** salta (como hoy) y suelta 3 destellos sumados durante 0,6 s (`MultiMesh`).
- **Espagueti** (`PieceSpot/Spaghetti`, idea de Pixel HD): un nido de 11 rulos y 2 hebras que suben hasta la boquilla, del color del filamento × 1,1, tubo de 4 mm; una malla, oculta si no se usa. Más grueso y brillante que el del Diorama: se lee sin abrir el panel.
- **Warping:** la pieza se inclina 12° y se le levanta una esquina; pantallita roja; cara preocupada.
- Pieza fallida: `WorldPalette.solid(FAILED_PIECE)` (contrato).
- Bandeja `Tray0..5`: bloquecitos con capas, del color del trabajo, al frente de la impresora.

---

## 10. Muebles, despacho y paquetes

`FurnitureModel.build(parent, nombre, id)` igual que hoy, con un parámetro opcional nuevo `wall_gap: float` (distancia a la pared del lugar; −1 = no hay pared). Los anclajes `PrinterSpot0..N` siguen siendo `Marker3D`.

| Mueble | Cómo se ve | Contrato y medidas |
|---|---|---|
| `mesa_computador` (inicial, no se vende) | Escritorio viejo de madera con cajonera de 3 cajones; **monitor de tubo beige** con papelito amarillo y LED verde; torre con bahías; teclado con teclas; ratón con alfombrilla; **lámpara articulada amarilla**; taza roja; portalápices impreso; bocetos, cuaderno y calibrador; cables a la regleta; **caja de cartón como silla con un cojín** (el comienzo humilde) | `Monitor/Screen`; marcadores nuevos `LampBulb` y `ScreenGlow`; **misma huella** (x ±0,65, z −0,41…0,81 local; arriba 1,15) |
| `mesa_auxiliar` | Mesita blanca de melamina con canto visible, patas cuadradas | 0,60 × 0,50 × 0,55; `PrinterSpot0` a 0,50 |
| `mesa_trabajo` | Banco de madera clara con cajonera metálica y repisa baja con cajas organizadoras | 1,30 × 0,80 × 0,60; `PrinterSpot0/1` a 0,80 |
| `estanteria_metalica` | **2,40 m**, postes negros, **4 tablas de madera** (y 0,08 / 0,85 / 1,62 / 2,37), amarras de cables | `PrinterSpot0..2` a 0,095 / 0,865 / 1,635: **0,74 m libres por nivel**, todas las familias caben (arregla las impresoras que atravesaban las tablas) |
| `repisa_filamento` | Dos tablas con 6 carretes de colores. **Pegada a la pared** en los lugares con pared; en el lugar 5 (sin pared) lleva **un pie propio** | Arregla que flotaba |
| `estanteria_cubos` | Mueble blanco de 2×2 cubos con carretes que muestran su color | 0,80 × 1,50 × 0,55 |
| `panel_herramientas` | Tablero perforado con alicates, calibrador, llaves Allen, espátula y cortafríos, ganchos impresos naranja. Pegado a la pared, con pie en el lugar 5 | — |

**Rincón de despacho** (`DispatchCornerModel`): mesita de embalar con dispensador de cinta, cúter y etiquetas, cartones planos y un rollo de plástico de burbujas debajo; **guacal de madera** (cajón de listones) con relleno de papel triturado como cajón de salida. **Huella exacta** (x −1,885…−1,0; z 2,42…2,82: la prueba la fija), `PackSpot0..2` y `OutSpot0..2` como `Marker3D`.

**Paquetes** (`PackageModel`): caja de cartón corrugado con cinta y etiqueta blanca (un ícono azul oscuro, sin texto). **Caja abierta** con solapas abiertas y la pieza adentro (`Piece`, teñida).

---

## 11. Interfaz

- **El tema no cambia** (azul marino y cian combinan con este mundo: los jueces lo confirmaron). Los nombres de `UiPalette`, las variaciones de tema y la estructura del HUD quedan igual.
- **Vistas 3D de la tienda y paneles** (`ModelPreview`): resolución alta (misma lógica `k` que el mundo), MSAA 4×, fondo transparente, inclinación −30° (igual que el mundo), materiales del kit con `preview_light = 1` (luz de estudio fija) y un sol con o sin sombra **igual que el nivel del mundo** (para que valga la misma cuenta de color). Detrás de cada vista, en 2D, un disco de luz radial `#2a3a66` → transparente para que los muebles oscuros se lean sobre el azul.
- **Retratos:** ver §7.9.
- **Lo que no se toca ahora:** paneles translúcidos, tinte de noche del HUD, plegar el panel de Objetivos (es diseño; ver §16).

---

## 12. Firma

1. **Crece capa a capa.** La pieza sube de a 1 cm con capas a la vista y una **capa caliente** naranja que se ve en cualquier zoom; al terminar, salto y destellos. Es "el detalle visual más importante" del GDD §8.
2. **Las compras se imprimen.** Cuando aparece un mueble o impresora nueva (`RoomView.sync_models()`), se le pone `kit_reveal` mientras dura: debajo del corte, sólido con la línea caliente `#ff8030`; por dentro (caras traseras) se ve el relleno en cuadrícula; **encima, solo las capas que faltan en cian** como la vista previa del programa de impresión. Muebles 1,6 s, impresoras 1,2 s; un toque lo termina al instante. Al final vuelve el material normal (el `discard` no se paga después).
3. **Mundo impreso.** La base y los cortes de pared tienen capas; las figuritas, macetas y portalápices impresos también. Paredes, telas y madera, no.
4. **La hora se siente.** Mañana con sol entre rejas, tarde dorada con rayos, noche lo-fi con lámpara, monitor y tira LED.
5. **Fallos que se leen.** Nido de espagueti del color del filamento, pantallita roja y el personaje con las manos en la cabeza.

---

## 13. Presupuesto

Medido con el contador sin pantalla (`tests/helpers/scene_budget.gd`, que coincide con los contadores de OpenGL) en la prueba `test_scene_budget.gd`:

| Escena | Llamadas de dibujo | Triángulos visibles | Triángulos con la pasada de sombra | Materiales | Luces |
|---|---|---|---|---|---|
| Cuarto inicial | **≤ 70** (meta 45) | ≤ 45.000 | ≤ 80.000 | ≤ 16 | 1 `DirectionalLight3D` con sombra, **0** omni/spot |
| 16 impresoras (5 estanterías + piso) | **≤ 200** (meta 150) | ≤ 60.000 | ≤ 100.000 | ≤ 18 | igual |
| Garaje de 40 (Fase 4, estimado) | ≤ 350 | ≤ 70.000 | ≤ 100.000 | ≤ 20 | igual |

Hoy: 333 y 1.204 llamadas. Otras metas: ≤ 15 mallas que dan sombra y ≤ 12 superficies transparentes en el cuarto inicial; armar la escena principal con las mallas en caché ≤ 40 ms sin pantalla; primer armado ≤ 400 ms en escritorio (si en el teléfono pasa de 1 s, hornear); **0 asignaciones de memoria en `_process`**.

**Cómo se llega:** una malla por objeto, un material compartido, sin contorno en el mundo, contorno del personaje sin sombra, impresoras de mueble con solo `Body` dando sombra, `MultiMesh` para halos, polvo y destellos, versión lejana de las impresoras a zoom lejos (piezas móviles ocultas: los nodos siguen existiendo), mapa de oclusión del piso en textura.

Hay que **medirlo en el teléfono del dueño** (panel de depuración en la versión web con fps, llamadas por cuadro, nivel de calidad y resultado de `ColorProbe`).

---

## 14. Lo que NO se hace ahora

- Glow del entorno, SSAO, SSR, profundidad de campo o desenfoque de maqueta, niebla volumétrica, Decals, LightmapGI, ReflectionProbe.
- Luces del motor extra (`OmniLight3D`, `SpotLight3D`), salvo que el dueño apruebe la excepción de §16.
- Contorno por posproceso de profundidad; contorno en el mundo.
- Sol "físico" que entra por el hueco con sombra de paredes (se probó: deja medio cuarto en sombra y desaparece en el nivel Bajo).
- Compensación de color escrita a mano en `light()`.
- La cáscara y distribución del garaje (Fase 4): solo los ganchos de nivel de detalle y el presupuesto.
- Piezas con forma real (llavero, perilla): se queda la caja; el acceso `PieceModel.shown_height()` queda listo.
- Personajes secundarios (Don Ernesto), retratos de clientes, mascotas, palomas, clima en la ventana, decoración de afuera del cuarto.
- Rediseño del HUD o nuevas fuentes. Sonido.
- Modelos de terceros, glTF o Blender.
- Papel picado como decoración permanente (es muy mexicano para la ciudad inventada; quizá como evento de temporada).
- Muebles que caen al comprarse ("unboxing", RUTA Fase 2).

---

## 15. Lista para agregar algo nuevo al mundo

1. ¿Es una sola malla del kit con el material `kit` (o una variante cacheada de `WorldPalette`)? ¿Respeta el presupuesto de §5.2?
2. ¿Escala real, frente +Z, base en y = 0, biseles según §5.1, sin detalles menores a 1 cm?
3. ¿Sus colores salen de §4? ¿Respeta la disciplina del cian?
4. Si fue impreso en la historia, ¿tiene `UV2.x` con su alto de capa?
5. Si es decoración: ¿está en `Room/Decor`, en una zona libre, registrada como obstáculo antes de `grid.build()`, lejos de los lugares de muebles?
6. ¿Se ve bien en la mañana y en la noche, con zoom lejos y cerca, en nivel Alto y Bajo? (capturas 30, 35, 02, 03)
7. ¿La prueba de presupuesto sigue en verde?
8. ¿Sin marcas reales ni texto legible?

---

## 16. Decisiones del dueño

| # | Decisión | Por qué hay que preguntar | Si no aprueba (opción segura) |
|---|---|---|---|
| D1 | **Dejar el pixel art** por "Mundo Impreso" (cambia GDD §8 y `docs/ESTILO.md`) | CLAUDE.md: cambiar el diseño del GDD | Se implementa "Pixel HD" (prototipo en `design_pixelhd`); se mantienen los pasos compartidos: guardas, personaje, pelo, espagueti, estantería, decoración y día/noche |
| D2 | **Hasta 2 `OmniLight3D` sin sombra** de noche (lámpara y monitor), 0 llamadas extra | CLAUDE.md: "una luz direccional más luz ambiental" | **No se agregan**: luces calculadas en el sombreador (ya alumbran al personaje). Es la opción por defecto |
| D3 | **Personaje rediseñado**: 1,40 m (~3,2 cabezas), cara nueva, buzo gris carbón con acento mostaza en vez de negro | GDD §3 describe "buzo negro" | Buzo casi negro `#30333e` con los mismos acentos (se pierde algo de lectura de noche) |
| D4 | **Hornear mallas** a `.res` (archivos generados en el repositorio) si el primer arranque en el teléfono pasa de 1 s | Agrega archivos generados | Armar las mallas durante la pantalla de carga, con caché |
| D5 | Estantería metálica de 2,40 m y pie propio para repisa y tablero en el lugar 5 | Cambia medidas de muebles del diseño | Se aplica igual (arregla dos errores visibles); solo se informa |
| D6 | Decoración del dormitorio (cama, puf, tapete…) y que crezca con el nivel | Agrega elementos al diseño | Se aplica (el dueño pidió agregar todo lo pertinente); solo se informa |
| D7 | Opción "Calidad gráfica" visible en Ajustes | Agrega una opción de interfaz | Solo modo automático, con cambio manual en el panel de depuración |
| D8 | Adelantar a esta fase el día y la noche visual y las reacciones del personaje (RUTA Fase 2) | Orden de fases | Solo lo visual: nada de menos pedidos de noche ni otros cambios de juego |

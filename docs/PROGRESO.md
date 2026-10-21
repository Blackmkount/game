# Progreso

## Estado actual

- **Fase actual:** 1. Simulación, en curso. Por pedido del dueño se adelantó el estilo visual de la Fase 2.
- **Diseño:** GDD versión 2.1 y guía de estilo en `docs/ESTILO.md`.
- **Siguiente paso:** tarea 3 de la Fase 1, tienda y envíos: que el botón "Comprar" funcione. La tarea 2 quedó adelantada en parte (estado, reloj y niveles); le falta el azar reproducible, que se completa cuando haga falta en la tarea 5.

| Fase | Estado |
|---|---|
| 0. Base | Completada (2026-10-21) |
| 1. Simulación | En curso: tarea 1 terminada, tarea 2 en parte |
| 2. Prototipo gris | Adelantado: estilo visual, habitación inicial, HUD y pantallas de solo lectura |
| 3. MVP completo | Sin empezar |
| 4. Móvil y pulido | Sin empezar |
| 5. Publicación | Sin empezar |

### Plan de la Fase 1

Cada tarea termina en un PR.

| # | Tarea | Estado |
|---|---|---|
| 1 | Diseño v2 en el GDD, datos de balance en `data/*.json` y su validación | Terminada |
| 2 | Estado del juego y reloj: dinero, inventario, impresoras, muebles, nivel, calendario, `advance()` y azar reproducible | En parte: falta el azar reproducible |
| 3 | Tienda y envíos: comprar impresoras, materiales, accesorios y muebles, días de envío, envío exprés, ferretería, almacenamiento y desbloqueo por nivel | Pendiente |
| 4 | Pedidos: tablero limitado que se renueva, aceptar y rechazar, plazos | Pendiente |
| 5 | Imprimir y entregar: reglas de asignación, pieza por pieza, cobrar, experiencia y subir de nivel. Prueba de que un paso grande da lo mismo que muchos pequeños | Pendiente |
| 6 | Fallos y accesorios: espagueti, warping, fin de filamento, limpiar y reintentar, rescate de Don Ernesto | Pendiente |
| 7 | Progreso fuera del juego (8 h, reloj que retrocede, resumen), avance de los objetivos y prueba de rendimiento | Pendiente |
| 8 | Simulador `tools/simulate.sh`: 7 días con un jugador automático y su informe | Pendiente |

Cada tarea conecta su lógica con la interfaz que ya existe. Por ejemplo, la tarea 3 activa el botón "Comprar" y hace aparecer en la habitación los muebles comprados.

---

## Historial

### 2026-10-21 — Fase 0: Base

**Qué se hizo**
- `GDD.md` movido a `docs/`.
- Godot 4.7.2-stable fijado en `.godot-version`.
- Scripts `tools/setup_godot.sh`, `tools/check.sh`, `tools/run_tests.sh` y `tools/export_web.sh`, probados en el entorno de Claude.
- Proyecto Godot "Capa a Capa": renderizador Compatibility, vertical 720×1280 con escalado adaptable, advertencia de declaraciones sin tipo como error, compresión ETC2/ASTC activada.
- Estructura de carpetas de `CLAUDE.md`, con `.gdignore` en `docs/` y `tools/`.
- Autoloads vacíos `Events`, `SaveManager` y `Game`, con comentarios de lo que harán.
- `localization/translations.csv` (es, en) registrado en el proyecto.
- GUT 9.7.1 en `addons/gut/`. Pruebas: `tests/unit/test_localization.gd` (traducciones completas y cargadas) y `tests/integration/test_test_scene.gd` (la escena carga y el botón cambia el color).
- Escena de prueba `game/scenes/test_scene.tscn`: cuarto de cajas, impresora de formas básicas con el cabezal moviéndose, cámara isométrica fija, una luz direccional, luz ambiental y un botón que cambia el color de la impresora.
- `.gitignore`, `.gitattributes` y `README.md`.
- Integración continua: `validate.yml` (revisión y pruebas en cada push y PR) y `web.yml` (exportación web y publicación en GitHub Pages en cada push a `main`).
- Preset de exportación Web en `export_presets.cfg` (Android e iOS se agregan en la Fase 4).

**Verificado**
- `check.sh` y `run_tests.sh` pasan (5 pruebas). Se comprobó que ambos fallan si se introduce un script con errores o sin tipos, o una prueba que falla.
- La exportación web funciona y la escena carga en un Chrome que simula un teléfono Android: se ve en español y el botón cambia el color al tocarlo.

**Ajustes después de fusionar (mismo día)**
- El dueño hizo público el repositorio para poder usar GitHub Pages gratis (ver `docs/DECISIONES.md`).
- La primera ejecución de "Versión web" en `main` exportó bien; la publicación se saltó porque Pages aún no estaba activado.
- Se agregó `docs/PROMPTS.md` (mensajes para trabajar con Claude), el enlace a la versión web en `README.md` y `tools/export_web.sh` a la tabla de scripts de `CLAUDE.md`.
- El dueño activó GitHub Pages. La versión web quedó publicada en https://blackmkount.github.io/game/ y **el dueño confirmó que funciona en su teléfono**. Con eso se cumple el criterio de terminado de la Fase 0.

**Problemas conocidos**
- El botón usa el estilo gris por defecto de Godot. El estilo visual de la interfaz se define en fases posteriores.
- La versión web pesa unos 40 MB, casi todo el motor. La primera carga con datos móviles puede tardar.
- Si el teléfono está en inglés, el juego se ve en inglés (ya hay traducción). En cualquier otro idioma se ve en español.

### 2026-10-21 — Fase 1, tarea 1: diseño v2 y datos de balance

**Qué se hizo**
- GDD versión 2 con los pedidos del dueño: habitación más amplia, personaje con nivel y barra de progreso, tienda con impresoras, materiales (incluida resina), accesorios y muebles a precios reales en dólares, impresoras que se desbloquean por nivel, envíos de 3 a 7 días de juego e inicio con $250 y una impresora tipo Ender 3.
- Propuestas de Claude incluidas en el diseño (resumen en la sección 16 del GDD): nombres ficticios, calendario de 1 día = 1 hora real, envío exprés, ferretería del barrio, muebles con función, accesorios por impresora, sin consumo eléctrico, plazos congelados fuera del juego, pedidos pieza por pieza, fin de filamento y rescate de Don Ernesto.
- `docs/REFERENCIAS.md`: producto real y precio de referencia de cada artículo, con fuentes.
- `data/*.json`: 7 impresoras, 4 materiales, 3 accesorios, 7 muebles, 2 espacios, 10 niveles, 6 tipos de cliente y 12 pedidos.
- `core/data/`: `DataCatalog` (lee los JSON) y `DataValidator` (revisa que estén completos y coherentes).
- Nombres de todo el catálogo en `translations.csv` (español e inglés).
- Pruebas: `test_data_files.gd` y `test_data_validator.gd` (20 pruebas en total).

**Verificado**
- `check.sh` y `run_tests.sh` pasan.
- La versión web exportada incluye los archivos de `data/`.

**Problemas conocidos**
- Varios precios de referencia no coinciden entre fuentes (ver `docs/REFERENCIAS.md`); los de muebles y accesorios son estimados.
- El balance (pagos, experiencia, tiempos) es una primera propuesta; se revisará con el simulador en la tarea 8.

### 2026-10-21 — Adelanto de la Fase 2: estilo visual y escena inicial

**Pedido del dueño:** usar el estilo gráfico de su imagen de referencia en todo el juego. Empezar solo con una mesa, un computador viejo y la impresora en el suelo, con 1 kg de PLA blanco. Mejorar lo que haga falta y sorprender.

**Qué se hizo**
- **Estilo pixel art isométrico:** el mundo 3D se dibuja a media resolución con píxeles nítidos, sombreado por bandas, sombras duras, contorno de 1 píxel y texturas pixel art generadas por código (madera, ladrillo, vista de la ciudad, pantallas).
- **Habitación inicial:** paredes de ladrillo, piso de madera, ventana con vista a la ciudad y puerta. Contiene la mesa con el computador viejo (monitor de tubo con texto verde, torre beige, taza) y una caja de cartón como silla, la impresora Cubo Uno en el suelo con su carrete blanco y el personaje chibi, que respira y mira su impresora. Los 5 lugares libres brillan en el piso.
- **Modelos 3D** de todas las impresoras y muebles del catálogo, listos para cuando se puedan comprar.
- **Interfaz con el estilo de la referencia:** tarjeta del personaje con retrato pixel art, nivel y barra de experiencia; dinero; fecha del juego, que avanza en vivo; ajustes; panel de objetivos; botones de Pedidos, Tareas y Mapa; barra inferior con Inicio, Taller, Inventario, Tienda y Perfil.
- **Pantallas:** Tienda (catálogo completo con vistas 3D, precios, envíos y candados por nivel), Inventario, Taller, Perfil, Pedidos (los de tu nivel), Tareas (12 objetivos), Mapa y Ajustes (cambio de idioma español e inglés y créditos).
- **Datos:** mesa con computador viejo, imprimir en el suelo con −5% de fiabilidad, 9 colores de filamento, carrete inicial de PLA blanco y `data/objectives.json`.
- **Lógica en `core/sim/`:** `GameState`, `GameClock`, `LevelTable`, `Simulation` (por ahora solo mueve el reloj) y `WorkshopRules`.
- **Documentación:** `docs/ESTILO.md`, GDD 2.1, imagen de referencia en `docs/referencias/` y tipografía Nunito registrada en `assets/CREDITS.md`.
- **Pruebas:** 50 en total, entre ellas pruebas de integración de la escena principal y de todas las pantallas.

**Verificado**
- `check.sh` y `run_tests.sh` pasan.
- Capturas en Linux de todas las pantallas.
- La versión web exportada se abrió en un Chrome que simula un Pixel 7: la habitación se ve en pixel art, el reloj avanza y tocar "Tienda" abre la tienda con sus vistas 3D.

**Problemas conocidos**
- El botón "Comprar" está desactivado hasta la tarea 3 de la Fase 1, y los pedidos solo se pueden ver hasta la tarea 4. Ambas pantallas lo avisan.
- El avance de los objetivos se muestra siempre en 0 hasta que existan las entregas y las compras.
- La partida no se guarda todavía: cada vez que se abre, empieza de nuevo el día 1.
- El modelo de la Bóveda P1 es muy simple (una caja con ventana); se mejorará con el resto del arte.


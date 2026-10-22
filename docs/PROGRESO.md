# Progreso

## Estado actual

- **Fase actual:** 1. Ciclo jugable, en curso (ruta aprobada por el dueño en `docs/RUTA.md`).
- **Diseño:** GDD versión 2.3, guía de estilo en `docs/ESTILO.md` y ruta en `docs/RUTA.md`.
- **Última tarea:** Arte 2.0 ("Mundo Impreso"), paso 8 de 16: las otras seis familias de impresoras (Rayo Mini, Rayo X1, Prisma MC, Bóveda P1, Titán Pro y Gota R1), cada una con su silueta, la pieza que crece y su falla, y el estado de noche por impresora (halo del color del estado y luz de adentro de las cerradas) (2026-10-22). Antes: paso 7, escritorio, despacho y paquetes.
- **Siguiente paso sugerido:** Arte 2.0, paso 9: muebles y estantería arreglada (con lugar para impresoras de 0,72 m). Después de Arte 2.0, la tarea 3 de la Fase 1 (navegación nueva y HUD despejado), lo que falta de la tarea 4 (versión en Ajustes y menú de pruebas) y la tarea 5 (tienda).
- **Diseño del ciclo:** aprobado por el dueño (GDD, versión 2.3 en la sección 16).

| Fase | Estado |
|---|---|
| 0. Base | Completada (2026-10-21) |
| 1. Ciclo jugable | En curso: tareas 1, 2, 6 y 7 terminadas; 4, 5 y 8 en parte |
| 2. Personaje vivo y game feel | Sin empezar (el estilo visual ya se adelantó) |
| 3. UX/UI y primera experiencia | Sin empezar |
| 4. Contenido y MVP completo | Sin empezar |
| 5. Móvil y rendimiento | Sin empezar |
| 6. Publicación | Sin empezar |
| 7. Después del lanzamiento | Sin empezar |

### Plan de la Fase 1

Cada tarea termina en un PR. El detalle está en `docs/RUTA.md`, sección 9.

| # | Tarea | Estado |
|---|---|---|
| 1 | Datos de balance y su validación | Terminada |
| 2 | Controles del mundo con joystick: caminar, tocar objetos, paneles, cercanía, cámara y zoom | Terminada |
| 3 | Navegación y HUD despejado | Pendiente |
| 4 | Guardado, azar reproducible y menú de pruebas (con la versión visible en Ajustes) | En parte: guardado automático y azar guardado hechos; faltan la versión en Ajustes y el menú de pruebas |
| 5 | Tienda y envíos | En parte: ferretería hecha |
| 6 | Pedidos tipo chat | Terminada |
| 7 | Modelar, imprimir, retirar, embalar y despachar | Terminada |
| 8 | Fallos y accesorios | En parte: los fallos se deciden al empezar cada pieza, con limpiar y reintentar, y ya se ven dibujados en las siete familias (espagueti, warping, la pieza de resina que cae; Arte 2.0, pasos 6 y 8); faltan el fin de filamento, los accesorios y el rescate |
| 9 | Fuera del juego y objetivos | Pendiente |
| 10 | Simulador y primer balance | Pendiente |

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


### 2026-10-21 — Ruta de desarrollo por fases (propuesta)

**Pedido del dueño:** un plan de acción para diseñar y mejorar el juego por fases, con variables de la vida real (precios, tiempos, máquinas) y empezando por el contenido, la jugabilidad, el game feel, los controles de movimiento y acciones y la UX/UI.

**Qué se hizo**
- `docs/RUTA.md`: ruta completa en 8 fases (0 a 7), con 35 tareas hasta la publicación. Cada tarea dice qué se podrá probar en el teléfono. La ruta incluye:
  - el diagnóstico de la versión actual, hecho con capturas de todas las pantallas;
  - qué se toma de la vida real y qué se comprime;
  - el diseño de los controles (cámara, tocar objetos y personaje que camina);
  - el catálogo de game feel;
  - los cambios de UX/UI, entre ellos una navegación nueva;
  - las metas de contenido y de ritmo;
  - las decisiones que necesita el dueño.
- `docs/REFERENCIAS.md`: nueva sección "Datos reales para el diseño", con fuentes: materiales e insumos para después del MVP, velocidad, fallos, precios de venta y cómo cobra un taller, electricidad, mantenimiento, humedad, impresión por lotes y envíos a Latinoamérica.
- Enlaces a la ruta en `README.md` y `CLAUDE.md`.

**Verificado**
- Solo cambió documentación. `check.sh` y `run_tests.sh` pasan (50 pruebas).
- Con la fórmula de precios de un taller real, los pagos actuales de `data/orders.json` quedan dentro de lo real (`docs/RUTA.md`, sección 3).

**Después (mismo día)**
- El dueño aprobó la ruta y respondió las decisiones: ver la entrada siguiente.

### 2026-10-21 — Fase 1, tarea 2: controles del mundo con joystick

**Pedido del dueño:** empezar la Fase 1 con sus respuestas a la ruta: 1 sí, 2 joystick, 3 aprobado, 4 sí, 5 sí, 6 aprobado.

**Qué se hizo**
- **Documentos:**
  - GDD 2.2 con las decisiones del dueño: controles con joystick y la regla de que caminar nunca es obligatorio para decidir (7.1), navegación aprobada (7.2), tiempos en tiempo real (5.1), ritmo meta (5.15), realismo por validar (5.16), contenido del MVP (13.1) y fases (15).
  - `docs/RUTA.md` marcada como aprobada, con el diseño del joystick (sección 4).
  - `docs/ESTILO.md` con los componentes nuevos y `docs/DECISIONES.md` con las decisiones técnicas.
- **Antes de programar:** tres críticos independientes revisaron el diseño de los controles (ergonomía móvil, juegos con joystick y técnica en Godot 4.7.2). Sus correcciones se aplicaron: dirección del joystick corregida para la vista isométrica, choques que rodean las esquinas, entrada que no pierde el dedo sobre los botones, cámara que sigue al personaje porque la vista normal no muestra todo el cuarto, y botón "atrás" de Android.
- **Joystick flotante** que aparece bajo el pulgar. El personaje camina hacia donde apunta el dedo, choca con los muebles y los rodea, y tiene animación de caminar, respirar y mirar lo que tiene cerca.
- **Tocar el mundo:**
  - Tocar un objeto abre su panel inferior: impresora, mesa del computador, lugar libre o puerta.
  - Tocar el piso hace caminar al personaje, con un círculo de destino.
  - Tocar al personaje le hace decir una frase graciosa.
- **Cercanía:** marco cian en el piso y burbuja sobre el objeto que el personaje tiene al lado; tocar la burbuja abre el panel.
- **Paneles inferiores** con datos reales:
  - La impresora muestra su fiabilidad, 80% (85% menos 5% por estar en el suelo), calculada en `core/` (`WorkshopRules.printer_reliability`).
  - Los botones llevan a la tienda (pestaña Muebles), a Pedidos, a Inventario o al Mapa.
  - Se cierran con la X, deslizando hacia abajo, tocando el mundo, caminando o con "atrás" en Android.
- **Cámara** que sigue al personaje, con tres niveles de zoom (normal, cerca y lejos) en un botón abajo a la izquierda, pellizcando o con la rueda del mouse. Se mueve de píxel en píxel sin temblor.
- **Pistas para jugadores nuevos:** "Arrastra el dedo para caminar" y luego "Toca un objeto para verlo". Quien camina tocando el piso también aprende la primera. Se recuerdan en `user://settings.cfg`.
- **Valores de los controles fijados por el dueño** después de probarlos en su teléfono con unos deslizadores temporales: caminar a 2,2 m/s, recorrido del joystick de 60 px, suavidad de la cámara de 0,10 s y distancia para resaltar de 0,60 m. Los deslizadores se quitaron de Ajustes.
- **Para probar en el computador:** WASD o flechas, E o Enter, Z, Escape y arrastrar con el mouse.
- **Herramientas:** `tools/screenshots.sh` saca 12 capturas en situaciones reales (zoom, joystick, paneles, globo, tienda y ajustes) para revisar la interfaz sin teléfono.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 135 pruebas. Las nuevas son de toques y joystick, choques y caminos, cercanía, personaje, cámara, cajas de los modelos, dirección del joystick, pistas e integración con toques simulados como en el teléfono (24 pruebas).
- `run_tests.sh` ahora también falla si GUT no llega a imprimir el resumen final, para que una prueba que cierre el juego antes de tiempo no pase por buena.
- Revisé las capturas de todas las situaciones.
- La versión web exportada se probó en un Chromium que simula un Pixel 7, con toques reales del navegador:
  - el joystick mueve al personaje hacia donde se arrastra;
  - tocar la impresora abre su panel una sola vez;
  - tocar arriba lo cierra sin caminar;
  - el botón Tienda funciona;
  - pellizcar con dos dedos cambia a "Cerca".
- La plantilla web de Godot ya trae `touch-action: none` y bloquea el zoom de la página.

**Problemas conocidos**
- El HUD actual (panel de objetivos y botones a la izquierda) todavía tapa parte del cuarto: se despeja en la tarea 3.
- Las pistas se recuerdan, pero el idioma elegido en Ajustes todavía no (llega con el guardado, tarea 4).
- Algunos botones de los paneles llevan a pantallas que todavía son de solo lectura (Pedidos, Tienda): lo dicen con un aviso.
- Si el personaje queda en el borde de adelante del cuarto, con zoom "Cerca" queda bajo en la pantalla, cerca del pulgar.
- La vibración y los sonidos llegan en la Fase 2.

### 2026-10-22 — Ciclo de pedidos: del mensaje a la puerta

**Pedido del dueño:** fijar los controles con los valores que probó (caminar a 2,2 m/s, joystick de 60 px, cámara de 0,10 s, resaltar a 0,60 m) y quitar los deslizadores; después, "trabajar en la experiencia de confirmar pedidos, modelar en 3D el pedido e imprimirlo, retirar la pieza impresa, embalarla y despacharla".

**Cómo se trabajó**
- Cuatro revisores leyeron en paralelo el diseño, la simulación, la interfaz y cómo trabaja un taller de impresión 3D real (con fuentes).
- Tres diseños independientes (experiencia del jugador, arquitectura y realismo) y dos jueces; la síntesis quedó como especificación.
- Se construyó en 14 pasos, cada uno con sus pruebas en verde y su commit, con una revisión adversaria de la simulación a mitad de camino y otra final jugando con toques reales.

**Qué se hizo**
- **Controles** con los valores del dueño y sin deslizadores en Ajustes.
- **Tocar el lugar libre detrás de la impresora del suelo** ahora abre ese lugar: el toque gana para lo que está justo bajo el dedo y las cajas de toque giran con el modelo.
- **El ciclo en seis pasos** (GDD 5.17), todo también tocando desde Pedidos o desde el objeto:
  1. Confirmar: mensajes tipo chat con lo que pide el cliente, requisitos, tiempos, pago y ganancia.
  2. Modelar: el computador empieza solo, con tiempos según cómo llega el diseño y un "Concentrarse" opcional.
  3. Imprimir: plan recomendado con tiempo real, calidad, riesgo, material y ganancia; la pieza crece capa a capa; las piezas siguientes empiezan solas.
  4. Retirar las piezas al rincón de despacho, junto a la puerta.
  5. Embalar.
  6. Despachar y cobrar: "+$6" y la XP vuelan al HUD y el cliente agradece.
- **Fallos:** se deciden al empezar cada pieza; las 3 primeras de una partida nueva no fallan; "Limpiar y reintentar" o "Limpiar".
- **Tablero:** 3 mensajes y 3 pedidos como máximo, primer mensaje a los 2,5 segundos, después uno cada 2,5 minutos reales; solo pedidos que se pueden hacer.
- **Avisos:** burbujas de estado sobre la impresora, el computador y el rincón; número en Pedidos; el personaje comenta el siguiente paso; la burbuja de cercanía hace la acción cuando no hay nada que decidir.
- **Objetivos con avance real** ("Entrega 3 llaveros (1/3)"); los premios llegan con la tarea 9.
- **Guardado automático** en `user://save.json`. En Ajustes, "Empezar partida nueva".
- **Ferretería del barrio:** PLA o PETG al instante, 50% más caro, en Pedidos (cuando no hay nada que hacer) y en Inventario.
- **Núcleo:** reloj de segundos enteros, dos flujos de azar guardados, simulación por eventos, material apartado, comandos que devuelven el motivo de error y señales en `Events`. Las decisiones están en `docs/DECISIONES.md`.
- **Capturas:** `tools/screenshots.sh` saca ahora 24 situaciones, 12 de ellas del ciclo.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 496 pruebas (antes 135). Entre ellas: un paso de 8 horas igual a miles de pasos pequeños (con fallos, modelos y mensajes en el medio), 8 horas con 40 impresoras en menos de 20 ms, la primera venta en menos de 2 minutos, guardar y cargar a mitad de una impresión, gramos que nunca aparecen ni desaparecen, el ciclo completo solo con tarjetas (sin caminar) y con toques reales.
- Revisé las 24 capturas.

**Problemas conocidos**
- Mientras el juego está cerrado o la pestaña escondida, el tiempo no pasa: el progreso fuera del juego llega con la tarea 9.
- Con 1 kg de PLA alcanzan unos 20 a 25 pedidos de nivel 1; después hay que comprar en la ferretería (la tienda llega con la tarea 5).
- Fuera de los 3 primeros, la impresora en el suelo falla 1 de cada 5 piezas en modo Normal: es intencional para que la mesa auxiliar valga la pena, pero hay que confirmarlo con el simulador (tarea 10).
- Dos impresoras sobre la misma mesa tendrían burbujas encimadas: todavía no se puede tener una segunda impresora (llega con la tienda).
- Las impresoras cerradas y de resina no muestran la pieza que crece; solo la pantalla y la burbuja.
- Los números de ritmo (un mensaje cada 60 minutos de juego, tiempos de modelado, 3 piezas de regalo, 3 pedidos en curso) son una propuesta: se ajustan con el simulador.
- El número de Pedidos sigue en el botón de la izquierda hasta la navegación nueva (tarea 3).

### 2026-10-22 — Arreglos de la revisión final del ciclo

**Qué se hizo**
- El dueño aprobó el diseño del ciclo (GDD 2.3): quedó anotado en el GDD, la ruta y este archivo.
- Una revisión de código con siete miradas distintas, cada hallazgo comprobado por revisores escépticos, encontró 9 problemas reales (y descartó 12). Todos se arreglaron, cada uno con una prueba que fallaba antes:
  - **Almacén:** el material apartado para piezas que faltan imprimir ahora ocupa lugar. Antes se podía comprar en la ferretería hasta llenar el almacén y pasarse del límite si una pieza fallaba.
  - **Mesa del computador:** "Imprimir" apunta al primer pedido que de verdad se puede imprimir, no al primero de la lista si ese no tiene material.
  - **Pruebas desde el editor:** correr las pruebas desde el panel de GUT ya no guarda encima de la partida del jugador ni de sus preferencias (`RunMode`).
  - **Toques en Pedidos:** si la pantalla se actualiza mientras el dedo está sobre un botón, espera a que se suelte, como ya hacían los paneles. Antes se podía perder el toque.
  - **"Atrás" en Android:** guarda la partida antes de cerrar.
  - **Botones de 88 px:** Aceptar, Rechazar, el botón del paso siguiente y "Cancelar pedido" en Pedidos, y "Empezar partida nueva" en Ajustes. Las opciones del panel inferior siguen en 64 px, como excepción anotada en `docs/ESTILO.md`.
  - **Una prueba del guardado automático** que nunca podía fallar ahora prueba de verdad.
- Las decisiones nuevas están en `docs/DECISIONES.md`.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 505 pruebas (antes 496).
- Revisé las capturas de Pedidos y Ajustes con los botones nuevos.

**Problemas conocidos**
- Los mismos de la entrada anterior.

### 2026-10-22 — Arte 2.0, paso 1: guardas antes de tocar el arte

**Pedido del dueño:** empezar la fase de diseño para que el personaje y los espacios se vean como un juego caro, con libertad total de estilo. La dirección de arte elegida es "Mundo Impreso" y se implementa en 16 pasos; este es el primero.

**Qué se hizo** (el juego se ve igual que antes)
- **Prueba de presupuesto de dibujo:** mide cuánto le cuesta al teléfono dibujar el cuarto inicial y el cuarto más lleno de hoy (16 impresoras): llamadas de dibujo, triángulos, materiales, sombras y luces. Falla si un cambio de arte lo encarece, si aparece una luz extra del motor o si hay algo que no sabe medir. Hoy: 334 llamadas el cuarto inicial y 1.042 el lleno; la meta del arte nuevo es 70 y 200.
- **Capturas de arte nuevas, sin interfaz:** el cuarto entero (30), con zoom normal (31), el personaje de frente, de perfil y de espaldas (32a, 32b, 32c) y su cara de muy cerca (33), la impresora y el escritorio de cerca (34), la pieza que crece vista desde lejos (45), la tienda de impresoras (46), una impresora de cada familia (26) y el cuarto lleno de estanterías, entero y de cerca (37, 38). Son la foto del "antes".
- **`tools/screenshots.sh` más estricto:** ahora falla si algo sale mal a mitad de camino (antes terminaba "bien" con menos capturas), deja la lista de capturas (`manifest.txt`) y lo que costó dibujar cada una (`budget.csv`). Opciones nuevas: `--only=art` (solo las de arte, unos 25 segundos), `--only=char` (solo el personaje) y `--resolution=1080x2400` (otro tamaño de pantalla).
- **Arreglo en las capturas 04 a 06:** el personaje caminaba de más y terminaba contra la pared; ahora queda junto a la impresora, porque el mundo avanza con un paso fijo en cada cuadro. Camina más de un metro con el joystick, así 05 muestra la pista "Toca un objeto para verlo" y las capturas siguientes salen sin pistas, como antes.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 520 pruebas (antes 505; las de antes no cambiaron).
- `screenshots.sh` saca las 36 capturas del manifiesto. Se comprobó que falla si se mete un error a propósito en un escenario (y se deshizo). Lo que cuenta OpenGL coincide con la medida de la prueba (334 y 1.042 llamadas con todo el cuarto a la vista).
- Revisé las 36 capturas.

**Qué revisar en el teléfono:** nada cambia en el juego con este paso.

**Problemas conocidos**
- Entre dos corridas de capturas cambian unos píxeles de lo que se anima con tiempo real (el latido de las marcas de lugar libre y el marco de resalte). El personaje y la cámara salen iguales.
- La opción `--quality` de las capturas solo queda anotada: el juego todavía tiene un solo nivel de calidad (llega en el paso 15).

### 2026-10-22 — Arte 2.0, paso 2: el mundo a resolución alta, sin pixel art

**Decisión del dueño:** dejar el pixel art por "Mundo Impreso" (D1, aprobada: "puedes cambiar el estilo gráfico... total libertad").

**Qué se hizo**
- **El mundo se dibuja con el ancho de tu pantalla** (hasta 1.080 px) en vez de a la mitad, con bordes suavizados (MSAA 4×) y estirado con filtro suave. En un teléfono de 1.080 px de ancho cada píxel del mundo es un píxel de la pantalla. Es el script nuevo `game/world/world_viewport.gd`.
- **Sin ajuste a píxeles:** la cámara y el personaje ya no se redondean a la cuadrícula del pixel art, y se borró el truco que corría la imagen para disimularlo.
- **Sombras suaves y más finas:** filtro suave, mapa de sombra de 2.048 también en el teléfono y la cámara ve solo la profundidad del cuarto (11 a 30 m), así cada punto de la sombra es más chico.
- **Luz provisoria:** sol y ambiente en 0,45 para que el piso no se vea quemado (el paso 3 trae la luz nueva).
- **La pieza crece de a 1 cm** (una capa) y nunca baja, con cualquier zoom. Antes crecía "de a un píxel" y el escalón cambiaba con el zoom.
- Las vistas 3D de la tienda, el retrato del HUD y el perfil también se ven suaves (sin pixelar, con MSAA).

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 524 pruebas (antes 520). Dos pruebas se adaptaron con la misma intención (la cámara llega justo a su meta; la pieza crece de a una capa y nunca baja) y una ayuda de prueba cambió `stretch_shrink` por `view_per_ui`; detalle en `docs/DECISIONES.md`. Nuevas: 3 de `WorldViewport` y una de toques con pantallas de 1.080 y 1.440 px.
- `screenshots.sh` saca las 36 capturas, a 720 × 1.280 y a 1.080 × 2.400 (en esta, el mundo se dibuja a 1.080 × 2.400: un píxel por píxel). La prueba de presupuesto da lo mismo que antes (334 y 1.042 llamadas): la resolución no cambia la cantidad de llamadas.
- Revisé 01, 02, 03, 05, 10, 18, 30, 32a, 33 y 46: todo se ve suave y la burbuja, el globo y los toques siguen alineados con el mundo.

**Qué revisar en el teléfono** (versión web)
- Que el cuarto se vea nítido y con bordes suaves, sin "escalones" de píxel, y que al caminar la cámara se mueva suave, sin temblor.
- Que tocar la impresora, el escritorio, una marca del piso y el piso (para caminar) siga funcionando igual que antes.
- Que el juego siga fluido. Si se siente más lento que antes, avisa: el paso 15 agrega una calidad Baja automática.

**Problemas conocidos**
- **Esperado por un paso:** el contorno oscuro de los objetos ahora mide unos 2 píxeles (4 con zoom cerca) y las texturas del piso y las paredes siguen siendo de pixel art. El paso 3 quita el contorno del mundo y cambia los materiales.
- El costo de dibujar a resolución alta con MSAA en un teléfono todavía no se midió (llega con el panel de depuración del paso 15).

### 2026-10-22 — Arte 2.0, paso 3: kit de materiales, modelo de color y entorno

**Qué se hizo**
- **"Lo que dice el hex es lo que se ve".** Todo el mundo usa los sombreadores nuevos de `game/world/look/`: un color bajo luz neutra se ve exactamente como su código de color. Al arrancar, `ColorProbe` mide cómo dibuja colores el motor en ese aparato y ajusta los sombreadores; la captura nueva `00_calibracion` lo comprueba sola (tarjetas gris, blanca y de la paleta con ambiente, con sol y con los dos: salen exactas).
- **Luces calculadas en el sombreador:** el ambiente de dos colores, un relleno desde el lado de la cámara, el brillo del monitor, el LED de la impresora del piso y el **parche de sol que entra por la ventana con las rayas de las rejas** (cae junto a la impresora del piso y sube por la pared del fondo). Cero luces extra y cero llamadas de dibujo extra. El sol sale de `DayCycle` (por ahora solo la mañana; el día y la noche llegan en el paso 13).
- **Sin contorno en el mundo** y sin texturas pixel art: el piso es de baldosa clara con junta y bisel, las paredes de pintura crema, la madera con vetas, la cama de la impresora dorada, el cartón corrugado. El monitor, las pantallitas de la impresora y la vista del barrio por la ventana se dibujan en el sombreador y se animan.
- **Fondo de diorama:** degradado azul con un resplandor detrás del cuarto y una sombra suave debajo, como una foto de producto.
- **La pieza que se imprime muestra sus capas** de 1 cm y una **capa caliente naranja** arriba, que brilla sola (se ve con cualquier zoom).
- Paleta nueva de la biblia de arte (`LookPalette`); el buzo del personaje pasa a gris carbón (D3).
- **Menos costo:** el cuarto inicial pasa de 334 a 177 llamadas de dibujo (el lleno, de 1.042 a 535).

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 544 pruebas (antes 524). Una prueba se adaptó (dos anotaciones de tipo: la comparación de materiales es la misma); 20 nuevas (materiales, `ColorProbe`, la mañana, los sombreadores). Detalle en `docs/DECISIONES.md`.
- `screenshots.sh` saca las 37 capturas (nueva: `00_calibracion`) y falla si la calibración no da lo que dice la biblia.
- Revisé 00, 01, 02, 03, 18, 23, 30, 33 y 34.

**Qué revisar en el teléfono** (versión web)
- Que el cuarto se vea cálido y limpio: piso claro de baldosa, paredes crema, sin bordes negros alrededor de las cosas.
- Que se vea el parche de sol con rayas cerca de la impresora del piso.
- Que la pantalla del computador y la pantallita de la impresora se muevan (texto que sube, barra que avanza al imprimir).
- Que al imprimir se vea la línea naranja arriba de la pieza, también con el zoom lejos.

**Problemas conocidos**
- Los modelos siguen siendo las cajas de antes (se cambian en los pasos 4 a 12): el personaje tiene la cara un poco a la sombra del pelo, la puerta y la ventana son provisorias, las dos paredes son del mismo color.
- La calibración solo se midió en llvmpipe (la computadora de Claude). En el teléfono, `ColorProbe` mide solo; lo que midió se verá en el panel de depuración del paso 15.

### 2026-10-22 — Arte 2.0, paso 4: kit de formas, caché y oclusión del piso

**Qué se hizo**
- **Kit de formas (`KitMesh`):** la herramienta con la que se arman todos los modelos nuevos de los pasos 5 a 14. Junta muchas formas en una sola malla (una llamada de dibujo por objeto): cajas con las aristas biseladas (atrapan la luz), cilindros con canto, tornos (un perfil que gira: carretes, macetas), formas redondas, cápsulas, tubos que siguen una curva suave sin retorcerse (cables, filamento, espaguetis), aros, discos, rectángulos y triángulos. Cada punto de la malla lleva su color, su superficie (madera, tela, metal...), si fue impreso (se ven las capas), si brilla, y una sombra de contacto ya incluida: más oscuro donde toca el piso o la mesa y debajo de las repisas. Cada malla se arma una vez y se guarda (caché).
- **Manchas de sombra bajo las cosas (`FloorAO`):** una textura chica del piso con una mancha suave bajo el escritorio, la impresora del piso y el rincón de despacho. Se pinta una vez al armar el cuarto, con los mismos obstáculos por los que no se puede caminar (la decoración del paso 12 tendrá su mancha sola). No cuesta llamadas de dibujo.
- La captura de calibración (`00`) arma ahora sus tarjetas "por vértice" con el kit: comprueba con los píxeles que el kit pinta el color exacto.
- **Prueba nueva de velocidad:** armar la escena principal con las mallas en caché tarda unos 20 ms en la computadora de Claude; la prueba falla si pasa de 120 ms (la meta de la biblia es 40).

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 565 pruebas (antes 544), ninguna adaptada; 21 nuevas (kit de formas, mapa del piso, manchas en el cuarto, tiempo de armado, cajas de los modelos del kit). Detalle en `docs/DECISIONES.md`.
- `screenshots.sh` saca las 37 capturas. Revisé 00, 01, 02, 30 y 34 lado a lado con las del paso 3: las manchas aparecen justo bajo el escritorio, alrededor de la impresora del piso y bajo el rincón de despacho, con borde suave, y no en el piso libre ni en las marcas. También revisé una galería de todas las formas del kit con la luz de la mañana (fuera del juego): caras, biseles, capas y sombras correctas.
- La prueba de presupuesto da lo mismo (177 y 535 llamadas): este paso no cambia lo que se dibuja.

**Qué revisar en el teléfono** (versión web)
- Que debajo del escritorio, alrededor de la base de la impresora del piso y debajo del rincón de despacho el piso se vea un poco más oscuro y azulado, con el borde difuminado (como una sombra de contacto), y que el resto del piso y las marcas cian se vean igual que antes.

**Problemas conocidos**
- Los modelos todavía son las cajas de antes: el kit se empieza a usar en el paso 5 (el cuarto) y los siguientes.

### 2026-10-22 — Arte 2.0, paso 5: el cuarto

**Qué se hizo**
- **El cuarto es una maqueta impresa:** se apoya en una base de plástico azul con sus capas a la vista y un borde fino de "primera capa" alrededor; los cortes de arriba de las paredes y de sus puntas también muestran capas. Piso de baldosa cálida (ahora con baldosas enteras contra las paredes), la pared de la ventana verde salvia y la del fondo crema, con zócalos.
- **La ventana:** un hueco de verdad en la pared, con una ventana corrediza de aluminio de dos hojas, alféizar de baldosa, rejas de hierro por fuera con un travesaño y un adorno de sol (dos aros), y una cortina mostaza recogida a los lados que se mueve apenas. Por ella se ve el barrio: cielo con nubes, cordillera, un cerro verde con casitas de colores y una torre de iglesia, edificios bajos y, cerca, la azotea del vecino con su tanque de agua negro, varillas "para el segundo piso", ropa tendida, una buganvilla y un poste con cables enredados. Un haz de luz suave baja desde la ventana.
- **El parche de sol:** la luz de la mañana entra por la ventana y dibuja en el piso las rayas de las rejas (y los aros del adorno); cruza la impresora del piso (su cama dorada brilla) y el escritorio y el personaje lo tapan. Para que cruce la impresora, la luz de la ventana gira 10° respecto del sol (detalle y motivo en `docs/DECISIONES.md`).
- **La puerta:** de madera con dos tableros, marco crema y manija de latón; se toca igual que antes.
- **Interruptor** con su canaleta blanca que sube hasta el borde de la pared y **enchufe** de la impresora en la pared del fondo.
- **Marcas del piso:** los lugares libres se marcan con cuatro esquinas y un "+" (antes un rectángulo entero); laten suave y se encienden cuando el personaje está cerca o la tienda está abierta. El marco de lo que está cerca también es de esquinas, y al tocar el piso aparece un aro.
- Más liviano: el cuarto inicial bajó de 177 a 136 llamadas de dibujo, y la escena se arma en unos 11 ms (antes 20).

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 575 pruebas (antes 565); 10 nuevas (cuarto, ventana, marcas, puerta, cortina) y 3 adaptadas con la misma intención (detalle en `docs/DECISIONES.md`).
- `screenshots.sh` saca las 37 capturas. Revisé 01, 02, 03, 05, 08, 09, 11, 30, 31, 34 y 37, y 01 al lado de la imagen del prototipo "Diorama". Medido en las capturas: dentro del parche ≥ 230 de 255 (picos en 255), el piso visible en promedio 191 de 255, la pared de la ventana (144, 153, 132), verde salvia.

**Qué revisar en el teléfono** (versión web)
- Al empezar (08:00): las rayas de luz de las rejas en el piso alrededor de la impresora del piso, con su cama dorada iluminada; la ventana con la cortina mostaza, las rejas negras con los dos aros arriba y el barrio detrás (el tanque negro, la ropa de colores, la buganvilla magenta, los cables).
- La base azul con capas debajo del piso y las tapas azules arriba de las paredes.
- Las marcas de los lugares libres (esquinas cian suaves): que se vean, que se enciendan al acercar el personaje y al abrir la Tienda, y que se puedan tocar como antes. Si cuestan verlas en el teléfono, se pueden subir (es un número).
- La puerta: que se toque y abra su panel como antes.

**Problemas conocidos**
- El parche no sube por la pared del fondo (la biblia lo pedía, pero no puede cruzar la impresora y subir por esa pared a la vez): elegí cruzar la impresora.
- Sobre el piso claro de baldosa el parche se nota menos que en el prototipo "Diorama" (que tenía piso de madera oscura y el sol solo por la ventana). El cuarto todavía está vacío: la decoración llega en el paso 12.
- La mañana es el único momento del día (el resto llega en el paso 13). El escritorio, la impresora, el despacho y el personaje siguen con los modelos de cajas (pasos 6 a 10).

### 2026-10-22 — Arte 2.0, paso 6: la impresora estrella

**Qué se hizo**
- **La Cubo Uno nueva** (la impresora del piso): marco negro de perfil de aluminio con sus ranuras, cama dorada con perillas amarillas en las esquinas, cabezal con ventilador azul y boquilla de latón, un tubo blanco que sube en arco, barra de luz LED que alumbra la cama, caja de control con la pantallita abajo a la derecha y el carrete arriba en un soporte impreso azul. Se arma en pocas piezas (más liviana que la de cajas) y la tienda y los paneles muestran la misma.
- **Sobre su baldosa:** la impresora del piso descansa en una baldosa de concreto clara con granitos, y su cable negro cruza el piso (sin pisar los lugares de muebles) hasta el enchufe de la pared del fondo.
- **El carrete:** tapas abiertas (un aro y cuatro rayos) y el bobinado del color del filamento con los surcos del enrollado. También cambiaron los carretes de los estantes.
- **La pieza:** sigue creciendo capa a capa con la capa caliente naranja arriba (se ve también desde lejos); al terminar da su saltito y suelta **tres destellos dorados** por medio segundo.
- **Los fallos se leen sin abrir el panel:** con **espagueti** aparece un nido de hilos del color del filamento sobre la pieza fallida y dos hebras que suben hasta la boquilla, que se queda encima; con **warping** la pieza se inclina y se le levanta una esquina, y el cabezal se aparta. Al limpiar, todo vuelve a su lugar.
- Captura nueva `36_impresora_cerca`: la impresora imprimiendo, de muy cerca.
- El cuarto inicial bajó de 136 a 120 llamadas de dibujo.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 590 pruebas (antes 575); 15 nuevas (la impresora, el carrete, el espagueti, el warping, la capa caliente, los destellos, la baldosa y el cable) y 4 adaptadas con la misma intención (detalle en `docs/DECISIONES.md`).
- `screenshots.sh` saca las 38 capturas. Revisé 01, 03, 18, 19, 23, 26, 34, 36, 38, 45 y 46, y los destellos aparte (duran menos que lo que tarda una captura).

**Qué revisar en el teléfono** (versión web)
- Al empezar: la impresora del piso sobre su baldosa gris clara y el cable fino que va hasta el enchufe de la pared crema.
- Con el zoom cerca mientras imprime: las capas de la pieza, la línea naranja arriba, el cabezal que va y viene, la luz de la barra LED y el carrete con sus surcos. Con el zoom lejos, que la línea naranja se siga viendo.
- Al terminar una pieza: el saltito y los tres destellos dorados (duran medio segundo).
- Si falla (más fácil con la perilla en PETG): el nido de hilos blancos encima de la pieza oscura, sin abrir el panel.

**Problemas conocidos**
- Las otras seis familias siguen con los modelos de cajas (paso 8). En la estantería vieja (tablas cada 0,62 m) el carrete de la Cubo Uno atraviesa la tabla de arriba, igual que pasaba con la de cajas: la estantería nueva del paso 9 deja lugar para impresoras de 0,72 m.
- El espagueti usa un hilo de 6 mm (la biblia pedía 4 mm, que no se leía en la captura).
- El escritorio, el despacho y el personaje siguen con los modelos de cajas (pasos 7 y 10).

### 2026-10-22 — Arte 2.0, paso 7: escritorio, despacho y paquetes

**Qué se hizo**
- **El escritorio del comienzo, nuevo:** mesa vieja de madera con una cajonera de tres cajones (el del medio entreabierto) y tiradores de bronce; monitor de tubo beige con un papelito amarillo y su luz verde; torre con sus bahías; teclado con teclas; ratón sobre su alfombrilla; una **lámpara articulada amarilla** (de noche se ve la ampolleta encendida); taza roja; un portalápices impreso morado con lápices; papeles con un croquis, cuaderno y calibrador; cables que bajan a una regleta en el piso, y la **caja de cartón con un cojín** como silla (el comienzo humilde). Ocupa exactamente lo mismo que antes: se toca, se rodea y se resalta igual.
- **Las luces del escritorio** (la lámpara y el brillo del monitor) salen de dos marcas del modelo. De día la lámpara está apagada; el paso 13 la enciende de noche.
- **El rincón de despacho, nuevo:** una mesita de embalar con dispensador de cinta, cúter, etiquetas y un marcador, y abajo cartones planos y un rollo de plástico de burbujas; al lado, un **guacal** de listones con relleno de papel triturado, donde se apilan los paquetes (un poco girados, como a mano).
- **Las cajas:** la caja abierta tiene las solapas hacia afuera, relleno de papel y la pieza del color del pedido asomando; el paquete es de cartón corrugado con cinta y una etiqueta blanca con un ícono azul (sin letras).
- Se dibuja menos: el cuarto inicial bajó de 120 a **75 llamadas de dibujo** y de 27 a 18 materiales.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 600 pruebas (antes 590); 10 nuevas (medidas, nodos, luces y presupuesto del escritorio, del rincón y de las cajas) y 2 adaptadas porque se borró una función que ya nadie usaba (detalle en `docs/DECISIONES.md`).
- `screenshots.sh` saca las 38 capturas. Revisé 03, 07, 16, 20, 21, 22, 30 y 34, y aparte (laboratorio) el escritorio y el rincón de muy cerca, de día y con una noche puesta a mano.

**Qué revisar en el teléfono** (versión web)
- Con el zoom cerca, junto al escritorio: la cajonera con el cajón entreabierto, el monitor con el papelito amarillo, la lámpara amarilla, la taza roja, el portalápices morado y la caja de cartón con el cojín.
- Toca el escritorio: el panel y su dibujito muestran el escritorio nuevo; al aceptar un pedido el monitor muestra el cubo que gira.
- Al retirar una pieza: la caja abierta aparece sobre la mesita de embalar con la pieza de su color asomando; al embalar, el paquete aparece sobre el guacal; al despachar, se va hacia la puerta.
- Que caminar alrededor del escritorio y del rincón se sienta igual que antes (no deben haber cambiado de tamaño).

**Problemas conocidos**
- La noche todavía no existe en el juego (paso 13): la lámpara encendida solo se probó en el laboratorio.
- Con el zoom normal el rincón de despacho sigue siendo chico (mide lo mismo que antes, a propósito); se lee mejor que el de cajas porque el guacal tiene espacios entre listones y la mesa tiene cosas encima.
- El cable de la regleta a la pared llega con la decoración (paso 12).
- Las otras seis familias de impresoras, los muebles y el personaje siguen con los modelos de cajas (pasos 8 a 10).

### 2026-10-22 — Arte 2.0, paso 8: las siete familias de impresoras

**Qué se hizo**
- **Seis impresoras nuevas, todas distintas por su forma:** la **Rayo Mini** (chiquita y achatada, blanca, con un cabezal redondo de aro verde que brilla y el carrete en un soporte aparte a la derecha); la **Rayo X1** (una sola columna alta con una barra de luz, el carrete arriba y la pantalla táctil en un brazo); la **Prisma MC** (como la X1 pero morada y con una caja de 4 carretes de colores arriba, sus tubos y la rampa de purga con restos de 4 colores); la **Bóveda P1** (un cubo grafito con puerta y techo de vidrio, la luz de adentro y el carrete asomando atrás); la **Titán Pro** (la grande, grafito con naranja, dos boquillas, pantalla ancha y la caja de colores arriba); y la **Gota R1** (la de resina: base negra y tapa ámbar transparente).
- **Todas muestran la pieza que crece y su falla.** En las cerradas el cabezal va arriba y la cama baja mientras la pieza crece; adentro la luz es cálida al imprimir, verde al terminar y roja si falla (con el espagueti adentro). En la de resina la pieza cuelga de la placa y crece hacia abajo mientras la placa sube; si falla, cae a la tina.
- **De noche cada impresora tiene un halo en el piso del color de su estado** (cálido imprimiendo, verde lista, rojo con falla). Todavía no hay noche en el juego (llega en el paso 13): se probó con una noche puesta a mano.
- Las impresoras de los muebles se dibujan con menos detalle que la del piso (no se nota a esa distancia) y solo su cuerpo da sombra: el taller lleno bajó de 395 a **230 llamadas de dibujo** y de 29 a 20 materiales.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 611 pruebas (antes 600); 10 nuevas en `tests/integration/test_printer_families.gd` (medidas, partes, presupuesto, que crezcan y fallen, halos) y 1 en `tests/unit/test_kit_mesh.gd` (el corte de biseles chicos). La herramienta que mide el presupuesto ahora entiende los `#ifdef` de los sombreadores (detalle en `docs/DECISIONES.md`).
- `screenshots.sh` saca las 38 capturas. Revisé 26 y 38 (y 36, 37 y 46), y aparte (laboratorio) cada familia de muy cerca: quieta, imprimiendo, lista y con falla, de día y con una noche puesta a mano.

**Qué revisar en el teléfono** (versión web)
- La tienda, pestaña Impresoras: los dibujitos de cada impresora ahora son los modelos nuevos (cada una con su forma).
- Hoy en una partida nueva solo está la Cubo Uno; las otras se ven cuando se puedan comprar (tarea 5). Si quieres verlas ya, la captura 26 de `build/screenshots/` las muestra a todas en el cuarto.

**Problemas conocidos**
- La estantería metálica todavía es la vieja (tablas cada 0,62 m): las impresoras altas la atraviesan (se ve en 38). La arregla el paso 9 (0,74 m por nivel).
- El carrete de las cerradas no cambia de color con el trabajo (es parte del cuerpo, para que cuesten 6 llamadas); se ve poco.
- La noche y sus halos solo se vieron en el laboratorio (paso 13).


# Progreso

## Estado actual

- **Fase actual:** 1. Ciclo jugable, en curso (ruta aprobada por el dueño en `docs/RUTA.md`).
- **Diseño:** GDD versión 2.3, guía de estilo en `docs/ESTILO.md` y ruta en `docs/RUTA.md`.
- **Última tarea:** el ciclo de pedidos completo, pedido por el dueño: tareas 6 y 7 de la Fase 1, con partes de las tareas 4, 5 y 8 (2026-10-22).
- **Siguiente paso sugerido:** tarea 3, navegación nueva y HUD despejado (el número de Pedidos pasa a la barra de abajo). Después, lo que falta de la tarea 4 (versión en Ajustes y menú de pruebas) y la tarea 5 (tienda).
- **Para el dueño:** confirmar el diseño propuesto para el ciclo (GDD, versión 2.3 en la sección 16).

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
| 8 | Fallos y accesorios | En parte: los fallos se deciden al empezar cada pieza, con limpiar y reintentar; falta verlos dibujados, el fin de filamento, los accesorios y el rescate |
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


# Progreso

## Estado actual

- **Fase actual:** 1. Ciclo jugable, en curso (ruta aprobada por el dueño en `docs/RUTA.md`).
- **Diseño:** GDD versión 2.3, guía de estilo en `docs/ESTILO.md` y ruta en `docs/RUTA.md`.
- **Última tarea:** Arte 2.0 ("Mundo Impreso"), paso 15 de 16: rendimiento. Calidad gráfica Alta y Baja con la opción "Calidad gráfica: Automática / Alta / Baja" en Ajustes, versión lejana de las impresoras con el zoom lejos (el taller lleno usa un 32 % menos de llamadas) y panel de depuración `#debug` para medir en el teléfono (2026-10-23). Antes: paso 14, la firma (lo que se compra se imprime en su lugar).
- **Siguiente paso sugerido:** que el dueño mida en su teléfono con el panel `#debug` (lista en la entrada del paso 15, abajo). Después, Arte 2.0, paso 16: interfaz, documentos y cierre. Luego la tarea 3 de la Fase 1 (navegación nueva y HUD despejado), lo que falta de la tarea 4 (versión en Ajustes; el panel de depuración ya existe) y la tarea 5 (tienda: su comando de compra solo tiene que agregar el mueble o la impresora al estado y pedir `RoomView.sync_models()`).
- **Diseño del ciclo:** aprobado por el dueño (GDD, versión 2.3 en la sección 16).

| Fase | Estado |
|---|---|
| 0. Base | Completada (2026-10-21) |
| 1. Ciclo jugable | En curso: tareas 1, 2, 6 y 7 terminadas; 4, 5 y 8 en parte |
| 2. Personaje vivo y game feel | Sin empezar (se adelantaron el estilo visual y, con D8, la animación y las reacciones del personaje) |
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
| 4 | Guardado, azar reproducible y menú de pruebas (con la versión visible en Ajustes) | En parte: guardado automático y azar guardado hechos; el panel de depuración (`#debug`, Arte 2.0 paso 15) ya prueba escenas sin tocar la partida; falta la versión en Ajustes y lo que el menú de pruebas sume para el balance |
| 5 | Tienda y envíos | En parte: ferretería hecha; el cuarto ya muestra lo que se agregue imprimiéndose (Arte 2.0, paso 14), falta el comando de compra |
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

### 2026-10-22 — Arte 2.0, paso 9: muebles y estantería arreglada

**Qué se hizo**
- **Los seis muebles de la tienda son del kit**, cada uno una sola pieza con su historia: la **mesa auxiliar** blanca con el canto de madera a la vista y una repisa abajo (un tarro impreso y el atomizador de alcohol); la **mesa de trabajo** de madera clara con una cajonera metálica y cajas organizadoras de colores en la repisa baja; la **estantería metálica**; la **repisa de filamento** con 6 carretes y escuadras impresas naranjas; la **estantería de cubos** blanca con pilas de carretes de los 9 colores, una caja de filamento, tarros impresos y un florero; y el **tablero de herramientas** con alicate, cortafríos, espátula, calibrador, llaves Allen, cinta y una caja de herramientas en el piso.
- **La estantería metálica se arregló:** ahora mide 2,40 m y deja 0,74 m libres en cada piso, así que cabe cualquier impresora (antes las altas atravesaban las tablas). Tiene postes negros de ángulo, tablas de madera, cruces, una regleta con los cables atados y cosas guardadas arriba.
- **La repisa y el tablero ya no flotan:** se cuelgan de la pared donde la hay; en el lugar del medio del cuarto (y bajo la ventana) van sobre un pie propio. Te lo informo (decisión D5 del plan): se aplicó tal como estaba propuesto.
- El taller lleno bajó de 230 a **170 llamadas de dibujo** y de 20 a 18 materiales (ya dentro de la meta final de la biblia).
- **Arreglos de la revisión:** se borró código que ya nadie usaba (una función de los carretes y tres colores repetidos), el mueble de cubos ya no se mete en el zócalo (queda a 3 cm de la pared), las cajas organizadoras ahora son abiertas de verdad (se ve adentro), arriba de la estantería hay dos carretes parados en vez de una pila que parecía una lata, y la prueba del pie de la repisa y del tablero es más estricta.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 619 pruebas (antes 611); 8 nuevas en `tests/integration/test_furniture_models.gd` (cada mueble se arma con sus lugares para impresoras y cabe en el presupuesto; cada familia cabe en cada piso de la estantería; la repisa y el tablero quedan pegados a la pared o sobre su pie).
- `screenshots.sh` saca las 38 capturas. Revisé 11, 26, 37 y 38, y aparte (laboratorio) cada mueble de cerca, colgado y sobre su pie.

**Qué revisar en el teléfono** (versión web)
- La tienda, pestaña Muebles: los dibujitos de los seis muebles son los nuevos (la repisa y el tablero se ven sobre su pie).
- En las capturas 26 y 38: las cajas de colores bajo las mesas se ven abiertas (con su interior más oscuro) y arriba de cada estantería hay dos carretes parados.
- Hoy en una partida nueva no hay muebles comprados (la tienda llega con la tarea 5). Para verlos en el cuarto ya, las capturas 37 y 38 de `build/screenshots/` muestran el taller lleno de estanterías.

**Problemas conocidos**
- La estantería mide 2,40 m: puesta en el lugar del medio del cuarto tapa un poco lo que hay detrás con el zoom lejos (es su alto real).
- Las tablas de la estantería quedaron 2 cm más abajo que lo que decía la biblia, para que los tres pisos tengan 0,74 m (detalle en `docs/DECISIONES.md`).
- El mueble de cubos tiene 2 × 4 huecos (la biblia decía 2 × 2 con las mismas medidas).

### 2026-10-22 — Arte 2.0, paso 10: el personaje nuevo

**Qué se hizo**
- **El protagonista es nuevo** (decisión D3, aprobada): un joven maker de 1,40 m (el escritorio le llega a la cintura), con la cabeza grande pero no de bebé. Pelo café en mechones grandes con flequillo de lado, buzo gris carbón con la capucha enrollada (forro mostaza), cordones, bolsillo canguro y el logo de tres capas cian en el pecho, jeans con la basta doblada y zapatillas blancas con una franja cian.
- **Cara con expresiones:** ojos grandes con dos brillos, cejas gruesas, rubor y 8 caras (normal, parpadeo, feliz, preocupado, dos para hablar, concentrado y sorpresa). Cuando mira algo, gira la cabeza un poco y el resto lo hacen los ojos: así siempre se le ve la cara.
- **Se dobla de verdad:** el cuerpo es una sola pieza con "piel" (como en los juegos 3D grandes), así rodillas y codos se doblan sin cortes. Por ahora camina como antes; las animaciones nuevas (pasos, gestos, reacciones) llegan en el paso 11.
- **Contorno fino** alrededor del personaje (1,5 píxeles en cualquier zoom), para que se separe del piso.
- **Retratos:** la tarjeta de arriba a la izquierda muestra su cabeza con una luz de estudio (la cara nunca queda oscura) y **cambia de cara**: feliz cuando te pagan a tiempo, preocupado si falla una impresión, sorprendido y después feliz al subir de nivel. La pantalla Perfil lo muestra de cuerpo entero.
- El globo de diálogo ahora sale de un punto sobre su cabeza.
- **Más liviano:** el personaje pasó de 48 a 6 llamadas de dibujo; el cuarto inicial, de 75 a 33.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 630 pruebas (antes 619); 8 nuevas del personaje en `tests/unit/test_character_model.gd`, 1 de la mirada, 1 del retrato que cambia de cara y 1 de la herramienta de presupuesto.
- `screenshots.sh` saca las 39 capturas (nueva: 47, la pantalla Perfil). Revisé 32a, 32b, 32c, 33, 01, 03, 10, 31 y 47, y aparte (laboratorio) el personaje de cerca desde 6 lados y desde arriba, las 8 caras, la mirada, poses dobladas y los retratos en grande.

**Qué revisar en el teléfono** (versión web)
- Al abrir el juego: el personaje nuevo junto a la impresora. Con el zoom "Cerca" se le ven bien los ojos, el flequillo, el forro mostaza de la capucha y las zapatillas.
- Camina con el joystick: las piernas y los brazos se mueven como antes (más pausado: pasos más largos).
- Quédate quieto junto a la impresora: gira un poco la cabeza y los ojos miran hacia ella.
- La tarjeta de arriba a la izquierda: su cara. Cuando entregues un pedido a tiempo debería verse feliz unos segundos.
- Toca "Perfil" (abajo a la derecha): el personaje de cuerpo entero.

**Problemas conocidos**
- En los retratos chicos (la tarjeta del HUD) la cara se ve un poco borrosa: se dibuja a su tamaño en pantalla; el paso 16 la dibuja a la resolución del teléfono.
- En el Perfil, el buzo oscuro se lee poco sobre el fondo azul oscuro; el paso 16 agrega un disco de luz detrás de cada vista.
- La captura de la cara de muy cerca (33) se ve un poco suave: la cara está hecha para el zoom del juego.
- El paso 12 (decoración) va a necesitar subir un poco los topes de la prueba de presupuesto del cuarto inicial (detalle en `docs/DECISIONES.md`).


### 2026-10-22 — Arte 2.0, paso 10, ronda de arreglos 1: hombros y detalles del personaje

**Qué se hizo**
- **Hombros arreglados** (lo pidió la revisión): antes cada hombro era una bola pegada encima del brazo, corrida hacia un lado, y se veía un corte oscuro y una "hombrera". Ahora la punta de cada manga es redonda y lisa, de una sola pieza con el brazo, y queda metida bajo el buzo.
- **El brazo gira desde el centro del hombro:** al levantar el brazo de costado o hacia arriba la manga ya no se despega del cuerpo (antes quedaba flotando a 8 cm). Esto prepara los gestos del paso 11 (puño arriba, estirarse, saludar).
- **Brazos más delgados** que las piernas, un poco abiertos, y más redondos de cerca (también las manos y los puños). La **capucha enrollada** es más suave y sus puntas son redondas.
- **La cara de lejos:** con el zoom lejos y el normal los ojos ya no se ven como manchas grises; ahora son puntos oscuros nítidos con su brillo. De cerca se ven igual que antes.
- **El pelo visto desde arriba** ya no hace un remolino tipo molinillo, y la espalda tiene mechones de distinto ancho.
- La captura 36 (la impresora de cerca) ya no muestra la manga del personaje en el borde.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 634 pruebas (4 nuevas: la manga es una sola cúpula lisa, la manga no se despega al mover el brazo, las puntas redondas del kit y que los sombreadores numeran las superficies igual que la paleta). Una prueba adaptada: los hombros a 0,86 m (detalle en `docs/DECISIONES.md`).
- `screenshots.sh` saca las 39 capturas. Revisé 32a, 32b, 32c, 33, 01, 02, 03, 30, 31, 36, 37 y 47, y aparte (laboratorio) los hombros desde 5 lados, con los brazos adelante, atrás, de costado y arriba, el pelo desde arriba y la cara en los tres zooms.

**Qué revisar en el teléfono** (versión web)
- Zoom "Cerca" junto a la impresora: los hombros redondos, sin cortes ni bultos; la capucha suave.
- Zoom "Lejos" y "Normal": se le ven los dos ojos como puntos oscuros (no manchas).
- Camina con el joystick: los brazos se balancean sin despegarse del buzo.


### 2026-10-22 — Arte 2.0, paso 11: el personaje vivo

**Qué se hizo** (decisión D8, aprobada: solo lo visual, el juego no cambia)
- **Camina como un personaje de verdad:** a la velocidad del juego es un trote suave; las rodillas se doblan y el pie de atrás se levanta, los codos van doblados, la cadera se balancea y se inclina hacia adelante. Al arrancar se aplasta un instante y al frenar de golpe se va un poco hacia adelante y se asienta. Los pies ya no se hunden ni flotan. Si gira sin moverse, da pasitos.
- **Quieto, está vivo:** respira, cambia el peso de lado, parpadea, mira lo que tiene cerca (la cabeza y los ojos) y, si no hay nada cerca, a los 2 segundos se gira de tres cuartos hacia ti. Si lo dejas quieto 8 segundos, hace cosas solo: mira el celular, se estira, se rasca la cabeza o mira la impresora con las manos en la cintura. De noche bosteza.
- **Reacciona a lo que pasa:** al cobrar un pedido a tiempo levanta el puño feliz (atrasado, se rasca la cabeza); si falla una pieza se agarra la cabeza preocupado y mira la impresora; al subir de nivel salta (se aplasta y se estira como en los dibujos animados); cuando llega un mensaje saca el celular y lo mira; si una impresora termina a su lado, pulgar arriba; si lo tocas, se da vuelta y te saluda; si algo no se pudo, se encoge de hombros; al embalar junto al rincón, hace el gesto de embalar. Mientras habla (el globo), mueve la boca; modelando cerca del escritorio, pone cara de concentrado.
- **El pelo, los cordones y la capucha se mecen** cuando arranca, frena, gira o salta.
- Todo esto es adorno: nunca hace esperar al juego ni obliga a caminar, y caminar corta cualquier gesto.
- Sigue costando lo mismo: 6 llamadas de dibujo; el celular es parte de su malla.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 659 pruebas (antes 634): 16 nuevas del animador y 9 de las reacciones en la escena principal. Una prueba adaptada (las constantes de la mirada se leen del animador; detalle en `docs/DECISIONES.md`).
- `screenshots.sh` saca las 41 capturas (nuevas: 48, el puño arriba, y 49, las manos a la cabeza). Revisé 04 (trotando), 19 (pulgar arriba), 22 (puño arriba mientras vuela lo cobrado), 23 (manos a la cabeza junto a la impresora que falló), 48, 49, 32a–c, 33, 45 y las demás del ciclo, y aparte (laboratorio) los 12 gestos desde tres lados, el trote cuadro a cuadro y el freno.

**Qué revisar en el teléfono** (versión web)
- Camina con el joystick: rodillas y codos doblados, un trote suave; suelta de golpe y mira cómo se asienta.
- Quédate quieto en medio del cuarto: a los 2 s se gira hacia ti; espera unos 10 s más y hace algo solo (el celular, estirarse...).
- Tócalo: se da vuelta, te saluda y dice algo.
- Acepta un pedido y quédate cerca del escritorio mientras modela: cara de concentrado. Cuando la impresora termine a su lado: pulgar arriba.
- Despacha un pedido: puño arriba y cara feliz (también en la tarjeta de arriba a la izquierda).
- Si falla una pieza: se agarra la cabeza.

**Problemas conocidos**
- Visto de espaldas (por ejemplo, con un panel abierto, cuando mira el objeto) algunos gestos se leen menos (el pulgar arriba).
- "Reducir movimiento" todavía no existe en Ajustes (RUTA Fase 2); cuando exista, apagará el estirar y aplastar.



### 2026-10-22 — Arte 2.0, paso 11, ronda de arreglos 1

**Qué se hizo** (lo pidió la revisión)
- **Código muerto:** se borraron dos funciones que nadie usaba.
- **El pulgar arriba se entiende:** cuando una impresora termina a su lado, se da vuelta hacia ti, levanta el pulgar y mira la impresora de reojo (antes, de espaldas, parecía rascarse la cabeza). El pulgar del mitón ahora sale hacia adelante (como una mano relajada), así en el gesto queda hacia arriba. Con un panel abierto no se da vuelta.
- **El celular:** lo mira con las dos manos delante del pecho y la cabeza gacha (antes, de frente, parecía taparse la boca).
- **Manos a la cabeza:** ahora tocan el pelo.
- **Empujar contra una pared** ya no cuenta como estar quieto: no se gira hacia la cámara ni hace gestos sueltos mientras empujas.
- Encogerse de hombros (0,7 s) y embalar (0,6 s) duran lo que dice la biblia.
- **Capturas:** una reacción que en el juego ya habría terminado no sigue en la captura siguiente (el celular de 13 ya no aparece en 16 y 17; en 23 el personaje y el retrato están igual de tranquilos; en 20 y 21 ya no queda la cara feliz). 13 lo muestra mirando el celular y 19 con el pulgar arriba de frente.

**Verificado**
- `check.sh` (212 archivos, 0 errores) y `run_tests.sh` (663 pruebas, antes 659: 4 nuevas) pasan. Una prueba más estricta: las manos a la cabeza tienen que tocar el pelo (detalle en `docs/DECISIONES.md`).
- `screenshots.sh` saca las 41 capturas. Revisé 13, 16, 17, 19, 20, 21, 22, 23, 32a, 45, 48 y 49, y aparte (laboratorio) los 12 gestos desde tres lados y las manos de muy cerca.

**Qué revisar en el teléfono** (versión web)
- Imprime algo y quédate al lado de la impresora sin tocar nada: al terminar, se da vuelta hacia ti y levanta el pulgar.
- Espera un mensaje nuevo quieto y sin paneles abiertos: mira el celular con las dos manos.
- Empuja el joystick contra una pared un buen rato: sigue mirando hacia donde empujas, sin girarse ni hacer gestos.

**Problemas conocidos**
- De cerca, con el brazo levantado de costado o más arriba (48, 49), el hombro hace un pliegue un poco anguloso donde la manga sale del buzo; se puede suavizar ensanchando la mezcla del hombro (paso 16).
- De frente, la pantalla del celular no se ve (mira a sus ojos); se lee por la pose.
- "Reducir movimiento" todavía no existe en Ajustes (RUTA Fase 2).


### 2026-10-22 — Arte 2.0, paso 11, ronda de arreglos 2

**Qué se hizo** (lo pidió la revisión)
- **El primer gesto ya no traba un cuadro:** los datos de los 12 gestos (unos 25 KB, ~2 ms de cálculo) se arman cuando se arma el cuarto, no con la primera reacción de la partida. Antes, en un teléfono lento o en la web, la primera vez que el personaje reaccionaba (casi siempre al sacar el celular por el primer mensaje) podía perderse un cuadro. También se preparan al empezar los valores que el personaje manda a los sombreadores (pelo, cordones, cara y mirada).
- **Frenar:** al soltar el joystick corriendo, el cuerpo se va un poquito hacia adelante y se asienta (antes casi nunca pasaba). Al chocar contra una pared ya no hay ese empujón: solo se endereza.
- **Estirarse:** de frente los brazos suben en V por encima de la cabeza (antes las manos quedaban sobre el pelo y parecía agarrarse la cabeza).
- **Celular:** los codos quedan más pegados al cuerpo.
- **Captura nueva 23a:** el momento en que falla la pieza, con el personaje agarrándose la cabeza, el globo "¡Nooo! Un espagueti." y el retrato preocupado.

**Verificado**
- `check.sh` (212 archivos, 0 errores) y `run_tests.sh` (665 pruebas, antes 663: 2 nuevas, detalle en `docs/DECISIONES.md`) pasan.
- `screenshots.sh` saca las 42 capturas. Revisé 23a, 23, 13, 19, 22, 24, 48 y 49, y aparte (laboratorio) los 12 gestos desde tres lados y el celular desde cuatro.

**Qué revisar en el teléfono** (versión web)
- Abre el juego y espera el primer mensaje quieto: al sacar el celular no debe notarse ningún tirón.
- Corre y suelta el joystick: se va un poquito hacia adelante antes de enderezarse. Corre contra una pared: se detiene sin irse hacia adelante.
- Haz que falle una impresión estando cerca: se agarra la cabeza mientras sale el globo.

**Problemas conocidos**
- De cerca, con el brazo levantado (48, 49), el hombro hace un pliegue un poco anguloso (paso 16). Con el celular, de espaldas, se nota el bulto del hombro por lo mismo.
- El pulgar del mitón es chico: a zoom normal, de frente, el pulgar arriba puede leerse como "hola" (paso 16). El puño arriba es un mitón abierto, no un puño cerrado (paso 16).
- En 23a el globo del personaje tapa el ícono de aviso de la impresora; y en 22 lo cobrado que vuela se cruza con el globo del cliente (interfaz, paso 16).
- "Reducir movimiento" todavía no existe en Ajustes (RUTA Fase 2).

### 2026-10-22 — Arte 2.0, paso 12: la decoración del dormitorio

**Qué se hizo** (decisión D6: se aplica y se informa; no cambia nada del juego)
- **El cuarto ya parece habitado:** del lado derecho (antes vacío) hay una cama de una plaza con una cobija de tigre (de color apagado a propósito) doblada, sábana, almohada celeste, un dragón articulado morado impreso y, en la repisa de la cabecera, una lámpara de hongo impresa y el celular; un puf verde azulado con un control de videojuegos encima y las zapatillas tiradas al lado.
- **En el rincón del fondo:** un librero alto con libros, cajas con etiqueta (sin letras), un jarrón en espiral impreso, un dragón y un potus que cuelga; al lado, una costilla de Adán en maceta de barro que se mece suave.
- **En las paredes:** tres pósters inventados (atardecer en los cerros, una boquilla imprimiendo un barquito capa a capa y un teleférico sobre el valle), una guirnalda de 14 focos, la bufanda de un club inventado, un reloj, el calendario de la tienda del barrio, un diploma; en la pared de la ventana, el corcho con notas y la foto familiar encima, el plano de una impresora sobre la cortina, la guitarra colgada, la repisa con sus primeras impresiones y un banderín sobre la puerta. En el alféizar: una suculenta en una lata, un cactus en una maceta impresa, el barquito de prueba naranja y una alcancía.
- **En el piso:** un tapete andino tejido con flecos, un felpudo en la puerta, el basurero de impresiones fallidas con espaguetis de colores (y un barquito que falló a las dos capas al lado) y el cable del escritorio que va por la pared hasta un enchufe nuevo bajo el interruptor.
- **Polvo en el rayo de sol:** 40 motas que flotan en el haz de la ventana de día.
- **Crece contigo:** al empezar, la repisa tiene 2 piezas, el corcho 2 notas y hay una caja de filamento en el rincón derecho. En el nivel 3 ("ya vendo") la repisa se llena (aparecen el gatito que brilla en la oscuridad, un dragón y un jarrón), el corcho tiene más notas y fotos, aparece el billete enmarcado de la primera venta y el basurero se llena más. En el nivel 5 ("taller") hay una pila de cajas de filamento, una placa enmarcada y una tira LED arriba de la pared del fondo que se enciende de noche. Nada de esto cambia por dónde se camina ni quita lugares para muebles.
- **De noche** (cuando llegue el paso 13): los focos de la guirnalda, el gatito, el celular y la lámpara de la cama brillan y dejan su halo; ya está todo puesto.
- Todo cabe en 6 llamadas de dibujo (la biblia permite 7) y unos 8.600 triángulos como mucho.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 678 pruebas (antes 665): 9 de la decoración (lejos de los lugares de muebles, de la puerta y de los puntos que usan las pruebas; nada se toca; lo plano es plano; subir de nivel no cambia la grilla ni pide memoria; el polvo sale de una semilla; la cama tapa el sol y lleva su lámpara), 1 del presupuesto en cada nivel, 2 del kit de formas, 1 del polvo con la hora y el sombreador del polvo. Una prueba adaptada y el tope de llamadas del cuarto inicial sube de 37 a 41 (detalle en `docs/DECISIONES.md`).
- `screenshots.sh` saca las 42 capturas. Revisé 01, 02, 03, 05, 26, 30, 31, 34 y 37, y aparte (laboratorio) cada cosa de cerca, los tres niveles y una noche puesta a mano.

**Qué revisar en el teléfono** (versión web)
- Con el zoom lejos: el lado derecho del cuarto ya no se ve vacío (la cama, el puf, los pósters y la guirnalda).
- Acércate a la cama, al puf y al rincón del librero: nada de eso se abre al tocarlo y el personaje camina alrededor.
- Mira el rayo de sol de la ventana: hay motas de polvo que flotan.
- Sube de nivel (con el menú de pruebas cuando exista, o jugando): la repisa de la pared de la ventana y el corcho se llenan.

**Problemas conocidos**
- Armar las tres decoraciones la primera vez tarda unos 19 ms en el computador; hay que medirlo en el teléfono (paso 15).
- La guirnalda y la tira LED de día se ven finas; de noche se calibran en el paso 13.
- El polvo todavía se ve en cualquier calidad: "solo en calidad Alta" llega con el paso 15.

### 2026-10-22 — Arte 2.0, paso 13: el día y la noche completos

**Qué se hizo** (D2: no se agregan luces del motor; D8: solo lo visual, nada cambia en el juego)
- **La hora se siente:** el cuarto pasa por seis momentos según el reloj del juego: el alba (05:45, luz rosada y las lámparas todavía encendidas), la mañana (07:00–10:30, el sol entre las rejas, como hasta ahora), el mediodía (12:30, luz alta y blanca), la tarde dorada (16:30–18:00: el sol tira la sombra de la planta en la pared del fondo y los rayos de la ventana cruzan el cuarto hacia la cámara), el atardecer (19:15, la hora azul con las lámparas encendiéndose) y la noche (20:15–05:00, luz de luna azulada, lámpara cálida, monitor y guirnalda). Cambian el sol, el ambiente, la luz de la ventana, el fondo detrás del cuarto y lo que se ve por la ventana (de noche: estrellas, luna y ventanas encendidas en el barrio).
- **Nunca de golpe:** entre un momento y otro la luz se mezcla suave, y cada minuto del reloj llega mezclándose en 2 segundos. Al abrir el juego o cargar una partida, la luz de esa hora aparece de una vez.
- **La noche se lee en el teléfono:** el piso lejos de las luces se ve claro (una prueba hace la cuenta y exige al menos 70 de 255 de brillo en un gris medio) y el personaje se separa del piso con su contorno y el relleno extra de noche.
- **Luces de noche:** la lámpara del escritorio deja una mancha cálida sobre la mesa y el monitor un resplandor; los 14 focos de la guirnalda parpadean suave, cada uno a su ritmo; el borde de la base brilla apenas en azul; en el taller (nivel 5) la tira LED lava de cian la pared del fondo. Las impresoras muestran su estado con un halo más fuerte que antes (cálido imprimiendo, verde lista, rojo con falla), y así el taller lleno se lee de noche.
- Nada de esto agrega luces del motor ni llamadas de dibujo: de noche el cuarto inicial usa 38 llamadas, igual que de día.
- **Capturas nuevas:** 41 y 42 (tarde dorada con y sin interfaz), 35 y 36b (noche sin y con interfaz), 44 (alba) y 43 (el taller lleno de noche, con impresoras en cada estado).

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 692 pruebas (antes 678): 8 nuevas del día y la noche (cada momento igual a la biblia, sin saltos minuto a minuto, mezcla suave, la lámpara apagada a las 10:00 y encendida a las 22:00, el piso de noche, el fondo y la ventana por momento, el reloj que mezcla y la carga que no, sin memoria nueva), 5 del cuarto de día y de noche, 1 del presupuesto de noche y 1 del kit de formas. Dos pruebas adaptadas (detalle en `docs/DECISIONES.md`).
- `screenshots.sh` saca las 48 capturas. Revisé las seis nuevas, la 30, la 37 y las del ciclo de pedidos (siguen en la mañana: llegan hasta las 10:27).

**Qué revisar en el teléfono** (versión web)
- El día del juego dura una hora real y el juego todavía no avanza con la app cerrada (la partida sigue a la hora en que la dejaste): juega o déjalo abierto. Desde las 08:00 de una partida nueva, la tarde dorada (16:30) llega a los ~21 minutos reales, el atardecer (19:15) a los ~28 y la noche (20:15) a los ~31. La hora está arriba, junto al día.
- En la tarde dorada: la pared del fondo se pone naranja y la sombra de la planta cae sobre ella; los rayos de la ventana cruzan el piso.
- De noche, con el brillo del teléfono bajo: ¿el piso, los muebles y el personaje se distinguen bien? ¿Los focos de la guirnalda parpadean suave (no molestan)? ¿Se ve la lámpara del escritorio y el resplandor del monitor?
- Mientras cambia la hora (por ejemplo entre las 18:00 y las 20:15), la luz debe cambiar sin saltos.

**Problemas conocidos**
- El atardecer (19:15) es el momento más oscuro del día (así lo dice la biblia). Si se ve muy oscuro en el teléfono, se puede subir su ambiente.
- Para mirar la noche sin esperar hace falta el menú de pruebas (tarea 4 de la Fase 1) o el panel `#debug` del paso 15.

### 2026-10-22 — Arte 2.0, paso 13, ronda de arreglos 1

**Qué se hizo** (lo pidió la revisión; no cambia nada de lo que se ve)
- **Las luces de noche, comprobadas donde de verdad alumbran:** el ciclo del día guardaba dónde estaba cada lámpara en dos lugares y uno ya no se usaba (se borró). Las pruebas que miran dónde está la lámpara del escritorio, el monitor, la lámpara de la cama y el LED de la impresora ahora miran lo mismo que recibe el sombreador (lugar y alcance), así un error en eso ya no pasaría sin que nadie lo note.
- La prueba del presupuesto de noche también mide los triángulos; la de los sombreadores suma dos que faltaban.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 693 pruebas (una nueva y tres adaptadas, detalle en `docs/DECISIONES.md`). `screenshots.sh` saca las 48 capturas, iguales a las de antes del arreglo.

**Qué revisar en el teléfono:** lo mismo del paso 13 (nada visible cambió).


### 2026-10-22 — Arte 2.0, paso 13, ronda de arreglos 2

**Qué se hizo** (lo pidió la revisión; no cambia nada de lo que se ve)
- **Las pruebas del día y la noche pasan por el cuarto de verdad:** la revisión mostró que dos errores posibles no los notaba ninguna prueba: que la luz se quede congelada en la hora de la carga, o que al cargar una partida la luz se mezcle en vez de aparecer de una vez. Ahora una prueba carga una partida de noche con el cuarto ya armado de mañana y otra deja correr los cuadros del juego de verdad mientras la luz llega a la hora del reloj. Comprobado rompiendo el código a propósito: con cada error, una prueba falla.
- **La tarde dorada y el alba, medidas:** son las horas con más cosas a la vez (los halos de noche a medias y el polvo del haz). Una prueba nueva las mide: caben en los topes, salvo una superficie transparente más en el cuarto inicial (10 en vez de 9, bajo el tope final de 12); tiene su propio tope, anotado en `docs/DECISIONES.md`.
- La prueba del piso de noche lee los números del sombreador en vez de copiarlos, y otra avisa si el balance acorta el minuto de juego por debajo de lo que dura la mezcla de la luz (2 s).

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 696 pruebas (tres nuevas y cuatro adaptadas, detalle en `docs/DECISIONES.md`). `screenshots.sh` saca las 48 capturas; las de la tarde, la noche y el alba son idénticas al píxel a las de antes.

**Qué revisar en el teléfono:** lo mismo del paso 13 (nada visible cambió).


### 2026-10-22 — Arte 2.0, paso 14: la firma (lo que se compra se imprime en su lugar)

**Qué se hizo**
- **Lo nuevo aparece imprimiéndose:** cuando en el cuarto aparece un mueble o una impresora, se imprime en su lugar de abajo hacia arriba: lo ya impreso es sólido, con sus capas y una línea caliente naranja en el corte; por el corte se ve el relleno en cuadrícula; y encima, solo las líneas de las capas que faltan, en cian, como la vista previa del programa de impresión. Un mueble tarda 1,6 segundos y una impresora 1,2; las impresoras de un mueble nuevo esperan a que termine su mueble. Tocar el mundo lo termina al instante (el toque igual hace lo suyo: caminar, abrir un panel). Al terminar vuelve el material de siempre: no cuesta nada después.
- **El cuarto sigue al estado:** antes el cuarto se armaba una sola vez, al abrir el juego. Ahora `RoomView.sync_models()` compara la partida con lo que se ve: arma lo que falta, quita lo que sobra y vuelve a armar lo que cambió de modelo o de lugar, y rehace todo lo que depende de eso (lugares libres, lo que se toca, por dónde se camina, las manchas del piso, los halos de noche, las luces del escritorio y de la impresora del piso, las burbujas de estado). Al cargar otra partida el cuarto queda igual a ella, de una vez y sin efecto (antes se quedaba con los muebles de la anterior). Si se abría el panel de algo que ya no está, se cierra.
- **Listo para la tienda:** todavía no existe el comando de compra (tarea 5). Cuando exista, solo tiene que agregar lo comprado al estado y pedir `sync_models()`: el efecto ya está.
- Captura nueva: `39_compra_imprimiendose` (una estantería de cubos y una impresora a mitad de imprimirse, junto a la impresora del piso). En `19_pieza_lista` ahora se ven los destellos de "lista".

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 709 pruebas (antes 696): 12 nuevas del cuarto que sigue al estado y 1 de los materiales "imprimiéndose". Ninguna prueba se adaptó (detalle en `docs/DECISIONES.md`). Comprobado rompiendo el código a propósito de 12 maneras (sin cargar el cuarto al cargar la partida, sin terminar con el toque, sin la espera de las impresoras, sin manchas del piso, sin efecto, sin devolver el material, sin obstáculos, sin burbujas, sin cerrar el panel, sin quitar la baldosa, sin sacar al personaje del mueble nuevo, sin halos): cada vez falla al menos una prueba.
- `screenshots.sh` saca las 49 capturas. Las demás son iguales a las del paso 13 (salvo lo que se mueve solo: cabezales, la pista de caminar y un parpadeo del personaje).

**Qué revisar en el teléfono** (versión web)
- En el juego todavía no se puede ver el efecto: no hay compras (llegan con la tarea 5). Mientras, la captura `39_compra_imprimiendose` muestra cómo se verá.
- Que nada cambió al jugar: el cuarto inicial, tocar objetos, caminar entre los muebles y "Nueva partida" en Ajustes funcionan igual que antes.

**Problemas conocidos**
- Los destellos de "pieza lista" se leen poco sobre el piso al sol (se ven mejor a la sombra o de noche); se revisa con la interfaz en el paso 16.
- Si la compra llega con la tienda abierta, el efecto pasaría detrás de la tienda: la tarea 5 debería pedir `sync_models()` al volver al cuarto.

### 2026-10-23 — Arte 2.0, paso 15: rendimiento (calidad gráfica, zoom lejos y panel de depuración)

**Qué se hizo**
- **Calidad gráfica** (decisión D7 del dueño): en Ajustes, "Calidad gráfica: Automática / Alta / Baja". **Alta** es lo de siempre (el mundo hasta 1.080 px de ancho, bordes suavizados 4×, sombras del sol, polvo en el haz). **Baja** dibuja el mundo hasta 720 px con suavizado 2×, sin las sombras del sol ni el polvo, y oscurece un poco más el piso bajo las cosas para que no se vean flotando; los colores, la luz de la ventana, las lámparas, los halos y el contorno del personaje son iguales. **Automática** (la de un jugador nuevo) empieza en Alta, mide los primeros segundos de juego y, si el teléfono va lento (más de 24 ms por cuadro, o sea menos de unos 40 cuadros por segundo), pasa a Baja una vez y lo recuerda. Debajo de las opciones dice en qué nivel se ve ahora. Las vistas 3D de la interfaz (el retrato, la tienda) siguen al nivel.
- **Zoom lejos más liviano:** con el zoom lejos cada impresora pasa a una versión lejana: menos detalle y sin lo que se mueve (la barra y el cabezal; en la de resina, la placa), pero con la pieza que crece y su capa naranja, el espagueti de las fallas, la pantallita y la luz de adentro de las cerradas. El taller lleno pasa de 133 a 90 llamadas de dibujo (−32 %); con trabajos, de 148 a 103.
- **Sombras como dice la biblia:** en las impresoras de las estanterías solo el cuerpo da sombra (las piezas, los espaguetis y las bandejas ya no): el taller lleno con trabajos bajó de 161 a 148 llamadas con el zoom normal.
- **Panel de depuración** para medir en el teléfono (ver abajo). Además deja probar el cuarto inicial, el taller lleno y la mañana, la tarde o la noche **sin tocar tu partida**: guarda la tuya antes y después no guarda nada hasta que vuelvas a abrir el juego.
- Capturas: nueva `30_heroe_sin_hud_baja` (el cuarto en Baja). Las que tienen el zoom lejos muestran la versión lejana de las impresoras.

**Verificado**
- `check.sh` y `run_tests.sh` pasan: 740 pruebas (antes 709; 31 nuevas). Tres archivos de prueba se adaptaron sin debilitarlos (detalle en `docs/DECISIONES.md`). Comprobado rompiendo el código a propósito de 11 maneras: cada vez falla al menos una prueba.
- `screenshots.sh` saca las 50 capturas; las de zoom normal son iguales a las del paso 14 salvo lo que se mueve solo.

**Qué revisar en el teléfono** (versión web) — **esto reemplaza a "el dueño reporta desde su teléfono"**
1. Abre la versión web con `#debug` al final de la dirección (por ejemplo `.../index.html#debug`) o, dentro del juego, toca **cinco veces seguidas** la tarjeta de arriba a la izquierda (tu retrato y el nivel). Se abre el panel de depuración.
2. Anota, con el juego quieto unos segundos en cada caso, los **cuadros por segundo** y las **llamadas de dibujo** (el botón **Menos** deja el panel solo con los números para ver el cuarto; **Más** devuelve los botones):
   - cuarto inicial de día (botones "Cuarto inicial" y "Mañana");
   - cuarto inicial de noche ("Noche");
   - taller lleno de día y de noche ("Taller lleno", "Mañana", "Noche"), con el zoom normal y con el zoom lejos;
   - todo lo anterior en **Alta** y en **Baja** (los botones de calidad del panel).
3. Anota la línea **ColorProbe** (debe decir "medido"; si dice "fuera de rango", mándame los números) y compara tu pantalla con la captura `00_calibracion`.
4. Anota la línea **Armado del cuarto** ("la primera vez"): si pasa de 1.000 ms, el juego tarda en arrancar y lo arreglamos (decisión D4: armar durante una pantalla de carga).
5. Prueba **Automática** en Ajustes: si en tu teléfono Alta va a menos de unos 40 cuadros por segundo, la automática debería pasar sola a Baja a los pocos segundos (en Ajustes dice "Ahora: Baja"). Elegir Automática otra vez la hace medir de nuevo. Si Alta va entre 40 y 60 se queda en Alta (es el umbral de la biblia, 24 ms por cuadro): si así se siente trabado, dímelo y bajamos el umbral para que pase a Baja por debajo de 60 (es un solo número).
6. Mira si **Baja** se ve bien (debería verse igual que Alta pero sin sombras) y si con el **zoom lejos** las impresoras se ven bien (no deberían faltar cosas importantes; la impresora del piso pierde la barra y el cabezal, se sigue viendo la pieza con su capa naranja).
7. Para volver a tu partida después de probar escenas, vuelve a abrir el juego (o recarga la página).

**Problemas conocidos**
- Nada medido todavía en un teléfono: los números de rendimiento son del computador sin tarjeta de video (llvmpipe), que no sirven para comparar con un teléfono.
- El ahorro del zoom lejos con trabajos queda justo en el 30 % que pide el plan (una llamada más por impresora lo rompería; la prueba avisa).
- Con el zoom lejos la impresora del piso no muestra la barra ni el cabezal moviéndose. Si se nota feo en el teléfono, se puede dejar completa (cuesta 6 llamadas).


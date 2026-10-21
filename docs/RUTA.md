# Ruta de desarrollo — "Capa a Capa"

> **Versión 1.1 (2026-10-21), aprobada por el dueño.** Reemplaza la tabla de fases del GDD (sección 15), que ahora apunta aquí. Las respuestas del dueño están en la sección 11.
>
> - Qué es el juego: `docs/GDD.md`.
> - En qué vamos: `docs/PROGRESO.md`.
> - **Esta ruta:** hacia dónde vamos, en qué orden y por qué.
>
> Lo marcado con **(cambia el GDD)** ya está aprobado y pasado al GDD (versión 2.2).

---

## Resumen en un minuto

- **Dónde estamos:** el juego ya **se ve** bien: la habitación en pixel art, la interfaz completa y una tienda con precios reales. Pero todavía **no se puede jugar**: no se compra, no llegan pedidos, no se imprime y no se guarda la partida.
- **Qué propongo:**
  1. Llegar cuanto antes a un ciclo que se pueda jugar en el teléfono, con buenos controles desde el principio.
  2. Darle vida: personaje que camina y trabaja, sonidos, animaciones y vibración.
  3. Pulir la experiencia (UX/UI) y el tutorial.
  4. Llenarlo de contenido y balancearlo.
  5. Móvil y publicación, y después actualizaciones.
- **Cómo:** cada tarea es un PR pequeño que trae **lógica, interfaz y respuesta visual juntas**. Después de cada PR podrás probar algo nuevo en tu teléfono.

| Fase | Nombre | Al terminarla podrás... | Tareas |
|---|---|---|---|
| 0 | Base | Abrir el juego desde un enlace | Hecha |
| 1 | **Ciclo jugable** | Jugar el ciclo completo (pedido → imprimir → cobrar → comprar), con controles táctiles y la partida guardada | 9 |
| 2 | **Personaje vivo y game feel** | Sentir que el juego responde: sonidos, animaciones, vibración; el personaje camina y trabaja | 5 |
| 3 | **UX/UI y primera experiencia** | Prestarle el teléfono a alguien que nunca lo jugó y que lo entienda solo | 5 |
| 4 | **Contenido y MVP completo** | Jugar del nivel 1 al 5 y mudarte al garaje | 6 |
| 5 | Móvil y rendimiento | Instalarlo en Android y en iPhone | 6 |
| 6 | Publicación | Verlo en Google Play y en la App Store | 4 |
| 7 | Después del lanzamiento | Recibir actualizaciones de contenido | Continuas |

**Tiempo aproximado:** si se cierran 3 o 4 tareas por semana, la Fase 1 toma unas 3 semanas, el MVP completo (Fase 4) unos 2 meses y la publicación unos 3 a 4 meses. La prueba cerrada de Google Play sola dura 14 días. Son estimaciones: dependen de cuánto tiempo tengas para revisar.

**Game feel** quiere decir "la sensación al tocar": que cada toque tenga una respuesta inmediata y satisfactoria (un sonido, un rebote, monedas que vuelan). Es lo que hace que un juego sencillo se sienta bien.

---

## 1. Dónde estamos

### Lo que ya está bien
- **Arquitectura sana:** la lógica (`core/`) está separada de los gráficos, todos los números viven en `data/*.json`, hay un validador de datos y 50 pruebas automáticas.
- **Estilo propio y coherente:** pixel art hecho con 3D, interfaz con un tema común y guía de estilo (`docs/ESTILO.md`).
- **Catálogo con precios reales** (`docs/REFERENCIAS.md`) e integración continua con versión web publicada.

### Lo que falta o hay que corregir
Revisé capturas de todas las pantallas de la versión actual:

1. **No se puede jugar.** Es lo más importante.
2. **El mundo no responde al dedo.** La cámara está fija; no se puede tocar la impresora, los lugares libres ni el personaje.
3. **La impresora se ve diminuta:** unos 90 píxeles de alto en una pantalla de 1280, menos del 8% de la altura. El detalle más importante del juego, la pieza que crece capa a capa (GDD, sección 8), no se va a notar si no se puede acercar la cámara.
4. **Demasiadas entradas:** hay 9 botones (5 abajo, 3 a la izquierda y ajustes). "Taller" e "Inventario" muestran casi lo mismo (los muebles), y "Tareas" repite el panel de objetivos.
5. **Lo más usado queda lejos del pulgar.** "Pedidos", el corazón del juego, está arriba a la izquierda, mientras que abajo hay secciones de poco uso, como "Perfil".
6. **El HUD tapa la habitación:** el panel de objetivos y los botones laterales cubren la pared, la ventana y parte del piso.
7. **Los tiempos se leen mal.** Una maceta dice "2 h", pero en realidad se espera 5 minutos (1 día de juego = 1 hora real). Un jugador nuevo puede pensar que debe esperar dos horas.
8. **No hay sonido, vibración ni animaciones de respuesta.**
9. **Contenido corto:** 12 pedidos y 6 tipos de cliente se repiten rápido, y los clientes no tienen cara ni personalidad.
10. **Balance sin probar:** el simulador todavía no existe.

### Riesgos y cómo se manejan

| Riesgo | Cómo se maneja |
|---|---|
| Querer hacer todo: es un proyecto de una persona | Cada fase tiene un criterio de terminado. Las ideas nuevas van a la Fase 7, no se cuelan en la fase actual |
| El contorno pixel art dibuja cada objeto dos veces: con 40 impresoras en el garaje puede ir lento | Prueba de estrés en la Fase 4, antes de llenar el garaje, y optimización en la Fase 5 |
| Mucho realismo puede aburrir | Regla de la sección 2: real en lo que se ve, generoso en lo que se espera |
| Probar el juego avanzado toma horas | Menú de pruebas oculto desde la Fase 1 (sección 10) |
| iOS necesita un Mac | Decidir antes de la Fase 5 (sección 11) |
| Google Play exige 12 testers durante 14 días | Empezar a reunirlos en la Fase 5 |

---

## 2. Principios de la ruta

1. **Jugable en cada PR.** Si un PR no cambia algo que puedas probar en el teléfono, debe ser muy pequeño o tener un motivo claro.
2. **Rebanadas completas.** Cada función llega con su lógica (con pruebas), su interfaz y una respuesta mínima (animación o sonido simple). Las Fases 2 y 3 la pulen, pero nunca llega "a medias".
3. **Real en lo que se ve, generoso en lo que se espera.** Los precios, materiales, máquinas, fallos y proporciones de tiempo vienen de la vida real. El tiempo se comprime (×24) y lo que solo castiga (luz, arriendo, impuestos) se deja fuera.
4. **Primero el ciclo, después el contenido.** Escribir 40 pedidos antes de tener el simulador sería balancearlos a ciegas y rehacerlos.
5. **Medir antes de ajustar.** Los cambios de balance se prueban con el simulador y con personas reales.
6. **Los pilares del GDD son el filtro.** Ver crecer el taller, decisiones con sentido, autenticidad con humor y respeto por el jugador. Lo que no apoya ninguno no entra.

---

## 3. La vida real en el juego

El juego se basa en la impresión 3D real. Esta tabla dice qué se toma de la realidad, qué se comprime y qué se deja fuera. Los datos y las fuentes están en `docs/REFERENCIAS.md`, en la sección "Datos reales para el diseño".

| Variable | En la vida real | En el juego | Cuándo |
|---|---|---|---|
| **Precio** de máquinas, materiales, accesorios y muebles | Precio de lista de 2026 | Igual, redondeado | Ya está |
| **Velocidad** de las máquinas | Una impresora moderna es de 2 a 5 veces más rápida que una clásica | De 1,0× a 2,5×: comprimido para que la Cubo Uno no quede inútil | Ya está |
| **Calidad y tiempo** | Capas más finas tardan más (0,28 / 0,20 / 0,12 mm) | Borrador ×0,6, Normal ×1,0, Fino ×1,6 | Ya está |
| **Preparación de cada pieza** | Calentar la cama, nivelar y retirar la pieza: de 3 a 8 minutos | **Propuesta:** +5 minutos de juego por pieza | Fase 1 |
| **Costo del material** | Gramos × precio por gramo (el PLA cuesta unos $0,018 el gramo) | **Propuesta:** mostrar el costo y la ganancia al asignar | Fase 1 |
| **Precio de venta** | Los talleres cobran material + hora-máquina ($2 a $8 la hora) + margen | Los pagos actuales ya coinciden (ver más abajo) | Ya está |
| **Fallos** | Máquina clásica mal calibrada: 10–20% de fallos; moderna con autonivelado: 2–5% | Cubo Uno 85% de fiabilidad (bien). **Propuesta:** subir las modernas de 92–94% a 95–97% | Fase 1 (simulador) |
| **Causas de fallo** | Primero la adherencia (warping); el espagueti es consecuencia de que la pieza se despegó | Espagueti y warping al azar; la cámara y la lámina PEI los reducen | Fase 1 |
| **Aprender reduce fallos** | En un estudio, leer el material de capacitación bajó los fallos de 33% a 6% | **Propuesta:** el Manual del maker da un pequeño bono de fiabilidad | Fase 3 |
| **Envíos** | En Latinoamérica tardan de 5 a 60 días; una tienda local, de 1 a 5 | De 3 a 7 días de juego (3 a 7 horas reales); exprés en 1 día; ferretería al instante pero 50% más cara | Fase 1 |
| **Electricidad** | Una impresora gasta de 1 a 3 centavos de dólar por hora | No se cobra (GDD 5.3). Puede aparecer como dato curioso | — |
| **Resina** | Tarda lo mismo con 1 que con 20 piezas en la placa: solo cuenta la altura | Placa múltiple | Fase 7 |
| **Placas múltiples (FDM)** | Varias piezas a la vez ahorran preparación, pero un fallo puede arruinar toda la placa | Decisión de riesgo contra eficiencia | Fase 7 |
| **Humedad** | El nylon se humedece en horas, el TPU en un día y el PETG en días; salen hilos y burbujas que suenan como tocino friéndose | Caja seca y secador | Fase 7 |
| **Desgaste de la boquilla** | La de latón dura años con PLA, pero el PLA que brilla en la oscuridad la gasta en 0,5–2 kg | Mantenimiento y boquilla endurecida | Fase 7 |
| **Día y noche** | Los clientes escriben de día | La ventana cambia de color. **Propuesta:** de noche llegan menos pedidos | Fase 2 y Fase 4 |

### Los pagos actuales ya son realistas
Un taller real cobra así: el material más 10% de desperdicio, de $3 a $5 por hora de máquina, unos $2 de trabajo por pieza y un 30% de margen. Con esa fórmula, los pagos del juego quedan dentro de lo real:

| Pedido | Material | Tiempo | Con la fórmula de un taller | En tiendas en línea | Pago en el juego |
|---|---|---|---|---|---|
| Llavero | 8 g ($0,16) | 20 min | $4 a $5 | $2 a $5 (personalizado, hasta $12) | $6 |
| Maceta | 80 g ($1,60) | 2 h | $13 a $18 | $16 a $22 | $18 |
| Organizador | 180 g ($3,60) | 6 h | $31 a $46 | $10 a $52 | $38 |
| Casco de cosplay | 1,3 kg ($26) | 33 h | $180 a $265 | $65 a $120, sin pintar | $240 |

El casco paga más que en las tiendas en línea, y está bien: es el gran pedido de esa etapa.

Lo real también da decisiones: **los pedidos cortos pagan más por hora pero exigen volver seguido**; los largos sirven para dejarlos corriendo cuando te vas. Y en la vida real **los repuestos pagan mucho más que los adornos** (una perilla descontinuada se vende entre $13 y $67, un llavero entre $2 y $5). Los pedidos de talleres deben sentirse como "el buen negocio".

---

## 4. Controles: movimiento y acciones

### 4.1 Decisión: el personaje se maneja con un joystick

Se propusieron tres opciones (A: tocar y el personaje lo hace; B: joystick; C: personaje decorativo). **El dueño eligió la B, el joystick.** Para que no traiga los problemas que se anotaron (sesiones cortas, una mano, muchas impresoras más adelante), se armó así, después de una revisión con tres críticos (ergonomía móvil, juegos con joystick y riesgos técnicos en Godot):

- **Joystick flotante:** aparece donde se apoya el pulgar, así que se juega con una mano.
- **Tocar un objeto abre su panel al instante**, sin caminar hasta él. Tocar el piso hace caminar solo al personaje (sirve a quien no quiere o no puede usar el joystick).
- **Regla de diseño:** caminar nunca es obligatorio para decidir, ni bloquea pagos ni el progreso fuera del juego (GDD, sección 7.1). Si más adelante alguna acción pide ir hasta un lugar, será corta, dará gusto y se podrá automatizar: un ayudante, zapatillas más rápidas, recoger varias piezas de una pasada.

### 4.2 Joystick y personaje (Fase 1, tarea 2)
- **Aro bajo el pulgar:** aparece al arrastrar más de 16 px. El personaje llega a la velocidad máxima con unos 60 px de recorrido; desde el primer paso camina al 35%, para que no se sienta lento. Si el dedo se sale del aro, el aro lo sigue y cambiar de dirección es inmediato.
- **Dirección corregida:** la vista inclinada aplasta la profundidad a la mitad. Sin corregir, un arrastre en diagonal movería al personaje unos 20° desviado; con la corrección va justo hacia donde apunta el pulgar.
- **Choques sin motor de física:** el personaje es un círculo que no atraviesa muebles ni impresoras y los rodea por las esquinas sin trabarse.
- **Animación por código:** piernas y brazos se mueven según la distancia caminada (los pies no patinan), se inclina un poco al caminar, respira quieto y mira lo que tiene cerca.
- **Toques del sistema:** si el dedo sale de la pantalla, llega una notificación o la app pasa a segundo plano, el joystick se suelta solo. Los toques muy cerca de los bordes izquierdo y derecho no mueven al personaje, porque ahí están los gestos de "atrás" del teléfono.

### 4.3 Tocar el mundo y cercanía

| Gesto | Qué pasa |
|---|---|
| Tocar una impresora, un mueble, un lugar libre o la puerta | Se abre su panel inferior. El personaje se gira a mirarlo |
| Tocar el piso | El personaje camina hasta ahí; un círculo cian marca el destino |
| Tocar al personaje | Dice una frase graciosa |
| Tocar el mundo con un panel abierto | Si es otro objeto, cambia el panel; si no, lo cierra (y no camina) |
| Arrastrar con un panel abierto | Cierra el panel y camina |
| Caminar cerca de una impresora, un mueble o la puerta | Marco cian en el piso y burbuja encima. Tocar la burbuja abre el panel |

- Cada objeto se puede tocar aunque se vea pequeño: hay un área mínima de 88 px.
- Una impresora gana sobre la mesa donde está, y el resalte no salta entre objetos vecinos: se mantiene hasta alejarse un poco más.
- Los lugares libres no se resaltan al pasar (cubren mucho piso); solo se tocan.
- Todo número que muestra un panel sale de `core/` y `data/` (por ejemplo, la fiabilidad con la penalización del suelo).

### 4.4 Cámara
- **Sigue al personaje** y lo deja un poco arriba del centro de la parte visible, para que el pulgar no lo tape.
- **Tres niveles de zoom:** normal (la vista de siempre), cerca (el doble) y lejos (todo el cuarto). Con el botón de abajo a la izquierda, pellizcando o con la rueda del mouse.
- **No se sale del cuarto.** Con un panel abierto, encuadra el objeto encima del panel.
- **Pixel art sin temblor:** la cámara y el personaje se mueven de píxel en píxel del dibujo, y la fracción que falta se compensa corriendo la imagen. El movimiento se ve suave y los bordes no tiemblan.

### 4.5 Notas técnicas (para Claude)
- **Entrada:** `WorldControls` (`game/world/world_controls.gd`) es un Control de pantalla completa entre la vista del mundo y el HUD. Recibe los toques en `_gui_input`, porque `_unhandled_input` pierde los arrastres cuando el dedo pasa sobre un botón (comprobado en Godot 4.7.2). Ignora los eventos de mouse que el sistema inventa al tocar (`DEVICE_ID_EMULATION`) y trata al mouse real como un dedo más.
- **Gestos:** `TouchTracker` (puro, con pruebas) decide si fue toque, joystick o pellizco.
- **Personaje:** `CharacterController` con `WalkGrid` (choques círculo contra rectángulo y caminos con `AStarGrid2D`) y `ReachTracker` para la cercanía.
- **Cámara:** `CameraRig`. Cada cuadro, `WorldControls` llama a `RoomView.step()`, que mueve al personaje, lo ajusta a los píxeles y después mueve la cámara.
- **Selección:** rayo contra las cajas de cada objeto (`PropBounds`, calculadas con las medidas de las formas), sin motor de física.
- **Valores de sensación:** todos en `ControlsTuning`. Los principales los fijó el dueño probándolos en su teléfono: caminar a 2,2 m/s, joystick de 60 px, cámara de 0,10 s y resaltar a 0,60 m.

## 5. Jugabilidad: el ciclo y sus decisiones

### 5.1 Un pedido, paso a paso (Fase 1)
1. **Llega un mensaje** al chat de Pedidos: burbuja con número, sonido de mensaje y la frase del cliente.
2. **Lo abres:** tarjeta con los requisitos en iconos (tamaño, calidad, material, multicolor, plazo), el pago y la XP. Botones **Aceptar** y **Rechazar**.
3. **Imprimir:** el juego **recomienda** impresora, material y modo y muestra: tiempo (en tiempo real), calidad, riesgo de fallo, costo del material y ganancia. Un toque en "Imprimir"; "Cambiar" para elegir otra cosa. Si algo no sirve, dice por qué ("No cabe: la Rayo Mini es tamaño S").
4. **La pieza crece** capa a capa en la impresora, con una burbuja de avance encima.
5. **Termina:** burbuja ✓ sobre la impresora. **Pendiente de decidir antes de la tarea 7** (sección 11): o se cobra tocando la impresora, o el personaje recoge la pieza y la lleva a una caja de despacho junto a la puerta, al estilo de los juegos con joystick.
6. **Cobras:** monedas que vuelan al contador, "+$6" flotante y la barra de XP que se llena.

### 5.2 Las decisiones que hacen el juego (pilar 2)
- **Qué pedido aceptar:** corto y bien pagado por hora, contra largo para dejarlo corriendo; con plazo o sin plazo; mucha XP o mucho dinero.
- **En qué impresora y en qué modo:** rápido y arriesgado (Borrador) o lento y seguro (Fino).
- **Cuándo comprar material:** el envío tarda días; exprés cuesta $12 más; la ferretería es inmediata pero 50% más cara.
- **En qué invertir:** otra impresora, un mueble para que quepa o un accesorio que evita fallos.

### 5.3 Ritmo: metas para el balance
Son metas para el simulador, no reglas fijas. Aprobadas por el dueño y pasadas al GDD (sección 5.15).

| Momento | Meta (jugando sesiones cortas de 2 a 5 minutos) |
|---|---|
| Primera venta | Menos de 2 minutos desde que abres el juego por primera vez |
| Comprar la mesa auxiliar | En la primera sesión (llega en la siguiente) |
| Nivel 2 | Primer día |
| Segunda impresora | Día 1 o 2 |
| Nivel 3 | Día 3 o 4 |
| Nivel 4 y mudanza al garaje | Día 7 a 10 |
| Nivel 5 y resina | Día 10 a 14 |
| Nunca quedarse atascado | Siempre (rescate de Don Ernesto) |

---

## 6. Game feel: que cada toque se sienta bien

| Momento | Qué se ve | Qué se oye | Vibración | Fase |
|---|---|---|---|---|
| Tocar un botón | Se hunde y rebota | Clic suave | Muy leve | 2 |
| Abrir o cerrar un panel | Sube desde abajo en 0,2 s | Deslizamiento | — | 2 |
| Empieza una impresión | El cabezal se mueve, el carrete gira y la pantalla de la impresora muestra el % | Pitido y motores en bucle, distintos para cada familia de impresoras | Leve | 1 (básico) y 2 |
| La pieza crece | Sube capa a capa, en escalones de un píxel | — | — | 1 |
| Termina | Burbuja ✓, brillo y la pieza da un salto | "Ding" | Leve | 1 |
| Entregar y cobrar | Monedas vuelan de la impresora al contador, que sube rodando; "+$6" flotante; la barra de XP se llena | Caja registradora | Media | 1 (básico) y 2 |
| Subir de nivel | Celebración en pantalla con confeti pixel y tarjetas de lo desbloqueado ("¡Nuevo! Rayo X1") | Fanfarria corta | Fuerte | 2 |
| Fallo | Nido de espagueti o pieza curvada; el personaje se agarra la cabeza; frase de Don Ernesto | Trombón triste corto | Doble | 1 (básico) y 2 |
| Llega un envío | Caja en la puerta; al tocarla se abre y lo comprado vuela a su lugar | Toc-toc | Leve | 1 (básico) y 2 |
| Nuevo mueble | Cae desde arriba con rebote y una nubecita de polvo | Golpe de madera | Media | 2 |
| Nueva impresora | Unboxing especial: se abre la caja y aparece la impresora con brillo | Fanfarria | Fuerte | 2 |
| Mensaje nuevo | Número sobre Pedidos | "Ping" de mensaje | Leve | 1 |
| Objetivo cumplido | La fila se marca ✓ y la recompensa vuela | Campanita | Leve | 2 |
| Paso del tiempo | La ventana cambia de color con la hora y de noche se enciende la lámpara del escritorio | — | — | 2 |

**Reglas:**
- La respuesta llega en **menos de 0,1 segundos** después del toque.
- El temblor de pantalla solo se usa en momentos grandes (subir de nivel), nunca en acciones comunes.
- Ajustes para **vibración**, **reducir movimiento** y **volumen** de música y efectos.
- Rendimiento: las partículas y números flotantes se reutilizan; nada de crear objetos en cada cuadro (`CLAUDE.md`).
- **Notas técnicas:** un nodo `Feedback` dentro de la escena principal (no un autoload nuevo) con grupos de números flotantes, monedas y avisos; `CPUParticles2D` para la interfaz; `Input.vibrate_handheld()` para la vibración (en iPhone desde el navegador no vibra; en la app sí); buses de audio Master, Música, Efectos e Interfaz.
- **Sonidos:** packs de Kenney (CC0) y efectos generados con herramientas como jsfxr. Todo queda registrado en `assets/CREDITS.md`.

---

## 7. UX/UI: problemas y cambios

### 7.1 Navegación nueva **(cambia el GDD, sección 7)**

```
Hoy (9 entradas)                         Propuesta (5 abajo + 3 atajos)
┌ retrato ┐ ┌ $ ┐ ┌⚙┐                    ┌ retrato→Perfil ┐ ┌ $ ┐ ┌⚙┐
Pedidos  ┌ Objetivos ┐                   [▸ Siguiente: entrega 3 llaveros 1/3]
Tareas   │           │
Mapa     └───────────┘                         (más habitación visible)
Inicio·Taller·Inventario·Tienda·Perfil   Inicio·Pedidos·Tienda·Inventario·Tareas
```

- **Abajo, al alcance del pulgar:** Inicio · **Pedidos** · Tienda · Inventario · Tareas.
- **Perfil:** al tocar el retrato.
- **Mapa:** al tocar la puerta de la habitación y desde Perfil.
- **Objetivos:** una sola línea compacta, "Siguiente: …", con su barrita; al tocarla se abre Tareas.
- **"Taller" se une a "Inventario"**, que muestra material, envíos en camino, impresoras con su estado y muebles con sus lugares libres.
- Los paneles de acciones (impresora, lugar libre, pedido) son **paneles inferiores** que dejan ver la habitación.
- **Burbujas sobre las impresoras** (✓ lista, ⚠ fallo, ⏸ sin material, % de avance), con icono **y** color, para leer el estado del taller de un vistazo.

### 7.2 Tiempo que se entiende **(cambia el GDD, sección 5.1)**
- Las **cuentas regresivas en tiempo real:** "Lista en 3 min". Es lo que el jugador va a esperar de verdad.
- Las **fechas en el calendario del juego:** "Llega el día 6", "Entregar antes del día 9".
- La duración de un pedido muestra las dos: "≈ 5 min (2 h de juego)".

### 7.3 Pantallas
- **Pedidos como app de mensajería:** lista de chats con avatar pixel del cliente, burbujas con humor, tarjeta de requisitos con iconos y "Llega un pedido nuevo en 2 min".
- **Tienda:** filtro "lo que puedo comprar", "Te faltan $49", fecha de llegada antes de pagar, opción exprés, comparar dos impresoras lado a lado y confirmación solo en compras grandes.
- **Primera experiencia con Don Ernesto (Fase 3):** de 5 a 8 minutos guiados y que se pueden saltar. Presenta la impresora, llega el primer llavero, se imprime, se cobra y aparece el objetivo de comprar la mesa. Usa un foco que ilumina el botón siguiente. Después solo da pistas la primera vez que pasa algo (primer fallo, primer envío, primer nivel).
- **Siempre hay un siguiente paso:** si no hay nada imprimiéndose, una pista lo dice ("Tu impresora está libre: revisa tus pedidos").
- **Manual del maker:** glosario que se desbloquea a medida que aparecen las cosas (warping, PEI, altura de capa...), explicado con humor. Enseña impresión 3D real (pilar 3) y, según la propuesta de la sección 3, da un pequeño bono de fiabilidad.
- **Accesibilidad:** texto grande, reducir movimiento, vibración, estados con icono además de color, botones de al menos 88 px y áreas seguras del notch (Fase 5).

---

## 8. Contenido

### 8.1 Metas del MVP **(cambia el GDD, sección 13.1)**

| Tipo | Hoy | Meta del MVP | Notas |
|---|---|---|---|
| Pedidos (plantillas) | 12 | Unos 36 | Más **variantes** automáticas: cantidad, color, plazo y pago ±15% |
| Clientes con nombre | 0 (6 tipos) | 12, dos por tipo | Avatar pixel, personalidad y de 3 a 5 frases cada uno |
| Frases de Don Ernesto | 0 | Unas 40 | Tutorial, consejos reales y reacciones a los fallos |
| Objetivos | 12 | Unos 30 | Cadena hasta el garaje y la resina |
| Logros (GDD 5.13) | 0 | Unos 20 | Primera venta, primer espagueti, 100 pedidos... |
| Entradas del Manual del maker | 0 | Unas 15 | |
| Impresoras, materiales, accesorios, muebles y espacios | Ya definidos | Igual | Cada familia de impresoras con su animación |

### 8.2 Ideas de pedidos nuevos, inspirados en precios reales
Tienen nombres de trabajo. Los números finales salen del simulador.

| Cliente | Pedido | Dato real | Por qué es interesante |
|---|---|---|---|
| Amigos | Clips para cables (set de 4) | $5–12 el set | Varias piezas pequeñas |
| Amigos | Dragón articulado | $6–25 | Viral en la vida real; sale de la impresora ya armado |
| Amigos | Cortador de galletas | $3–20 | Rápido y barato |
| Vecinos | **Litofanía** (foto que se ve a contraluz) | $35–50 | Exige calidad 3: la Cubo Uno solo llega en modo Fino. Decisión de modo |
| Vecinos | Perilla de horno descontinuada | $13–67 | Los repuestos pagan mucho |
| Tiendas | Soporte de menú con código QR (set) | Estimado | Varias piezas, plazo corto |
| Tiendas | Letrero por capas para vitrina | $60–130 | Multicolor |
| Makers | Plantilla de taller (jig) | Estimado | PETG, calidad 3 |
| Cosplayers | Espada por partes | Estimado | Muchas piezas, plazo largo |
| Cosplayers | Guantelete flexible | Estimado | TPU |
| Talleres | Repuesto de bicicleta | Estimado | PETG, plazo |
| Makers (resina) | Set de dados de rol | Estimado | Resina |
| Makers (resina) | Miniaturas para juego de mesa (set de 5) | $6–15 cada una | Prepara la placa múltiple de la Fase 7 |

### 8.3 Clientes con personalidad
Ejemplos de nombres que puedes cambiar: Sofi (tu prima), Doña Carmen (la vecina de las plantas), Don Ramiro (el ferretero), Lucía (cosplayer), Mateo (maker de drones) y "El Profe" (taller de bicicletas). Humor cercano y sin estereotipos (GDD, sección 3).

### 8.4 Temporadas (Fase 7)
Máscaras en Halloween, adornos en Navidad, regreso a clases y feria maker los fines de semana del calendario del juego.

---

## 9. Las fases en detalle

Cada tarea termina en un PR. **Tamaño:** S = una sesión de trabajo, M = una o dos, L = dos o tres.

### Fase 0 — Base · Hecha
Proyecto Godot, pruebas, integración continua y versión web en GitHub Pages.

### Fase 1 — Ciclo jugable
**Objetivo:** jugar en el teléfono el ciclo completo con controles táctiles, la partida guardada y una respuesta visual básica. Reorganiza la Fase 1 actual e incluye el ciclo jugable de la antigua Fase 2.

| # | Tarea | Qué podrás probar en el teléfono | Tamaño |
|---|---|---|---|
| 1 | Datos de balance y su validación | — | Hecha |
| 2 | **Controles del mundo con joystick:** joystick flotante, personaje que camina con choques y animación, tocar objetos y piso, cercanía con resalte y burbuja, paneles inferiores, cámara que sigue con tres niveles de zoom, teclado y mouse en la web, ajustes de controles para probar. Capturas automáticas para que Claude revise la interfaz | Caminas con el pulgar, tocas la impresora y ves su panel, cambias el zoom | L |
| 3 | **Navegación y HUD despejado** (sección 7.1): barra inferior nueva, objetivo compacto, sin botones laterales | Pedidos queda abajo y se ve más habitación | M |
| 4 | **Guardado, azar reproducible y menú de pruebas:** guardar en `user://save.json` (versión, archivo temporal, guardado después de cada comando, cada cierto tiempo y al salir), semilla del azar en el estado, versión visible en Ajustes y menú de pruebas oculto | Cierras y abres el juego: sigue igual | M |
| 5 | **Tienda y envíos:** comprar con confirmación, días de envío, exprés, ferretería, almacenamiento y desbloqueo por nivel; "En camino" en Inventario; la caja llega a la puerta, se abre al tocarla y el objeto aparece en su lugar | Compras la mesa auxiliar, llega días después, la abres y la impresora sube a la mesa | L |
| 6 | **Pedidos tipo chat:** tablero limitado que se renueva, aceptar y rechazar, plazos, mensajes con personalidad por tipo de cliente | Te llegan mensajes y aceptas un llavero | M |
| 7 | **Imprimir y entregar:** asignación con recomendación (tiempo real, calidad, riesgo, costo y ganancia), la pieza crece capa a capa, retirar y entregar, dinero y XP con animación básica, subir de nivel. Prueba de que un paso grande da lo mismo que muchos pequeños | Imprimes el llavero, lo ves crecer, cobras $6 y sube la XP | L |
| 8 | **Fallos y accesorios:** espagueti, warping y fin de filamento visibles; limpiar y reintentar; instalar accesorios; rescate de Don Ernesto | Ves un espagueti y lo limpias; instalas la lámina PEI | M |
| 9 | **Fuera del juego y objetivos:** progreso de hasta 8 horas, resumen al volver, protección contra cambios de reloj, objetivos con avance real y recompensas, prueba de rendimiento | Cierras una hora, vuelves y ves "Mientras no estabas..." | M |
| 10 | **Simulador y primer balance:** `tools/simulate.sh` juega 7 días con un jugador automático; informe y ajustes en `data/` | El informe en el PR, con propuestas para que las apruebes | M |

**Criterio de terminado:** en tu teléfono juegas desde el día 1 hasta comprar una segunda impresora y llegar al nivel 2, cerrando y abriendo el juego entre sesiones. El simulador muestra un ritmo cercano a las metas de la sección 5.3.

### Fase 2 — Personaje vivo y game feel
**Objetivo:** que el juego se sienta vivo y responda a cada toque.

| # | Tarea | Qué podrás probar | Tamaño |
|---|---|---|---|
| 1 | **Kit de respuesta:** botones que rebotan, números flotantes, monedas que vuelan, avisos arriba, vibración; ajustes de vibración y de reducir movimiento | Cada toque responde | M |
| 2 | **Sonido:** buses de audio, efectos de interfaz, cobro, fallo y nivel, motores por familia de impresora y música tranquila; volúmenes en Ajustes; créditos | El taller suena | M |
| 3 | **Personaje que actúa:** animaciones de acciones (retirar la pieza, limpiar un espagueti, abrir cajas), emociones y rutinas; los muebles que lo tapan se vuelven transparentes. Caminar ya llegó en la Fase 1 | El personaje celebra al cobrar y se agarra la cabeza con un espagueti | M |
| 4 | **Mundo vivo:** animación de cada familia de impresoras (cabezal, cama, resina), carrete que gira, burbujas de estado, día y noche en la ventana y la lámpara, rutinas del personaje | El cuarto se mueve solo | M |
| 5 | **Grandes momentos:** celebración al subir de nivel, unboxing de impresoras, muebles que caen con rebote, primera venta | Subir de nivel se siente como un premio | M |

**Criterio de terminado:** tabla de la sección 6 cumplida (cada acción tiene imagen, sonido y, donde aplica, vibración en menos de 0,1 s), 60 fps en un teléfono de gama media en la versión web, y tú notas la diferencia.

### Fase 3 — UX/UI y primera experiencia
**Objetivo:** que alguien que nunca lo jugó lo entienda solo.

| # | Tarea | Qué podrás probar | Tamaño |
|---|---|---|---|
| 1 | **Panel de impresora completo y lista de impresoras** en Inventario: al tocar una de la lista, la cámara va hacia ella | Controlas varias impresoras sin perderte | M |
| 2 | **Tienda mejorada:** filtros, comparar, "te faltan $", fecha de llegada, ferretería clara | Comprar es rápido y claro | M |
| 3 | **Tutorial con Don Ernesto** (se puede saltar) y pistas de "siguiente paso" | Una partida nueva te guía | L |
| 4 | **Manual del maker y accesibilidad:** glosario que se desbloquea, bono de fiabilidad, texto grande | Aprendes impresión 3D real jugando | S |
| 5 | **Pulido y prueba con personas:** estados vacíos, mensajes de error claros, transiciones, revisión de textos; prueba con 3 personas | — | M |

**Criterio de terminado:** 3 personas que nunca jugaron completan el primer pedido y compran la mesa sin ayuda en menos de 10 minutos.

### Fase 4 — Contenido y MVP completo
**Objetivo:** el MVP de la sección 13.1 del GDD completo, de principio a fin.

| # | Tarea | Qué podrás probar | Tamaño |
|---|---|---|---|
| 1 | **Garaje:** su escena, la mudanza (muebles e impresoras se llevan) y el Mapa | Te mudas al garaje | L |
| 2 | **Garaje lleno:** prueba de estrés con 40 impresoras, optimización y modelos mejorados (por ejemplo, la Bóveda P1) | El garaje lleno sigue fluido | M |
| 3 | **Pedidos ampliados** (unos 36 más variantes) y clientes con nombre, cara y frases | Los pedidos no se repiten | L |
| 4 | **Objetivos, logros y frases de Don Ernesto** | Siempre hay una meta | M |
| 5 | **Balance final del MVP** con el simulador, del nivel 1 al 5 con el garaje | Informe del simulador | M |
| 6 | **Prueba de una semana** con 3 a 5 personas en la versión web, y correcciones | — | M |

**Criterio de terminado:** un jugador llega del nivel 1 al 5 y se muda al garaje en unas 2 semanas de sesiones cortas, sin quedarse atascado.

### Fase 5 — Móvil y rendimiento
**Objetivo:** que funcione fluido como app instalada.

| # | Tarea | Tamaño |
|---|---|---|
| 1 | Build de Android firmada en la integración continua (keystore en GitHub Secrets; cuenta de Google Play) | M |
| 2 | Build de iOS (Mac o servicio en la nube; cuenta de Apple Developer) | L |
| 3 | Áreas seguras del notch, botón "atrás" de Android, pausa y reanudar, guardado al salir, ahorro de batería (menos cuadros por segundo cuando nada se mueve) | M |
| 4 | Notificaciones locales ("Tu pedido terminó"). Necesitan un plugin: te preguntaré antes | M |
| 5 | Rendimiento en gama baja: mediciones, `MultiMesh`, costo del contorno y texturas | M |
| 6 | Inglés completo y revisión de todos los textos | S |

**Criterio de terminado:** al menos 30 fps en un Android de gama baja y fluido en un iPhone. Empieza a reunir a los 12 testers.

### Fase 6 — Publicación

| # | Tarea | Tamaño |
|---|---|---|
| 1 | Identidad: icono, nombre final, capturas, video corto y textos de la tienda en español e inglés | M |
| 2 | Legal: política de privacidad, formularios de privacidad de cada tienda y clasificación por edad | S |
| 3 | Prueba cerrada de Google Play (12 testers durante 14 días) y TestFlight en iOS, con correcciones | L |
| 4 | Lanzamiento | S |

**Criterio de terminado:** publicado en ambas tiendas.

### Fase 7 — Después del lanzamiento
Actualizaciones de contenido, ordenadas por cuánto aportan contra cuánto cuestan. Cada una se discute antes de empezar.

1. **Cola de impresión y placa múltiple** (FDM y resina): más eficiencia a cambio del riesgo de perder toda la placa.
2. **Mantenimiento y humedad:** boquillas que se gastan, caja seca, secador y "turno nocturno".
3. **Materiales técnicos:** ABS y ASA (necesitan impresora cerrada), fibra de carbono (boquilla endurecida) y nylon (secador).
4. **Posprocesado:** lijar, pintar y lavar y curar la resina, para pedidos que pagan más.
5. **Local comercial** con vitrina, Titán Pro, niveles 6 a 10 y clientes empresa.
6. **Empleados** que automatizan tareas, y herramientas para que caminar nunca aburra con muchas impresoras: un ayudante que recoge y entrega, más velocidad al caminar, recoger varias piezas de una pasada.
7. **Temporadas y eventos** (sección 8.4).
8. Monetización según la sección 11 del GDD, guardado en la nube y logros de las tiendas.

---

## 10. Mejoras al proceso de trabajo

| Mejora | Para qué | Cuándo |
|---|---|---|
| **Menú de pruebas oculto** (por ejemplo, tocar 7 veces la versión en Ajustes): acelerar el tiempo, dar dinero, subir de nivel, provocar un fallo | Probar en el teléfono lo avanzado sin jugar horas. Usa los mismos comandos de `Game` | Fase 1, tarea 4 |
| **Versión visible en Ajustes** (fecha y número del cambio) | Saber si el teléfono ya cargó la versión nueva y no una guardada en caché | Fase 1, tarea 4 |
| **Capturas automáticas** (`tools/screenshots.sh` con `xvfb-run`) | Que Claude revise cómo se ve cada pantalla antes de abrir un PR. Hecho en la Fase 1, tarea 2 (`tools/screenshots.sh`) | Hecho |
| **Versión de prueba por PR** *(opcional)* | Probar en el teléfono **antes** de fusionar, en un enlace como `.../game/pr-12/`. Requiere cambiar una opción de GitHub Pages | Cuando quieras |

---

## 11. Decisiones del dueño

Respuestas del 2026-10-21:

| # | Decisión | Respuesta |
|---|---|---|
| 1 | Aprobar esta ruta (reemplaza la tabla de fases del GDD y agrega la Fase 7) | Sí |
| 2 | Control del personaje | **Joystick** (sección 4.1) |
| 3 | Navegación nueva: Inicio · Pedidos · Tienda · Inventario · Tareas (sección 7.1) | Aprobada |
| 4 | Cuentas regresivas en tiempo real y fechas en el calendario del juego (sección 7.2) | Sí |
| 5 | Realismo: preparación por pieza, costo y ganancia, fiabilidad de las modernas y bono del Manual del maker (sección 3), probados con el simulador antes de aplicarlos | Sí |
| 6 | Contenido del MVP a unos 36 pedidos con clientes con nombre, y ritmo meta de unas 2 semanas (secciones 5.3 y 8) | Aprobado |
| 7 | Versión de prueba por PR (sección 10) | Sin respuesta: queda para cuando la pidas |
| 8 | *(Antes de la Fase 5)* iOS: Mac propio o servicio en la nube | Pendiente |

### Preguntas abiertas

| Pregunta | Cuándo hace falta |
|---|---|
| **Entregar con el joystick:** ¿se cobra tocando la impresora terminada, o el personaje recoge la pieza y la lleva a una caja de despacho junto a la puerta? En el segundo caso, las impresoras guardan lo terminado mientras no estás (nada se pierde) y más adelante se puede automatizar | Antes de la Fase 1, tarea 7 |

## 12. Cómo se mantiene esta ruta
- `docs/PROGRESO.md` dice en qué tarea vamos. Esta ruta solo cambia cuando cambia el plan.
- Si una tarea resulta más grande de lo esperado, se divide en dos PR y se anota aquí.
- Las ideas nuevas se agregan a la Fase 7 y se discuten antes de moverlas a una fase anterior.
- Al terminar cada fase se revisa esta ruta completa con el dueño.

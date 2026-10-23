# Documento de diseño — "Capa a Capa" (título provisional)

> Este documento es la fuente de verdad sobre **qué** es el juego. Las reglas técnicas sobre **cómo** se construye están en `CLAUDE.md`. Los números de este documento son valores iniciales para balancear, no definitivos: los valores reales viven en `data/*.json`.
>
> **Versión 2.4** (2026-10-23). Los cambios están resumidos en la sección 16. El estilo visual se detalla en `docs/ESTILO.md` (dirección de arte completa en `docs/BIBLIA_ARTE.md`) y el orden de trabajo en `docs/RUTA.md`.

---

## 1. Concepto

Un joven emprendedor recibe de su vecino una impresora 3D vieja y, con $250 ahorrados, una mesa, un computador viejo y un carrete de PLA blanco, empieza a imprimir llaveros para sus amigos desde su habitación, con la impresora en el suelo. Pedido a pedido, compra mejores máquinas, materiales y muebles, sube de nivel, consigue clientes más exigentes y convierte su pasatiempo en un taller de fabricación.

**Género:** simulador de gestión / tycoon en 3D, con progreso mientras el jugador no está.
**Plataformas:** Android e iOS. Versión web solo para pruebas internas.
**Orientación:** vertical (retrato), jugable con una mano.
**Sesiones:** cortas, de 2 a 5 minutos, varias veces al día.
**Público:** jugadores casuales de juegos de gestión y la comunidad maker, que reconocerá los detalles reales de la impresión 3D.

## 2. Pilares de diseño

Cada función nueva debe apoyar al menos uno de estos pilares. Si no apoya ninguno, no entra.

1. **Ver crecer el taller.** La satisfacción principal es ver el cuarto lleno de cables convertirse en un taller ordenado y lleno de máquinas.
2. **Decisiones con sentido.** Qué pedido aceptar, en qué impresora, con qué material y en qué modo. Nunca hay una única respuesta correcta.
3. **Autenticidad con humor.** Los fallos, materiales y mejoras se basan en la impresión 3D real (el "espagueti", el warping, la cama PEI), contados con cariño y humor.
4. **Respeto por el jugador.** Sin castigos por no jugar, sin presión artificial, monetización no agresiva.

## 3. Ambientación y tono

- Ciudad latinoamericana ficticia, ambiente cálido y cercano.
- El protagonista es un joven adulto; el jugador elige su nombre. Aparece en la escena 3D (ver 5.10): pelo café alborotado, buzo gris carbón (casi negro) con capucha de forro mostaza, jeans y zapatillas blancas.
- **Don Ernesto**, el vecino que le regala su vieja impresora, funciona como guía del tutorial y aparece de vez en cuando con consejos.
- Los pedidos llegan como mensajes de clientes en una **app de mensajería ficticia** dentro del teléfono del protagonista. Cada cliente tiene personalidad propia y frases con humor local, sin caer en estereotipos.
- **Todas las marcas son ficticias**: impresoras, filamentos, muebles, apps y tiendas. Nunca se usan nombres reales como Prusa, Bambu Lab, Creality, IKEA o WhatsApp, ni nombres de productos reales (Ender, A1, SKÅDIS...).
- **Inspiración real:** cada impresora, material, accesorio y mueble se inspira en un producto real. Su precio en dólares y sus características se basan en ese producto, pero con nombre ficticio. A qué producto real corresponde cada uno, y de qué fecha son los precios, está en `docs/REFERENCIAS.md`. Ese documento es interno y nunca aparece en el juego.

## 4. Ciclo de juego

**Ciclo corto (segundos a minutos):** del mensaje a la puerta, en seis pasos (detalle en la sección 5.17).
1. **Confirmar:** llega un pedido como mensaje de un cliente y el jugador lo acepta o lo rechaza.
2. **Modelar:** el computador viejo modela el pedido en 3D. Empieza solo al aceptar.
3. **Imprimir:** el jugador asigna una impresora, un carrete y un modo (el juego recomienda uno). La pieza crece capa a capa con el tiempo del juego y puede fallar.
4. **Retirar:** al terminar, saca las piezas de la impresora. Quedan en el rincón de despacho.
5. **Embalar:** las mete en una caja.
6. **Despachar:** el paquete sale por la puerta. Cobra dinero y gana experiencia.

**Ciclo medio (una sesión)**
Revisar qué terminó mientras no estaba, retirar, embalar y despachar, recibir los envíos que llegaron, **pedir material antes de que se acabe** (tarda días en llegar), aceptar nuevos pedidos, dejar impresiones largas corriendo y comprar una impresora, un accesorio o un mueble.

**Ciclo largo (días o semanas)**
Subir de nivel, desbloquear impresoras, materiales y clientes, llenar la habitación de muebles y máquinas, mudarse al garaje y alcanzar hitos.

## 5. Sistemas

### 5.1 Tiempo de juego

- El juego tiene su propio calendario: **1 día de juego dura 1 hora real** (el tiempo del juego corre 24 veces más rápido que el real). La barra superior muestra la fecha, por ejemplo "Día 12 · 14:30".
- Así las duraciones pueden ser realistas: un llavero tarda 20 minutos de juego (50 segundos reales) y un envío de 3 días tarda 3 horas reales.
- La velocidad del tiempo vive en `data/config.json`, para ajustarla con el simulador.
- **Todas las duraciones de este documento están en tiempo de juego**, salvo que se diga lo contrario.
- **Cómo se muestran los tiempos al jugador:** lo que el jugador va a esperar de verdad se cuenta en **tiempo real** ("Lista en 3 min"). Las fechas van en el **calendario del juego** ("Llega el día 6", "Entregar antes del día 9"). La duración de un pedido muestra las dos: "≈ 5 min (2 h de juego)". Así nadie cree que una maceta tarda dos horas de verdad.

### 5.2 Pedidos

Cada pedido tiene:

| Atributo | Descripción |
|---|---|
| Cliente | Tipo de cliente (amigos, vecinos, tiendas, makers, cosplayers, talleres) |
| Tamaño | S, M o L. Debe caber en el volumen de la impresora |
| Calidad mínima | De 1 a 5 |
| Materiales aceptados | Lista de materiales válidos |
| Multicolor | Sí o no. Requiere impresora multicolor |
| Piezas | Cantidad de piezas que hay que imprimir |
| Gramos por pieza | Material consumido |
| Tiempo por pieza | Minutos de juego con una impresora de velocidad 1,0× en modo Normal |
| Pago | Dinero al despachar, en dólares |
| Plazo | Opcional, en días de juego. Se revisa al despachar: si va tarde, se cobra la mitad y no se gana experiencia (igual cuenta como entregado) |
| Experiencia | Puntos de experiencia (XP) al despacharse a tiempo |
| Nivel mínimo | Nivel del jugador necesario para que este pedido aparezca |
| Modelado | Cómo llega el diseño (plantilla, a medida, hay que medir o archivo del cliente) y cuántos minutos de juego tarda en modelarse (sección 5.17) |
| Mensaje | Lo que escribe el cliente al pedirlo |

- **Tablero:** hasta 3 mensajes sin responder y hasta 3 pedidos en curso. Los mensajes no vencen. El primero (un llavero) llega al minuto de juego de empezar, el segundo 27 minutos de juego después, y desde ahí uno cada 60 minutos de juego (2,5 minutos reales). Con el tablero lleno no llegan más hasta responder uno.
- **Solo llegan pedidos que el jugador puede hacer** con sus impresoras y su material, y de su nivel.
- Rechazar un mensaje no tiene castigo; simplemente desaparece. Cancelar un pedido aceptado tampoco, salvo el material que ya se usó.
- **Pedidos de varias piezas:** un pedido se imprime completo en una sola impresora, pieza por pieza. Cada pieza es una impresión independiente: al empezar se decide si fallará, y un fallo solo pierde esa pieza. Al terminar una pieza, la siguiente empieza sola; la impresora guarda las terminadas hasta que el jugador las retira, una sola vez por pedido.
- **Plazos y ausencia:** el plazo solo corre mientras el juego está abierto. Mientras el jugador no está, se congela (pilar 4).

### 5.3 Impresoras

| Atributo | Descripción |
|---|---|
| Tecnología | FDM (filamento) o resina |
| Velocidad | Divide el tiempo por pieza: una impresora de 2,0× imprime en la mitad del tiempo |
| Calidad máxima | De 1 a 5 |
| Volumen | S (hasta 18 cm), M (hasta 25 cm) o L (más grande) |
| Materiales compatibles | Lista |
| Multicolor | Sí o no |
| Cerrada | Con carcasa: menos warping |
| Fiabilidad | Probabilidad base de que una impresión no falle |
| Accesorios incluidos | Algunas impresoras ya traen sensor, lámina PEI o cámara |
| Precio | En dólares, basado en el modelo real que la inspira |
| Nivel | Nivel del jugador desde el que se puede comprar |
| Envío | Días de juego que tarda en llegar |

- Cada impresora necesita un lugar en un mueble (ver 5.9).
- Se quitó el consumo eléctrico de la versión 1: con precios reales, una impresora gasta centavos de luz por hora y no aportaba decisiones.

### 5.4 Modos de impresión

| Modo | Calidad | Tiempo | Fallos |
|---|---|---|---|
| Borrador | −1 | ×0,6 | ×1,3 |
| Normal | 0 | ×1,0 | ×1,0 |
| Fino | +1 | ×1,6 | ×0,8 |

La calidad final es la calidad máxima de la impresora ajustada por el modo, sin bajar de 1 ni pasar de 5. Si no alcanza la calidad mínima del pedido, no se puede asignar.

### 5.5 Materiales e inventario

| Material | Precio | Propiedades | Nivel |
|---|---|---|---|
| PLA | $18 el carrete de 1 kg | Fácil y barato. Fallos ×1,0 | 1 |
| PETG | $20 el carrete de 1 kg | Resistente. Algunos pedidos lo exigen. Fallos ×1,15 | 1 |
| TPU | $28 el carrete de 1 kg | Flexible. Tiempo ×1,6, fallos ×1,2. Requiere impresora compatible | 3 |
| Resina | $25 la botella de 1 kg | Máximo detalle. Solo impresoras de resina | 5 |

- El material se compra en la tienda (ver 5.6) y tarda días en llegar.
- **Almacenamiento:** la habitación guarda hasta 4 kg de material. Las repisas y estanterías aumentan ese límite (ver 5.9). No se puede comprar más de lo que cabe, contando lo que viene en camino.
- **Material apartado:** al empezar a imprimir se aparta todo el material del pedido. Si una pieza falla, se pierde solo lo impreso hasta el fallo y el resto vuelve al carrete. Por ahora no se puede empezar sin material suficiente.
- **Si el material no alcanza** *(Fase 1, tarea 8)*: se puede empezar igual, con un aviso. La impresión se detiene justo donde se acaba el material, y eso se sabe desde el inicio. Sin sensor de filamento, la pieza falla; con sensor, se pausa y continúa al reponer material.
- **Don Ernesto al rescate:** si el jugador no tiene material, ni dinero para un carrete, ni impresiones en curso, ni piezas por entregar, ni envíos en camino, Don Ernesto le regala un carrete de PLA. Así nunca se queda atascado.
- **Colores:** cada carrete tiene un color (9 colores en `config.filament_colors`). Por ahora es solo visual: la pieza sale del color del carrete. Los pedidos que exigen un color son posteriores al MVP.
- Mejora posterior: compra automática de material cuando se acaba.

### 5.6 Tienda y envíos

- Una tienda en línea ficticia vende **impresoras, materiales, accesorios y muebles**. Cada artículo muestra su precio, para qué sirve y desde qué nivel se puede comprar. Los bloqueados se ven con un candado y el nivel necesario.
- **Las compras tardan en llegar.** El número exacto de días se decide al comprar con el azar de la partida y se muestra ("Llega el día 15"):

| Categoría | Envío normal |
|---|---|
| Materiales | 3 a 5 días |
| Accesorios | 3 a 7 días |
| Muebles | 3 a 6 días |
| Impresoras | 5 a 7 días |

- **Envío exprés:** cualquier compra llega en 1 día pagando $12 más.
- **Ferretería del barrio:** vende PLA y PETG para llevar al instante, pero 50% más caro. Es la opción de emergencia.
- Los envíos llegan aunque el jugador no esté jugando.

### 5.7 Fallos

Cuando una impresión falla, se detiene en un punto de su avance y el material usado hasta ahí se pierde. El jugador debe tocar la impresora para limpiarla y reintentar.

| Fallo | Visual | Mitigación |
|---|---|---|
| Espagueti | Nido de filamento enredado | Cámara (pausa automática al 10%, pierde menos material) |
| Warping | Pieza despegada y curvada | Lámina PEI, impresora cerrada |
| Fin de filamento | La impresión se queda a medias | Sensor de filamento (pausa en vez de fallar) |
| Boquilla tapada *(post-MVP)* | La impresora "imprime aire" | Mantenimiento |

- Espagueti y warping ocurren al azar: probabilidad de fallo = (1 − fiabilidad) × modificador del material × modificador del modo × modificadores de accesorios y muebles.
- El fin de filamento solo ocurre cuando el material no alcanza (ver 5.5).
- Todo se decide al iniciar cada pieza: si fallará, de qué tipo y en qué porcentaje de avance. El espagueti se detiene entre el 10% y el 60% del avance; el warping, entre el 2% y el 25%, porque la pieza se despega en las primeras capas.
- **Regalo de Don Ernesto:** las 3 primeras piezas de una partida nueva nunca fallan ("la dejó recién calibrada"), para que la primera venta salga bien.
- Tras un fallo, el jugador elige **Limpiar y reintentar** (vuelve a imprimir esa pieza y puede cambiar el modo) o **Limpiar** (libera la impresora; el pedido vuelve a "listo para imprimir" y conserva las piezas terminadas).
- Por ahora un fallo se ve como una pieza oscura detenida, la pantalla de la impresora en rojo y una burbuja ⚠. El espagueti dibujado, la cámara y el sensor llegan con la Fase 1, tarea 8.
- Los fallos pueden ocurrir mientras el jugador no está. Volver y encontrar un espagueti es parte del humor del juego, pero la cámara está disponible desde el inicio para que no resulte frustrante.

### 5.8 Accesorios

Se compran en la tienda y se instalan en **una impresora específica**. Algunas impresoras ya los traen de fábrica.

| Accesorio | Efecto en esa impresora | Precio | Nivel |
|---|---|---|---|
| Lámina PEI | Warping −50% | $30 | 1 |
| Sensor de filamento | El fin de filamento pausa en vez de fallar | $12 | 1 |
| Cámara de monitoreo | El espagueti pausa la impresión al 10% de avance | $35 | 1 |

Posteriores al MVP: turno nocturno (amplía el progreso fuera del juego de 8 a 12 horas), compra automática de material, boquillas de repuesto y caja seca para la humedad del filamento.

### 5.9 Muebles y espacios

- La **habitación** es amplia: tiene **6 lugares** en el piso para muebles. Al empezar está casi vacía: solo la mesa con el computador viejo ocupa un lugar. La imagen `docs/referencias/taller_final.webp` muestra cómo puede verse al final.
- **Imprimir en el suelo:** al empezar, la impresora está en el suelo porque la mesa la ocupa el computador. En el suelo cabe una impresora, que pierde un 5% de fiabilidad (polvo, vibraciones y algún pisotón). Comprar una mesa la saca del suelo; es el primer objetivo de mejora.
- Cada mueble ocupa un lugar. Hay muebles para impresoras, para guardar material y para herramientas.
- Los muebles se ven en la escena 3D: comprarlos hace crecer el taller (pilar 1).

| Mueble | Función | Precio | Nivel |
|---|---|---|---|
| Mesa con computador viejo (inicial) | Aquí está el computador; no le cabe una impresora | — | — |
| Mesa auxiliar | 1 impresora | $25 | 1 |
| Mesa de trabajo | 2 impresoras | $120 | 2 |
| Estantería metálica | 3 impresoras | $150 | 3 |
| Repisa de filamento | +6 kg de material | $35 | 1 |
| Estantería de cubos | +12 kg de material | $90 | 2 |
| Panel perforado de herramientas | Herramientas a mano: fiabilidad +2% en todas las impresoras. Solo cuenta uno | $30 | 1 |

| Espacio | Lugares para muebles | Costo | Nivel | En MVP |
|---|---|---|---|---|
| Habitación | 6 | Inicial | 1 | Sí |
| Garaje | 14 | $2.500 | 4 | Sí |
| Local comercial | — | — | — | No |
| Taller | — | — | — | No |
| Fábrica | — | — | — | No |

- Los espacios se compran una sola vez. **No hay arriendo**, para no castigar a quien deja de jugar unos días.
- Al mudarse, los muebles y las impresoras se llevan al nuevo espacio.
- Cada espacio es una escena 3D distinta.

### 5.10 Personaje y nivel

- **El personaje** aparece en la escena 3D, en su habitación: un joven maker de 1,40 m de proporciones simpáticas (unas 3,2 cabezas), con la cara pintada y 8 expresiones, que respira, mira lo que tiene cerca y reacciona a lo que pasa (feliz al cobrar, las manos a la cabeza con un espagueti, un salto al subir de nivel). Las reacciones son solo de adorno: nunca bloquean ni cambian el juego. Detalle en `docs/ESTILO.md`.
- **Se maneja con un joystick** y camina por el espacio (sección 7.1). Su posición es solo presentación: no se guarda en la partida y al abrir el juego aparece junto a su escritorio.
- **Experiencia y nivel:** entregar pedidos a tiempo da experiencia (XP). La barra superior muestra siempre el retrato del personaje, su nivel y una **barra de progreso** hacia el siguiente nivel.
- Entregar tarde no da experiencia.
- Cada nivel desbloquea clientes, pedidos, impresoras, materiales y muebles:

| Nivel | XP total | Desbloquea |
|---|---|---|
| 1 | 0 | Amigos y familia. PLA y PETG. Mesa auxiliar, repisa de filamento y panel de herramientas |
| 2 | 100 | Vecinos y tiendas del barrio. Rayo Mini y Rayo X1. Mesa de trabajo y estantería de cubos |
| 3 | 300 | Makers y cosplayers. Prisma MC. TPU. Estantería metálica |
| 4 | 700 | Talleres de reparación. Bóveda P1. Garaje |
| 5 | 1.500 | Gota R1 y resina |
| 6 | 3.000 | *(post-MVP)* |
| 7 | 5.500 | Titán Pro *(post-MVP)* |
| 8 a 10 | 9.000 / 14.000 / 21.000 | Empresas y startups *(post-MVP)* |

### 5.11 Progreso fuera del juego

- Al volver, el juego calcula lo que pasó usando la misma simulación del juego activo (ver `CLAUDE.md`).
- Límite inicial de 8 horas reales (8 días de juego) de progreso acumulado fuera del juego.
- Mientras el jugador no está, las impresiones avanzan y los envíos llegan, pero los plazos de los pedidos se congelan.
- Al abrir, se muestra un resumen: "Mientras no estabas: 3 pedidos terminados, 1 espagueti, llegó tu carrete de PETG".
- Protección básica contra trampas de reloj: si la hora del sistema retrocede, no se otorga progreso.
- Las notificaciones locales del tipo "Tu pedido terminó" quedan para la fase móvil.

### 5.12 Tiempos de impresión

Propuesta inicial, que se ajustará al balancear:

| Etapa | Impresión típica (tiempo de juego) | Equivale en tiempo real |
|---|---|---|
| Inicio (habitación) | 20 minutos a 2 horas | 50 segundos a 5 minutos |
| Media (garaje) | 4 a 8 horas por pieza | 10 a 20 minutos |
| Avanzada (post-MVP) | 12 a 48 horas | 30 minutos a 2 horas |

### 5.13 Hitos y logros

Primera venta, primer espagueti, primeros $1.000, primera impresora comprada, primer mueble, mudanza al garaje, 100 pedidos entregados. Dan pequeñas recompensas y marcan el avance.

### 5.14 Objetivos

- Una cadena de objetivos guía al jugador y le da una meta clara en cada sesión: "Entrega 3 llaveros", "Saca la impresora del suelo: compra una mesa auxiliar", "Instala una lámina PEI", "Llega al nivel 2"...
- Cada objetivo da dinero o experiencia. Viven en `data/objectives.json`.
- **No vencen ni castigan** (pilar 4): no son "diarios" con fecha límite, sino una lista que avanza al ritmo del jugador.
- El HUD muestra el siguiente en una sola línea compacta; la pantalla Tareas muestra la lista completa con su avance y recompensa.

### 5.15 Ritmo del juego

Metas para el balance, jugando sesiones cortas de 2 a 5 minutos varias veces al día. Se comprueban con el simulador y con pruebas con personas; no son reglas fijas.

| Momento | Meta |
|---|---|
| Primera venta | Menos de 2 minutos desde que se abre el juego por primera vez |
| Comprar la mesa auxiliar | En la primera sesión (llega en la siguiente) |
| Nivel 2 | Primer día |
| Segunda impresora | Día 1 o 2 |
| Nivel 3 | Día 3 o 4 |
| Nivel 4 y mudanza al garaje | Día 7 a 10 |
| Nivel 5 y resina | Día 10 a 14 |
| Quedarse atascado | Nunca (rescate de Don Ernesto) |

### 5.16 Realismo por validar

Propuestas aprobadas por el dueño, basadas en datos reales (`docs/REFERENCIAS.md`, sección "Datos reales para el diseño"). Se prueban con el simulador (Fase 1, tarea 10) antes de pasar a `data/*.json`:

- **Preparación de cada pieza:** unos 5 minutos de juego extra por pieza, por calentar la cama, nivelar y retirar la pieza. En la vida real son de 3 a 8 minutos.
- **Costo y ganancia a la vista:** al asignar un pedido se muestran el costo del material y la ganancia, como haría un taller real.
- **Impresoras modernas más fiables:** de 92–94% a 95–97%. En la vida real fallan de 2 a 5% de las veces; las clásicas, de 10 a 20%.
- **Aprender reduce fallos:** el Manual del maker (sección 7) da un pequeño bono de fiabilidad. En un estudio real, leer el material de capacitación bajó los fallos de 33% a 6%.

### 5.17 Del computador a la puerta (versión 2.3)

Lo que pasa con un pedido después de aceptarlo. **Todo se puede hacer tocando desde cualquier parte** (sección 7.1): desde su tarjeta en Pedidos o tocando el objeto. Caminar cerca solo agrega un atajo.

**Modelar**
- Al aceptar, el computador viejo empieza a modelar el pedido solo. Modela uno a la vez, en fila, y trabaja mientras las impresoras imprimen.
- Cuánto tarda depende de cómo llega el diseño, como en un taller real:

| Cómo llega el diseño | Pedidos (minutos de juego) |
|---|---|
| Plantilla: solo hay que adaptarla | Llavero (4), funda flexible (8) |
| A medida, desde cero | Soporte para celular (12), maceta (16), organizador (20), letrero (24) |
| Hay que medir con pie de rey | Perilla (30), carcasa (30), engranaje (36) |
| El cliente mandó el archivo | Figura (2), miniatura (2), casco de cosplay (6) |

- **Concentrarse** (opcional, una vez por pedido): ahorra la mitad del tiempo que falta. Se puede apagar desde los datos si se siente como una obligación.
- Mientras modela, la pantalla del computador muestra un cubo de alambre.

**Imprimir**
- Con el modelo listo, el juego **recomienda** impresora, carrete y modo, y muestra: el tiempo en tiempo real ("Lista en 50 s (20 min de juego)"), la calidad, el riesgo de fallo, los gramos y lo que queda en el carrete, el costo del material y la ganancia. Con botones se cambia el modo, el carrete o el pedido.
- Si algo no sirve, el botón Imprimir se apaga y dice por qué ("No cabe: la Rayo Mini es tamaño S").
- La pieza crece capa a capa sobre la cama. En pedidos de varias piezas, las terminadas esperan en una bandeja al frente de la impresora.

**Retirar, embalar y despachar**
- **Retirar:** al terminar aparece una burbuja ✓ sobre la impresora. Retirar saca todas las piezas del pedido de una vez y las lleva al **rincón de despacho**: una mesita para embalar con un cajón de salida, junto a la puerta. Es fijo: no ocupa ninguno de los 6 lugares de muebles y deja libres el paso por la puerta y el lugar donde llegarán las cajas de la tienda.
- **Embalar:** la caja abierta con la pieza pasa a ser un paquete con cinta, sobre el cajón. No cuesta dinero ni usa cajas del inventario.
- **Despachar:** el paquete sale por la puerta y **se cobra en ese momento**, sin tiempo de viaje. El plazo se revisa al despachar. Cada tipo de cliente tiene su forma de entrega, solo como texto: los amigos pasan a buscarlo, a los vecinos se lo lleva el jugador, a tiendas y talleres los atiende un mensajero en moto, y a makers y cosplayers les llega por encomienda.
- Al cobrar, "+$6" vuela al dinero, la barra de experiencia se llena y el cliente agradece con una frase.

**Avisos y atajos**
- **Burbujas de estado:** sobre la impresora (tiempo que falta, ✓ o ⚠), el computador (tiempo que falta) y el rincón de despacho (cuántos paquetes esperan).
- **Número en Pedidos:** cuántas cosas esperan al jugador (mensajes, piezas para retirar, embalar o despachar, fallos y modelos listos con una impresora libre).
- El personaje comenta de vez en cuando el siguiente paso ("¡Terminó! Voy a sacar la pieza").
- **Burbuja de cercanía:** si no hay nada que decidir (retirar, embalar, despachar o concentrarse), tocarla hace la acción directamente. Para imprimir y ante un fallo, siempre abre el panel.

**Ferretería del barrio** (sección 5.6): mientras no existe la tienda, vende 1 kg de PLA o PETG blanco al instante, por $27 y $30. Aparece en Pedidos cuando no hay nada que se pueda hacer, y en Inventario.

**Guardado:** la partida se guarda sola, después de cada acción, cada 10 segundos y al salir. Mientras el juego está cerrado, el tiempo no pasa: el progreso fuera del juego llega con la Fase 1, tarea 9. En Ajustes, "Empezar partida nueva" borra la partida con dos toques.

## 6. Datos iniciales

### 6.1 Impresoras

| id | Nombre | Tipo | Precio | Velocidad | Calidad máx. | Volumen | Materiales | Multicolor | Cerrada | Fiabilidad | Incluye | Nivel | En MVP |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cubo_uno | Cubo Uno | FDM básica (la de Don Ernesto) | $199 | 1,0× | 2 | M | PLA, PETG, TPU | No | No | 85% | — | 1 | Sí |
| rayo_mini | Rayo Mini | FDM rápida compacta | $299 | 2,0× | 3 | S | PLA, PETG, TPU | No | No | 92% | Sensor, PEI | 2 | Sí |
| rayo_x1 | Rayo X1 | FDM rápida | $399 | 2,0× | 3 | M | PLA, PETG, TPU | No | No | 92% | Sensor, PEI | 2 | Sí |
| prisma_mc | Prisma MC | FDM multicolor | $549 | 2,0× | 3 | M | PLA, PETG | Sí | No | 90% | Sensor, PEI | 3 | Sí |
| boveda_p1 | Bóveda P1 | FDM cerrada | $699 | 2,5× | 4 | M | PLA, PETG, TPU | No | Sí | 94% | Sensor, PEI, cámara | 4 | Sí |
| gota_r1 | Gota R1 | Resina | $399 | 1,0× | 5 | S | Resina | No | Sí | 92% | — | 5 | Sí |
| titan_pro | Titán Pro | FDM industrial multicolor | $1.899 | 2,5× | 4 | L | PLA, PETG, TPU | Sí | Sí | 97% | Sensor, PEI, cámara | 7 | No |

### 6.2 Pedidos del MVP

| id | Pedido | Cliente | Tamaño | Calidad mín. | Material | Multicolor | Piezas | Gramos por pieza | Tiempo por pieza | Pago | XP | Nivel | Plazo |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| llavero | Llavero con nombre | Amigos | S | 1 | PLA | No | 1 | 8 | 20 min | $6 | 5 | 1 | — |
| soporte_celular | Soporte para celular | Amigos | S | 1 | PLA, PETG | No | 1 | 35 | 1 h | $12 | 10 | 1 | — |
| maceta | Maceta decorativa | Vecinos | S | 2 | PLA | No | 1 | 80 | 2 h | $18 | 15 | 1 | — |
| figura | Figura de colección | Vecinos | S | 2 | PLA | No | 1 | 45 | 2 h 30 min | $28 | 25 | 2 | — |
| perilla | Perilla de lavadora | Vecinos | S | 1 | PETG | No | 2 | 15 | 50 min | $18 | 15 | 2 | 3 días |
| organizador | Organizador de escritorio | Tiendas | M | 2 | PLA, PETG | No | 1 | 180 | 6 h | $38 | 30 | 2 | — |
| letrero | Letrero para negocio | Tiendas | M | 2 | PLA | Sí | 1 | 140 | 7 h | $75 | 60 | 3 | 5 días |
| funda_flexible | Funda flexible para celular | Amigos | S | 2 | TPU | No | 1 | 30 | 1 h 30 min | $15 | 15 | 3 | — |
| carcasa | Carcasa para electrónica | Makers | M | 3 | PETG | No | 2 | 90 | 4 h | $65 | 50 | 3 | — |
| casco_cosplay | Casco de cosplay por partes | Cosplayers | M | 2 | PLA | No | 6 | 220 | 5 h 30 min | $240 | 180 | 3 | 10 días |
| engranaje | Engranajes de repuesto | Talleres | S | 3 | PETG | No | 4 | 20 | 1 h 30 min | $56 | 45 | 4 | 4 días |
| miniatura | Miniatura de alto detalle | Makers | S | 5 | Resina | No | 1 | 25 | 2 h | $35 | 30 | 5 | — |

### 6.3 Estado inicial

- Dinero: $250
- Una mesa con un computador viejo (monitor de tubo, torre beige) y una caja de cartón como silla
- Una impresora Cubo Uno (regalo de Don Ernesto, inspirada en la Ender 3) **en el suelo**
- Un carrete de PLA blanco (1 kg), montado en la impresora
- Nivel 1, sin experiencia
- Día 1, 08:00
- El tutorial con Don Ernesto empieza al abrir el juego por primera vez

## 7. Interfaz y controles

### 7.1 Controles del mundo

El dueño eligió que **el personaje se maneje con un joystick** (2026-10-21).

- **Joystick flotante:** se apoya el pulgar en cualquier parte del mundo (fuera de los botones) y se arrastra. Aparece un aro bajo el dedo y el personaje camina hacia donde apunta el pulgar en la pantalla, también en diagonal. Se juega con una mano.
- **Tocar un objeto** (impresora, mueble, lugar libre, puerta, rincón de despacho): abre al instante su **panel inferior**, desde cualquier parte del cuarto. El personaje se gira a mirarlo.
- **Tocar el piso:** el personaje camina solo hasta ese punto, rodeando los muebles. Sirve también a quien no puede o no quiere usar el joystick.
- **Tocar al personaje:** dice una frase graciosa.
- **Cercanía:** al caminar junto a una impresora, un mueble, la puerta o el rincón de despacho, el objeto se marca con un marco cian en el piso y aparece una burbuja encima. Tocar la burbuja abre su panel, o hace la acción directamente cuando no hay nada que decidir (sección 5.17).
- **Cámara:** sigue al personaje. Tiene tres niveles de zoom: **normal**, **cerca** y **lejos**, que muestra todo el espacio. Se cambian con el botón de abajo a la izquierda o pellizcando.
- **Paneles inferiores:** se cierran con la X, deslizándolos hacia abajo, tocando el mundo o con el botón "atrás" de Android. Empezar a caminar también los cierra.
- **Regla de diseño: caminar nunca es obligatorio para decidir.** El personaje es presentación. Toda la información y todas las decisiones (pedidos, tienda, asignar impresiones) se pueden hacer tocando. Caminar nunca bloquea los pagos ni el progreso fuera del juego. Si más adelante alguna acción pide ir hasta un lugar (por ejemplo, recoger piezas), será corta, dará gusto y se podrá automatizar.
- **Para probar en el computador:** WASD o flechas para caminar, E o Enter para abrir lo resaltado, Z o la rueda del mouse para el zoom y Escape para cerrar el panel. Arrastrar con el mouse también mueve el joystick.

### 7.2 Distribución

Como la imagen de referencia; el detalle está en `docs/ESTILO.md`.

- **Barra superior:** tarjeta del personaje (retrato, nivel y barra de experiencia), dinero, fecha del juego y ajustes.
- **Barra inferior, al alcance del pulgar:** Inicio · Pedidos · Tienda · Inventario · Tareas. *(Aprobada; se implementa en la Fase 1, tarea 3. Hasta entonces sigue la distribución anterior: Pedidos, Tareas y Mapa a la izquierda, y Taller y Perfil abajo.)*
- **Perfil:** al tocar el retrato. **Mapa:** al tocar la puerta y desde Perfil.
- **Objetivos:** una línea compacta con el siguiente objetivo; al tocarla se abre Tareas.
- **Inventario** reúne lo que antes estaba en "Taller": material, envíos en camino, impresoras con su estado y muebles con sus lugares libres.
- **Burbujas de estado** sobre las impresoras, el computador y el rincón de despacho (sección 5.17), con icono y texto. El botón Pedidos muestra un número con lo que espera al jugador.
- Las secciones se abren como un panel sobre la habitación, que sigue visible detrás. La información de un objeto del mundo se abre como panel inferior.
- **Retroalimentación:** cada acción importante tiene sonido, animación y vibración ligera. Cobrar dinero y subir de nivel deben sentirse muy bien.
- Diseño para pulgares: botones grandes en la mitad inferior de la pantalla, respetando las áreas seguras (notch y barra de gestos).

## 8. Arte

- **Estilo: "Mundo Impreso"** (desde la versión 2.4; antes, pixel art). Un diorama 3D suave y cálido del cuarto del protagonista, presentado como una **maqueta impresa capa a capa**, a resolución alta con bordes suavizados. Se inspira en la imagen de referencia del dueño (`docs/referencias/taller_final.webp`). La guía completa está en `docs/ESTILO.md` y la dirección de arte, con todos sus números, en `docs/BIBLIA_ARTE.md`.
- **Técnica:** el mundo es 3D hecho por código (formas con bisel, una malla y un material por objeto), con la luz calculada en el sombreador: un solo sol con sombra y las lámparas, el monitor y los LEDs sin luces extra del motor. Así se ve "caro" y sigue siendo barato en un teléfono; dos niveles de calidad (Alta y Baja, con una opción automática en Ajustes) cuidan los teléfonos de gama baja.
- **La hora se ve:** el reloj del juego lleva la luz del alba a la noche (sol entre las rejas de la ventana en la mañana, tarde dorada, noche de lámpara y monitor). Es solo visual: el juego no cambia de noche.
- **Interfaz:** paneles azul marino con bordes y brillos cian, tipografía Nunito e iconos propios. Las impresoras, los muebles y el personaje se ven en 3D también en la tienda y en los retratos, con una luz de estudio fija.
- **Recursos de terceros:** por ahora ninguno en el mundo (todo es procedural). Si más adelante se usa alguno, se revisa su licencia, se registra en `assets/CREDITS.md` y tiene que pasar por el mismo kit de materiales y la misma paleta.
- Las impresoras deben verse claramente distintas entre sí, por la silueta antes que por el color.
- La pieza que se imprime debe "crecer" capa a capa dentro de la impresora, con una capa caliente que se vea con cualquier zoom. Es el detalle visual más importante del juego. Lo que se compra también aparece imprimiéndose en su lugar.

## 9. Audio

- Sonido característico de los motores de la impresora, distinto para cada tipo.
- Sonidos de interfaz, cobro, fallo y subida de nivel.
- Música tranquila de fondo, con volumen independiente.
- Fuentes: Kenney (CC0) y otras con licencia comprobada, registradas en `assets/CREDITS.md`.

## 10. Accesibilidad e idiomas

- Español como idioma principal e inglés desde la fase móvil. Todo texto pasa por el sistema de traducción desde el día uno.
- Los pedidos multicolor nunca dependen solo del color: siempre llevan icono y texto.
- Tamaño de texto legible en pantallas pequeñas.
- Ninguna mecánica exige reflejos rápidos.
- El joystick no exige precisión: todo lo que se hace caminando también se puede hacer tocando (sección 7.1).

## 11. Monetización (a decidir antes de la fase de publicación)

Propuesta:
- Juego gratuito.
- Anuncios con recompensa **opcionales**, por ejemplo para acelerar una impresión o un envío. Nunca anuncios forzados entre acciones.
- Una compra única para quitar anuncios con algún extra cosmético.
- Sin moneda premium, sin cajas de botín y sin mecánicas que bloqueen el progreso si no se paga.

El dinero del juego se muestra en dólares, pero es solo moneda del juego: no se compra con dinero real. La imagen de referencia muestra gemas como segunda moneda; el juego no las tiene y en su lugar muestra la fecha del calendario.

El MVP no incluye monetización.

## 12. Privacidad

- El MVP no recoge datos personales ni usa analítica.
- Antes de publicar se necesita una política de privacidad, aunque no se recojan datos, y llenar los formularios de privacidad de cada tienda.
- Si se agregan anuncios, en iOS hay que pedir permiso de rastreo y actualizar la política.

## 13. Alcance

### 13.1 Versión mínima (MVP)

- Espacios: habitación amplia y garaje.
- Impresoras: Cubo Uno, Rayo Mini, Rayo X1, Prisma MC, Bóveda P1 y Gota R1.
- Materiales: PLA, PETG, TPU y resina, con inventario y almacenamiento.
- Tienda con envíos de varios días, envío exprés y ferretería del barrio.
- Unos 36 pedidos: los 12 de la sección 6.2 y otros inspirados en precios reales (ideas en `docs/RUTA.md`, sección 8), con variantes automáticas de cantidad, color, plazo y pago (±15%).
- 12 clientes con nombre, cara y personalidad (dos por cada tipo de cliente), y unas 40 frases de Don Ernesto.
- Unos 30 objetivos y unos 20 logros (sección 5.13).
- Manual del maker: glosario de impresión 3D real que se desbloquea al jugar.
- Modos de impresión: Borrador, Normal y Fino.
- Fallos: espagueti, warping y fin de filamento.
- Accesorios: lámina PEI, sensor de filamento y cámara.
- Los muebles de la sección 5.9.
- Cadena de objetivos (sección 5.14).
- Personaje con nivel del 1 al 5 y barra de experiencia.
- Progreso fuera del juego con límite de 8 horas y resumen al volver.
- Guardado automático.
- Tutorial corto con Don Ernesto.
- Interfaz completa para móvil en español.

### 13.2 Fuera del MVP

Lavado y curado de la resina, Titán Pro, local comercial y espacios mayores, empleados, habilidades del protagonista (diseño, marketing, negociación), eventos como ferias maker o pedidos urgentes, decoración del taller, boquillas y mantenimiento, humedad del filamento, compra automática, notificaciones, idioma inglés, monetización y logros de las tiendas.

## 14. Decisiones abiertas

| Decisión | Propuesta actual |
|---|---|
| Título final | "Capa a Capa" |
| Velocidad del tiempo | 1 día de juego = 1 hora real. Se ajusta con el simulador |
| Duración de impresiones | Sección 5.12, a ajustar con el simulador y pruebas reales |
| Apariencia del protagonista | Se define en la fase de arte |
| Compilación de iOS | Mac propia o servicio en la nube, a decidir antes de la Fase 5 |
| Monetización | Sección 11 |

## 15. Fases de desarrollo

Cada fase termina con algo que se puede probar. No se avanza a la siguiente sin cumplir su criterio de terminado. **El detalle de cada fase, sus tareas y el porqué del orden están en `docs/RUTA.md`**, aprobada por el dueño el 2026-10-21.

| Fase | Contenido | Criterio de terminado |
|---|---|---|
| **0. Base** | Proyecto Godot, pruebas automáticas, integración continua y versión web en GitHub Pages | Hecha |
| **1. Ciclo jugable** | Joystick, cámara y paneles; navegación nueva; guardado; tienda y envíos; pedidos; imprimir y entregar; fallos y accesorios; progreso fuera del juego; simulador de balance | En el teléfono se juega desde el día 1 hasta comprar una segunda impresora y llegar al nivel 2, cerrando y abriendo el juego entre sesiones |
| **2. Personaje vivo y game feel** | Respuesta a cada toque, sonido, animaciones de acciones y emociones, mundo vivo y grandes momentos | Cada acción tiene imagen, sonido y vibración en menos de 0,1 s, y 60 fps en un teléfono de gama media |
| **3. UX/UI y primera experiencia** | Panel y lista de impresoras, tienda mejorada, tutorial con Don Ernesto, Manual del maker y accesibilidad | 3 personas que nunca jugaron completan el primer pedido y compran la mesa sin ayuda en menos de 10 minutos |
| **4. Contenido y MVP completo** | Garaje, garaje lleno y rendimiento, pedidos y clientes, objetivos y logros, balance final, prueba de una semana | El MVP de la sección 13.1 completo, del nivel 1 al 5, en unas 2 semanas de sesiones cortas |
| **5. Móvil y rendimiento** | Builds de Android e iOS, áreas seguras, notificaciones, rendimiento en gama baja, inglés completo | Al menos 30 fps en un Android de gama baja y fluido en un iPhone |
| **6. Publicación** | Identidad, textos de tienda, privacidad, prueba cerrada de Google Play y TestFlight | Publicado en ambas tiendas |
| **7. Después del lanzamiento** | Actualizaciones de contenido (sección 13.2) | Continua |

**Importante:** la prueba cerrada de Google Play exige 12 testers activos durante 14 días seguidos. Conviene empezar a reunir testers durante la Fase 5.

## 16. Historial de cambios del diseño

### Versión 2 (2026-10-21)

**Pedidos del dueño:**
- Habitación más amplia.
- Personaje en la escena con nivel y barra de progreso.
- Tienda con impresoras, materiales (incluida resina), insumos y muebles (mesas, estanterías, repisas de filamento y panel de herramientas), con precios reales en dólares.
- Impresoras que se desbloquean según el nivel del jugador.
- Las compras de material e insumos tardan de 3 a 7 días de juego en llegar.
- El jugador empieza con una impresora tipo Ender 3 y $250.

**Diseño propuesto por Claude para que todo encaje:**
- Nombres ficticios inspirados en los productos reales (sección 3 y `docs/REFERENCIAS.md`), porque las marcas reales pueden hacer que las tiendas de apps rechacen el juego.
- Calendario de juego: 1 día = 1 hora real (5.1), para que los envíos de varios días y las duraciones realistas funcionen.
- Envío exprés y ferretería del barrio (5.6), para que la espera de los envíos sea una decisión y no un bloqueo.
- Los muebles definen cuántas impresoras y cuánto material caben (5.9): comprar muebles es una decisión con efecto, no solo decoración.
- Las mejoras globales de la versión 1 pasan a ser accesorios por impresora con precios reales (5.8). Las impresoras modernas ya los traen.
- Se quitó el consumo eléctrico (5.3).
- Plazos congelados mientras el jugador no está, pedidos impresos pieza por pieza, fin de filamento cuando el material no alcanza, y Don Ernesto regala un carrete si el jugador se queda atascado.
- La reputación de la versión 1 pasa a ser el nivel del personaje (5.10).
- El MVP llega hasta el nivel 5 para incluir la resina.

### Versión 2.1 (2026-10-21)

**Pedidos del dueño:**
- Estilo gráfico según su imagen de referencia, coherente en todo el juego.
- Inicio con solo una mesa, un computador viejo y la impresora en el suelo, con 1 kg de PLA blanco. La imagen de referencia es el taller final de ese espacio.

**Diseño propuesto por Claude:**
- Pixel art isométrico hecho con 3D a media resolución (sección 8) y guía de estilo en `docs/ESTILO.md`.
- Imprimir en el suelo con una pequeña penalización de fiabilidad, para que la primera mejora sea comprar una mesa (5.9).
- Colores de filamento, por ahora solo visuales (5.5).
- Cadena de objetivos sin vencimiento (5.14) y distribución de la interfaz según la referencia (7).
- Sin gemas ni moneda premium: en su lugar se muestra la fecha (11).

### Versión 2.2 (2026-10-21)

**Decisiones del dueño** (respuestas a `docs/RUTA.md`, sección 11):
- Aprobó la ruta de desarrollo en 8 fases (sección 15 y `docs/RUTA.md`).
- **El personaje se maneja con un joystick** (sección 7.1).
- Aprobó la navegación nueva (sección 7.2), los tiempos en tiempo real (5.1), el realismo por validar (5.16), el contenido ampliado del MVP (13.1) y el ritmo meta (5.15).

**Diseño propuesto por Claude para que el joystick encaje:**
- Joystick flotante que aparece bajo el pulgar, con la dirección corregida para la vista isométrica.
- Tocar un objeto abre su panel al instante, sin tener que caminar; tocar el piso hace caminar al personaje.
- Resalte por cercanía con burbuja, cámara que sigue al personaje y tres niveles de zoom.
- Regla de diseño: caminar nunca es obligatorio para decidir ni bloquea pagos ni progreso fuera del juego (7.1).

### Versión 2.3 (2026-10-22)

**Pedido del dueño:** trabajar la experiencia de confirmar pedidos, modelar en 3D el pedido, imprimirlo, retirar la pieza impresa, embalarla y despacharla. Esto responde la pregunta abierta de la entrega (sección 14): el personaje retira la pieza, la embala y la despacha.

**Diseño propuesto por Claude, aprobado por el dueño (2026-10-22):**
- El ciclo corto pasa a 6 pasos (sección 4) y se detalla en la nueva sección 5.17.
- Se cobra al despachar, sin tiempo de viaje, y el plazo se revisa en ese momento (5.2).
- Modelar empieza solo en el computador, uno a la vez y mientras se imprime, con tiempos según cómo llega el diseño, y un botón opcional "Concentrarse" (5.17).
- Rincón de despacho fijo junto a la puerta, sin ocupar lugares de muebles (5.17).
- Tablero de pedidos: 3 mensajes y 3 pedidos en curso como máximo, el primer mensaje al minuto de juego y uno nuevo cada 60 minutos de juego en lugar de 120, solo pedidos que se pueden hacer (5.2).
- Las 3 primeras piezas no fallan, puntos de falla por tipo, y "Limpiar y reintentar" o "Limpiar" (5.7).
- El material se aparta al empezar a imprimir (5.5).
- La velocidad de la impresora divide el tiempo; se corrige la redacción (5.3).
- La burbuja de cercanía hace la acción cuando no hay nada que decidir (7.1).
- Se adelantan un guardado mínimo (de la Fase 1, tarea 4) y la ferretería (de la tarea 5).

### Versión 2.4 (2026-10-23)

**Pedido del dueño:** empezar la fase de diseño: que el personaje y los espacios se vean como un juego caro, mejorar y agregar todo lo pertinente, con libertad para cambiar el estilo gráfico.

**Decisiones del dueño** (Arte 2.0, detalle en `docs/BIBLIA_ARTE.md` §16 y `docs/DECISIONES.md`):
- **D1:** el estilo pasa de pixel art a "Mundo Impreso" (sección 8).
- **D2:** sin luces extra del motor de noche: las lámparas y el monitor se calculan en el sombreador.
- **D3:** personaje rediseñado: 1,40 m, cara nueva y buzo gris carbón con forro mostaza (el "buzo negro" de la sección 3, más legible de noche).
- **D4:** las mallas se arman por código al empezar, sin archivos generados en el repositorio.
- **D5 y D6** (se informaron): la estantería metálica de 2,40 m con 0,74 m libres por piso, la repisa y el tablero con pie propio donde no hay pared, y la decoración del dormitorio que crece con el nivel.
- **D7:** opción "Calidad gráfica: Automática / Alta / Baja" en Ajustes.
- **D8:** se adelantan de la Fase 2 el día y la noche visuales y las reacciones del personaje; ningún cambio de juego (por ejemplo, de noche no llegan menos pedidos).

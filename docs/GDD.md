# Documento de diseño — "Capa a Capa" (título provisional)

> Este documento es la fuente de verdad sobre **qué** es el juego. Las reglas técnicas sobre **cómo** se construye están en `CLAUDE.md`. Los números de este documento son valores iniciales para balancear, no definitivos: los valores reales viven en `data/*.json`.
>
> **Versión 2** (2026-10-21). Los cambios respecto a la versión 1 están resumidos en la sección 16.

---

## 1. Concepto

Un joven emprendedor recibe de su vecino una impresora 3D vieja y, con $250 ahorrados, empieza a imprimir llaveros para sus amigos desde su habitación. Pedido a pedido, compra mejores máquinas, materiales y muebles, sube de nivel, consigue clientes más exigentes y convierte su pasatiempo en un taller de fabricación.

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
- El protagonista es joven; el jugador elige su nombre. Aparece en la escena 3D (ver 5.10).
- **Don Ernesto**, el vecino que le regala su vieja impresora, funciona como guía del tutorial y aparece de vez en cuando con consejos.
- Los pedidos llegan como mensajes de clientes en una **app de mensajería ficticia** dentro del teléfono del protagonista. Cada cliente tiene personalidad propia y frases con humor local, sin caer en estereotipos.
- **Todas las marcas son ficticias**: impresoras, filamentos, muebles, apps y tiendas. Nunca se usan nombres reales como Prusa, Bambu Lab, Creality, IKEA o WhatsApp, ni nombres de productos reales (Ender, A1, SKÅDIS...).
- **Inspiración real:** cada impresora, material, accesorio y mueble se inspira en un producto real. Su precio en dólares y sus características se basan en ese producto, pero con nombre ficticio. A qué producto real corresponde cada uno, y de qué fecha son los precios, está en `docs/REFERENCIAS.md`. Ese documento es interno y nunca aparece en el juego.

## 4. Ciclo de juego

**Ciclo corto (segundos a minutos)**
1. Llega un pedido como mensaje de un cliente.
2. El jugador lo acepta o lo rechaza.
3. Asigna una impresora libre, un material compatible y un modo de impresión.
4. La impresión avanza con el tiempo del juego. Puede fallar.
5. Al terminar, el jugador toca la pieza para entregarla.
6. Cobra dinero y gana experiencia.

**Ciclo medio (una sesión)**
Revisar qué terminó mientras no estaba, entregar, recibir los envíos que llegaron, **pedir material antes de que se acabe** (tarda días en llegar), aceptar nuevos pedidos, dejar impresiones largas corriendo y comprar una impresora, un accesorio o un mueble.

**Ciclo largo (días o semanas)**
Subir de nivel, desbloquear impresoras, materiales y clientes, llenar la habitación de muebles y máquinas, mudarse al garaje y alcanzar hitos.

## 5. Sistemas

### 5.1 Tiempo de juego

- El juego tiene su propio calendario: **1 día de juego dura 1 hora real** (el tiempo del juego corre 24 veces más rápido que el real). La barra superior muestra la fecha, por ejemplo "Día 12 · 14:30".
- Así las duraciones pueden ser realistas: un llavero tarda 20 minutos de juego (50 segundos reales) y un envío de 3 días tarda 3 horas reales.
- La velocidad del tiempo vive en `data/config.json`, para ajustarla con el simulador.
- **Todas las duraciones de este documento están en tiempo de juego**, salvo que se diga lo contrario.

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
| Pago | Dinero al entregar, en dólares |
| Plazo | Opcional, en días de juego. Si se entrega tarde, se cobra la mitad y no se gana experiencia |
| Experiencia | Puntos de experiencia (XP) al entregarse a tiempo |
| Nivel mínimo | Nivel del jugador necesario para que este pedido aparezca |

- Hay un tablero con un número limitado de pedidos disponibles que se renueva con el tiempo.
- Rechazar un pedido no tiene castigo; simplemente desaparece.
- **Pedidos de varias piezas:** un pedido se imprime completo en una sola impresora, pieza por pieza. Cada pieza es una impresión independiente: al empezar se decide si fallará, y un fallo solo pierde esa pieza.
- **Plazos y ausencia:** el plazo solo corre mientras el juego está abierto. Mientras el jugador no está, se congela (pilar 4).

### 5.3 Impresoras

| Atributo | Descripción |
|---|---|
| Tecnología | FDM (filamento) o resina |
| Velocidad | Multiplicador sobre el tiempo por pieza |
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
- **Si el material no alcanza:** se puede empezar igual, con un aviso. La impresión se detiene justo donde se acaba el material, y eso se sabe desde el inicio. Sin sensor de filamento, la pieza falla; con sensor, se pausa y continúa al reponer material.
- **Don Ernesto al rescate:** si el jugador no tiene material, ni dinero para un carrete, ni impresiones en curso, ni piezas por entregar, ni envíos en camino, Don Ernesto le regala un carrete de PLA. Así nunca se queda atascado.
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
- Todo se decide al iniciar cada pieza: si fallará, de qué tipo y en qué porcentaje de avance.
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

- La **habitación** es amplia: tiene **6 lugares** en el piso para muebles, además de la cama y la decoración. El escritorio inicial ocupa uno y sostiene una impresora.
- Cada mueble ocupa un lugar. Hay muebles para impresoras, para guardar material y para herramientas.
- Los muebles se ven en la escena 3D: comprarlos hace crecer el taller (pilar 1).

| Mueble | Función | Precio | Nivel |
|---|---|---|---|
| Escritorio (inicial) | 1 impresora | — | — |
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

- **El personaje** aparece en la escena 3D, en su habitación. Al principio se arma con formas básicas; su apariencia definitiva se define en la fase de arte.
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
- Una impresora Cubo Uno (regalo de Don Ernesto) sobre el escritorio de la habitación
- Un carrete de PLA (1 kg)
- Nivel 1, sin experiencia
- El tutorial con Don Ernesto empieza al abrir el juego por primera vez

## 7. Interfaz y controles

- **Cámara:** vista isométrica fija sobre el espacio actual. Pellizcar para hacer zoom, arrastrar para desplazarse dentro de límites.
- **Tocar una impresora:** abre un panel inferior con su estado y acciones (asignar pedido, limpiar, instalar accesorio).
- **Barra inferior:** Pedidos (teléfono con mensajes), Tienda, Taller (muebles y accesorios), Inventario (material y envíos en camino).
- **Barra superior:** retrato del personaje con su nivel y barra de experiencia, dinero y fecha del juego.
- **Retroalimentación:** cada acción importante tiene sonido, animación y vibración ligera. Cobrar dinero y subir de nivel deben sentirse muy bien.
- Diseño para pulgares: botones grandes en la mitad inferior de la pantalla, respetando las áreas seguras (notch y barra de gestos).

## 8. Arte

- **Estilo:** low-poly con colores cálidos y saturados, luz suave y sin texturas complejas.
- **Fuentes de recursos gratuitos:** Kenney, Quaternius y Poly Pizza. Revisar la licencia de cada recurso y registrarla en `assets/CREDITS.md`.
- **Mientras tanto:** las impresoras, los muebles y el personaje se arman con formas básicas (cajas, cilindros y cápsulas) para probar la jugabilidad antes de invertir en arte.
- Las impresoras deben verse claramente distintas entre sí, aun siendo sencillas.
- La pieza que se imprime debe "crecer" capa a capa dentro de la impresora. Es el detalle visual más importante del juego.

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

## 11. Monetización (a decidir antes de la fase de publicación)

Propuesta:
- Juego gratuito.
- Anuncios con recompensa **opcionales**, por ejemplo para acelerar una impresión o un envío. Nunca anuncios forzados entre acciones.
- Una compra única para quitar anuncios con algún extra cosmético.
- Sin moneda premium, sin cajas de botín y sin mecánicas que bloqueen el progreso si no se paga.

El dinero del juego se muestra en dólares, pero es solo moneda del juego: no se compra con dinero real.

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
- Los 12 pedidos de la sección 6.2.
- Modos de impresión: Borrador, Normal y Fino.
- Fallos: espagueti, warping y fin de filamento.
- Accesorios: lámina PEI, sensor de filamento y cámara.
- Los muebles de la sección 5.9.
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
| Compilación de iOS | Mac propia o servicio en la nube, a decidir antes de la fase 4 |
| Monetización | Sección 11 |

## 15. Fases de desarrollo

Cada fase termina con algo que se puede probar. No se avanza a la siguiente sin cumplir su criterio de terminado.

| Fase | Contenido | Criterio de terminado |
|---|---|---|
| **0. Base** | Proyecto Godot, estructura, pruebas automáticas, integración continua, versión web en GitHub Pages | Una escena 3D simple se abre desde un enlace en el navegador del teléfono |
| **1. Simulación** | Lógica pura de tiempo de juego, pedidos, impresoras, materiales, modos, fallos, tienda y envíos, accesorios, muebles, dinero y nivel, con pruebas. Sin gráficos | Las pruebas pasan y un script simula 7 días reales de juego con un jugador automático |
| **2. Prototipo gris** | Escena 3D de la habitación amplia con formas básicas: muebles, impresoras y personaje. Cámara, interfaz mínima (nivel con barra de experiencia, dinero, fecha), tienda, ciclo completo jugable y guardado | Se puede jugar el ciclo completo en el navegador del teléfono, incluida la tienda |
| **3. MVP completo** | Garaje, todas las impresoras del MVP, accesorios y muebles visibles, fallos visibles, progreso fuera del juego, tutorial y balance con el simulador | El MVP de la sección 13.1 completo y jugable de principio a fin |
| **4. Móvil y pulido** | Controles táctiles finos, áreas seguras, rendimiento, arte low-poly, sonido, inglés, notificaciones y builds de Android e iOS | Funciona fluido en un Android de gama baja y en un iPhone |
| **5. Publicación** | Icono, capturas, textos de tienda, política de privacidad, prueba cerrada en Google Play (12 testers durante 14 días) y TestFlight en iOS | Publicado en ambas tiendas |

**Importante:** la prueba cerrada de Google Play exige 12 testers activos durante 14 días seguidos. Conviene empezar a reunir testers durante la fase 4.

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

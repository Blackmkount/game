# Documento de diseño — "Capa a Capa" (título provisional)

> Este documento es la fuente de verdad sobre **qué** es el juego. Las reglas técnicas sobre **cómo** se construye están en `CLAUDE.md`. Los números de este documento son valores iniciales para balancear, no definitivos: los valores reales viven en `data/*.json`.

---

## 1. Concepto

Un joven emprendedor recibe una impresora 3D vieja y empieza a imprimir llaveros para sus amigos desde su cuarto. Pedido a pedido, compra mejores máquinas, aprende a manejar nuevos materiales, gana reputación, consigue clientes más exigentes y convierte su pasatiempo en un taller de fabricación.

**Género:** simulador de gestión / tycoon en 3D, con progreso mientras el jugador no está.
**Plataformas:** Android e iOS. Versión web solo para pruebas internas.
**Orientación:** vertical (retrato), jugable con una mano. *(Decisión abierta, ver sección 14.)*
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
- El protagonista es joven; el jugador elige su nombre. Su apariencia se define en la fase de arte.
- **Don Ernesto**, el vecino que le regala su vieja impresora, funciona como guía del tutorial y aparece de vez en cuando con consejos.
- Los pedidos llegan como mensajes de clientes en una **app de mensajería ficticia** dentro del teléfono del protagonista. Cada cliente tiene personalidad propia y frases con humor local, sin caer en estereotipos.
- **Todas las marcas son ficticias**: impresoras, filamentos, apps y tiendas. Nunca se usan nombres reales como Prusa, Bambu Lab, Creality o WhatsApp.

## 4. Ciclo de juego

**Ciclo corto (segundos a minutos)**
1. Llega un pedido como mensaje de un cliente.
2. El jugador lo acepta o lo rechaza.
3. Asigna una impresora libre, un material compatible y un modo de impresión.
4. La impresión avanza en tiempo real. Puede fallar.
5. Al terminar, el jugador toca la pieza para entregarla.
6. Cobra dinero y gana reputación.

**Ciclo medio (una sesión)**
Revisar qué terminó mientras no estaba, entregar, reponer filamento, aceptar nuevos pedidos, dejar impresiones largas corriendo y comprar alguna mejora.

**Ciclo largo (días o semanas)**
Subir de nivel de reputación, desbloquear clientes e impresoras, mudarse a un espacio más grande y alcanzar hitos.

## 5. Sistemas

### 5.1 Pedidos

Cada pedido tiene:

| Atributo | Descripción |
|---|---|
| Cliente | Tipo de cliente (amigos, vecinos, tiendas, makers, empresas) |
| Tamaño | S, M o L. Debe caber en el volumen de la impresora |
| Calidad mínima | De 1 a 5 |
| Materiales aceptados | Lista de materiales válidos |
| Multicolor | Sí o no. Requiere impresora multicolor |
| Piezas | Cantidad de piezas que hay que imprimir |
| Gramos por pieza | Material consumido |
| Tiempo base | Segundos por pieza con una impresora de velocidad 1.0x en modo Normal |
| Pago | Dinero al entregar |
| Plazo | Opcional. Si se entrega tarde, se pierde reputación y parte del pago |
| Reputación | Puntos que da al entregarse bien |
| Reputación mínima | Nivel necesario para que este pedido aparezca |

- Hay un tablero con un número limitado de pedidos disponibles que se renueva con el tiempo.
- Rechazar un pedido no tiene castigo; simplemente desaparece.

### 5.2 Impresoras

| Atributo | Descripción |
|---|---|
| Velocidad | Multiplicador sobre el tiempo base |
| Calidad máxima | De 1 a 5 |
| Volumen | S, M o L |
| Materiales compatibles | Lista |
| Multicolor | Sí o no |
| Fiabilidad | Probabilidad base de que una impresión no falle |
| Precio | Costo de compra |
| Consumo eléctrico | Costo por minuto de impresión |

Cada impresora ocupa un espacio del taller.

### 5.3 Modos de impresión

| Modo | Calidad | Tiempo | Fallos |
|---|---|---|---|
| Borrador | −1 | ×0,6 | ×1,3 |
| Normal | 0 | ×1,0 | ×1,0 |
| Fino | +1 | ×1,6 | ×0,8 |

La calidad final es la calidad máxima de la impresora ajustada por el modo, sin bajar de 1 ni pasar de 5. Si no alcanza la calidad mínima del pedido, no se puede asignar.

### 5.4 Materiales e inventario

| Material | Costo por gramo | Propiedades | En MVP |
|---|---|---|---|
| PLA | 0,02 | Fácil y barato. Fallos ×1,0 | Sí |
| PETG | 0,03 | Resistente. Algunos pedidos lo exigen. Fallos ×1,15 | Sí |
| TPU | 0,05 | Flexible. Tiempo ×1,6 y requiere impresora compatible | No |
| Resina | 0,06 | Máximo detalle. Requiere lavado y curado | No |

- El material se compra en carretes de 1 kg, o botellas en el caso de la resina, desde una tienda ficticia dentro del juego.
- Si no hay suficiente material para un pedido, no se puede iniciar la impresión.
- Mejora posterior: compra automática de material cuando se acaba.

### 5.5 Fallos

Cuando una impresión falla, se detiene en un punto aleatorio de su avance y el material usado hasta ahí se pierde. El jugador debe tocar la impresora para limpiarla y reintentar.

| Fallo | Visual | Mitigación |
|---|---|---|
| Espagueti | Nido de filamento enredado | Cámara (pausa automática, pierde menos material) |
| Warping | Pieza despegada y curvada | Cama PEI, cerramiento |
| Boquilla tapada | La impresora "imprime aire" | Mantenimiento, boquilla de mejor calidad |
| Fin de filamento | La impresión se queda a medias | Sensor de filamento (pausa en vez de fallar) |

Probabilidad de fallo = (1 − fiabilidad) × modificador del material × modificador del modo × modificadores de mejoras.

Los fallos pueden ocurrir mientras el jugador no está. Volver y encontrar un espagueti es parte del humor del juego, pero la cámara debe estar disponible pronto para que no resulte frustrante.

### 5.6 Reputación y clientes

- La reputación es experiencia acumulada que sube niveles del 1 al 10.
- Entregar a tiempo y con calidad suma. Entregar tarde resta.
- Cada nivel desbloquea tipos de cliente, pedidos e impresoras:

| Nivel | Desbloquea |
|---|---|
| 1 | Amigos y familia |
| 2 | Vecinos y tiendas del barrio. Impresora Rayo X1 |
| 3 | Makers y cosplayers. Impresora Prisma MC |
| 4 | Talleres de reparación y oficinas. Garaje |
| 5 y más | Empresas y startups *(post-MVP)* |

### 5.7 Espacios

| Espacio | Impresoras | Costo | En MVP |
|---|---|---|---|
| Cuarto | 2 | Inicial | Sí |
| Garaje | 5 | $3.000 | Sí |
| Local comercial | 10 | — | No |
| Taller | 20 | — | No |
| Fábrica | 40 | — | No |

- Los espacios se compran una sola vez. **No hay arriendo**, para no castigar a quien deja de jugar unos días.
- Cada espacio es una escena 3D distinta con decoración que también se puede mejorar.

### 5.8 Mejoras del taller

| Mejora | Efecto | Costo | En MVP |
|---|---|---|---|
| Cama PEI | Warping −50% en todas las impresoras | $400 | Sí |
| Cámara de monitoreo | El espagueti pausa la impresión al 10% de avance | $700 | Sí |
| Sensor de filamento | Fin de filamento pausa en vez de fallar | $300 | Sí |
| Cerramiento | Warping −30%, permite materiales exigentes | — | No |
| Turno nocturno | Amplía el límite de progreso fuera del juego de 8 h a 12 h | — | No |
| Compra automática | Repone material solo | — | No |

### 5.9 Progreso fuera del juego

- Al volver, el juego calcula lo que pasó usando la misma simulación del juego activo (ver `CLAUDE.md`).
- Límite inicial de 8 horas de progreso acumulado fuera del juego.
- Al abrir, se muestra un resumen: "Mientras no estabas: 3 pedidos terminados, 1 espagueti".
- Protección básica contra trampas de reloj: si la hora del sistema retrocede, no se otorga progreso.
- Las notificaciones locales del tipo "Tu pedido terminó" quedan para la fase móvil.

### 5.10 Tiempos de impresión

Propuesta inicial, que se ajustará al balancear:

| Etapa | Duración de una impresión típica |
|---|---|
| Inicio (cuarto) | 20 segundos a 2 minutos |
| Media (garaje) | 5 a 30 minutos |
| Avanzada (post-MVP) | 1 a 8 horas |

### 5.11 Hitos y logros

Primera venta, primer espagueti, primeros $1.000, primera impresora comprada, mudanza al garaje, 100 pedidos entregados. Dan pequeñas recompensas y marcan el avance.

## 6. Datos iniciales

### 6.1 Impresoras

| id | Nombre | Tipo | Precio | Velocidad | Calidad máx. | Volumen | Materiales | Multicolor | Fiabilidad | Desbloqueo | En MVP |
|---|---|---|---|---|---|---|---|---|---|---|---|
| cubo_uno | Cubo Uno | FDM básica | Inicial | 1,0× | 2 | S | PLA | No | 85% | Inicio | Sí |
| rayo_x1 | Rayo X1 | FDM rápida | $600 | 2,0× | 3 | M | PLA, PETG | No | 90% | Rep. 2 | Sí |
| prisma_mc | Prisma MC | FDM multicolor | $2.000 | 1,5× | 3 | M | PLA, PETG | Sí | 88% | Rep. 3 | Sí |
| gota_r1 | Gota R1 | Resina | $2.500 | 1,0× | 5 | S | Resina | No | 92% | Rep. 5 | No |
| titan_pro | Titán Pro | FDM industrial | $15.000 | 2,5× | 4 | L | PLA, PETG, TPU | No | 97% | Rep. 7 | No |

### 6.2 Pedidos del MVP

| id | Pedido | Cliente | Tamaño | Calidad mín. | Material | Multicolor | Piezas | Tiempo base por pieza | Pago | Rep. mín. |
|---|---|---|---|---|---|---|---|---|---|---|
| llavero | Llavero con nombre | Amigos | S | 1 | PLA | No | 1 | 20 s | $15 | 1 |
| soporte_celular | Soporte para celular | Amigos | S | 1 | PLA, PETG | No | 1 | 45 s | $25 | 1 |
| maceta | Maceta decorativa | Vecinos | S | 2 | PLA | No | 1 | 90 s | $40 | 1 |
| figura | Figura de colección | Vecinos | S | 2 | PLA | No | 1 | 120 s | $60 | 2 |
| perilla | Perilla de lavadora | Vecinos | S | 1 | PETG | No | 2 | 60 s | $50 | 2 |
| organizador | Organizador de escritorio | Tiendas | M | 2 | PLA, PETG | No | 1 | 300 s | $120 | 2 |
| letrero | Letrero para negocio | Tiendas | M | 2 | PLA | Sí | 1 | 400 s | $220 | 3 |
| carcasa | Carcasa para electrónica | Makers | M | 3 | PETG | No | 2 | 240 s | $260 | 3 |
| casco_cosplay | Casco de cosplay por partes | Cosplayers | M | 2 | PLA | No | 6 | 300 s | $600 | 3 |
| engranaje | Engranajes de repuesto | Talleres | S | 3 | PETG | No | 4 | 150 s | $380 | 4 |

Algunos pedidos tienen plazo; se define en `data/orders.json`.

### 6.3 Estado inicial

- Dinero: $50
- Una impresora Cubo Uno en el cuarto
- Un carrete de PLA (1.000 g)
- Reputación nivel 1
- El tutorial con Don Ernesto empieza al abrir el juego por primera vez

## 7. Interfaz y controles

- **Cámara:** vista isométrica fija sobre el espacio actual. Pellizcar para hacer zoom, arrastrar para desplazarse dentro de límites.
- **Tocar una impresora:** abre un panel inferior con su estado y acciones (asignar pedido, limpiar, mejorar).
- **Barra inferior:** Pedidos (teléfono con mensajes), Tienda, Mejoras, Taller.
- **Barra superior:** dinero, nivel de reputación, inventario de material.
- **Retroalimentación:** cada acción importante tiene sonido, animación y vibración ligera. Cobrar dinero debe sentirse muy bien.
- Diseño para pulgares: botones grandes en la mitad inferior de la pantalla, respetando las áreas seguras (notch y barra de gestos).

## 8. Arte

- **Estilo:** low-poly con colores cálidos y saturados, luz suave y sin texturas complejas.
- **Fuentes de recursos gratuitos:** Kenney, Quaternius y Poly Pizza. Revisar la licencia de cada recurso y registrarla en `assets/CREDITS.md`.
- **Mientras tanto:** las impresoras y muebles se arman con formas básicas (cajas y cilindros) para probar la jugabilidad antes de invertir en arte.
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
- Anuncios con recompensa **opcionales**, por ejemplo para acelerar una impresión. Nunca anuncios forzados entre acciones.
- Una compra única para quitar anuncios con algún extra cosmético.
- Sin moneda premium, sin cajas de botín y sin mecánicas que bloqueen el progreso si no se paga.

El MVP no incluye monetización.

## 12. Privacidad

- El MVP no recoge datos personales ni usa analítica.
- Antes de publicar se necesita una política de privacidad, aunque no se recojan datos, y llenar los formularios de privacidad de cada tienda.
- Si se agregan anuncios, en iOS hay que pedir permiso de rastreo y actualizar la política.

## 13. Alcance

### 13.1 Versión mínima (MVP)

- Espacios: cuarto y garaje.
- Impresoras: Cubo Uno, Rayo X1 y Prisma MC.
- Materiales: PLA y PETG, con inventario y tienda.
- Los 10 pedidos de la sección 6.2.
- Modos de impresión: Borrador, Normal y Fino.
- Fallos: espagueti, warping y fin de filamento.
- Mejoras: cama PEI, cámara y sensor de filamento.
- Reputación del nivel 1 al 4.
- Progreso fuera del juego con límite de 8 horas y resumen al volver.
- Guardado automático.
- Tutorial corto con Don Ernesto.
- Interfaz completa para móvil en español.

### 13.2 Fuera del MVP

Resina y postprocesado, TPU, Titán Pro, local comercial y espacios mayores, empleados, habilidades del protagonista (diseño, marketing, negociación), eventos como ferias maker o pedidos urgentes, decoración del taller, notificaciones, idioma inglés, monetización y logros de las tiendas.

## 14. Decisiones abiertas

| Decisión | Propuesta actual |
|---|---|
| Título final | "Capa a Capa" |
| Orientación | Vertical |
| Duración de impresiones | Sección 5.10, a ajustar con el simulador y pruebas reales |
| Apariencia del protagonista | Se define en la fase de arte |
| Compilación de iOS | Mac propia o servicio en la nube, a decidir antes de la fase 4 |
| Monetización | Sección 11 |

## 15. Fases de desarrollo

Cada fase termina con algo que se puede probar. No se avanza a la siguiente sin cumplir su criterio de terminado.

| Fase | Contenido | Criterio de terminado |
|---|---|---|
| **0. Base** | Proyecto Godot, estructura, pruebas automáticas, integración continua, versión web en GitHub Pages | Una escena 3D simple se abre desde un enlace en el navegador del teléfono |
| **1. Simulación** | Lógica pura de pedidos, impresoras, materiales, modos, fallos, dinero, reputación y tiempo, con pruebas. Sin gráficos | Las pruebas pasan y un script simula 7 días de juego con un jugador automático |
| **2. Prototipo gris** | Escena 3D del cuarto con formas básicas, cámara, interfaz mínima, ciclo completo jugable y guardado | Se puede jugar el ciclo completo en el navegador del teléfono |
| **3. MVP completo** | Garaje, las tres impresoras, mejoras, fallos visibles, progreso fuera del juego, tutorial y balance con el simulador | El MVP de la sección 13.1 completo y jugable de principio a fin |
| **4. Móvil y pulido** | Controles táctiles finos, áreas seguras, rendimiento, arte low-poly, sonido, inglés, notificaciones y builds de Android e iOS | Funciona fluido en un Android de gama baja y en un iPhone |
| **5. Publicación** | Icono, capturas, textos de tienda, política de privacidad, prueba cerrada en Google Play (12 testers durante 14 días) y TestFlight en iOS | Publicado en ambas tiendas |

**Importante:** la prueba cerrada de Google Play exige 12 testers activos durante 14 días seguidos. Conviene empezar a reunir testers durante la fase 4.

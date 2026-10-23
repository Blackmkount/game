# Análisis gráfico: cómo llevar el pixel art a calidad comercial

> **Superado (2026-10-23):** el dueño eligió dejar el pixel art por "Mundo Impreso" (Arte 2.0). La dirección de arte vigente está en `docs/BIBLIA_ARTE.md` y `docs/ESTILO.md`. Este análisis queda como historia.

**Fecha:** 2026-10-21. **Estado:** análisis terminado y verificado. **No se cambió nada del juego**: esto es una propuesta y necesita decisiones del dueño antes de implementarse (ver "Decisiones pendientes").

Pregunta del dueño: *"¿Qué necesitas para mejorar la calidad gráfica, y que se vea más como un juego triple A de estilo pixel art?"*

## Cómo se hizo

Un flujo de trabajo de 7 agentes (`workflow_analisis.js`) hizo:

1. **Auditoría visual:** comparó capturas del juego con la referencia (`docs/referencias/taller_final.webp`).
2. **Investigación de técnicas:** cómo logran su estilo Eastward, Sea of Stars, Octopath Traveler, t3ssel8r y A Short Hike, y qué funciona en Godot con el renderizador Compatibility.
3. **Dos experimentos reales en Godot 4.7.2 Compatibility,** en proyectos aparte, con capturas y medición de cuadros por segundo.
4. **Necesidades y recursos:** herramientas, paquetes con licencia libre (CC0), costo de artistas y decisiones.
5. **Plan priorizado.**
6. **Verificación escéptica de 94 afirmaciones técnicas:** 87 correctas, 4 falsas y 3 dudosas. Las correcciones ya están aplicadas abajo.

Todos los resultados, completos, están en `resultados.json`. Los shaders y scripts de los experimentos están en `experimentos/`, y las capturas comparativas en `capturas/`.

> **Ojo con las mediciones:** se hicieron con llvmpipe, que dibuja por software en el servidor. Sirven para comparar unas técnicas con otras, no como números reales. Hay que confirmarlas en un teléfono, y también en la versión web (WebGL2), que no se probó.

## Respuesta corta

- **"Triple A" no es alcanzable** para una persona con Claude: son estudios de 50 a 500 personas con años de trabajo. Lo realista es un **indie pulido de calidad comercial**, al nivel de *A Short Hike* o *Unpacking*: estilo coherente, escena llena, buena luz y una interfaz que responde.
- **La técnica base ya es la correcta:** 3D a media resolución con cámara isométrica, sombreado por bandas y sombras duras, la misma familia que t3ssel8r. No falta resolución. Lo que falta, en orden de impacto:
  1. **Luz y valores:** el piso sale quemado (255,152,78) y el personaje y la impresora son casi negros.
  2. **Densidad:** hay solo 3 objetos en 36 m².
  3. **Legibilidad:** del protagonista (la cara no se lee) y de las impresoras (su negro es casi el mismo del contorno).
  4. **Disciplina de píxel:** el contorno mide menos de un píxel y la escala no es entera.
  5. **Vida:** las impresoras no imprimen, no hay partículas y la interfaz no tiene animaciones.
  6. **Encuadre:** esquinas cortadas, una puerta fuera de cuadro cuya sombra sí se ve, y una franja vacía abajo.
- **Hay tres techos, según lo que se invierta:**

| Inversión | Resultado esperado |
|---|---|
| Solo Claude y código, $0 | De "prototipo" a "indie limpio y bonito". La escena combinada de los experimentos (`capturas/b_cmp_final.png`) ya se acerca a la referencia |
| Más Blockbench (gratis), paquetes CC0 recoloreados y tiempo del dueño, unos 2 a 4 meses a medio tiempo (estimado) | Bastante cerca de la densidad y el encanto de la referencia |
| Más un artista para el protagonista, las impresoras y el retrato | Identidad propia; la diferencia entre "se ve bien" y "se recuerda" |

## Plan propuesto

### Bloque A: Claude puede hacerlo ya, sin costo

Varios pasos cambian reglas de `docs/ESTILO.md` o de `CLAUDE.md` y necesitan aprobación (ver "Decisiones pendientes").

| # | Paso | Impacto | ¿Probado? | Notas tras la verificación |
|---|---|---|---|---|
| A1 | Mapa de sombras más pequeño y sombra del sol ajustada a la habitación | Medio | Sí | 1024 deja bordes de sombra escalonados (cambia del 1 al 1,7 % de los píxeles). Se recomienda **2048** en web; Android e iOS ya usan 2048 por defecto. Cuidar que `max_distance` cubra la esquina más lejana del piso |
| A2 | **Rampa toon propia de 3 bandas** (sombra fría, tono medio, luz cálida) con la función `light()` | Alto | Sí | `experimentos/b/shaders/toon_ramp.gdshader`. Reemplaza la mezcla sol 0,75 + ambiente 0,5 |
| A3 | **Contorno de 1 píxel por postproceso** (profundidad más normales reconstruidas), en lugar del "inverted hull" | Alto | Sí, solo en escritorio | `experimentos/a/shaders/depth_outline_normals.gdshader`. Unos +2,8 ms en llvmpipe. Hay que probarlo en WebGL2 y en un Android de gama baja. Además reduce a la mitad los triángulos dibujados, porque ya no duplica cada objeto |
| A4 | **Reencuadrar y cerrar el diorama:** el piso llega a la barra inferior, la puerta queda visible, y se agregan cimiento exterior y plantas para que no haya vacío | Alto | No | — |
| A5 | **Haz de luz y polvo** en la ventana: prisma aditivo y unas 70 motas de `CPUParticles3D` | Medio | Sí | `light_shaft.gdshader` |
| A6 | **Hueco real en la pared de la ventana** y paredes que proyectan sombra | Alto | No | Con el sol actual, la sombra de la pared solo cubre ~28 % del piso. Hay que reorientar el sol para que la mancha de la ventana caiga en el centro |
| A7 | **Oclusión y sombras de contacto falsas** con planos que oscurecen (al pie de las paredes y bajo cada objeto y el personaje) | Medio | Sí | `contact_ao.gdshader`. El nodo `Decal` no funciona en Compatibility |
| A8 | **Pantallas y LED vivos** con un shader animado a 8 cuadros por segundo | Medio | Sí | `screen_flicker.gdshader`. La pantalla del computador ocupa unos 14 píxeles de ancho (no 9); su rejilla debe ser de unas 14 columnas |
| A9 | **Disciplina de píxel:** escala entera del mundo, densidad fija y ajuste a la rejilla | Alto | No | La escala no entera ocurre dentro de Godot (`SubViewportContainer`); `image-rendering: pixelated` en la web casi no ayuda |
| A10 | **Interfaz con respuesta:** botones que se hunden, dinero que rueda, monedas que vuelan, vibración | Alto | No | Coincide con la Fase 2, tarea 1, de `docs/RUTA.md` |
| A11 | **Jerarquía de la interfaz:** tres niveles visuales y hojas que dejan ver la habitación | Medio | No | Coincide con la Fase 1, tarea 3 (HUD despejado) |
| A12 | **Vistas previas de la tienda y retrato legibles:** encuadre exacto, mismo ángulo que el mundo y fondo de pedestal claro | Medio | No | — |
| A13 | **Paleta maestra cerrada** de 32 a 48 colores en rampas por material; el negro de las impresoras pasa a ~#3a3d4a | Alto | No | Necesita aprobación del dueño |

### Bloque B: trabajo medio

| # | Paso | Notas |
|---|---|---|
| B1 | **Luces locales y día y noche:** luces falsas con quads aditivos y de 1 a 3 `OmniLight3D` sin sombra, ligadas al reloj del juego | Probado: funciona en Compatibility. **Choca con la regla de `CLAUDE.md`** "una luz direccional más ambiental": necesita aprobación |
| B2 | **Impresoras legibles que imprimen:** escala estilizada de 1,3 a 1,5×, plástico más claro, interior iluminado y la pieza creciendo capa a capa | La impresora mide ~49 px de alto, no 30 como se dijo al principio. Lo que la hace ilegible es su color, casi igual al contorno. Coincide con la Fase 2, tarea 4 |
| B3 | **Protagonista legible:** cara como textura pixel art de 12×12 (ojos con brillo, cejas, boca, parpadeo), pelo limpio, buzo con borde de luz y escala de 1,15 a 1,25× | Coincide con la Fase 2, tarea 3 |
| B4 | **Decoración del cuarto (no jugable):** colchón, alfombra, póster con dibujos sin texto, flexo, cables, caja de impresiones fallidas, figuritas, reloj y plantas | Puede crecer con el nivel (pilar 1) |
| B5 | **Texturas por material:** madera de mueble, metal perforado y plástico con juntas; la proyección triplanar queda solo para piso y paredes | — |
| B6 | **Viñeta y tramado** en el contenedor del mundo | **Corrección:** cuesta de +3,6 a 4,6 ms en llvmpipe, no +0,4 ms (se había medido en el viewport equivocado). Es caro: mejor dejarlo como opción de "calidad alta" |
| B7 | **Sonidos de interfaz CC0** (Kenney Interface Sounds) y caja registradora con jsfxr | Coincide con la Fase 2, tarea 2 |

### Bloque C: grande (depende de tiempo o dinero del dueño)

| # | Paso | Costo estimado |
|---|---|---|
| C1 | Flujo de arte con Blockbench y paquetes CC0 en glTF (KayKit Furniture Bits, Kenney Furniture Kit), recoloreados con la paleta | $0 más tiempo |
| C2 | Personaje con esqueleto y animación a pasos (8 a 12 cuadros por segundo). Ojo: además del modo `MANUAL` del animador hay que ajustar la raíz a la rejilla de píxeles para que no tiemble | $0 a $300 |
| C3 | Encargos de arte: retrato pixel art con 3 o 4 expresiones e iconos (unos $200-600); protagonista 3D con esqueleto y las 7 familias de impresoras (unos $800-2.500) | Opcional |

## Descartado, con la razón

| Idea | Por qué no |
|---|---|
| Normales del motor (`hint_normal_roughness_texture`) | No existen en Compatibility: error de compilación (experimento A2) |
| Nodo `Decal` | Compatibility lo ignora sin avisar (experimento B3c) |
| Oclusión por color de vértice | 15.600 triángulos, hay que recalcularla al mover muebles y no se ve mejor que los planos |
| Contorno solo por profundidad | Umbral demasiado delicado: o salen puntos en la esfera o desaparecen aristas |
| Paleta o tramado con `hint_screen_texture` en un cuadro 3D | Imprecisa en los oscuros, no ve los transparentes y cuesta +2,9 ms |
| Reducir toda la imagen a una paleta de 32 colores | Desvía los tonos: el LED verde sale beige |
| Glow o bloom global | El efecto más caro medido (+5,6 ms), se ve borroso y tiene un error que cuadruplica el brillo del fondo |
| Luz que proyecta una textura (cookie o proyector) | No está en Compatibility |
| Profundidad de campo o tilt-shift estilo HD-2D | No está en Compatibility y el desenfoque destruye el pixel art |
| Niebla volumétrica | No está en Compatibility |
| Lightmaps horneados | Necesitan una GPU que este entorno no tiene, son estáticos y salen suaves |
| SSAO | Pasada borrosa a pantalla completa; como mucho, una opción futura de "calidad alta" |
| Escala entera global de la ventana | Encoge la interfaz y deja barras negras |
| Contorno "Stencil Outline" de Godot 4.5+ | Experimental y no verificado en Compatibility |
| Protagonista como sprite 2D (HD-2D) | Habría que dibujar 4 direcciones por cada animación |
| Paquetes de pago tipo Synty, packs 2D isométricos o vóxeles | Licencia, estilo muy visto o rompen la coherencia |
| Arte generado por IA dentro del juego | En EE. UU. no tendría derechos de autor; solo como referencia |

## Decisiones pendientes del dueño

1. **Meta:** aceptar "indie pulido de calidad comercial" como meta realista, con la referencia como norte de espíritu y no como copia exacta.
2. **Aprobar cambios a `docs/ESTILO.md` y `CLAUDE.md`:** rampa toon en lugar de sol + ambiente, contorno por postproceso en lugar de inverted hull, paredes que dan sombra y 1 a 3 luces locales sin sombra (la regla actual dice "una luz direccional más ambiental").
3. **Escala estilizada:** impresoras a 1,3-1,5× y personaje a 1,15-1,25×, en lugar de escala real.
4. **Cuándo hacerlo.** La ruta aprobada (`docs/RUTA.md`) ya tiene lugares naturales:
   - Bloque A como 1 o 2 tareas cortas (por ejemplo, junto a la Fase 1, tarea 3, o al inicio de la Fase 2).
   - Bloque B dentro de la Fase 2 (tareas 1 a 4).
   - Rendimiento en la Fase 5, tarea 5.
5. **Probar en un teléfono real**, si se puede también en un Android de gama baja (unos $80-150), y mandar capturas con los cuadros por segundo.
6. **Paleta maestra:** revisar y aprobar la que proponga Claude (2 a 4 horas del dueño).
7. **Hoja del personaje:** vistas, colores, expresiones y animaciones. Una foto de un boceto sirve; si lo hace un artista, unos $50-300.
8. **Autorizar recursos CC0** (KayKit, Kenney Furniture Kit, Kenney Interface Sounds, jsfxr), registrados en `assets/CREDITS.md`.

Opcionales: Aseprite ($19,99) o Pixelorama (gratis), artistas (bloque C), música (de $0 con CC0 a $300-3.000 por encargo) y una postura sobre el arte hecho con IA.

## Cómo continuar desde otra cuenta o sesión

1. Abre una sesión de Claude Code con este repositorio.
2. Pega este mensaje:

```
Lee CLAUDE.md, docs/PROGRESO.md, docs/RUTA.md y docs/analisis_grafico/README.md.
Hay un análisis gráfico terminado y verificado (detalle en docs/analisis_grafico/resultados.json).
Mis decisiones sobre la sección "Decisiones pendientes" son: [escribe aquí tus respuestas, por ejemplo "1 sí, 2 sí, 3 sí, 4 hazlo al empezar la Fase 2"].
Con eso, actualiza docs/ESTILO.md, CLAUDE.md y docs/RUTA.md según lo que apruebe, y empieza por el Bloque A en tareas pequeñas, cada una con su PR.
Antes de implementar, vuelve a probar en el proyecto real lo que solo se probó en experimentos y confírmalo en la versión web.
```

### Archivos de esta carpeta

| Archivo | Qué es |
|---|---|
| `resultados.json` | Resultado completo de los 7 agentes: auditoría, técnicas con fuentes, experimentos, necesidades, plan y verificación |
| `experimentos/a/` | Experimentos de postproceso: contorno por profundidad y normales, tramado, glow. `run.sh` y `main.gd` arman la escena de prueba |
| `experimentos/b/` | Experimentos de luz y detalle: rampa toon, luces locales, oclusión falsa, polvo, pantallas. `bench.sh` mide los cuadros por segundo |
| `capturas/` | Comparaciones: `b_cmp_final.png` es la escena con todo combinado, de día y de noche |
| `workflow_analisis.js` | El flujo de trabajo, para repetirlo con la herramienta Workflow |

Los scripts `run.sh` y `bench.sh` tienen rutas absolutas del entorno donde se corrieron (`/tmp/claude-0/.../scratchpad/gfx-exp-*`). Para repetirlos, copia la carpeta a un directorio temporal y ajusta esas rutas. **No los ejecutes dentro del repositorio**: `docs/` tiene `.gdignore` y Godot no los importa ahí.

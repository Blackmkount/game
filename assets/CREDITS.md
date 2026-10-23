# Créditos de recursos

Todo recurso de terceros (modelos, sonidos, música, fuentes, texturas) se registra aquí antes de subirlo al repositorio. Solo se aceptan licencias claras, preferiblemente CC0.

| Recurso | Archivo(s) | Autor | Fuente | Licencia |
|---|---|---|---|---|
| Nunito (tipografía variable) | `assets/fonts/Nunito.ttf` | The Nunito Project Authors | https://github.com/googlefonts/nunito (vía Google Fonts) | SIL Open Font License 1.1 (`assets/fonts/Nunito-OFL.txt`) |

## Código de terceros

| Componente | Ubicación | Autor | Fuente | Licencia |
|---|---|---|---|---|
| GUT (Godot Unit Test) 9.7.1 | `addons/gut/` | Tom "Butch" Wesley y colaboradores | https://github.com/bitwes/Gut | MIT (`addons/gut/LICENSE.md`) |

Hechos para este proyecto (sin terceros): el icono del proyecto (`icon.svg`), los iconos de la interfaz (`assets/icons/*.svg`), las superficies y pantallas del mundo (dibujadas por los sombreadores de `game/world/look/`) y todos los modelos 3D (formas básicas en `game/world/props/`).

**Arte 2.0 ("Mundo Impreso", 2026-10-23): todo es procedural, sin recursos externos.** El mundo, las impresoras, los muebles, la decoración y el personaje se arman por código con el kit de formas (`game/world/look/kit_mesh.gd`, `hair_kit.gd`) y se pintan con los sombreadores de `game/world/look/` (superficies, capas impresas, luces, la vista del barrio por la ventana, las pantallas); la cara del personaje la pinta `FacePainter` al empezar. No hay modelos, texturas, imágenes ni sonidos de terceros, ni archivos de mallas generados en el repositorio. Los pósters, la bufanda, el banderín y el calendario de la decoración son inventados, sin letras ni marcas.

Con el ciclo de pedidos se sumaron dos iconos, también hechos para el juego con el mismo estilo (48×48, trazo blanco de 4 px): `assets/icons/design.svg` (un lápiz, para modelar en el computador) y `assets/icons/warning.svg` (un triángulo de aviso, para una impresión que falló). Los modelos nuevos (rincón de despacho, cajas, paquetes y piezas) y las texturas nuevas (la pantalla del computador modelando y las de las impresoras) también son propios.

`docs/referencias/taller_final.webp` es la imagen de referencia de estilo que entregó el dueño del proyecto. Es solo documentación interna: no se incluye en el juego.

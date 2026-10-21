# Progreso

## Estado actual

- **Fase actual:** 0. Base — **completada** el 2026-10-21.
- **Siguiente paso:** **Fase 1: Simulación** (sección 15 del GDD). Primero se propone un plan de tareas y se espera la aprobación del dueño.

| Fase | Estado |
|---|---|
| 0. Base | Completada (2026-10-21) |
| 1. Simulación | Sin empezar |
| 2. Prototipo gris | Sin empezar |
| 3. MVP completo | Sin empezar |
| 4. Móvil y pulido | Sin empezar |
| 5. Publicación | Sin empezar |

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

# Capa a Capa

Juego móvil 3D de gestión (tycoon) para Android e iOS, hecho en Godot. Un joven emprendedor empieza imprimiendo llaveros en 3D desde su cuarto y, pedido a pedido, convierte su pasatiempo en un taller de fabricación.

Lo desarrolla una sola persona con ayuda de Claude.

## Documentación

| Archivo | Para qué sirve |
|---|---|
| [`docs/GDD.md`](docs/GDD.md) | Qué es el juego: diseño, sistemas, datos y fases. Es la fuente de verdad del diseño. |
| [`docs/PROGRESO.md`](docs/PROGRESO.md) | En qué vamos y cuál es el siguiente paso. |
| [`docs/DECISIONES.md`](docs/DECISIONES.md) | Por qué se tomó cada decisión técnica. |
| [`CLAUDE.md`](CLAUDE.md) | Reglas técnicas del proyecto (las lee Claude en cada sesión). |

## Abrir el proyecto en tu computador

1. Descarga **Godot 4.7.2 estable** (la versión normal, no la ".NET") desde la página oficial de Godot. La versión exacta del proyecto está en `.godot-version`.
2. Abre Godot, pulsa **Importar** y elige el archivo `project.godot` de esta carpeta.
3. Pulsa ▶ (o F5) para jugar la escena principal.

Las pruebas se pueden correr desde el editor con el panel **GUT** (abajo).

## Cómo se trabaja

- Cada tarea se hace en su propia rama y termina en un PR (pull request) en español que explica cómo probar el cambio.
- Al abrir o actualizar un PR, GitHub corre automáticamente la **validación** (`.github/workflows/validate.yml`): revisa que no haya errores y corre todas las pruebas.
- Al fusionar en `main`, GitHub exporta la **versión web** y la publica en GitHub Pages (`.github/workflows/web.yml`). Es solo para pruebas internas desde el teléfono.

### Scripts (Linux, para Claude y para la integración continua)

| Script | Qué hace |
|---|---|
| `tools/setup_godot.sh` | Descarga Godot en `.tools/`. Con `--web-templates` también descarga las plantillas para exportar a web. |
| `tools/check.sh` | Importa el proyecto y falla si algún script o escena tiene errores. |
| `tools/run_tests.sh` | Corre todas las pruebas GUT. |
| `tools/export_web.sh` | Exporta la versión web a `build/web/`. |

## Estructura

```
core/          Lógica pura del juego (sin gráficos)
data/          Números de balance en JSON
game/          Escenas 3D, interfaz y cámara
autoload/      Game, SaveManager y Events
assets/        Modelos, sonidos y fuentes (con CREDITS.md)
localization/  Textos del juego en español e inglés
tests/         Pruebas automáticas (GUT)
tools/         Scripts de trabajo
docs/          Documentación
```

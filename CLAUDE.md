# Capa a Capa — Instrucciones para Claude

Juego móvil 3D de gestión (tycoon) para Android e iOS: un joven emprendedor empieza imprimiendo en 3D desde su cuarto y crece hasta tener un taller. Lo desarrolla una sola persona con ayuda de Claude.

- **Qué es el juego:** `docs/GDD.md` (fuente de verdad del diseño).
- **En qué vamos:** `docs/PROGRESO.md` (léelo antes de empezar cualquier tarea).
- **Hacia dónde vamos:** `docs/RUTA.md` (fases, tareas y su orden).
- **Por qué se decidió algo técnico:** `docs/DECISIONES.md`.
- **Cómo se ve:** `docs/ESTILO.md` (guía de estilo visual). Todo lo visual nuevo debe seguirla.

El dueño del proyecto no es programador experto. Explícale en español sencillo qué hiciste, por qué, y cómo probarlo.

---

## Stack

- **Motor:** Godot 4, versión estable fijada en `.godot-version`. No uses versiones beta. Solo se cambia de versión si el dueño lo aprueba.
- **Lenguaje:** GDScript con tipado estático en todo. No uses C#.
- **Renderizador:** Compatibility. Es el que permite exportar a web y el más compatible con Android de gama baja.
- **Pruebas:** GUT (Godot Unit Test), en `addons/gut/`.
- **Destinos:** Android e iOS. Web solo para pruebas internas, publicada en GitHub Pages.

## Entorno de trabajo

Las sesiones corren en un entorno en la nube donde Godot no viene instalado.

| Script | Qué hace |
|---|---|
| `tools/setup_godot.sh` | Descarga el Godot oficial para Linux de la versión en `.godot-version` desde los releases de `godotengine/godot-builds` en GitHub y lo deja en `.tools/` (ignorado por git). Si ya está, no hace nada |
| `tools/check.sh` | Importa el proyecto en modo headless y falla si hay errores de scripts o escenas |
| `tools/run_tests.sh` | Corre todas las pruebas GUT en modo headless |
| `tools/export_web.sh` | Exporta la versión web a `build/web/`. Necesita las plantillas: `tools/setup_godot.sh --web-templates` |
| `tools/simulate.sh` | Corre el simulador de balance (desde la fase 1) |
| `tools/screenshots.sh` | Saca capturas de la escena principal en varias situaciones en `build/screenshots/`, con `xvfb-run`. Úsalo para revisar la interfaz antes de abrir un PR. Las situaciones están en `tools/screenshot_runner.gd` |

- Al empezar una sesión, ejecuta `tools/setup_godot.sh`.
- Si una descarga falla por restricciones de red, díselo al dueño. No busques rutas alternativas.
- **No puedes ver ni jugar el juego.** Verifica con pruebas y con `check.sh`. Al terminar una tarea visual, dile al dueño exactamente qué revisar en la versión web desde su teléfono. Si el entorno lo permite, puedes intentar generar capturas con `xvfb-run`, pero no inviertas mucho tiempo en eso.

## Arquitectura

**Principio central: la simulación está separada de la presentación.**

```
res://  (raíz del repositorio)
├── core/          Lógica pura del juego. Sin nodos ni escenas.
│   ├── data/      Lectura y validación de data/*.json (DataCatalog, DataValidator)
│   └── sim/       GameState, Order, Printer, Inventory, Economy, Reputation...
├── data/          Balance en JSON: config, levels, materials, printers, accessories, furniture, spaces, clients, orders
├── game/          Presentación: escenas 3D, interfaz, cámara, efectos
│   ├── world/
│   ├── ui/
│   └── scenes/
├── autoload/      Pocos singletons: Game, SaveManager, Events
├── assets/        Modelos, sonidos, fuentes y CREDITS.md
├── localization/  translations.csv (es, en)
├── tests/         unit/ e integration/
├── tools/         Scripts de shell y simulador (con .gdignore)
├── docs/          Documentación (con .gdignore)
└── addons/gut/
```

### Reglas de `core/`

- Solo clases `RefCounted` o `Resource`. Nunca referencias a nodos, escenas, `Input`, `OS` ni a la hora del sistema.
- El tiempo entra como parámetro: `advance(seconds: float)`.
- **Determinista:** el azar usa un `RandomNumberGenerator` cuya semilla se guarda en el estado.
- **Los fallos se deciden al iniciar cada impresión:** en ese momento se calcula si fallará y en qué porcentaje de avance. Así `advance()` es pura aritmética y da el mismo resultado avance en un paso de 8 horas o en miles de pasos pequeños. Debe haber una prueba que lo verifique.
- `advance()` con 8 horas y 40 impresoras debe ser rápido (menos de 100 ms en móvil): avanza por eventos o de forma analítica, no segundo a segundo.
- El mismo `advance()` se usa para el juego en vivo, para el progreso fuera del juego y para el simulador de balance.

### Comunicación entre capas

- La presentación nunca modifica el estado directamente. Llama a comandos del autoload `Game` (`accept_order`, `start_print`, `buy_printer`...), que validan y devuelven un resultado con éxito o motivo de error.
- El estado avisa cambios mediante señales en el autoload `Events`. La interfaz se actualiza con esas señales, no en cada cuadro.

### Datos

- **Ningún número de balance va en el código.** Precios, tiempos, pagos, probabilidades y desbloqueos viven en `data/*.json`.
- Una prueba valida todos los JSON: campos obligatorios, tipos correctos y referencias válidas entre archivos (por ejemplo, que cada material de un pedido exista en `materials.json`).

### Guardado

- JSON en `user://save.json` con campo `version` y migraciones para versiones anteriores.
- Escribir primero en un archivo temporal y luego renombrar, para no corromper la partida si la app se cierra a mitad.
- Guardar después de cada comando, de forma periódica y cuando la app pasa a segundo plano o se cierra.
- Guardar la hora Unix para calcular el progreso fuera del juego. Si la hora retrocede, no se otorga progreso.

### Textos

Todo texto visible para el jugador pasa por `tr("CLAVE")` y `localization/translations.csv`. Nunca escribas textos de interfaz directamente en el código.

## Convenciones de código

- Nombres en el código en inglés, siguiendo la convención de Godot. Comentarios, documentación, commits y PR en español.
- `snake_case` para archivos, funciones y variables. `PascalCase` para `class_name` y nodos. `UPPER_SNAKE_CASE` para constantes.
- Tipado estático siempre: `var money: int`, `func start_print() -> bool`. Activa como error la advertencia de declaraciones sin tipo en la configuración del proyecto.
- Archivos pequeños, una responsabilidad por archivo.
- **Solo API de Godot 4.** Es un error común mezclar patrones de Godot 3. Verifica contra la documentación oficial de la versión en uso:

| Godot 3 (no usar) | Godot 4 |
|---|---|
| `yield` | `await` |
| `export`, `onready` | `@export`, `@onready` |
| `Spatial`, `KinematicBody` | `Node3D`, `CharacterBody3D` |
| `instance()` | `instantiate()` |
| `connect("señal", obj, "metodo")` | `senal.connect(callable)` |
| `rand_range()` | `randf_range()` |

- Los archivos `.uid` que genera Godot se suben a git; no los borres.
- Al editar un `.tscn` a mano, mantén coherentes los `ext_resource` y verifica con `check.sh`.

## Flujo de trabajo

1. Lee `docs/PROGRESO.md` y la parte relevante de `docs/GDD.md`.
2. Trabaja en una rama por tarea. Tareas pequeñas.
3. Para la lógica en `core/`, escribe pruebas. Si corriges un error, primero escribe una prueba que lo reproduzca.
4. Antes de cada commit, ejecuta `check.sh` y `run_tests.sh`. Nunca subas código con pruebas fallando.
5. Al terminar, actualiza `docs/PROGRESO.md` con fecha, qué se hizo, estado de la fase, problemas conocidos y siguiente paso sugerido.
6. Si tomaste una decisión técnica importante, anótala en `docs/DECISIONES.md` (fecha, decisión, motivo).
7. Abre un PR en español con: qué cambió, por qué, **cómo probarlo** en pasos sencillos y qué queda pendiente.

### Pregunta antes de

- Agregar plugins, addons o dependencias.
- Cambiar la arquitectura descrita aquí.
- Cambiar algo del diseño en `docs/GDD.md`.
- Borrar código importante.
- Cualquier cosa que cueste dinero o requiera crear cuentas.
- Pasar a la siguiente fase.

Si algo del GDD o de este archivo te parece mala idea, por diversión o por razones técnicas, dilo con argumentos en lugar de seguirlo en silencio.

## Rendimiento móvil

- Objetivo de 60 fps en gama media y nunca menos de 30 en gama baja.
- Menos de 100.000 triángulos por escena. Una luz direccional más luz ambiental; nada de muchas luces con sombras en tiempo real.
- Reutiliza materiales. Usa `MultiMesh` para objetos repetidos si hace falta.
- La simulación no depende de los fps. Nada de asignar memoria dentro de `_process`.
- Compresión de texturas ETC2/ASTC activada para móvil.

## Recursos, legal y seguridad

- Solo recursos con licencia clara, preferiblemente CC0. Regístralos en `assets/CREDITS.md` con nombre, autor, fuente y licencia.
- Ninguna marca real (impresoras, filamentos, apps) ni personajes con derechos de autor.
- **Nunca subas secretos** al repositorio: keystores, contraseñas, llaves de API ni certificados. Van en GitHub Secrets. El `.gitignore` debe cubrir `*.keystore`, `*.jks`, `*.p12`, `*.mobileprovision` y `.godot/`.
- En los workflows de GitHub Actions, prefiere descargar los binarios oficiales de Godot. Si usas una action de terceros, fíjala por el hash del commit, no por etiqueta.

## Definición de terminado

- `check.sh` y `run_tests.sh` pasan, y la integración continua está en verde.
- `docs/PROGRESO.md` está actualizado.
- El PR explica cómo probar el cambio.
- No quedan `print()` de depuración ni código muerto.

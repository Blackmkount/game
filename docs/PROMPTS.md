# Prompts para Claude Code — "Capa a Capa"

Estos prompts se pegan en Claude Code con el repositorio de GitHub abierto. Los archivos `CLAUDE.md` y `docs/GDD.md` deben estar ya en el repositorio.

---

## 1. Prompt inicial (Fase 0)

```
Hola. Vamos a empezar el desarrollo de "Capa a Capa", un juego móvil 3D de gestión hecho en Godot.

Antes de hacer cualquier cosa, lee completos CLAUDE.md y docs/GDD.md. Si GDD.md está en la raíz del repositorio, muévelo a docs/.

Tu tarea en esta sesión es la Fase 0 (Base) de la sección 15 del GDD. No empieces la Fase 1.

1. Versión de Godot. Busca la última versión estable de Godot 4 (no betas ni release candidates) y escríbela en .godot-version.

2. Herramientas. Crea tools/setup_godot.sh, tools/check.sh y tools/run_tests.sh como describe CLAUDE.md, y verifica que funcionan en este entorno.

3. Proyecto Godot. Créalo en la raíz del repositorio con:
   - Nombre "Capa a Capa", renderizador Compatibility, orientación vertical y un tamaño base pensado para teléfono (por ejemplo 720×1280), con escalado que se adapte a distintas pantallas.
   - La estructura de carpetas de CLAUDE.md, con .gdignore en docs/ y tools/.
   - Autoloads vacíos Game, SaveManager y Events, con comentarios que expliquen qué harán.
   - La advertencia de declaraciones sin tipo configurada como error.
   - Compresión de texturas ETC2/ASTC activada.
   - localization/translations.csv con columnas es y en, un par de claves de ejemplo y registrado en el proyecto.

4. Pruebas. Instala GUT (la versión compatible con nuestra Godot) en addons/gut/ y crea una prueba de ejemplo en tests/unit/ que pase.

5. Escena de prueba. Una escena 3D sencilla: un cuarto hecho con cajas, una "impresora" armada con formas básicas, cámara isométrica fija, una luz direccional y un botón en la interfaz que cambie el color de la impresora. Los textos van con tr(). Sirve para comprobar que la versión web funciona en mi teléfono.

6. Git. Un .gitignore para Godot (que incluya .godot/, .tools/, keystores y credenciales), un .gitattributes que normalice los saltos de línea y un README.md breve en español que explique qué es el proyecto y cómo se trabaja.

7. Integración continua con GitHub Actions:
   - Workflow de validación: en cada push y PR descarga Godot y ejecuta check.sh y run_tests.sh.
   - Workflow de versión web: en cada push a main exporta a web sin soporte de hilos (para que funcione en GitHub Pages sin cabeceras especiales) y publica en GitHub Pages.
   - export_presets.cfg con el preset Web. Los presets de Android e iOS se agregan en la Fase 4.

8. Documentación. Crea docs/PROGRESO.md (estado actual, Fase 0 completada, siguiente paso: Fase 1) y docs/DECISIONES.md con las decisiones técnicas de esta sesión.

9. PR. Abre un PR con un resumen en español que incluya:
   - Qué se creó.
   - Lo que debo hacer yo a mano en GitHub, paso a paso (por ejemplo, activar GitHub Pages con origen "GitHub Actions"). Si el repositorio es privado y mi plan no permite GitHub Pages, explícame las alternativas.
   - Cómo abrir la escena de prueba desde mi teléfono una vez publicada.

Si algo de CLAUDE.md o del GDD te parece mal planteado técnicamente, dímelo antes de cambiarlo. Al terminar, resúmeme en lenguaje sencillo qué quedó listo y qué sigue.
```

---

## 2. Empezar una fase nueva

Cambia el número y el nombre de la fase. Úsalo después de haber aprobado y fusionado el trabajo de la fase anterior.

```
Lee CLAUDE.md, docs/PROGRESO.md y docs/GDD.md. Vamos a empezar la Fase [N] ([nombre]) según la sección 15 del GDD.

Primero propón un plan dividido en tareas pequeñas, donde cada tarea termine en un PR que yo pueda revisar, y espera mi aprobación. Después haz solo la primera tarea.
```

### Notas extra por fase (agrégalas al prompt anterior)

Las fases y sus tareas están en `docs/RUTA.md`.

**Fase 1 — Ciclo jugable**
```
Recuerda: la lógica va en core/ con pruebas, y cada tarea la conecta con la interfaz para que yo pueda probarla en el teléfono. Todos los números en data/*.json. Los fallos se deciden al iniciar cada impresión, y advance() debe dar el mismo resultado en un paso grande que en muchos pequeños, con una prueba que lo demuestre. La pieza debe verse "crecer" dentro de la impresora aunque sea un cubo que sube de altura.

La fase termina con tools/simulate.sh: un jugador automático sencillo que juega 7 días y genera un informe con dinero, nivel, impresoras compradas y el momento de cada desbloqueo, para revisar el balance.
```

**Fase 2 — Personaje vivo y game feel**
```
Cada acción tiene que responder en menos de 0,1 segundos con imagen, sonido y, donde corresponda, vibración. Usa solo sonidos con licencia clara (preferiblemente CC0) y regístralos en assets/CREDITS.md. Dime exactamente qué revisar en el teléfono.
```

**Fase 5 — Móvil y rendimiento**
```
En esta fase necesitaremos mi cuenta de Google Play, mi cuenta de Apple Developer y firmar las apps. Antes de cada cosa que dependa de mí, explícame paso a paso qué tengo que hacer, qué secretos crear en GitHub y cómo. Nunca subas keystores, certificados ni contraseñas al repositorio.
```

**Fase 6 — Publicación**
```
Ayúdame a preparar todo lo de las tiendas: textos de la ficha en español e inglés, lista de capturas necesarias, política de privacidad, formularios de privacidad de cada tienda, clasificación por edad y el plan para la prueba cerrada de Google Play (12 testers durante 14 días seguidos).
```

---

## 3. Continuar en una sesión nueva

```
Lee CLAUDE.md y docs/PROGRESO.md. Continúa con la siguiente tarea pendiente de la fase actual. Al terminar, abre el PR y dime en pasos sencillos cómo probarlo.
```

---

## 4. Reportar un error

```
Lee CLAUDE.md y docs/PROGRESO.md. Encontré un problema jugando la versión web:

- Qué hice: [pasos]
- Qué esperaba que pasara: [...]
- Qué pasó en realidad: [...]
- Teléfono y navegador: [...]

Si es un error de lógica, primero escribe una prueba que lo reproduzca y luego corrígelo.
```

Si puedes, adjunta una captura de pantalla o un video corto.

---

## 5. Ajustar el balance

```
Lee CLAUDE.md y docs/PROGRESO.md. Jugando siento que [el inicio es muy lento / el dinero sube demasiado rápido / la Rayo X1 llega muy tarde / ...].

Corre tools/simulate.sh, muéstrame los números relevantes y propón ajustes en data/*.json explicando qué efecto esperas de cada uno. Espera mi aprobación antes de aplicarlos.
```

---

## 6. Proponer una idea nueva

```
Lee CLAUDE.md y docs/GDD.md. Tengo esta idea para el juego: [idea].

No escribas código todavía. Dime si encaja con los pilares de diseño, cuánto trabajo sería, en qué fase tendría sentido y qué partes del GDD habría que cambiar. Si te parece mala idea, dímelo con argumentos.
```

---

## 7. Revisión de salud del proyecto (cada 2 o 3 semanas)

```
Lee CLAUDE.md y docs/PROGRESO.md. Haz una revisión del proyecto sin cambiar nada: código que no cumpla las reglas de CLAUDE.md, lógica sin pruebas, deuda técnica, posibles problemas de rendimiento en móvil y documentación desactualizada. Dame un informe con prioridades (alta, media, baja).
```

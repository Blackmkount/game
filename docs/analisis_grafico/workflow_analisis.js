export const meta = {
  name: 'pixel-art-aaa-plan',
  description: 'Diagnóstico visual, investigación de técnicas, experimentos en Godot y plan para un pixel art de alta calidad',
  phases: [
    { title: 'Diagnóstico', detail: 'auditoría visual, técnicas, experimentos y necesidades en paralelo' },
    { title: 'Síntesis', detail: 'plan priorizado con impacto, costo y lo que se necesita del dueño' },
    { title: 'Verificación', detail: 'revisión escéptica de las afirmaciones técnicas' },
  ],
}

const A = args
const CONTEXT = `
Proyecto: "Capa a Capa", juego móvil tycoon de impresión 3D, repo en ${A.repo}.
Motor: Godot ${A.godot_version}, renderizador Compatibility (OpenGL ES 3 / WebGL2). Destinos: Android gama baja/media, iOS y web (GitHub Pages, sin hilos).
Reglas de rendimiento (CLAUDE.md): 60 fps gama media, nunca <30 en gama baja, <100.000 triángulos por escena, UNA luz direccional + ambiental (nada de muchas luces con sombras), reutilizar materiales, MultiMesh si hace falta.
Técnica visual actual (ver ${A.repo}/docs/ESTILO.md): mundo 3D con formas básicas (BoxMesh, CylinderMesh, SphereMesh) dibujado en un SubViewport a media resolución (stretch_shrink 2, filtro NEAREST, sin MSAA), StandardMaterial3D con DIFFUSE_TOON, sombras duras, contorno "inverted hull" (game/world/pixel/outline.gdshader), texturas pixel art generadas por código (game/world/pixel/pixel_textures.gd), cámara ortográfica isométrica (-30°, 45°). Interfaz por código con tema común (game/ui/theme/ui_theme.gd), tipografía Nunito, iconos SVG propios.
Código del mundo: ${A.repo}/game/world/ (room_view.gd, props/*.gd, pixel/*). Código de la interfaz: ${A.repo}/game/ui/.
Imagen de referencia del dueño (meta visual, taller final): ${A.reference}.
Capturas actuales del juego (puedes abrirlas con la herramienta Read): ${A.screenshots.join(', ')}.
El dueño NO es programador; trabaja solo con ayuda de Claude. Pregunta: "¿Qué necesitas para mejorar la calidad gráfica y que se vea más como un juego triple A de estilo pixel art?"
Responde en español. No modifiques archivos del repositorio.`

const GAPS_SCHEMA = {
  type: 'object',
  properties: {
    gaps: { type: 'array', items: { type: 'object', properties: {
      area: { type: 'string' }, gap: { type: 'string' }, evidence: { type: 'string' },
      severity: { type: 'string', enum: ['alta', 'media', 'baja'] }, fix_idea: { type: 'string' },
    }, required: ['area', 'gap', 'evidence', 'severity', 'fix_idea'] } },
    overall: { type: 'string' },
  },
  required: ['gaps', 'overall'],
}
const TECH_SCHEMA = {
  type: 'object',
  properties: {
    techniques: { type: 'array', items: { type: 'object', properties: {
      name: { type: 'string' }, what_it_does: { type: 'string' }, examples: { type: 'string' },
      feasible_in_compatibility: { type: 'string', enum: ['sí', 'parcial', 'no', 'no verificado'] },
      mobile_cost: { type: 'string', enum: ['bajo', 'medio', 'alto'] },
      impact: { type: 'string', enum: ['alto', 'medio', 'bajo'] },
      notes: { type: 'string' }, sources: { type: 'array', items: { type: 'string' } },
    }, required: ['name', 'what_it_does', 'feasible_in_compatibility', 'mobile_cost', 'impact', 'notes', 'sources'] } },
  },
  required: ['techniques'],
}
const EXP_SCHEMA = {
  type: 'object',
  properties: {
    experiments: { type: 'array', items: { type: 'object', properties: {
      name: { type: 'string' }, works_in_compatibility: { type: 'boolean' },
      evidence: { type: 'string' }, screenshot_path: { type: 'string' }, notes: { type: 'string' },
    }, required: ['name', 'works_in_compatibility', 'evidence', 'notes'] } },
  },
  required: ['experiments'],
}
const NEEDS_SCHEMA = {
  type: 'object',
  properties: {
    needs: { type: 'array', items: { type: 'object', properties: {
      item: { type: 'string' },
      kind: { type: 'string', enum: ['herramienta', 'recurso', 'persona', 'decisión', 'dinero', 'referencia', 'tiempo'] },
      cost: { type: 'string' }, why: { type: 'string' },
      priority: { type: 'string', enum: ['alta', 'media', 'baja'] }, sources: { type: 'array', items: { type: 'string' } },
    }, required: ['item', 'kind', 'cost', 'why', 'priority'] } },
  },
  required: ['needs'],
}

const SCRATCH = A.scratch
const EXP_COMMON = `Trabaja SOLO dentro de ${SCRATCH}/<tu_carpeta> (crea un proyecto Godot mínimo propio con project.godot, renderizador gl_compatibility; no toques ${A.repo}).
Godot está en ${A.godot_bin}. Para importar: "${A.godot_bin} --headless --path <dir> --import". Para capturar en GPU real de software:
xvfb-run -a -s "-screen 0 1400x1400x24" ${A.godot_bin} --path <dir> --rendering-driver opengl3 --fixed-fps 30 --write-movie <dir>/shots/f.png --quit-after 20
(el último cuadro queda en shots/f00000019.png; ábrelo con Read para juzgarlo). Usa GDScript con tipos estáticos. Si algo no funciona en Compatibility, dilo con la evidencia (mensaje de error o captura). Sé empírico: un experimento cuenta solo si lo corriste.`

phase('Diagnóstico')
const [audit, tech, exp1, exp2, needs] = await parallel([
  () => agent(`${CONTEXT}

Tarea: AUDITORÍA VISUAL. Abre la imagen de referencia y las capturas actuales con Read, y lee el código del mundo y de la interfaz. Compara con ojo de director de arte de juegos pixel art de alto nivel (Eastward, Sea of Stars, Octopath Traveler HD-2D, el trabajo 3D-pixel-art de t3ssel8r, Hyper Light Drifter, Stardew Valley). Enumera las diferencias concretas que más alejan el juego de un aspecto "triple A pixel art": iluminación (luces cálidas locales, sombras de contacto, oclusión), riqueza de materiales y texturas, densidad de detalle y "props" de ambientación, proporciones y silueta del personaje, animación y vida (partículas, polvo, parpadeo de pantallas), composición y encuadre, coherencia de paleta, nitidez del píxel (temblor, mezcla de resoluciones, contornos irregulares), calidad de la interfaz (jerarquía, micro-animaciones, retroalimentación), y cualquier error visual que veas (texturas estiradas, z-fighting, contornos rotos). Para cada brecha da evidencia (qué se ve y dónde) y una idea de arreglo. Sé específico y honesto.`, { label: 'auditoría visual', phase: 'Diagnóstico', schema: GAPS_SCHEMA }),

  () => agent(`${CONTEXT}

Tarea: INVESTIGACIÓN DE TÉCNICAS. Investiga en la web (usa WebSearch/WebFetch; carga sus esquemas con ToolSearch si hace falta) cómo se logra el pixel art 3D de alta calidad y el estilo "HD-2D", y cuáles se pueden usar en Godot 4 con el renderizador Compatibility, en web y en móviles de gama baja. Cubre al menos: cámara con ajuste a píxel (pixel snapping) y suavizado sub-píxel al mover la cámara; contornos por detección de bordes con profundidad y normales vs inverted hull; rampas de sombreado toon personalizadas (función light() en shaders); cuantización a paleta y dithering; luces locales falsas (texturas emisivas, "light cookies", luces sin sombra, decals); oclusión ambiental horneada o falsa (vertex colors, texturas de AO, sombras de contacto falsas); lightmaps en Compatibility; bloom/glow en Compatibility; partículas pixeladas (CPUParticles3D/GPUParticles3D en Compatibility); niebla y profundidad de campo estilo HD-2D (posibilidad y costo); modelos low-poly con texturas pixel art hechas en Blockbench o similares; sprites 2D en mundo 3D (billboards) para personajes; animación por huesos o por cuadros. Para cada técnica: qué hace, ejemplos de juegos, factibilidad en Compatibility (marca "no verificado" si no encontraste fuente clara), costo en móvil, impacto visual, notas de implementación y fuentes (URLs).`, { label: 'investigación de técnicas', phase: 'Diagnóstico', schema: TECH_SCHEMA }),

  () => agent(`${CONTEXT}

Tarea: EXPERIMENTOS A (postproceso). ${EXP_COMMON}
Usa la carpeta ${SCRATCH}/gfx-exp-a. Arma una escena simple (piso, dos cajas, una esfera, cámara ortográfica isométrica, una luz direccional) dentro de un SubViewport a media resolución con filtro NEAREST, como el juego. Prueba y reporta, con captura cada uno:
1) Contorno por detección de bordes usando la textura de profundidad (hint_depth_texture) en un shader de pantalla completa dentro del SubViewport, en Compatibility. ¿Funciona? ¿Qué limitaciones?
2) ¿Está disponible hint_normal_roughness_texture en Compatibility? (pruébalo y reporta el error si no).
3) Cuantización a paleta + dithering ordenado (Bayer 4x4) como postproceso con hint_screen_texture en Compatibility.
4) Glow/bloom del Environment en Compatibility a esta resolución (¿se activa? ¿cómo se ve?).`, { label: 'experimentos: postproceso', phase: 'Diagnóstico', schema: EXP_SCHEMA }),

  () => agent(`${CONTEXT}

Tarea: EXPERIMENTOS B (iluminación y detalle). ${EXP_COMMON}
Usa la carpeta ${SCRATCH}/gfx-exp-b. Arma una escena interior simple (piso, dos paredes, una mesa, una caja) con cámara ortográfica isométrica en un SubViewport a media resolución con filtro NEAREST. Prueba y reporta, con captura cada uno:
1) Rampa de sombreado toon personalizada con la función light() de un shader spatial (3 bandas de color cálido/frío) en Compatibility.
2) Luces locales: 2-3 OmniLight3D SIN sombra (lámpara de escritorio, pantalla) además de la direccional: ¿funcionan en Compatibility? ¿hay límite de luces por objeto? Mide FPS aproximado si puedes (Engine.get_frames_per_second en un label o print) con --fixed-fps desactivado.
3) Oclusión ambiental falsa: vertex colors o una textura/decal oscura en las esquinas y bajo los objetos (sombra de contacto). ¿Qué tan bien se ve?
4) Partículas pixeladas (CPUParticles3D con quads pequeños) para polvo flotando en la luz de la ventana.
5) Una pantalla/monitor emisivo con parpadeo animado barato (shader con TIME).`, { label: 'experimentos: luz y detalle', phase: 'Diagnóstico', schema: EXP_SCHEMA }),

  () => agent(`${CONTEXT}

Tarea: NECESIDADES Y RECURSOS. Investiga en la web (WebSearch/WebFetch vía ToolSearch) qué haría falta, más allá del código, para que el juego se vea de calidad comercial alta en pixel art: herramientas (Blockbench, Aseprite, Pixelorama, Krita, MagicaVoxel; precio y licencia de cada una), packs de recursos con licencia clara compatibles con este estilo (Kenney, Quaternius, itch.io CC0; ¿sirven al pasar por el render pixel art?), cuánto cuesta aproximadamente contratar a un artista pixel art o 3D low-poly por pieza/personaje/escena (rangos de mercado con fuentes), qué referencias o decisiones debe tomar el dueño (paleta definitiva, hoja de personaje, mood board, prioridad: personaje vs ambiente vs UI), audio y "juice" (sonidos, vibración) que influyen en la percepción de calidad, y tiempo realista. Incluye la restricción de no usar marcas reales. Da costos aproximados y fuentes cuando existan; si un dato es estimado, dilo.`, { label: 'necesidades y recursos', phase: 'Diagnóstico', schema: NEEDS_SCHEMA }),
])

log(`Diagnóstico: ${audit ? audit.gaps.length : 0} brechas, ${tech ? tech.techniques.length : 0} técnicas, ${(exp1 ? exp1.experiments.length : 0) + (exp2 ? exp2.experiments.length : 0)} experimentos, ${needs ? needs.needs.length : 0} necesidades`)

const PLAN_SCHEMA = {
  type: 'object',
  properties: {
    summary: { type: 'string' },
    honest_expectations: { type: 'string' },
    steps: { type: 'array', items: { type: 'object', properties: {
      title: { type: 'string' },
      tier: { type: 'string', enum: ['ya, sin costo', 'medio', 'grande'] },
      what: { type: 'string' }, impact: { type: 'string', enum: ['alto', 'medio', 'bajo'] },
      mobile_cost: { type: 'string', enum: ['bajo', 'medio', 'alto'] },
      verified_by_experiment: { type: 'boolean' }, depends_on_owner: { type: 'boolean' },
      technical_claims: { type: 'array', items: { type: 'string' } },
    }, required: ['title', 'tier', 'what', 'impact', 'mobile_cost', 'verified_by_experiment', 'depends_on_owner', 'technical_claims'] } },
    needs_from_owner: { type: 'array', items: { type: 'object', properties: {
      item: { type: 'string' }, why: { type: 'string' }, cost: { type: 'string' }, optional: { type: 'boolean' },
    }, required: ['item', 'why', 'cost', 'optional'] } },
    discarded: { type: 'array', items: { type: 'object', properties: { idea: { type: 'string' }, reason: { type: 'string' } }, required: ['idea', 'reason'] } },
  },
  required: ['summary', 'honest_expectations', 'steps', 'needs_from_owner', 'discarded'],
}

phase('Síntesis')
const plan = await agent(`${CONTEXT}

Eres el director técnico de arte. Con estos insumos, arma un plan priorizado para llevar el juego a un pixel art de calidad alta, realista para un desarrollador solo con Claude, sin romper las reglas de rendimiento ni el renderizador Compatibility.

AUDITORÍA: ${JSON.stringify(audit)}
TÉCNICAS: ${JSON.stringify(tech)}
EXPERIMENTOS (lo que de verdad se probó en Godot ${A.godot_version} Compatibility): ${JSON.stringify([exp1, exp2])}
NECESIDADES: ${JSON.stringify(needs)}

Reglas: prioriza por impacto visual / costo. Marca verified_by_experiment solo si un experimento lo confirmó. Si una técnica no funciona en Compatibility según los experimentos, va en "discarded" con la razón. Separa lo que Claude puede hacer ya, sin costo, de lo que depende del dueño (dinero, artista, decisiones). En technical_claims anota las afirmaciones técnicas concretas que sostienen cada paso (para verificarlas después). En honest_expectations explica con franqueza qué significa "triple A" para un juego así y qué es alcanzable.`, { label: 'plan', phase: 'Síntesis', schema: PLAN_SCHEMA })

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    reviews: { type: 'array', items: { type: 'object', properties: {
      claim: { type: 'string' }, verdict: { type: 'string', enum: ['correcta', 'dudosa', 'falsa'] }, reason: { type: 'string' },
    }, required: ['claim', 'verdict', 'reason'] } },
    plan_issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['reviews', 'plan_issues'],
}

phase('Verificación')
const claims = plan ? plan.steps.flatMap(s => s.technical_claims.map(c => `[${s.title}] ${c}`)) : []
const verdict = claims.length ? await agent(`Eres un revisor técnico escéptico de Godot ${A.godot_version} (renderizador Compatibility, web y móvil de gama baja). Intenta REFUTAR cada afirmación; ante la duda marca "dudosa". Puedes consultar la documentación oficial (WebFetch vía ToolSearch) y, si hace falta, correr una prueba rápida en ${SCRATCH}/gfx-verify con Godot en ${A.godot_bin} (no toques ${A.repo}). Evidencia de experimentos ya corridos: ${JSON.stringify([exp1, exp2])}.

Afirmaciones:
${claims.map((c, i) => `${i + 1}. ${c}`).join('\n')}

También señala en plan_issues cualquier paso del plan que choque con estas reglas: una sola luz direccional con sombras más luz ambiental, <100k triángulos, 60 fps en gama media, web sin hilos.
Plan completo: ${JSON.stringify(plan)}`, { label: 'verificación escéptica', phase: 'Verificación', schema: VERDICT_SCHEMA }) : null

return { audit, tech, experiments: [exp1, exp2], needs, plan, verdict }

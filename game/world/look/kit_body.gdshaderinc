// Cuerpo del material "kit" (biblia de arte §3): el de casi todo el mundo.
//
// kit.gdshader lee todo de los vértices de la malla (KitMesh), así un mueble
// entero es una malla con un material, una llamada de dibujo:
//   COLOR.rgb  color (hex de la paleta, espacio de pantalla)
//   COLOR.a    oclusión horneada (1 = nada)
//   UV.x       parte entera: tipo de superficie; parte decimal: brillo
//   UV.y       peso del balanceo (plantas, cortina, cobija); < 0: la
//              luz propia parpadea (los focos de la guirnalda)
//   UV2.x      alto de capa si es impreso, en metros (0 = no impreso)
//   UV2.y      luz propia: > 0 siempre, < 0 solo de noche
// kit_tinted.gdshader (define KIT_TINTED) toma lo mismo de los uniform: la
// pieza, la bandeja, el filamento y los modelos de cajas de antes.
// kit_printing.gdshader (además HOT_LAYER) es la pieza mientras se imprime,
// con la capa caliente arriba. kit_glass.gdshader (además KIT_GLASS) es
// transparente y se ve de los dos lados (la tapa ámbar de la impresora de
// resina). kit_character.gdshader (KIT_CHARACTER) es el cuerpo del
// personaje: más relleno de cámara y, en los retratos, una luz de estudio;
// kit_head.gdshader (además KIT_HEAD), su cabeza con la cara pintada.
//
// OJO: un "instance uniform" le cuesta a CADA instancia que use el material
// 16 lugares del búfer de globales (en la web y en muchos teléfonos caben
// 1.024 en total). Por eso solo los tienen la variante HOT_LAYER y las del
// personaje (unas pocas instancias).

#include "res://game/world/look/world_light.gdshaderinc"

#ifdef KIT_TINTED
// Sin "source_color": los colores van en el espacio de la pantalla.
uniform vec4 albedo = vec4(1.0);
uniform int surface = 0;
uniform float gloss = 0.0;
uniform float layer = 0.0;
uniform float emit = 0.0;
#endif
// Terminador: 0 suave (mundo), más alto más marcado (personaje).
uniform float toon = 0.0;
// Luz de borde, solo del lado iluminado y teñida con el color del objeto
// (la prueba del piso de noche lee de aquí la del mundo).
uniform float rim = 0.28;
#ifdef KIT_GLASS
uniform float alpha = 0.5;
#endif
#ifdef HOT_LAYER
// Borde de arriba de la pieza que se imprime, en el espacio de la malla: ahí
// va la capa caliente. -100 = no hay.
instance uniform float hot_top = -100.0;
#endif
#ifdef KIT_CHARACTER
// 1 en las vistas previas (retratos): una luz de estudio fija en vez de la
// luz del mundo (ModelPreview la pone en cada malla).
instance uniform float preview_light = 0.0;
// Movimiento secundario (CharacterAnimator, biblia §7.7): lo que cuelga
// (UV.y = su peso) se mueve con inercia en vez de mecerse con el viento. En
// el cuerpo, `swing` es un corrimiento en metros (cordones y capucha); en la
// cabeza, giros chicos (radianes alrededor de x, y, z) del pelo alrededor de
// hair_pivot. outline_character.gdshader hace lo mismo con el contorno.
instance uniform vec3 swing = vec3(0.0);
// Luz de estudio (espacio de la pantalla): ambiente de arriba y de abajo,
// llave cálida desde arriba a la izquierda, relleno frío desde la derecha y
// borde desde atrás. Direcciones en el espacio de la cámara.
uniform vec3 studio_sky = vec3(0.39, 0.42, 0.49);
uniform vec3 studio_ground = vec3(0.36, 0.29, 0.23);
uniform vec3 studio_key = vec3(0.36, 0.32, 0.25);
uniform vec3 studio_fill = vec3(0.11, 0.13, 0.17);
uniform vec3 studio_rim = vec3(0.45, 0.43, 0.40);
const vec3 CC_STUDIO_KEY_DIR = vec3(-0.55, 0.62, 0.56);
const vec3 CC_STUDIO_FILL_DIR = vec3(0.86, 0.05, 0.5);
#endif
#ifdef KIT_HEAD
// La cara (FacePainter): atlas de expresiones en celdas, proyectado
// alrededor del eje vertical de la cabeza (face_axis: centro del cráneo a la
// altura de los ojos, en el espacio de la malla). Una celda cubre face_span
// radianes alrededor y face_height metros de alto. Solo en la piel (la
// superficie SKIN; el pelo no recibe la cara). El alfa del atlas es la
// máscara de los ojos: ahí adentro el iris y la pupila se corren `gaze`
// (fracción del ancho de la cara); lo que queda atrás es la tinta del ojo.
uniform sampler2D face_atlas : filter_linear_mipmap, repeat_disable;
uniform int face_cells = 8;
uniform vec3 face_axis = vec3(0.0, 0.19, 0.0);
uniform float face_span = 2.0944;
uniform float face_height = 0.3;
uniform vec4 eye_ink = vec4(0.1647, 0.102, 0.1333, 1.0);
// Sesgo del nivel de detalle del atlas (negativo: más nítido) y texeles por
// píxel entre los que los ojos pasan de pintados a puntos de tinta.
const float CC_FACE_LOD_BIAS = -1.0;
const vec2 CC_FACE_FAR = vec2(2.5, 5.0);
instance uniform int expression = 0;
instance uniform vec2 gaze = vec2(0.0);
// Centro del casquete del pelo (CharacterModel.HAIR_CENTER): alrededor de
// él se mece el pelo.
uniform vec3 hair_pivot = vec3(0.0, 0.24, -0.007);
#endif

// Superficies (UV.x entero).
const int CC_SMOOTH = 0;
const int CC_TILE = 1;
const int CC_WOOD = 2;
const int CC_PAINT = 3;
const int CC_FABRIC = 4;
const int CC_CARDBOARD = 5;
const int CC_METAL = 6;
const int CC_PEI = 7;
// Del personaje: la piel (recibe la cara) y el pelo (contorno café).
const int CC_SKIN = 8;
const int CC_HAIR = 9;

// Baldosa del piso: lado, medio ancho de la junta y bisel (m).
const float CC_TILE_SIZE = 0.4;
const float CC_GROUT_HALF = 0.002;
const float CC_TILE_BEVEL = 0.006;
// Tablas de la madera (m).
const float CC_PLANK = 0.11;
// Paredes a contraluz: reciben al menos este tanto del sol.
const float CC_WALL_WRAP = 0.35;
// El sol en light(): envoltura y medio ancho del terminador del mundo (el
// personaje lo marca más con `toon`). La prueba del piso de noche
// (tests/unit/test_day_cycle.gd) hace la misma cuenta leyendo estos números
// de aquí, junto con `rim` y CC_FILL_SPREAD (world_light.gdshaderinc).
const float CC_SUN_WRAP = 0.35;
const float CC_SUN_TERMINATOR = 0.18;
// Capa caliente: color (se ve tal cual, brilla sola) y grosor mínimo
// (PieceModel.LAYER_STEP).
const vec3 CC_HOT_COLOR = vec3(1.0, 0.5412, 0.2392);
const float CC_HOT_MIN = 0.01;

varying vec3 v_world;
varying vec3 v_local;
varying vec3 v_wnormal;
// Hacia dónde crecen las capas: el "arriba" del objeto (su eje Y en el
// mundo) y la altura del punto a lo largo de ese eje. Para casi todo es el
// arriba del mundo; un carrete acostado muestra así los surcos del bobinado
// (anillos alrededor de su eje) y una pieza torcida, sus capas torcidas.
varying vec3 v_up;
varying float v_layer;
varying vec4 v_color;
varying vec4 v_attr;
// De fragment() a light(): el color del objeto y cuánto sol recibe esta
// superficie a contraluz. El color va por aquí y no por ALBEDO: en la pasada
// del sol con sombra, Compatibility le entrega a light() el ALBEDO ya pasado
// a lineal (medido en la captura 00_calibracion: el gris salía a la mitad).
varying vec3 v_albedo;
varying float v_wall_wrap;
// Lo que puso la pasada base (para sumar el sol sin sombra, nivel Bajo).
varying vec3 v_base;

void vertex() {
#ifdef KIT_TINTED
	v_color = vec4(albedo.rgb, 1.0);
	v_attr = vec4(float(surface) + clamp(gloss, 0.0, 0.99), 0.0, layer, emit);
#else
	v_color = COLOR;
	v_attr = vec4(UV.x, UV.y, UV2.x, UV2.y);
#endif
	if (v_attr.y > 0.0) {
#ifdef KIT_HEAD
		VERTEX += cross(swing * v_attr.y, VERTEX - hair_pivot);
#elif defined(KIT_CHARACTER)
		VERTEX += swing * v_attr.y;
#else
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float phase = cc_anim_time * 1.3 + w.x * 2.1 + w.z * 1.7;
		float k = v_attr.y * 0.03;
		VERTEX.x += sin(phase) * k;
		VERTEX.z += cos(phase * 0.83) * k * 0.7;
#endif
	}
	v_local = VERTEX;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnormal = MODEL_NORMAL_MATRIX * NORMAL;
	v_up = normalize((MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	v_layer = dot(v_world, v_up);
}

// Baldosa: damero suave, variación por baldosa, junta clara y bisel que
// atrapa la luz (inclina la normal hacia afuera de la baldosa). Solo arriba:
// los cantos quedan lisos.
vec3 cc_tile(vec3 base, inout vec3 n, inout float shine) {
	if (n.y < 0.5) {
		return base;
	}
	// La grilla empieza en el rincón del cuarto: baldosas enteras contra las
	// paredes.
	vec2 g = (v_world.xz - cc_room.xy) / CC_TILE_SIZE;
	vec2 id = floor(g);
	vec2 f = fract(g);
	vec2 to_edge = min(f, 1.0 - f) * CC_TILE_SIZE;
	float edge = min(to_edge.x, to_edge.y);
	float fw = max(fwidth(v_world.x), fwidth(v_world.z));
	vec3 c = base * mix(vec3(1.0), vec3(0.974, 0.954, 0.929), mod(id.x + id.y, 2.0));
	c *= 1.0 + (cc_hash(id) - 0.5) * 0.06;
	float mottle = cc_noise(v_world.xz * 6.0) * 0.6 + cc_noise(v_world.xz * 19.0) * 0.4;
	c *= 0.975 + mottle * 0.045;
	float bevel = (1.0 - smoothstep(CC_GROUT_HALF, CC_TILE_BEVEL, edge)) * cc_aa_fade(fw, CC_TILE_BEVEL * 2.0);
	vec2 side = to_edge.x < to_edge.y ? vec2(f.x < 0.5 ? -1.0 : 1.0, 0.0) : vec2(0.0, f.y < 0.5 ? -1.0 : 1.0);
	n = normalize(n + vec3(side.x, 0.0, side.y) * 0.55 * bevel);
	float grout = 1.0 - smoothstep(CC_GROUT_HALF, CC_GROUT_HALF + fw, edge);
	c = mix(c, mix(base, vec3(1.0, 0.973, 0.922), 0.55), grout);
	shine = mix(shine, 0.0, grout);
	return c;
}

// Madera: tablas con ±6 % de variación, veta a lo largo y la unión entre
// tablas apenas marcada.
vec3 cc_wood(vec3 base, vec3 n) {
	vec3 q = v_local;
	vec3 a = abs(n);
	float along = a.x > 0.6 ? q.z : q.x;
	float across = a.y > 0.6 ? q.z : q.y;
	float plank = floor(across / CC_PLANK);
	float grain = cc_noise(vec2(along * 3.0, across * 55.0 + plank * 7.0)) * 0.7
		+ cc_noise(vec2(along * 11.0, across * 160.0)) * 0.3;
	vec3 c = base * (1.0 + (cc_hash(vec2(plank, 3.1)) - 0.5) * 0.12) * (0.93 + grain * 0.12);
	float fw = fwidth(across);
	float seam = 1.0 - smoothstep(0.0, max(fw, 0.0005), min(fract(across / CC_PLANK), 1.0 - fract(across / CC_PLANK)) * CC_PLANK);
	return c * (1.0 - 0.18 * seam * cc_aa_fade(fw, CC_PLANK * 0.25));
}

// Superficies procedurales (biblia §3.3). Pueden cambiar la normal y el
// brillo.
vec3 cc_surface(int kind, vec3 base, inout vec3 n, inout float shine) {
	if (kind == CC_TILE) {
		return cc_tile(base, n, shine);
	}
	if (kind == CC_WOOD) {
		return cc_wood(base, n);
	}
	if (kind == CC_PAINT) {
		vec2 uv = abs(n.x) > 0.5 ? v_world.zy : v_world.xy;
		float m = cc_noise(uv * 2.2) * 0.6 + cc_noise(uv * 9.0) * 0.4;
		return base * (0.9825 + m * 0.035);
	}
	if (kind == CC_FABRIC) {
		vec2 uv = abs(n.y) > 0.5 ? v_world.xz : (abs(n.x) > 0.5 ? v_world.zy : v_world.xy);
		float fw = max(fwidth(uv.x), fwidth(uv.y));
		float weave = sin(uv.x * 420.0) * sin(uv.y * 420.0) * cc_aa_fade(fw, 0.015);
		return base * (0.94 + cc_noise(uv * 7.0) * 0.08 + weave * 0.04);
	}
	if (kind == CC_CARDBOARD) {
		vec3 a = abs(n);
		vec2 uv = a.y > 0.5 ? v_local.xz : (a.x > 0.5 ? v_local.zy : v_local.xy);
		float fw = fwidth(uv.x);
		float flutes = sin(uv.x * 1570.0) * cc_aa_fade(fw, 0.004);
		return base * (0.94 + cc_noise(uv * 14.0) * 0.1 + flutes * 0.03);
	}
	if (kind == CC_METAL) {
		float fw = fwidth(v_local.y);
		return base * (0.97 + sin(v_local.y * 900.0) * cc_aa_fade(fw, 0.007) * 0.03);
	}
	if (kind == CC_PEI) {
		vec2 uv = v_local.xz;
		float fw = max(fwidth(uv.x), fwidth(uv.y));
		float grain = mix(0.5, cc_hash(floor(uv * 900.0)), cc_aa_fade(fw, 0.0011));
		return base * (0.93 + grain * 0.1 + cc_noise(uv * 30.0) * 0.04);
	}
	return base;
}

#ifdef KIT_HEAD
// La cara pintada sobre la piel (ver face_atlas). El atlas se lee siempre,
// fuera de los if: así sus mipmaps no dependen de por dónde pasó cada píxel.
vec3 cc_face(vec3 skin, int kind) {
	vec3 q = v_local - face_axis;
	vec2 uv = vec2(0.5 + atan(q.x, q.z) / face_span, 0.5 - q.y / face_height);
	float cells = float(face_cells);
	vec2 cell = vec2((uv.x + float(clamp(expression, 0, face_cells - 1))) / cells, uv.y);
	// Texeles de la celda por píxel. Lejos la cara mide pocos píxeles: se lee
	// un nivel de detalle más nítida (sesgo) y los ojos pasan a ser puntos de
	// tinta con borde firme, en vez de una mancha gris del promedio de
	// contorno, iris y brillos.
	float texels = max(fwidth(uv.x), fwidth(uv.y)) * float(textureSize(face_atlas, 0).y);
	float lod = max(log2(max(texels, 1.0)) + CC_FACE_LOD_BIAS, 0.0);
	vec4 face = textureLod(face_atlas, cell, lod);
	vec4 moved = textureLod(face_atlas, cell - vec2(gaze.x / cells, -gaze.y), lod);
	bool inside = kind == CC_SKIN && uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0;
	if (!inside) {
		return skin;
	}
	vec3 eye = moved.a > 0.5 ? moved.rgb : eye_ink.rgb;
	float far = smoothstep(CC_FACE_FAR.x, CC_FACE_FAR.y, texels);
	float sparkle = smoothstep(0.5, 0.8, dot(moved.rgb, vec3(0.3, 0.55, 0.15)));
	eye = mix(eye, mix(eye_ink.rgb, moved.rgb, sparkle), far);
	float cover = mix(face.a, smoothstep(0.25, 0.6, face.a), far);
	return mix(face.rgb, eye, cover);
}
#endif

// La luz de la pasada base: la del mundo (ver world_light.gdshaderinc) o, en
// los retratos del personaje, la de estudio.
vec3 cc_base_light(vec3 n, float ao, mat4 view) {
#ifdef KIT_CHARACTER
	if (preview_light > 0.5) {
		vec3 nv = normalize((view * vec4(n, 0.0)).xyz);
		vec3 ambient = mix(studio_ground, studio_sky, clamp(nv.y * 0.5 + 0.5, 0.0, 1.0));
		float key_light = clamp((dot(nv, normalize(CC_STUDIO_KEY_DIR)) + 0.3) / 1.3, 0.0, 1.0);
		float fill_light = clamp((dot(nv, normalize(CC_STUDIO_FILL_DIR)) + 0.3) / 1.3, 0.0, 1.0);
		float back_light = pow(1.0 - clamp(nv.z, 0.0, 1.0), 3.0) * smoothstep(-0.2, 0.4, nv.y);
		return (ambient + studio_key * key_light + studio_fill * fill_light) * cc_ao_color(ao) + studio_rim * back_light;
	}
	return cc_world_light(v_world, n, ao, 1.0);
#else
	return cc_world_light(v_world, n, ao, 0.0);
#endif
}

void fragment() {
	vec3 n = normalize(v_wnormal);
#ifdef KIT_GLASS
	// Las caras de atrás de la tapa (adentro) miran hacia el otro lado.
	n = FRONT_FACING ? n : -n;
#endif
	vec3 base = v_color.rgb;
	int kind = int(floor(v_attr.x + 0.001));
	float shine = fract(v_attr.x + 0.0001);
	float layer_height = v_attr.z;
	float emit_amount = v_attr.w;
	base = cc_surface(kind, base, n, shine);
#ifdef KIT_HEAD
	base = cc_face(base, kind);
#endif

	// Lo impreso muestra sus capas: crestas que atrapan la luz, bandas claras
	// y surcos oscuros en los lados, y el relleno en diagonal arriba. Se
	// apagan cuando una capa mide menos de ~1,3 píxeles (nunca centellean).
	if (layer_height > 0.0) {
		vec3 up = normalize(v_up);
		float y = v_layer;
		float fade = cc_aa_fade(fwidth(y), layer_height);
		float t = fract(y / layer_height);
		float along = dot(n, up);
		float side = 1.0 - smoothstep(0.55, 0.85, abs(along));
		n = normalize(n + up * (sin(t * 6.2831853) * 0.38 * fade * side));
		float amount = clamp(layer_height * 14.0, 0.07, 0.36) * fade * side;
		float groove = smoothstep(0.62, 1.0, abs(t * 2.0 - 1.0));
		base *= 1.0 + amount * (0.55 * sin(t * 6.2831853 + 1.2) - 0.9 * groove);
		// El relleno en diagonal solo en la cara de arriba de lo impreso parado.
		float diag = (v_world.x + v_world.z) / (layer_height * 1.5);
		float top = smoothstep(0.75, 0.95, along) * smoothstep(0.75, 0.95, n.y);
		float infill = smoothstep(0.55, 1.0, abs(fract(diag) * 2.0 - 1.0)) * cc_aa_fade(fwidth(diag), 1.0);
		base *= 1.0 - 0.08 * top * infill;
		shine = max(shine, 0.25);
	}

	vec3 glow = vec3(0.0);
	// Capa caliente: el filamento recién puesto en los lados de la pieza que
	// se imprime, arriba. Mide al menos 2 píxeles (se ve con cualquier zoom) y
	// brilla sola con su color exacto: ni el sol ni el parche la queman.
	float hot = 0.0;
#ifdef HOT_LAYER
	if (hot_top > -50.0) {
		float band = max(CC_HOT_MIN, 2.0 * cc_px_m);
		float depth = hot_top - v_local.y;
		float side = 1.0 - smoothstep(0.5, 0.8, abs(normalize(v_wnormal).y));
		hot = step(-0.0005, depth) * (1.0 - smoothstep(band * 0.7, band, depth)) * side;
	}
#endif
	if (emit_amount != 0.0) {
		float lit = emit_amount > 0.0 ? emit_amount : -emit_amount * cc_night;
		// Un balanceo negativo marca lo que parpadea (los focos de la
		// guirnalda, KitMesh.night_glow con twinkle).
		if (v_attr.y < 0.0) {
			lit *= cc_twinkle(v_world.x);
		}
		glow += base * lit;
	}

	float ao = v_color.a * cc_occlusion(v_world, n);
	v_wall_wrap = kind == CC_PAINT ? CC_WALL_WRAP : 0.0;
	v_albedo = base * (1.0 - hot);
	v_base = clamp(mix(base * cc_base_light(n, ao, VIEW_MATRIX) + glow, CC_HOT_COLOR, hot), 0.0, 1.0);
	ALBEDO = base;
#ifdef KIT_GLASS
	ALPHA = alpha;
#endif
	ROUGHNESS = 1.0 - shine;
	EMISSION = cc_out(v_base);
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
}

// El sol del motor (el único DirectionalLight3D): terminador suave con
// envoltura, sombra recibida, brillo Blinn y luz de borde.
void light() {
	float ndl = dot(NORMAL, LIGHT);
	float wrap = clamp((ndl + CC_SUN_WRAP) / (1.0 + CC_SUN_WRAP), 0.0, 1.0);
	float soft = mix(CC_SUN_TERMINATOR, 0.06, toon);
	float diffuse = max(smoothstep(0.5 - soft, 0.5 + soft, wrap), v_wall_wrap);
	float shade = smoothstep(0.1, 0.9, ATTENUATION);
	float shine = 1.0 - ROUGHNESS;
	vec3 h = normalize(LIGHT + VIEW);
	float spec = pow(max(dot(NORMAL, h), 0.0), mix(8.0, 60.0, shine)) * shine * 0.45 * step(0.0, ndl);
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0) * rim * diffuse;
	vec3 c = (v_albedo * (diffuse + edge) + vec3(spec)) * LIGHT_COLOR / PI * shade;
	SPECULAR_LIGHT += cc_sun_out(c, v_base);
}

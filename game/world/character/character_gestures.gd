class_name CharacterGestures
extends RefCounted
## Los gestos del personaje (biblia de arte §7.7–7.8) como datos: cada uno
## es una lista de poses clave en el tiempo. CharacterAnimator los toca una
## vez, con una mezcla de BLEND segundos al entrar y al salir, y los corta si
## el personaje camina: nunca bloquean nada.
##
## Cada pose clave dice solo lo que mueve, por nombre de canal:
## - los huesos de CharacterModel ("body", "hip_l", "knee_l", "hip_r",
##   "knee_r", "shoulder_l", "elbow_l", "shoulder_r", "elbow_r", "head",
##   "phone"): giro en radianes (x, y, z) sumado a su reposo;
## - "hand_l"/"hand_r": [punto, polo]. Lleva el centro de esa mano al punto
##   (espacio del personaje con el cuerpo en reposo) con el codo hacia el
##   polo (una dirección). Se resuelve una vez, al cargar (solve_arm);
## - "phone_at": el punto que mira la pantalla del celular (los ojos);
## - "move": corrimiento del cuerpo y las caderas (m; los pies se apoyan
##   solos en el piso, esto es lo que se despega);
## - "shape": x estirar (+) o aplastar (−) el cuerpo, y el celular a la vista
##   (0 a 1), z el cuello que se hunde (m, negativo);
## - "eyes": hacia dónde corren las pupilas (x, y; fracción de la cara).
## Lo que un gesto mueve en alguna pose y no dice en otra vuelve a la pose
## suelta (brazos colgando, piernas derechas). Lo que no mueve nunca lo
## deja como está (el animador sigue con su respiración o su caminata).
##
## Los datos se arman una vez en arreglos planos (cuaterniones por hueso y
## vectores por canal); sample() no crea memoria.

enum Gesture {
	NONE, CHEER, HANDS_ON_HEAD, JUMP, PHONE, THUMBS_UP, WAVE, SHRUG, PACK, SCRATCH_HEAD, STRETCH, YAWN, WATCH,
}

## Huesos (los de CharacterModel.Bone) y los tres canales que siguen.
const BONES: int = CharacterModel.Bone.PHONE + 1
const MOVE: int = 0
const SHAPE: int = 1
const EYES: int = 2
const VECTORS: int = 3
## Segundos de mezcla al entrar y al salir de un gesto.
const BLEND: float = 0.12
## La pose suelta de los brazos (sumada al reposo): el hombro un poco hacia
## adelante y el codo apenas doblado, así las manos cuelgan delante del borde
## del buzo.
const ARM_HANG: Vector2 = Vector2(-0.06, -0.2)

## Nombre de cada canal de giro (en el orden de CharacterModel.Bone).
const BONE_NAMES: Array[String] = [
	"body", "hip_l", "knee_l", "hip_r", "knee_r", "shoulder_l", "elbow_l", "shoulder_r", "elbow_r", "head", "phone",
]
const VECTOR_NAMES: Array[String] = ["move", "shape", "eyes"]
## Los huesos cuyo giro se suma a lo que ya hace el animador (el cuerpo y la
## cabeza: se inclinan sobre la respiración y la mirada); los demás se
## reemplazan por los del gesto.
const ADDITIVE: Array[int] = [CharacterModel.Bone.BODY, CharacterModel.Bone.HEAD]

## Los gestos: largo (s), punto alto (s, el que muestran las capturas), la
## cara del gesto entre dos tiempos (opcional) y las poses clave [t, canales].
const DATA: Dictionary = {
	# Puño arriba al cobrar (el codo afuera, el puño al lado de la cabeza):
	# sube, baja "¡sí!" y vuelve a subir.
	Gesture.CHEER: {
		"length": 0.8, "peak": 0.3,
		"keys": [
			[0.0, {}],
			[0.12, {"hand_r": [Vector3(0.3, 0.98, 0.14), Vector3(1.0, -0.6, 0.0)], "body": Vector3(0.05, 0.06, 0.0)}],
			[0.3, {
				"hand_r": [Vector3(0.35, 1.13, 0.06), Vector3(1.0, -0.15, 0.0)],
				"hand_l": [Vector3(-0.21, 0.7, 0.13), Vector3(-1.0, -0.4, -0.5)],
				"body": Vector3(-0.06, 0.1, 0.06), "head": Vector3(-0.1, 0.0, -0.06),
				"move": Vector3(0.0, 0.015, 0.0), "shape": Vector3(0.04, 0.0, 0.0),
			}],
			[0.46, {
				"hand_r": [Vector3(0.34, 1.02, 0.1), Vector3(1.0, -0.3, 0.0)],
				"hand_l": [Vector3(-0.21, 0.72, 0.13), Vector3(-1.0, -0.4, -0.5)],
				"body": Vector3(0.02, 0.07, 0.02), "shape": Vector3(-0.02, 0.0, 0.0),
			}],
			[0.6, {
				"hand_r": [Vector3(0.35, 1.11, 0.07), Vector3(1.0, -0.15, 0.0)],
				"hand_l": [Vector3(-0.21, 0.7, 0.13), Vector3(-1.0, -0.4, -0.5)],
				"body": Vector3(-0.03, 0.07, 0.03), "head": Vector3(-0.06, 0.0, -0.03),
			}],
			[0.8, {}],
		],
	},
	# Se agarra la cabeza cuando falla una pieza (RUTA §6) y la mueve "no, no".
	Gesture.HANDS_ON_HEAD: {
		"length": 1.2, "peak": 0.4,
		"keys": [
			[0.0, {}],
			[0.2, {
				"hand_l": [Vector3(-0.25, 1.09, 0.1), Vector3(-0.8, -0.2, 0.6)],
				"hand_r": [Vector3(0.25, 1.09, 0.1), Vector3(0.8, -0.2, 0.6)],
				"head": Vector3(0.08, 0.0, 0.0), "body": Vector3(0.04, 0.0, 0.0),
			}],
			[0.4, {
				"hand_l": [Vector3(-0.218, 1.15, 0.045), Vector3(-0.8, -0.1, 0.6)],
				"hand_r": [Vector3(0.218, 1.15, 0.045), Vector3(0.8, -0.1, 0.6)],
				"head": Vector3(0.07, 0.0, 0.07), "body": Vector3(0.06, 0.0, 0.0),
				"shape": Vector3(-0.03, 0.0, -0.01),
			}],
			[0.65, {
				"hand_l": [Vector3(-0.218, 1.15, 0.045), Vector3(-0.8, -0.1, 0.6)],
				"hand_r": [Vector3(0.218, 1.15, 0.045), Vector3(0.8, -0.1, 0.6)],
				"head": Vector3(0.07, 0.0, -0.07), "body": Vector3(0.06, 0.0, 0.0),
				"shape": Vector3(-0.03, 0.0, -0.01),
			}],
			[0.9, {
				"hand_l": [Vector3(-0.218, 1.14, 0.045), Vector3(-0.8, -0.1, 0.6)],
				"hand_r": [Vector3(0.218, 1.14, 0.045), Vector3(0.8, -0.1, 0.6)],
				"head": Vector3(0.06, 0.0, 0.05), "body": Vector3(0.05, 0.0, 0.0),
			}],
			[1.2, {}],
		],
	},
	# Salto al subir de nivel: se agacha (aplasta), despega (estira), arriba
	# con los brazos al cielo, cae y amortigua (aplasta).
	Gesture.JUMP: {
		"length": 0.9, "peak": 0.4,
		"keys": [
			[0.0, {}],
			[0.13, {
				"hip_l": Vector3(-0.5, 0.0, 0.0), "hip_r": Vector3(-0.5, 0.0, 0.0),
				"knee_l": Vector3(1.0, 0.0, 0.0), "knee_r": Vector3(1.0, 0.0, 0.0),
				"shoulder_l": Vector3(0.55, 0.0, 0.0), "shoulder_r": Vector3(0.55, 0.0, 0.0),
				"elbow_l": Vector3(-0.35, 0.0, 0.0), "elbow_r": Vector3(-0.35, 0.0, 0.0),
				"body": Vector3(0.22, 0.0, 0.0), "head": Vector3(-0.12, 0.0, 0.0),
				"shape": Vector3(-0.08, 0.0, 0.0),
			}],
			[0.25, {
				"hip_l": Vector3(-0.08, 0.0, 0.0), "hip_r": Vector3(-0.08, 0.0, 0.0),
				"knee_l": Vector3(0.15, 0.0, 0.0), "knee_r": Vector3(0.15, 0.0, 0.0),
				"hand_l": [Vector3(-0.25, 1.22, 0.14), Vector3(-1.0, -0.3, 0.0)],
				"hand_r": [Vector3(0.25, 1.22, 0.14), Vector3(1.0, -0.3, 0.0)],
				"body": Vector3(-0.04, 0.0, 0.0), "head": Vector3(-0.1, 0.0, 0.0),
				"move": Vector3(0.0, 0.07, 0.0), "shape": Vector3(0.1, 0.0, 0.0),
			}],
			[0.4, {
				"hip_l": Vector3(-0.6, 0.0, 0.0), "hip_r": Vector3(-0.55, 0.0, 0.0),
				"knee_l": Vector3(1.1, 0.0, 0.0), "knee_r": Vector3(1.0, 0.0, 0.0),
				"hand_l": [Vector3(-0.31, 1.36, 0.05), Vector3(-1.0, -0.2, 0.0)],
				"hand_r": [Vector3(0.31, 1.36, 0.05), Vector3(1.0, -0.2, 0.0)],
				"body": Vector3(-0.06, 0.0, 0.0), "head": Vector3(-0.16, 0.0, 0.0),
				"move": Vector3(0.0, 0.22, 0.0), "shape": Vector3(0.03, 0.0, 0.0),
			}],
			[0.54, {
				"hip_l": Vector3(-0.2, 0.0, 0.0), "hip_r": Vector3(-0.2, 0.0, 0.0),
				"knee_l": Vector3(0.35, 0.0, 0.0), "knee_r": Vector3(0.35, 0.0, 0.0),
				"hand_l": [Vector3(-0.3, 1.24, 0.1), Vector3(-1.0, -0.3, 0.0)],
				"hand_r": [Vector3(0.3, 1.24, 0.1), Vector3(1.0, -0.3, 0.0)],
				"move": Vector3(0.0, 0.07, 0.0), "shape": Vector3(0.05, 0.0, 0.0),
			}],
			[0.64, {
				"hip_l": Vector3(-0.55, 0.0, 0.0), "hip_r": Vector3(-0.55, 0.0, 0.0),
				"knee_l": Vector3(1.05, 0.0, 0.0), "knee_r": Vector3(1.05, 0.0, 0.0),
				"hand_l": [Vector3(-0.29, 0.94, 0.15), Vector3(-1.0, -0.5, 0.0)],
				"hand_r": [Vector3(0.29, 0.94, 0.15), Vector3(1.0, -0.5, 0.0)],
				"body": Vector3(0.18, 0.0, 0.0), "head": Vector3(0.04, 0.0, 0.0),
				"shape": Vector3(-0.09, 0.0, -0.01),
			}],
			[0.78, {
				"hip_l": Vector3(-0.15, 0.0, 0.0), "hip_r": Vector3(-0.15, 0.0, 0.0),
				"knee_l": Vector3(0.3, 0.0, 0.0), "knee_r": Vector3(0.3, 0.0, 0.0),
				"body": Vector3(0.04, 0.0, 0.0), "shape": Vector3(0.02, 0.0, 0.0),
			}],
			[0.9, {}],
		],
	},
	# Saca el celular y lo lee con las dos manos delante del pecho y la cabeza
	# gacha (de frente no le tapa la cara), con la pantalla hacia sus ojos.
	# Después lo guarda.
	Gesture.PHONE: {
		"length": 1.6, "peak": 0.8,
		"keys": [
			[0.0, {}],
			[0.2, {"hand_r": [Vector3(0.17, 0.8, 0.17), Vector3(1.0, -1.0, -0.2)], "phone_at": Vector3(0.0, 1.12, 0.16), "shape": Vector3(0.0, 1.0, 0.0)}],
			[0.45, {
				"hand_r": [Vector3(0.05, 0.9, 0.25), Vector3(1.0, -1.0, -0.3)], "phone_at": Vector3(0.01, 1.16, 0.17),
				"hand_l": [Vector3(-0.06, 0.88, 0.24), Vector3(-1.0, -1.0, -0.3)],
				"head": Vector3(0.28, 0.04, 0.0), "shape": Vector3(0.0, 1.0, 0.0), "eyes": Vector3(-0.004, -0.03, 0.0),
			}],
			[0.8, {
				"hand_r": [Vector3(0.05, 0.91, 0.25), Vector3(1.0, -1.0, -0.3)], "phone_at": Vector3(0.01, 1.16, 0.17),
				"hand_l": [Vector3(-0.06, 0.89, 0.24), Vector3(-1.0, -1.0, -0.3)],
				"head": Vector3(0.3, 0.05, 0.03), "shape": Vector3(0.0, 1.0, 0.0), "eyes": Vector3(-0.004, -0.03, 0.0),
			}],
			[1.2, {
				"hand_r": [Vector3(0.05, 0.9, 0.25), Vector3(1.0, -1.0, -0.3)], "phone_at": Vector3(0.01, 1.16, 0.17),
				"hand_l": [Vector3(-0.06, 0.88, 0.24), Vector3(-1.0, -1.0, -0.3)],
				"head": Vector3(0.28, 0.02, -0.02), "shape": Vector3(0.0, 1.0, 0.0), "eyes": Vector3(0.006, -0.03, 0.0),
			}],
			[1.4, {"hand_r": [Vector3(0.17, 0.8, 0.17), Vector3(1.0, -1.0, -0.2)], "phone_at": Vector3(0.0, 1.12, 0.16), "shape": Vector3(0.0, 1.0, 0.0)}],
			[1.5, {"shape": Vector3(0.0, 0.0, 0.0)}],
			[1.6, {}],
		],
	},
	# Pulgar arriba: con el antebrazo hacia adelante y el codo hacia abajo, el
	# pulgar del mitón queda hacia arriba; la mano va afuera del cuerpo, lejos
	# de la cabeza (RoomView lo gira hacia la cámara).
	Gesture.THUMBS_UP: {
		"length": 0.8, "peak": 0.32,
		"keys": [
			[0.0, {}],
			[0.16, {"hand_r": [Vector3(0.33, 0.86, 0.19), Vector3(0.3, -1.0, 0.0)], "body": Vector3(0.0, 0.06, 0.0)}],
			[0.32, {
				"hand_r": [Vector3(0.33, 0.93, 0.2), Vector3(0.3, -1.0, 0.0)], "body": Vector3(0.0, 0.08, 0.0),
				"head": Vector3(0.0, 0.0, 0.08), "move": Vector3(0.0, 0.01, 0.0),
			}],
			[0.52, {"hand_r": [Vector3(0.34, 0.88, 0.19), Vector3(0.3, -1.0, 0.0)], "body": Vector3(0.0, 0.06, 0.0), "head": Vector3(0.0, 0.0, 0.05)}],
			[0.8, {}],
		],
	},
	# Saluda con la mano a quien lo tocó.
	Gesture.WAVE: {
		"length": 1.3, "peak": 0.5,
		"keys": [
			[0.0, {}],
			[0.18, {"hand_r": [Vector3(0.3, 1.14, 0.12), Vector3(1.0, -0.7, 0.1)], "head": Vector3(0.0, 0.0, 0.06), "body": Vector3(0.0, -0.05, 0.03)}],
			[0.34, {"hand_r": [Vector3(0.36, 1.12, 0.1), Vector3(1.0, -0.7, 0.1)], "head": Vector3(0.0, 0.0, 0.08), "body": Vector3(0.0, -0.05, 0.03)}],
			[0.5, {"hand_r": [Vector3(0.25, 1.17, 0.12), Vector3(1.0, -0.7, 0.1)], "head": Vector3(0.0, 0.0, 0.08), "body": Vector3(0.0, -0.05, 0.03)}],
			[0.66, {"hand_r": [Vector3(0.36, 1.12, 0.1), Vector3(1.0, -0.7, 0.1)], "head": Vector3(0.0, 0.0, 0.08), "body": Vector3(0.0, -0.05, 0.03)}],
			[0.82, {"hand_r": [Vector3(0.25, 1.17, 0.12), Vector3(1.0, -0.7, 0.1)], "head": Vector3(0.0, 0.0, 0.07), "body": Vector3(0.0, -0.05, 0.03)}],
			[1.0, {"hand_r": [Vector3(0.33, 1.13, 0.11), Vector3(1.0, -0.7, 0.1)], "head": Vector3(0.0, 0.0, 0.05), "body": Vector3(0.0, -0.03, 0.02)}],
			[1.3, {}],
		],
	},
	# Se encoge de hombros (una acción que no se pudo): codos pegados, los
	# antebrazos abiertos hacia los lados, el cuello hundido y la cabeza de
	# lado.
	Gesture.SHRUG: {
		"length": 0.7, "peak": 0.28,
		"keys": [
			[0.0, {}],
			[0.26, {
				"shoulder_l": Vector3(0.05, -0.9, -0.22), "elbow_l": Vector3(-1.45, 0.0, 0.0),
				"shoulder_r": Vector3(0.05, 0.9, 0.22), "elbow_r": Vector3(-1.45, 0.0, 0.0),
				"head": Vector3(-0.04, 0.0, 0.15), "shape": Vector3(-0.02, 0.0, -0.03),
			}],
			[0.46, {
				"shoulder_l": Vector3(0.05, -0.85, -0.2), "elbow_l": Vector3(-1.4, 0.0, 0.0),
				"shoulder_r": Vector3(0.05, 0.85, 0.2), "elbow_r": Vector3(-1.4, 0.0, 0.0),
				"head": Vector3(-0.03, 0.0, 0.13), "shape": Vector3(-0.02, 0.0, -0.026),
			}],
			[0.7, {}],
		],
	},
	# Embala: se inclina y dobla las solapas de una caja con las dos manos.
	Gesture.PACK: {
		"length": 0.6, "peak": 0.24,
		"keys": [
			[0.0, {}],
			[0.12, {
				"hand_l": [Vector3(-0.13, 0.76, 0.25), Vector3(-1.0, -0.6, 0.0)],
				"hand_r": [Vector3(0.13, 0.76, 0.25), Vector3(1.0, -0.6, 0.0)],
				"body": Vector3(0.2, 0.0, 0.0), "head": Vector3(0.14, 0.0, 0.0),
			}],
			[0.24, {
				"hand_l": [Vector3(-0.1, 0.72, 0.27), Vector3(-1.0, -0.6, 0.0)],
				"hand_r": [Vector3(0.1, 0.72, 0.27), Vector3(1.0, -0.6, 0.0)],
				"body": Vector3(0.26, 0.0, 0.0), "head": Vector3(0.16, 0.0, 0.0), "move": Vector3(0.0, -0.01, 0.0),
			}],
			[0.38, {
				"hand_l": [Vector3(-0.14, 0.76, 0.25), Vector3(-1.0, -0.6, 0.0)],
				"hand_r": [Vector3(0.14, 0.76, 0.25), Vector3(1.0, -0.6, 0.0)],
				"body": Vector3(0.18, 0.0, 0.0), "head": Vector3(0.12, 0.0, 0.0),
			}],
			[0.6, {}],
		],
	},
	# Se rasca la cabeza (llegó tarde, o de puro aburrido).
	Gesture.SCRATCH_HEAD: {
		"length": 1.4, "peak": 0.55,
		"keys": [
			[0.0, {}],
			[0.25, {"hand_r": [Vector3(0.215, 1.2, -0.02), Vector3(1.0, -0.2, 0.5)], "head": Vector3(0.06, -0.1, 0.12)}],
			[0.4, {"hand_r": [Vector3(0.215, 1.23, -0.045), Vector3(1.0, -0.2, 0.5)], "head": Vector3(0.06, -0.1, 0.13)}],
			[0.55, {"hand_r": [Vector3(0.215, 1.19, -0.02), Vector3(1.0, -0.2, 0.5)], "head": Vector3(0.06, -0.1, 0.13)}],
			[0.7, {"hand_r": [Vector3(0.215, 1.23, -0.045), Vector3(1.0, -0.2, 0.5)], "head": Vector3(0.06, -0.1, 0.13)}],
			[0.85, {"hand_r": [Vector3(0.215, 1.19, -0.02), Vector3(1.0, -0.2, 0.5)], "head": Vector3(0.06, -0.1, 0.12)}],
			[1.05, {"hand_r": [Vector3(0.215, 1.21, -0.03), Vector3(1.0, -0.2, 0.5)], "head": Vector3(0.05, -0.08, 0.1)}],
			[1.4, {}],
		],
	},
	# Se estira con los brazos al cielo, con los ojos cerrados de gusto.
	Gesture.STRETCH: {
		"length": 2.0, "peak": 0.9, "face": [FacePainter.Face.HAPPY, 0.55, 1.35],
		"keys": [
			[0.0, {}],
			[0.4, {
				"hand_l": [Vector3(-0.22, 1.22, 0.1), Vector3(-1.0, -0.2, 0.0)],
				"hand_r": [Vector3(0.22, 1.22, 0.1), Vector3(1.0, -0.2, 0.0)],
				"body": Vector3(-0.04, 0.0, 0.0), "shape": Vector3(0.02, 0.0, 0.0),
			}],
			[0.9, {
				"hand_l": [Vector3(-0.2, 1.42, -0.02), Vector3(-1.0, 0.0, 0.0)],
				"hand_r": [Vector3(0.2, 1.42, -0.02), Vector3(1.0, 0.0, 0.0)],
				"body": Vector3(-0.12, 0.0, 0.0), "head": Vector3(-0.2, 0.0, 0.0),
				"move": Vector3(0.0, 0.01, 0.0), "shape": Vector3(0.05, 0.0, 0.0),
			}],
			[1.3, {
				"hand_l": [Vector3(-0.22, 1.4, 0.0), Vector3(-1.0, 0.0, 0.0)],
				"hand_r": [Vector3(0.22, 1.4, 0.0), Vector3(1.0, 0.0, 0.0)],
				"body": Vector3(-0.1, 0.0, 0.05), "head": Vector3(-0.16, 0.0, 0.05), "shape": Vector3(0.04, 0.0, 0.0),
			}],
			[1.7, {
				"hand_l": [Vector3(-0.27, 0.9, 0.1), Vector3(-1.0, -0.4, 0.0)],
				"hand_r": [Vector3(0.27, 0.9, 0.1), Vector3(1.0, -0.4, 0.0)],
			}],
			[2.0, {}],
		],
	},
	# Bosteza de noche: la mano tapa la boca, el otro brazo se estira de lado
	# y la cabeza va hacia atrás con los ojos cerrados.
	Gesture.YAWN: {
		"length": 2.2, "peak": 0.9, "face": [FacePainter.Face.BLINK, 0.45, 1.55],
		"keys": [
			[0.0, {}],
			[0.35, {"hand_r": [Vector3(0.08, 1.0, 0.22), Vector3(1.0, -1.0, 0.0)], "head": Vector3(-0.08, 0.0, 0.0)}],
			[0.6, {
				"hand_r": [Vector3(0.03, 1.06, 0.2), Vector3(1.0, -1.0, 0.0)],
				"shoulder_l": Vector3(-0.3, 0.0, -1.0), "elbow_l": Vector3(-0.9, 0.0, 0.0),
				"head": Vector3(-0.2, 0.0, 0.05), "body": Vector3(-0.06, 0.0, 0.0), "shape": Vector3(0.04, 0.0, 0.0),
			}],
			[1.25, {
				"hand_r": [Vector3(0.03, 1.06, 0.2), Vector3(1.0, -1.0, 0.0)],
				"shoulder_l": Vector3(-0.35, 0.0, -1.1), "elbow_l": Vector3(-0.8, 0.0, 0.0),
				"head": Vector3(-0.18, 0.0, 0.08), "body": Vector3(-0.05, 0.0, 0.02), "shape": Vector3(0.03, 0.0, 0.0),
			}],
			[1.65, {"hand_r": [Vector3(0.18, 0.8, 0.14), Vector3(1.0, -1.0, 0.0)], "head": Vector3(-0.04, 0.0, 0.0)}],
			[2.2, {}],
		],
	},
	# Mira cómo trabaja la impresora con las manos en la cintura (el animador
	# le pone la mirada en el cabezal).
	Gesture.WATCH: {
		"length": 2.6, "peak": 1.0,
		"keys": [
			[0.0, {}],
			[0.35, {
				"hand_l": [Vector3(-0.215, 0.56, 0.0), Vector3(-1.0, 0.1, -0.6)],
				"hand_r": [Vector3(0.215, 0.56, 0.0), Vector3(1.0, 0.1, -0.6)],
				"head": Vector3(0.06, 0.0, 0.05),
			}],
			[1.0, {
				"hand_l": [Vector3(-0.215, 0.56, 0.0), Vector3(-1.0, 0.1, -0.6)],
				"hand_r": [Vector3(0.215, 0.56, 0.0), Vector3(1.0, 0.1, -0.6)],
				"head": Vector3(0.08, 0.0, -0.03), "body": Vector3(0.0, 0.0, 0.02),
			}],
			[2.2, {
				"hand_l": [Vector3(-0.215, 0.56, 0.0), Vector3(-1.0, 0.1, -0.6)],
				"hand_r": [Vector3(0.215, 0.56, 0.0), Vector3(1.0, 0.1, -0.6)],
				"head": Vector3(0.07, 0.0, 0.04), "body": Vector3(0.0, 0.0, -0.02),
			}],
			[2.6, {}],
		],
	},
}

## Lo armado de DATA (ver _build): por gesto, su primera pose clave, cuántas
## tiene, largo, punto alto, canales que mueve (bits: huesos, después los
## vectores) y su cara; por pose clave, su tiempo, el giro de cada hueso y
## los vectores.
static var _first: PackedInt32Array
static var _count: PackedInt32Array
static var _length: PackedFloat32Array
static var _peak: PackedFloat32Array
static var _mask: PackedInt32Array
static var _face: PackedInt32Array
static var _face_window: PackedVector2Array
static var _times: PackedFloat32Array
static var _rotations: Array[Quaternion] = []
static var _vectors: PackedVector3Array


static func length_of(gesture: Gesture) -> float:
	_ensure()
	return _length[gesture]


## El momento más expresivo del gesto (segundos desde que empieza).
static func peak_of(gesture: Gesture) -> float:
	_ensure()
	return _peak[gesture]


## Si el gesto mueve ese canal (un hueso, o BONES + MOVE/SHAPE/EYES).
static func drives(gesture: Gesture, channel: int) -> bool:
	_ensure()
	return _mask[gesture] & (1 << channel) != 0


## La cara del gesto a los `t` segundos (FacePainter.Face), o -1.
static func face_at(gesture: Gesture, t: float) -> int:
	_ensure()
	var window: Vector2 = _face_window[gesture]
	return _face[gesture] if t >= window.x and t <= window.y else -1


## La pose del gesto a los `t` segundos: el giro de cada hueso que mueve en
## `rotations` (el del gesto en los que reemplaza; el que se suma en BODY y
## HEAD) y los tres vectores en `vectors`. Devuelve su peso de mezcla (0 a
## 1, BLEND al entrar y al salir). Sin memoria nueva.
static func sample(gesture: Gesture, t: float, rotations: Array[Quaternion], vectors: Array[Vector3]) -> float:
	_ensure()
	var first: int = _first[gesture]
	var count: int = _count[gesture]
	var length: float = _length[gesture]
	var at: float = clampf(t, 0.0, length)
	var k: int = 0
	while k < count - 2 and at >= _times[first + k + 1]:
		k += 1
	var span: float = maxf(_times[first + k + 1] - _times[first + k], 0.0001)
	var u: float = clampf((at - _times[first + k]) / span, 0.0, 1.0)
	var a: int = first + k
	var b: int = a + 1
	var before: int = maxi(a - 1, first)
	var after: int = mini(b + 1, first + count - 1)
	for bone: int in BONES:
		if _mask[gesture] & (1 << bone) == 0:
			continue
		var qa: Quaternion = _rotations[a * BONES + bone]
		rotations[bone] = qa.spherical_cubic_interpolate(_rotations[b * BONES + bone], _rotations[before * BONES + bone], _rotations[after * BONES + bone], u)
	for c: int in VECTORS:
		var va: Vector3 = _vectors[a * VECTORS + c]
		vectors[c] = va.cubic_interpolate(_vectors[b * VECTORS + c], _vectors[before * VECTORS + c], _vectors[after * VECTORS + c], u)
	return smoothstep(0.0, BLEND, at) * smoothstep(0.0, BLEND, length - at)


## Giros del hombro y del codo de ese lado (-1 izquierdo, 1 derecho; cada
## uno respecto de su padre, con el reposo incluido) que llevan el centro de
## la mano a `hand` (espacio del personaje con el cuerpo en reposo) con el
## codo hacia `pole`. Si no alcanza, el brazo queda estirado hacia el punto.
## El codo es una bisagra: se dobla solo hacia adelante.
static func solve_arm(side: float, hand: Vector3, pole: Vector3) -> Array[Quaternion]:
	var shoulder: Transform3D = CharacterModel.local_rest(CharacterModel.Bone.SHOULDER_L if side < 0.0 else CharacterModel.Bone.SHOULDER_R)
	var body: Transform3D = CharacterModel.local_rest(CharacterModel.Bone.BODY)
	var target: Vector3 = body.affine_inverse() * hand - shoulder.origin
	var upper: Vector3 = Vector3(0.0, -CharacterModel.ELBOW_DROP, 0.0)
	var fore: Vector3 = CharacterModel.HAND - upper
	var reach: float = clampf(target.length(), absf(upper.length() - fore.length()) + 0.002, upper.length() + fore.length() - 0.0005)
	# El ángulo del codo (negativo: el antebrazo va hacia adelante, +Z) que
	# deja la mano a esa distancia del hombro.
	var q: float = (upper.length_squared() + fore.length_squared() - reach * reach) / (2.0 * upper.length())
	var offset: float = atan2(fore.z, -fore.y)
	var elbow: float = offset - acos(clampf(-q / fore.length(), -1.0, 1.0))
	var hand_local: Vector3 = upper + Basis(Vector3.RIGHT, elbow) * fore
	# Gira el brazo para que la mano apunte al punto y el codo quede del lado
	# del polo.
	var m1: Vector3 = hand_local.normalized()
	var m2: Vector3 = (upper - m1 * upper.dot(m1)).normalized()
	var n1: Vector3 = target.normalized()
	var toward: Vector3 = pole - n1 * pole.dot(n1)
	if toward.length() < 0.001:
		toward = Vector3(side, 0.0, 0.0) - n1 * side * n1.x
	var n2: Vector3 = toward.normalized()
	var turn: Basis = Basis(n1, n2, n1.cross(n2)) * Basis(m1, m2, m1.cross(m2)).transposed()
	return [turn.get_rotation_quaternion(), Quaternion(Vector3.RIGHT, elbow)]


## Dónde queda el centro de la mano con esos giros de hombro y codo (espacio
## del personaje con el cuerpo en reposo). Para las pruebas y para mirar el
## celular.
static func hand_position(side: float, shoulder_rotation: Quaternion, elbow_rotation: Quaternion) -> Vector3:
	return _elbow_frame(side, shoulder_rotation, elbow_rotation) * (CharacterModel.HAND - Vector3(0.0, -CharacterModel.ELBOW_DROP, 0.0))


static func _elbow_frame(side: float, shoulder_rotation: Quaternion, elbow_rotation: Quaternion) -> Transform3D:
	var shoulder: Transform3D = CharacterModel.local_rest(CharacterModel.Bone.SHOULDER_L if side < 0.0 else CharacterModel.Bone.SHOULDER_R)
	var body: Transform3D = CharacterModel.local_rest(CharacterModel.Bone.BODY)
	return body * Transform3D(Basis(shoulder_rotation), shoulder.origin) * Transform3D(Basis(elbow_rotation), Vector3(0.0, -CharacterModel.ELBOW_DROP, 0.0))


static func _ensure() -> void:
	if _first.is_empty():
		_build()


static func _build() -> void:
	var rest: Array[Quaternion] = []
	var rest_euler: PackedVector3Array = PackedVector3Array()
	for bone: int in BONES:
		var euler: Vector3 = CharacterModel.local_rest(bone as CharacterModel.Bone).basis.get_euler()
		rest_euler.append(euler)
		rest.append(Quaternion.from_euler(euler))
	_first.resize(Gesture.size())
	_count.resize(Gesture.size())
	_length.resize(Gesture.size())
	_peak.resize(Gesture.size())
	_mask.resize(Gesture.size())
	_face.resize(Gesture.size())
	_face_window.resize(Gesture.size())
	_face.fill(-1)
	# NONE: una pose vacía.
	_add_key(0.0, {}, rest, rest_euler)
	_add_key(1.0, {}, rest, rest_euler)
	_count[Gesture.NONE] = 2
	_length[Gesture.NONE] = 1.0
	for gesture: int in range(1, Gesture.size()):
		var data: Dictionary = DATA[gesture]
		_first[gesture] = _times.size()
		_length[gesture] = data["length"]
		_peak[gesture] = data["peak"]
		var mask: int = 0
		for key: Array in data["keys"]:
			mask |= _key_mask(key[1])
			_add_key(key[0], key[1], rest, rest_euler)
		_count[gesture] = (data["keys"] as Array).size()
		_mask[gesture] = mask
		if data.has("face"):
			_face[gesture] = data["face"][0]
			_face_window[gesture] = Vector2(data["face"][1], data["face"][2])
		_keep_hemisphere(gesture)


## Los canales que dice una pose clave (bits).
static func _key_mask(channels: Dictionary) -> int:
	var mask: int = 0
	for channel: String in channels:
		match channel:
			"hand_l":
				mask |= (1 << CharacterModel.Bone.SHOULDER_L) | (1 << CharacterModel.Bone.ELBOW_L)
			"hand_r":
				mask |= (1 << CharacterModel.Bone.SHOULDER_R) | (1 << CharacterModel.Bone.ELBOW_R)
			"phone_at":
				mask |= 1 << CharacterModel.Bone.PHONE
			_:
				if channel in BONE_NAMES:
					mask |= 1 << BONE_NAMES.find(channel)
				elif channel in VECTOR_NAMES:
					mask |= 1 << (BONES + VECTOR_NAMES.find(channel))
	return mask


## Agrega una pose clave: lo que no dice queda en la pose suelta.
static func _add_key(t: float, channels: Dictionary, rest: Array[Quaternion], rest_euler: PackedVector3Array) -> void:
	_times.append(t)
	var pose: Array[Quaternion] = []
	for bone: int in BONES:
		var loose: Vector3 = Vector3.ZERO
		match bone:
			CharacterModel.Bone.SHOULDER_L, CharacterModel.Bone.SHOULDER_R:
				loose.x = ARM_HANG.x
			CharacterModel.Bone.ELBOW_L, CharacterModel.Bone.ELBOW_R:
				loose.x = ARM_HANG.y
		var euler: Vector3 = channels.get(BONE_NAMES[bone], loose)
		if bone in ADDITIVE:
			pose.append(Quaternion.from_euler(euler))
		else:
			pose.append(Quaternion.from_euler(rest_euler[bone] + euler) if euler != Vector3.ZERO else rest[bone])
	for side_name: String in ["hand_l", "hand_r"]:
		if channels.has(side_name):
			var side: float = -1.0 if side_name == "hand_l" else 1.0
			var arm: Array[Quaternion] = solve_arm(side, channels[side_name][0], channels[side_name][1])
			var shoulder: int = CharacterModel.Bone.SHOULDER_L if side < 0.0 else CharacterModel.Bone.SHOULDER_R
			pose[shoulder] = arm[0]
			pose[shoulder + 1] = arm[1]
	if channels.has("phone_at"):
		pose[CharacterModel.Bone.PHONE] = _phone_facing(pose[CharacterModel.Bone.SHOULDER_R], pose[CharacterModel.Bone.ELBOW_R], channels["phone_at"])
	_rotations.append_array(pose)
	for vector_name: String in VECTOR_NAMES:
		_vectors.append(channels.get(vector_name, Vector3.ZERO))


## Giro del celular (respecto del codo derecho) que deja la pantalla mirando
## a `eyes`, con su parte de arriba hacia donde apunta el antebrazo.
static func _phone_facing(shoulder: Quaternion, elbow: Quaternion, eyes: Vector3) -> Quaternion:
	var frame: Transform3D = _elbow_frame(1.0, shoulder, elbow)
	var at: Vector3 = frame * CharacterModel.PHONE_GRIP
	var screen: Vector3 = (eyes - at).normalized()
	var along: Vector3 = (hand_position(1.0, shoulder, elbow) - frame.origin).normalized()
	var up: Vector3 = (along - screen * along.dot(screen)).normalized()
	var wanted: Basis = Basis(up.cross(screen), up, screen)
	return (frame.basis.inverse() * wanted).get_rotation_quaternion()


## Las poses clave seguidas de un gesto en el mismo hemisferio (q y −q son el
## mismo giro): así la interpolación va por el camino corto.
static func _keep_hemisphere(gesture: int) -> void:
	for k: int in range(_first[gesture] + 1, _first[gesture] + _count[gesture]):
		for bone: int in BONES:
			var previous: Quaternion = _rotations[(k - 1) * BONES + bone]
			var current: Quaternion = _rotations[k * BONES + bone]
			if previous.dot(current) < 0.0:
				_rotations[k * BONES + bone] = -current

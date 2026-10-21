class_name HintFlow
extends RefCounted
## Orden de las pistas para jugadores nuevos:
## 1. "Arrastra el dedo para caminar", hasta caminar un poco con el joystick o
##    tocando el piso.
## 2. "Toca un objeto para verlo", hasta abrir el primer panel. Si ya se abrió
##    uno antes, esta pista no aparece.
## Lo que ya se aprendió se recuerda en UserSettings, aparte de la partida.

const MOVE: String = "move"
const TAP: String = "tap"
## Metros caminados con el joystick para dar por aprendida la primera pista.
const WALK_DISTANCE: float = 1.0

var _settings: UserSettings
var _walked: float = 0.0


func _init(settings: UserSettings) -> void:
	_settings = settings


func mode() -> MoveHint.Mode:
	if not _settings.has_seen(MOVE):
		return MoveHint.Mode.MOVE
	if not _settings.has_seen(TAP):
		return MoveHint.Mode.TAP
	return MoveHint.Mode.NONE


## Suma metros caminados con el joystick o el teclado (no al caminar solo).
func add_walk(meters: float) -> void:
	if _settings.has_seen(MOVE):
		return
	_walked += meters
	if _walked >= WALK_DISTANCE:
		_settings.mark_seen(MOVE)


## Empezó a caminar solo hacia un punto del piso que se tocó.
func walked_by_tap() -> void:
	_settings.mark_seen(MOVE)


func sheet_opened() -> void:
	_settings.mark_seen(TAP)

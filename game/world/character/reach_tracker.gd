class_name ReachTracker
extends RefCounted
## Elige qué objeto resaltar cuando el personaje está cerca.
##
## - Cuenta la distancia del centro del personaje al borde del objeto en el piso.
## - Una impresora gana sobre la mesa donde está (prioridad).
## - Para que el resalte no salte entre vecinos, el objeto actual se mantiene
##   hasta alejarse más de reach_exit, o hasta que otro esté claramente más cerca.

## Metros de ventaja que da cada punto de prioridad.
const PRIORITY_WEIGHT: float = 0.15

var tuning: ControlsTuning
var current: WorldInteractable = null


func _init(p_tuning: ControlsTuning = null) -> void:
	tuning = p_tuning if p_tuning != null else ControlsTuning.current


## Actualiza con la posición del personaje (x, z) y devuelve el objeto
## resaltado, o null.
func update(point: Vector2, items: Array[WorldInteractable]) -> WorldInteractable:
	var best: WorldInteractable = null
	var best_score: float = INF
	for item: WorldInteractable in items:
		if not item.reachable:
			continue
		var distance: float = WalkGrid.distance_to_rect(point, item.footprint())
		if distance > tuning.reach_enter:
			continue
		var score: float = _score(item, distance)
		if score < best_score:
			best_score = score
			best = item
	if current != null and current in items:
		var current_distance: float = WalkGrid.distance_to_rect(point, current.footprint())
		if current_distance <= tuning.reach_exit:
			if best != null and best != current:
				# La histéresis evita saltos entre vecinos parecidos, pero no debe
				# impedir que una impresora le gane a la mesa donde está.
				var margin: float = tuning.reach_switch_margin if best.priority() <= current.priority() else 0.0
				if best_score < _score(current, current_distance) - margin:
					current = best
			return current
	current = best
	return current


func _score(item: WorldInteractable, distance: float) -> float:
	return distance - item.priority() * PRIORITY_WEIGHT

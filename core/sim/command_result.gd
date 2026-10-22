class_name CommandResult
extends RefCounted
## Resultado de un comando del jugador: si se pudo, o por qué no.
##
## Los argumentos del motivo son: un int tal cual; un String, que es una clave
## de texto (se traduce); o un Dictionary con una sola cantidad:
## {"seconds": segundos de juego}, {"grams": gramos} o {"cents": centavos}.
## La interfaz los formatea (UiFormat.reason).

var ok: bool = true
## Clave de texto del motivo del error.
var reason: String = ""
var args: Array = []
## Lo cobrado (despachar y los comandos que agrupan).
var cents: int = 0
var xp: int = 0
## Cuántos pedidos se procesaron (embalar todo, despachar todo).
var count: int = 0
## uid afectado (al aceptar, el uid del pedido).
var uid: int = -1


static func success() -> CommandResult:
	return CommandResult.new()


static func fail(reason_key: String, reason_args: Array = []) -> CommandResult:
	var result: CommandResult = CommandResult.new()
	result.ok = false
	result.reason = reason_key
	result.args = reason_args
	return result


static func seconds_arg(game_seconds: int) -> Dictionary:
	return {"seconds": game_seconds}


static func grams_arg(grams: int) -> Dictionary:
	return {"grams": grams}


static func cents_arg(cents: int) -> Dictionary:
	return {"cents": cents}

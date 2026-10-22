extends Node
## Bus de señales global (autoload "Events").
##
## La simulación avisa aquí de sus cambios y la interfaz se conecta a estas
## señales para actualizarse solo cuando algo cambia, en lugar de revisar el
## estado en cada cuadro. Game las emite al terminar cada comando y cada
## avance del tiempo (Game._flush_changes), en un orden fijo.
##
## Este archivo solo debe contener declaraciones de señales, sin lógica.

## El reloj del juego avanzó al menos un minuto de juego.
@warning_ignore("unused_signal")
signal time_changed(game_minutes: float)

## Pasó un segundo real de juego (game_seconds / R cambió): cuentas
## regresivas, crecimiento de la pieza y burbujas de estado.
@warning_ignore("unused_signal")
signal clock_ticked(game_seconds: int)

## Cambió la lista de mensajes sin responder.
@warning_ignore("unused_signal")
signal offers_changed

## Llegó un mensaje nuevo.
@warning_ignore("unused_signal")
signal offer_arrived(offer_uid: int)

## Un pedido aceptado cambió de etapa o de datos.
@warning_ignore("unused_signal")
signal order_changed(order_uid: int)

## Un pedido ya no está: se despachó o se canceló.
@warning_ignore("unused_signal")
signal order_removed(order_uid: int)

## Se despachó un pedido: lo que se cobró, la experiencia y si llegó atrasado.
@warning_ignore("unused_signal")
signal order_delivered(order_uid: int, order_id: String, cents: int, xp: int, late: bool)

## Una impresora cambió (empezó, terminó o falló una pieza, se liberó...).
@warning_ignore("unused_signal")
signal printer_changed(printer_uid: int)

## Falló una pieza en esa impresora.
@warning_ignore("unused_signal")
signal print_failed(printer_uid: int, failure_type: String)

## El computador empezó o terminó de modelar.
@warning_ignore("unused_signal")
signal computer_changed

## Cambiaron los gramos de algún carrete.
@warning_ignore("unused_signal")
signal spools_changed

@warning_ignore("unused_signal")
signal money_changed(money_cents: int)

@warning_ignore("unused_signal")
signal xp_changed(xp: int)

## Se subió de nivel.
@warning_ignore("unused_signal")
signal level_up(level: int)

## Hay una partida nueva o recién cargada (después de Game.reset_game).
@warning_ignore("unused_signal")
signal game_loaded

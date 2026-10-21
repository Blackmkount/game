extends Node
## Bus de señales global (autoload "Events").
##
## La simulación avisa aquí de sus cambios y la interfaz se conecta a estas
## señales para actualizarse solo cuando algo cambia, en lugar de revisar el
## estado en cada cuadro.
##
## Este archivo solo debe contener declaraciones de señales, sin lógica.

## El reloj del juego avanzó al menos un minuto de juego.
@warning_ignore("unused_signal")
signal time_changed(game_minutes: float)

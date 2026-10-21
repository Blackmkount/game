extends Node
## Punto de entrada de la presentación hacia la simulación (autoload "Game").
##
## Responsabilidades a partir de la Fase 1:
## - Ser dueño del GameState de core/sim y avanzarlo con el tiempo real
##   llamando a advance(seconds).
## - Exponer los comandos del jugador (accept_order, start_print,
##   buy_printer...). Cada comando valida la acción y devuelve un resultado
##   con éxito o con el motivo del error. La interfaz nunca modifica el estado
##   directamente: siempre pasa por aquí.
## - Avisar de los cambios a través de las señales del autoload Events.

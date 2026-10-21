extends Node
## Guardado y carga de la partida (autoload "SaveManager").
##
## Responsabilidades a partir de la Fase 2:
## - Guardar el estado en user://save.json, con un campo "version" y
##   migraciones para partidas de versiones anteriores.
## - Escribir primero en un archivo temporal y luego renombrarlo, para no
##   corromper la partida si la app se cierra a mitad de guardado.
## - Guardar después de cada comando, de forma periódica y cuando la app pasa
##   a segundo plano o se cierra.
## - Registrar la hora Unix del guardado para calcular el progreso fuera del
##   juego. Si la hora del sistema retrocede, no se otorga progreso.

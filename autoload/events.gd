extends Node
## Bus de señales global (autoload "Events").
##
## Aquí se declararán las señales con las que la simulación avisa de cambios
## a la presentación: dinero actualizado, pedido nuevo, impresión terminada o
## fallida, subida de nivel de reputación, etc.
##
## La interfaz se conecta a estas señales para actualizarse solo cuando algo
## cambia, en lugar de revisar el estado en cada cuadro.
##
## Este archivo solo debe contener declaraciones de señales, sin lógica.
## Las señales se agregan a partir de la Fase 1.

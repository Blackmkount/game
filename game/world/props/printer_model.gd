class_name PrinterModel
extends RefCounted
## Modelo 3D de cada impresora (GDD §8, biblia de arte §9). Las siete
## familias se distinguen por la silueta antes que por el color. El frente
## mira hacia +Z y la base queda en y = 0.
##
## Cada familia vive en su archivo (game/world/props/printers/): CuboUnoModel
## (la clásica), RayoModel (Rayo Mini, Rayo X1 y Prisma MC, de voladizo),
## EnclosedPrinterModel (Bóveda P1 y Titán Pro, cerradas) y
## ResinPrinterModel (Gota R1). Lo que comparten, en PrinterParts.
##
## Todas tienen "Body" (una malla del kit), "Display" (la pantallita) y los
## marcadores "PieceAnchor", "TrayAnchor" y "BedLight"; el resto depende del
## modo, que PrinterView reconoce por sus partes:
## - abiertas ("Bed"): "Gantry", "PrintHead/Carriage", "Spool/Filament",
##   "HeadRest" y "HeadPark";
## - cerradas ("Platform"): "Interior", "PrintHead/Carriage", "PlatformLow",
##   "HeadRest" y "HeadPark";
## - de resina ("Plate"): "Resin", "Lid", "PlateTop" y "VatFloor".

## Alto máximo de toda impresora, con su carrete (biblia §9.1: cabe en la
## estantería).
const MAX_HEIGHT: float = 0.72


## `detail`: PrinterParts.FLOOR_DETAIL para la impresora del piso,
## PrinterParts.FURNITURE_DETAIL para las de los muebles (menos triángulos y
## solo "Body" da sombra).
static func build(parent: Node3D, node_name: String, printer_id: String, spool_color: String = "f2efe6", detail: float = PrinterParts.FLOOR_DETAIL) -> Node3D:
	var printer: Node3D = PropBuilder.group(parent, node_name)
	match printer_id:
		"rayo_mini":
			RayoModel.build(printer, RayoModel.Kind.MINI, spool_color, detail)
		"rayo_x1":
			RayoModel.build(printer, RayoModel.Kind.X1, spool_color, detail)
		"prisma_mc":
			RayoModel.build(printer, RayoModel.Kind.PRISMA, spool_color, detail)
		"boveda_p1":
			EnclosedPrinterModel.build(printer, EnclosedPrinterModel.Kind.VAULT, spool_color, detail)
		"titan_pro":
			EnclosedPrinterModel.build(printer, EnclosedPrinterModel.Kind.TITAN, spool_color, detail)
		"gota_r1":
			ResinPrinterModel.build(printer, spool_color, detail)
		_:
			CuboUnoModel.build(printer, spool_color, detail)
	return printer


## Escala del modelo: la Rayo Mini es más chica. PrinterView la usa para el
## vaivén y el espacio del cabezal, la bandeja y el espagueti.
static func frame_scale(printer_id: String) -> float:
	return RayoModel.MINI_SCALE if printer_id == "rayo_mini" else 1.0


## Color de la luz de adentro de una impresora cerrada mientras imprime ("" si
## no es cerrada).
static func interior_hex(printer_id: String) -> String:
	match printer_id:
		"boveda_p1":
			return EnclosedPrinterModel.INSIDE[EnclosedPrinterModel.Kind.VAULT]
		"titan_pro":
			return EnclosedPrinterModel.INSIDE[EnclosedPrinterModel.Kind.TITAN]
	return ""

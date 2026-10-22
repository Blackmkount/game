class_name Previews
extends RefCounted
## Vistas pequeñas para tarjetas: modelos 3D de impresoras y muebles, y
## carretes del color del material.

const SIZE: float = 92.0


static func printer(printer_id: String) -> Control:
	return _tile(ModelPreview.new(func(world: Node3D) -> void: PrinterModel.build(world, "Model", printer_id), SIZE))


static func furniture(furniture_id: String) -> Control:
	return _tile(ModelPreview.new(func(world: Node3D) -> void: FurnitureModel.build(world, "Model", furniture_id), SIZE))


static func spool(color: Color) -> Control:
	return UiKit.icon_tile("spool", SIZE, color)


static func icon(icon_name: String, color: Color = UiPalette.ACCENT) -> Control:
	return UiKit.icon_tile(icon_name, SIZE, color)


static func _tile(preview: Control) -> Control:
	var tile: PanelContainer = UiKit.panel("IconTile")
	tile.custom_minimum_size = Vector2(SIZE, SIZE)
	tile.add_child(preview)
	return tile

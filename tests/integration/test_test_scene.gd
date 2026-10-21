extends GutTest
## Revisa que la escena de prueba de la Fase 0 cargue y que el botón cambie
## el color de la impresora.

const SCENE: PackedScene = preload("res://game/scenes/test_scene.tscn")


func test_button_changes_printer_color() -> void:
	var scene: Node3D = SCENE.instantiate() as Node3D
	add_child_autofree(scene)
	var material: StandardMaterial3D = scene.get("printer_body_material")
	var button: Button = scene.get_node("%ChangeColorButton")
	var color_before: Color = material.albedo_color

	button.pressed.emit()

	assert_ne(material.albedo_color, color_before)


func test_texts_use_translation_keys() -> void:
	var scene: Node3D = SCENE.instantiate() as Node3D
	add_child_autofree(scene)
	var button: Button = scene.get_node("%ChangeColorButton")

	assert_eq(button.text, tr("TEST_CHANGE_COLOR"))
	assert_ne(button.text, "TEST_CHANGE_COLOR", "La clave no tiene traducción")

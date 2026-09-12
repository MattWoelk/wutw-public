@tool
class_name ArtListingEntry
extends TextureRect

signal clicked

@export var art_piece: ArtPiece:
	set(value):
		art_piece = value

var _tween: Tween

func _ready() -> void:
	_update()

func _update() -> void:
	(%Label_Missing as Label).visible = false
	if art_piece:
		texture = await art_piece.get_original_image()
	else:
		texture = null
	(%Label_Missing as Label).visible = texture == null

func _on_mouse_entered() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, 'z_index', 1, 0.01)
	_tween.tween_property(self, 'scale', Vector2(1.05, 1.05), 0.2)
	_tween.play()

func _on_mouse_exited() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, 'scale', Vector2.ONE, 0.2)
	_tween.tween_property(self, 'z_index', 0, 0.01)
	_tween.play()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			clicked.emit()

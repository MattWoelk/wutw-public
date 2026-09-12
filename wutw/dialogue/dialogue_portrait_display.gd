@tool
class_name DialoguePortraitDisplay
extends TextureRect

const HIGHLIGHT_DURATION := 0.3

@export var character: Character:
	set(value):
		character = value
		if is_node_ready():
			_update()
@export var mirrored: bool = false:
	set(value):
		mirrored = value
		if is_node_ready():
			_update()
@export var highlighted: bool = false:
	set(value):
		highlighted = value
		if is_node_ready():
			if _highlight_tween:
				_highlight_tween.kill()
			_highlight_tween = create_tween()
			_highlight_tween.tween_property(%Highlight, 'modulate:a', 0.5 if highlighted else 0.2, HIGHLIGHT_DURATION)
			_highlight_tween.parallel().tween_property(%Container.get_child(1), 'modulate:a', 1.0 if highlighted else 0.6, HIGHLIGHT_DURATION)
			_highlight_tween.play()

var _highlight_tween: Tween

func _ready() -> void:
	_update()

func _update() -> void:
	if %Container.get_child_count() > 1:
		Utils.clear_node(%Container, 1)
	if character:
		var portrait := character.dialogue_scene.instantiate() as Control
		%Container.add_child(portrait)
		portrait.scale.x = -1 if mirrored else 1

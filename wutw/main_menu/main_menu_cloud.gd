class_name MainMenuCloud
extends Sprite2D

@export var speed: float = -13.0
@export var speed_randomization: float = 0.8

func _ready() -> void:
	speed *= randf_range(1.0 - speed_randomization, 1.0 + speed_randomization)

func _process(delta: float) -> void:
	# Move and wrap around the sides of the screen.
	if not Utils.is_in_editor():
		var parent_width: float = 1920
		position.x += delta * speed
		var half_width := texture.get_width() * scale.x / 2
		if position.x > parent_width + half_width:
			position.x = -half_width

@tool
extends Node2D

@export var random_seed: int = 123

@export_tool_button('Set Random Seed')
@warning_ignore('unused_private_class_variable')
var _set_random_seed_tool := _set_random_seed

func _ready() -> void:
	_set_random_seed()
	if not Utils.is_in_editor():
		(%AnimationPlayer as AnimationPlayer).play('pan')
		await (%AnimationPlayer as AnimationPlayer).animation_finished
		if OS.has_feature('movie'):
			get_tree().quit()

func _set_random_seed() -> void:
	seed(random_seed)

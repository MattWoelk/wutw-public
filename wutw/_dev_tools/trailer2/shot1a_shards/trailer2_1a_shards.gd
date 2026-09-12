extends Node2D

func _ready() -> void:
	(%AnimationPlayer as AnimationPlayer).play('explode')
	await (%AnimationPlayer as AnimationPlayer).animation_finished
	await get_tree().create_timer(2).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

extends Node2D

func _ready() -> void:
	(%AnimationPlayer as AnimationPlayer).play('idle')
	await get_tree().create_timer(5).timeout
	if OS.has_feature('movie'):
		get_tree().quit()

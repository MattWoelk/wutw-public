extends Node2D

func _ready() -> void:
	var start_spot := (%MapEditor as MapEditor).generated_map.starting_point
	(%MapEditor as MapEditor).instant_focus_location(start_spot + Vector2i(-0, 40), 1.5)
	await (%MapEditor as MapEditor).cloud_generation_finished
	await get_tree().create_timer(1.0).timeout
	(%MapEditor as MapEditor).focus_location(start_spot, 3.0, 7.0)
	await get_tree().create_timer(6.0).timeout
	if OS.has_feature('movie'):
		get_tree().quit()

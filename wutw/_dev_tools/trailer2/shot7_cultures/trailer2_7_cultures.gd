extends Node2D

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GameSettings.Interface.tooltip_speed.set_value(.001)
	GlobalSaveGame.load_game(199)
	GlobalSaveGame.read_only = true
	await get_tree().create_timer(0.5).timeout

	ShardExplorer.open_link('shard_type:mq_teo_abode')
	var shard_explorer := ShardExplorer._active_instance
	var shard_details := shard_explorer.get_node('%ShardDetails') as ShardDetails
	var history_block := shard_details.get_node('%VBox_Histories').get_child(1) as ShardHistoryBlock

	await get_tree().create_timer(2).timeout

	history_block._on_reveal_button_pressed()
	history_block._reveal_tween.set_speed_scale(2)

	await get_tree().create_timer(8).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

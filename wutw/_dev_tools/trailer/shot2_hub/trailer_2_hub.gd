extends Node2D

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GameSettings.Interface.tooltip_speed.set_value(.001)
	GlobalSaveGame.init_new_game(13)
	for event: Event in Event.get_all_events().values():
		event.mark_all_choices_seen()

	(%HubContent.get_node('%Shrine').get_node('%Shrine').get_node('%NewSkillsLabel') as Control).modulate.a = 0
	var available_images := MuseumExhibit.get_available_images()
	available_images.shuffle()
	for exhibit: MuseumExhibit in %HubContent.get_node('%HubMuseum').get_node('%Exhibits').get_children():
		exhibit.image = available_images.pop_back()

	(%MonkCharacterBack as Node2D).position = Vector2(583, 249)
	(%MonkCharacterBack.get_node('%AnimationPlayer') as AnimationPlayer).play('idle')

	(%AnimationPlayer as AnimationPlayer).play('pan')

	await get_tree().create_timer(8).timeout

	(%MonkCharacterBack as Node2D).position = Vector2(583, 249)
	(%MonkCharacterBack.get_node('%AnimationPlayer') as AnimationPlayer).play('walk', 0.5)
	await get_tree().create_timer(4).timeout
	if OS.has_feature('movie'):
		get_tree().quit()

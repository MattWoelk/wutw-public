extends Node2D

func _enter_tree() -> void:
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P510_FINISHED_OUTRO_CUTSCENE)

func _ready() -> void:
	for event: Event in Event.get_all_events().values():
		event.mark_all_choices_seen()
	(%HubContent.get_node('%Shrine').get_node('%Shrine').get_node('%NewSkillsLabel') as Control).modulate.a = 0
	var available_images := MuseumExhibit.get_available_images()
	available_images.shuffle()
	for exhibit: MuseumExhibit in %HubContent.get_node('%HubMuseum').get_node('%Exhibits').get_children():
		exhibit.image = available_images.pop_back()

	await get_tree().create_timer(2).timeout

	Utils.take_screenshot(self, 'C:/users/max99/wutw/screenshots/hub.png')

	await get_tree().process_frame
	get_tree().quit()

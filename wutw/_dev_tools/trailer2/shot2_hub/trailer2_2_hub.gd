extends Node2D

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GameSettings.Interface.tooltip_speed.set_value(.001)
	GlobalSaveGame.init_new_game(13)
	for event: Event in Event.get_all_events().values():
		event.mark_all_choices_seen()

	var hc := %Hub.get_node('%HubContent') as HubContents
	(hc.get_node('%Shrine').get_node('%Shrine').get_node('%NewSkillsLabel') as Control).modulate.a = 0
	(hc.get_node('%Shrine').get_node('%Shrine').get_node('%NewSkillsLabel') as Control).modulate.a = 0
	var available_images := MuseumExhibit.get_available_images()
	available_images.shuffle()
	for exhibit: MuseumExhibit in hc.get_node('%HubMuseum').get_node('%Exhibits').get_children():
		exhibit.image = available_images.pop_back()

	await get_tree().create_timer(3).timeout

	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P110_COMPLETED_TUTORIAL)
	GlobalSaveGame.unlock_skill(Skill.get_skill_by_id('craft_1_common'))
	GlobalConsoleCommands._cmd_respawn()
	GlobalAudioSystem.play(AK.EVENTS.SFX_TRANSITION_HUB)

	await get_tree().create_timer(3).timeout

	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P120_ESTABLISHED_CAPITAL)
	GlobalConsoleCommands._cmd_respawn()
	GlobalAudioSystem.play(AK.EVENTS.SFX_TRANSITION_HUB)

	await get_tree().create_timer(3).timeout

	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P200_STARTED_MAGIC)
	GlobalConsoleCommands._cmd_respawn()
	GlobalAudioSystem.play(AK.EVENTS.SFX_TRANSITION_HUB)

	await get_tree().create_timer(3).timeout

	for companion in Companion.get_all_companions():
		GlobalSaveGame.unlock_companion(companion)
	for facility in Utils.get_all_hub_facilities_within(%Hub):
		if facility is HubCompanion:
			(facility as HubCompanion)._ready()
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P500_STARTED)
	GlobalConsoleCommands._cmd_respawn()
	GlobalAudioSystem.play(AK.EVENTS.SFX_TRANSITION_HUB)

	await get_tree().create_timer(3).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

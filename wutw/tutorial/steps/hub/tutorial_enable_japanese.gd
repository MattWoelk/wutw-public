class_name Tutorial_EnableJapanese
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	GlobalSaveGame.changed.connect(_on_savegame_changed)
	_on_savegame_changed()

func stop_listening() -> void:
	GlobalSaveGame.changed.disconnect(_on_savegame_changed)

func get_tutorial_order() -> int:
	return 800

func _on_savegame_changed() -> void:
	if GlobalSaveGame.get_quest_instance(load('res://quests/main/phase1/1_20_capital/quest_main_1_20_capital.tres') as Quest):
		ready_to_trigger.emit()
	elif GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P120_ESTABLISHED_CAPITAL:
		# For old saves.
		ready_to_trigger.emit()

func trigger() -> void:
	var hub := Utils.get_active_hub()
	await hub.get_tree().create_timer(1.0).timeout  # HACK: Wait for quest UI.

	if not GameSettings.Japanese.practice_enabled.value() or not GameSettings.Japanese.kanji_drawing_enabled.value():
		var text := tr('This game has minigames for practicing Japanese.')
		text += tr(' They are completely optional and assume basic familiarity with the language.')
		text += '\n\n'
		text += tr('Would you like to enable learning minigames now?')
		text += '\n\n'
		text += tr('You can always change learning options in the game settings.')
		var modal := GlobalUI.show_confirm(
			tr('Are You Learning Japanese?'), text, tr('Enable Minigames'), tr('Cancel'))
		modal.confirmed.connect(func() -> void:
			GameSettings.Japanese.practice_enabled.set_value(true, true)
			GameSettings.Japanese.kanji_drawing_enabled.set_value(true, true)
		)
	_on_continued()

func get_skip_id() -> String:
	return 'enable_japanese'

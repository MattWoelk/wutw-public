extends Node2D

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GameSettings.Interface.tooltip_speed.set_value(.001)
	GameSettings.Japanese.practice_enabled.set_value(true)
	GameSettings.Japanese.kanji_practice_max_level.set_value(60)
	GameSettings.Japanese.kanji_practice_lru_level.set_value(29)
	GlobalSaveGame.init_new_game(13)

	await get_tree().create_timer(0.5).timeout

	(%Hub as Hub)._on_hub_content_scroll_clicked()
	await get_tree().create_timer(1).timeout

	var practice := (%Hub as Hub)._opened_menus[-1] as BlanksPractice
	practice._random.reseed(1344)
	practice.starting_level = 29
	practice._on_start_button_pressed()

	await get_tree().create_timer(4).timeout

	Input.warp_mouse(Vector2(1100, 960))
	var card := practice.deck.get_hand_cards()[-1]
	card.is_selected = true
	card.drag_started.emit()
	var drag_tween := create_tween()
	drag_tween.set_ease(Tween.EaseType.EASE_OUT)
	drag_tween.set_trans(Tween.TRANS_CUBIC)
	drag_tween.tween_method(Input.warp_mouse, Vector2(1100, 960), Vector2(525, 500), 1.0)
	drag_tween.play()
	await drag_tween.finished
	var slot := practice._get_all_slots()[5]
	practice._on_card_dropped_on_slot(card, slot)
	card.drag_ended.emit()

	await get_tree().create_timer(4).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

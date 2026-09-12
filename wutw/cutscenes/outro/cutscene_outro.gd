class_name Cutscene_Outro
extends Cutscene_Slideshow

const SCROLL_SPEED := 0.03

var _credits_tween: Tween

func _ready() -> void:
	(%CreditsContainer as Control).modulate.a = 0
	super._ready()

func _show_next_slide(index: int) -> void:
	await super._show_next_slide(index)
	if index == texts.size() - 1:
		if _anim_player.is_playing():
			await _anim_player.animation_finished
		_credits_tween = create_tween()
		_credits_tween.tween_interval(6.5)  # Based on voice audio timing.
		_credits_tween.tween_property(%MainMenu.get_node('%Logo'), 'modulate:a', 1.0, 3.3)
		_credits_tween.tween_interval(0.6)
		_credits_tween.tween_property(%Label, 'modulate:a', 0.0, 1.0)
		_credits_tween.parallel().tween_property(%CreditsContainer, 'modulate:a', 1.0, 1.0)
		_credits_tween.tween_interval(1.5)
		_credits_tween.tween_property(%CreditsContainer, 'size:y', 362.0, 3.0)
		var max_scroll := (%CreditsContainer as ScrollContainer).get_v_scroll_bar().max_value
		_credits_tween.tween_property(%CreditsContainer, 'scroll_vertical', max_scroll, max_scroll * SCROLL_SPEED)
		_credits_tween.play()
		await _credits_tween.finished

func _on_skip_button_pressed() -> void:
	if _finished:
		return
	elif _cur_slide < texts.size() - 1:
		_cur_slide += 1
		_show_next_slide(_cur_slide)
	elif _credits_tween and not _credits_tween.is_running():
		_finished = true

		if not preview_mode:
			GlobalSaveGame.set_main_quest_progress(main_quest_progress)
			GlobalSaveGame.save_game()
			GlobalSaveGame.clear()

		while not _credits_tween:
			await get_tree().process_frame
		var tween := create_tween()
		tween.tween_property(%CreditsContainer, 'modulate:a', 0.0, 0.5)
		tween.play()
		await tween.finished

		_audio_player.stop()

		finished.emit()

func skip_cutscene() -> void:
	if _finished:
		return

	if _cur_slide < texts.size() - 1:
		_cur_slide = texts.size() - 1
		_show_next_slide(_cur_slide)
		_on_skip_button_pressed()
	elif _credits_tween and _credits_tween.is_running():
		_credits_tween.set_speed_scale(15)

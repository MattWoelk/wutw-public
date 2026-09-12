class_name LockAbilityDialog
extends Node2D

signal closed

const MINIMIZE_BUTTON_ANIMATION_DURATION := 0.15
const MINIMIZE_ANIMATION_DURATION := 0.6

var _minimize_tween: Tween
var _minimized: bool = false
var _closing := false

func _ready() -> void:
	var dropdown := %Dropdown as Dropdown
	var run := Utils.get_active_run()
	for spot in run.get_current_stage().get_spots():
		if not spot.is_locked:
			var spot_title := tr(spot.spot_type.name)
			var upgrades := spot.get_current_upgrades()
			if upgrades:
				spot_title += ' (%s)' % tr(upgrades[-1].name)
			dropdown.add_item(spot_title, spot)

	if dropdown.get_num_items() == 0:
		GlobalUI.show_error(tr('No unlocked <term_lower:spot>s to lock.'))
		await get_tree().process_frame  # Called awaits for closed after _ready().
		closed.emit()
		queue_free()
		return

	(%ScrollPanel as ScrollPanel).animate_unroll()

func close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled(%ScrollPanel as Control, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		get_parent().remove_child(self)
		queue_free()
		closed.emit()

func _on_cancel_button_pressed() -> void:
	close()

func _on_confirm_button_pressed() -> void:
	var spot_to_lock := (%Dropdown as Dropdown).get_selected_value() as Spot
	if Utils.ensure(spot_to_lock != null):
		spot_to_lock.is_locked = true
	close()

func _on_one_turn_button_pressed() -> void:
	var spot_to_lock := (%Dropdown as Dropdown).get_selected_value() as Spot
	if Utils.ensure(spot_to_lock != null):
		spot_to_lock.is_locked = true
		var run := Utils.get_active_run()
		run.signals.redraw_started.connect(func(_is_first: bool) -> void:
			spot_to_lock.is_locked = false
		)
	close()

func _on_minimize_button_pressed() -> void:
	# Copied from CardDeckViewer.
	Utils.set_input_enabled(%ScrollPanel as Control, false)
	Utils.set_input_enabled(%MinimizeButton as Control, false)
	_minimize_tween = create_tween()
	if _minimized:
		(%BG as Control).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
		_minimize_tween.set_ease(Tween.EASE_OUT)
		var visible_y := (%CenterContainer as Control).position.y - 1000
		_minimize_tween.tween_property(%CenterContainer, 'position:y', visible_y, MINIMIZE_ANIMATION_DURATION)
		_minimize_tween.parallel().tween_property(%BG, 'modulate:a', 1.0, MINIMIZE_ANIMATION_DURATION)
		_minimize_tween.parallel().tween_property(%MinimizeButton, 'modulate:a', 0.9, MINIMIZE_ANIMATION_DURATION)
	else:
		(%BG as Control).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		_minimize_tween.set_ease(Tween.EASE_IN)
		var hidden_y := (%CenterContainer as Control).position.y + 1000
		_minimize_tween.tween_property(%CenterContainer, 'position:y', hidden_y, MINIMIZE_ANIMATION_DURATION)
		_minimize_tween.parallel().tween_property(%BG, 'modulate:a', 0.2, MINIMIZE_ANIMATION_DURATION)
		_minimize_tween.parallel().tween_property(%MinimizeButton, 'modulate:a', 0.5, MINIMIZE_ANIMATION_DURATION)
	_minimize_tween.parallel().tween_callback(func() -> void:
		await get_tree().create_timer(MINIMIZE_ANIMATION_DURATION * 0.3).timeout
		(%MinimizeButton as Button).icon = (
			load('res://events/system/scenes/minimize_arrow_down.png') if _minimized
			else load('res://events/system/scenes/minimize_arrow_up.png'))
		(%MinimizeButton as Button).text = tr('Hide') if _minimized else tr('Show')
		_minimized = not _minimized
	)
	_minimize_tween.set_speed_scale(Utils.anim_speed())
	_minimize_tween.play()
	await _minimize_tween.finished
	Utils.set_input_enabled(%ScrollPanel as Control, true)
	Utils.set_input_enabled(%MinimizeButton as Control, true)

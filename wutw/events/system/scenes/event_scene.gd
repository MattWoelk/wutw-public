@tool
class_name EventScene
extends Node

signal finished

const MINIMIZE_BUTTON_ANIMATION_DURATION := 0.15
const MINIMIZE_ANIMATION_DURATION := 0.6
static var EVENT_STEP_SCENE := AsyncLoadedResource.new('res://events/system/scenes/event_step_scene.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

@export var event: Event:
	set(value):
		event = value
		if is_node_ready():
			_recreate()

var _current_step_scene: EventStepScene
var _minimize_tween: Tween
var _minimized: bool = false
var _is_new: bool = false

func _ready() -> void:
	var run := Utils.get_active_run()
	if run:  # Not editor or event creator preview.
		_is_new = not GlobalSaveGame.has_seen_event(event)
		run.get_events_state().set_int(event.event_id, Event.TRIGGERED_STAGE_INDEX_VAR, run.get_current_stage_index())
		GlobalSaveGame.get_events_state().set_bool(event.event_id, Event.TRIGGERED_EVER_VAR, true)
	if event and not Utils.is_in_editor():
		if event.start_dialogue:
			(%ScrollPanel as Control).visible = false
			await GlobalUI.show_dialogue(event.start_dialogue)
			(%ScrollPanel as Control).visible = true
		(%BG as FadedBackground).fade_in()
		if not event.steps:  # Dialogue-only
			assert(event.start_dialogue)
			finished.emit()
			return
	_recreate()
	var tween := create_tween()
	(%MinimizeButton as Control).modulate.a = 0.0
	tween.tween_property(%MinimizeButton, 'modulate:a', 0.75, 0.5)
	tween.play()

func _enter_tree() -> void:
	GlobalAudioSystem.is_in_event = true

func _exit_tree() -> void:
	GlobalAudioSystem.is_in_event = false

func _shortcut_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed('minimize', false):
		_on_minimize_button_pressed()
		get_viewport().set_input_as_handled()

func get_current_step_scene() -> EventStepScene:
	return _current_step_scene

func _recreate() -> void:
	if not event:
		return
	(%TitleLabel as Label).text = tr(event.event_name)
	(%NewIcon as Control).visible = _is_new
	_switch_to_step(event.steps[0], null, true)

func _switch_to_step(step: EventStep, outcome_widget: EventOutcomeWidget, first: bool = false) -> void:
	var scroll_panel := %ScrollPanel as ScrollPanel
	Utils.set_input_enabled(scroll_panel, false)
	if not first:
		var is_end := step == null
		if is_end:
			var tween := create_tween()
			tween.tween_property(%MinimizeButton, 'modulate:a', 0.0, 0.5)
			tween.play()
			(%BG as FadedBackground).fade_out(1.0)
		await scroll_panel.animate_roll(scroll_panel.default_roll_duration, is_end)

	# Make sure we never size down after a choice.
	var main_panel := %MainPanel as Control
	main_panel.custom_minimum_size.x = max(main_panel.custom_minimum_size.x, main_panel.size.x)

	Utils.clear_node(%MainPanel)
	_current_step_scene = null

	if not step:
		if event.should_mark_all_choices_seen():
			event.mark_all_choices_seen()
		finished.emit()
		return

	_current_step_scene = EVENT_STEP_SCENE.instantiate_loaded_scene() as EventStepScene
	_current_step_scene.event = event
	_current_step_scene.event_step = step
	_current_step_scene.outcome_widget = outcome_widget
	_current_step_scene.finished.connect(_switch_to_step)
	%MainPanel.add_child(_current_step_scene)

	await scroll_panel.animate_unroll(scroll_panel.default_unroll_duration, first)
	Utils.set_input_enabled(scroll_panel, true)

func _on_minimize_button_pressed() -> void:
	Utils.set_input_enabled(%ScrollPanel as Control, false)
	Utils.set_input_enabled(%MinimizeButton as Control, false)
	_minimize_tween = create_tween()
	if _minimized:
		_minimize_tween.set_ease(Tween.EASE_OUT)
		var visible_y := (%PanelContainer as Control).position.y - 1000
		_minimize_tween.tween_property(%PanelContainer, 'position:y', visible_y, MINIMIZE_ANIMATION_DURATION)
		_minimize_tween.parallel().tween_property(%BG, 'modulate:a', 1.0, MINIMIZE_ANIMATION_DURATION)
		_minimize_tween.parallel().tween_property(%MinimizeButton, 'modulate:a', 0.9, MINIMIZE_ANIMATION_DURATION)
	else:
		_minimize_tween.set_ease(Tween.EASE_IN)
		var hidden_y := (%PanelContainer as Control).position.y + 1000
		_minimize_tween.tween_property(%PanelContainer, 'position:y', hidden_y, MINIMIZE_ANIMATION_DURATION)
		_minimize_tween.parallel().tween_property(%BG, 'modulate:a', 0.3, MINIMIZE_ANIMATION_DURATION)
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

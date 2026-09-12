@tool
class_name RunSetupEventButton
extends RunSetupButtonBase

@export var event: Event_Stage:
	set(value):
		event = value
		_update()
@export var empty_state_text: String = tr('Choose Event to Guarantee'):
	set(value):
		empty_state_text = value
		_update()

func _ready() -> void:
	super._ready()
	_update()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.BEGIN])

func _gui_input(input_event: InputEvent) -> void:
	var mouse_event := input_event as InputEventMouseButton
	if not mouse_event:
		return
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if event and Utils.is_museum_unlocked():
			MuseumBrowser.open_museum_entry(event, UI.Layer.STATE_MENU)

func _update() -> void:
	if event:
		assert(event.steps)
		icon = await event.steps[0].start_loading_texture()
		text = ''
	else:
		icon = null
		text = empty_state_text

func _make_tooltip_text() -> String:
	if not event:
		return tr('%s to select an event to guarantee.') % InputPrompts.get_input_markup(InputPrompts.InputType.LEFT_CLICK)

	var result := ''
	var spot_upgrade := event.default_spot_upgrade
	result += '<header_font_size>[b]%s[/b][/font_size]' % tr(event.event_name)
	result += '\n\n' + tr('This <term_lower:event> can be encountered in %s - %s.') % [
		tr(SpotType.get_spot_type_by_upgrade(spot_upgrade).name), tr(spot_upgrade.name)]
	if event.default_probability_weight == Event_Stage.Probability.LOW:
		result += '\n\n' + tr('This <term_lower:event> is rare.')
	elif event.default_probability_weight == Event_Stage.Probability.VERY_LOW:
		result += '\n\n' + tr('This <term_lower:event> is very rare.')

	var reqs_hint := event.get_markedup_requirements_hint()
	if reqs_hint:
		result += '\n\n' + tr('[b]May require[/b]: %s') % reqs_hint
	var outcomes_hint := event.get_markedup_outcomes_hint()
	if outcomes_hint:
		result += '\n\n' + tr('[b]May grant[/b]: %s') % outcomes_hint

	if Utils.is_museum_unlocked():
		result += '\n\n' + tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)

	return result

func get_search_text() -> Array[String]:
	if event:
		return event.get_search_text()
	else:
		return []

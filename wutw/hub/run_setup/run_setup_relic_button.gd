@tool
class_name RunSetupRelicButton
extends RunSetupButtonBase

@export var relic: Relic:
	set(value):
		relic = value
		_update()
@export var empty_state_text: String = tr('Choose Relic'):
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
		if relic and Utils.is_museum_unlocked():
			MuseumBrowser.open_museum_entry(relic, UI.Layer.STATE_MENU)

func _update() -> void:
	if relic:
		icon = relic.icon
		text = ''
	else:
		icon = null
		text = empty_state_text

func _make_tooltip_text() -> String:
	if not relic:
		return tr('%s to select a starting relic.') % InputPrompts.get_input_markup(InputPrompts.InputType.LEFT_CLICK)

	var result := ''
	result += tr('<header_font_size>[b]%s[/b][/font_size]') % relic.get_relic_name(true)
	result += '\n\n' + relic.get_markedup_description()

	if Utils.is_museum_unlocked():
		result += '\n\n' + tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)

	return result

func get_search_text() -> Array[String]:
	var result: Array[String]
	if relic:
		result.append_array([relic.get_relic_name(false), relic.get_description()])
	return result

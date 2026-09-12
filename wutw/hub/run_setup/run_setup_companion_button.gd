@tool
class_name RunSetupCompanionButton
extends RunSetupButtonBase

@export var companion: Companion:
	set(value):
		companion = value
		_update()
@export var empty_state_text: String = tr('Choose Companion'):
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
		if companion and Utils.is_museum_unlocked():
			MuseumBrowser.open_museum_entry(companion, UI.Layer.STATE_MENU)

func _update() -> void:
	if companion:
		icon = companion.image
		text = ''
	else:
		icon = null
		text = empty_state_text

func _make_tooltip_text() -> String:
	if not companion:
		return tr('%s to select a companion.') % InputPrompts.get_input_markup(InputPrompts.InputType.LEFT_CLICK)

	var result := ''
	result += tr('<header_font_size>[b]%s[/b][/font_size]') % tr(companion.companion_name)
	if companion.description:
		result += '\n\n' + tr(companion.description)
	result += '\n\n' + tr('[b]Ability[/b]: ') + tr(companion.ability_description)

	if Utils.is_museum_unlocked():
		result += '\n\n' + tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)

	return result

func get_search_text() -> Array[String]:
	var result: Array[String]
	if companion:
		result.append(tr(companion.companion_name))
	return result

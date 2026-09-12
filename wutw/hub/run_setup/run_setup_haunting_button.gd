@tool
class_name RunSetupHauntingButton
extends RunSetupButtonBase

@export var haunting_type: HauntingType:
	set(value):
		haunting_type = value
		_update()
@export var empty_state_text: String = '':
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
		if haunting_type and Utils.is_museum_unlocked():
			MuseumBrowser.open_museum_entry(haunting_type, UI.Layer.STATE_MENU)

func _update() -> void:
	if haunting_type:
		icon = haunting_type.image_small_realistic if Utils.is_realistic_era() else haunting_type.image_small
		text = ''
	else:
		icon = null
		if empty_state_text:
			text = empty_state_text
		else:
			text = (
				tr('Choose Challenge to Prevent') if Utils.is_realistic_era()
				else tr('Choose Haunting to Ward Against'))

func _make_tooltip_text() -> String:
	if not haunting_type:
		return tr('%s to select a <term_lower:haunting> to ward against.') % InputPrompts.get_input_markup(InputPrompts.InputType.LEFT_CLICK)

	var result := ''
	result += '<header_font_size>[b]%s[/b][/font_size]\n\n' % (
		tr(haunting_type.name_realistic) if Utils.is_realistic_era()
		else haunting_type.get_localized_name())
	if Utils.is_realistic_era():
		result += tr('[b]Challenge: %s[/b]') % haunting_type.get_mechanics_description(HauntingTrigger.Mode.UNIVERSAL)
		result += '\n\n'
		result += tr('This <term:haunting> can be resolved by <term_lower:fill>ing the associated <term_lower:aspect_slot>s.')
		result += '\n\n'
		result += tr('“%s”') % tr(haunting_type.description_realistic)
	else:
		result += tr('[b]Haunting: %s[/b]') % haunting_type.get_mechanics_description(HauntingTrigger.Mode.UNIVERSAL)
		result += '\n\n'
		result += tr('This <term:haunting> can be pacified by <term_lower:fill>ing the associated <term_lower:aspect_slot>s.')
		result += '\n\n'
		result += tr('“%s”') % tr(haunting_type.description)

	if Utils.is_museum_unlocked():
		result += '\n\n' + tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)

	return result

func get_search_text() -> Array[String]:
	var result: Array[String]
	if haunting_type:
		result.append(tr(haunting_type.name).to_lower().replace('ō', 'o').replace('ū', 'u'))
		result.append_array([tr(haunting_type.name_realistic), haunting_type.name_japanese, tr(haunting_type.name_translation)])
	return result

@tool
class_name Discovery_Haunting
extends Control

@export var haunting_type: HauntingType:
	set(value):
		haunting_type = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.ABOVE, Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.LEFT],
			[Tooltip.Alignment.CENTERED])

func _gui_input(input_event: InputEvent) -> void:
	var mouse_event := input_event as InputEventMouseButton
	if not mouse_event:
		return
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if Utils.is_museum_unlocked():
			MuseumBrowser.open_museum_entry(haunting_type, UI.Layer.STATE_MENU_SUBMENU)

func _update() -> void:
	if not haunting_type:
		return
	(%TitleLabel as Label).text = (
		tr(haunting_type.name_realistic) if Utils.is_realistic_era()
		else haunting_type.get_localized_name())
	(%BG as TextureRect).texture = haunting_type.image_small_realistic if Utils.is_realistic_era() else haunting_type.image_small

func _make_tooltip_text() -> String:
	var text := '[b]<term:haunting>: %s[/b]\n\n' % haunting_type.get_mechanics_description(HauntingTrigger.Mode.UNIVERSAL)
	if Utils.is_realistic_era():
		text += tr('“%s”') % tr(haunting_type.description_realistic)
	else:
		text += tr('“%s”') % tr(haunting_type.description)

	if Utils.is_museum_unlocked():
		text += '\n\n'
		text += tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)

	return text

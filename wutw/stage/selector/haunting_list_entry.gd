class_name HauntingListEntry
extends Control

var haunting_type: HauntingType:
	set(value):
		haunting_type = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
		[Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.LEFT, Tooltip.RelativeDirection.BELOW],
		[Tooltip.Alignment.CENTERED])

func _gui_input(input_event: InputEvent) -> void:
	var mouse_event := input_event as InputEventMouseButton
	if not mouse_event:
		return
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if GlobalSaveGame.has_seen_haunting(haunting_type) and Utils.is_museum_unlocked():
			MuseumBrowser.open_museum_entry(haunting_type, UI.Layer.GAME_MENU)
		else:
			GlobalUI.show_error(tr('The <term_lower:haunting> hasn\'t been discovered yet.'))

func _update() -> void:
	if not haunting_type:
		return
	(%NameLabel as Label).text = haunting_type.name_realistic if Utils.is_realistic_era() else haunting_type.get_localized_name()
	(%NewIcon as Control).visible = not GlobalSaveGame.has_seen_haunting(haunting_type)

func _make_tooltip_text() -> String:
	var text := '[b]<term:haunting>: %s[/b]\n\n' % haunting_type.get_mechanics_description(HauntingTrigger.Mode.SPOT)

	if Utils.is_realistic_era():
		text += tr('This <term_lower:haunting> can be resolved by <term_lower:fill>ing the associated <term_lower:aspect_slot>s.')
	else:
		text += tr('This <term_lower:haunting> can be pacified by <term_lower:fill>ing the associated <term_lower:aspect_slot>s.')

	text += '\n\n'
	text += tr('Slots: ')
	var run := Utils.get_active_run()
	for aspect_type in haunting_type.get_toal_aspect_slots(run, HauntingTrigger.Mode.SPOT):
		var icon := aspect_type.get_used_icon() if aspect_type else load('res://aspects/types/universal_slot.png')
		text += '[img width=1.5em height=1.5em]%s[/img] ' % icon.resource_path

	text += '\n\n'
	if Utils.is_realistic_era():
		text += tr('“%s”') % tr(haunting_type.description_realistic)
	else:
		text += tr('“%s”') % tr(haunting_type.description)

	if GlobalSaveGame.has_seen_haunting(haunting_type):
		if Utils.is_museum_unlocked():
			text += '\n\n'
			text += tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)
	else:
		text += '\n\n'
		text += tr('[b]This <term_lower:haunting> has not been discovered yet.[/b]')

	return text

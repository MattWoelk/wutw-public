class_name EventListEntry
extends Control

var event: Event_Stage:
	set(value):
		event = value
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
		if Utils.is_museum_unlocked():
			if GlobalSaveGame.has_seen_event(event):
				MuseumBrowser.open_museum_entry(event, UI.Layer.GAME_MENU)
			else:
				GlobalUI.show_error(tr('The <term_lower:event> hasn\'t been discovered yet.'))

func _update() -> void:
	if not event:
		return
	(%NameLabel as Label).text = tr(event.event_name)
	(%NewIcon as Control).visible = not GlobalSaveGame.has_seen_event(event)

	if Event.Category.MAIN_STORY in event.categories:
		(%NameLabel as Label).add_theme_color_override('font_color', Color(0.392, 0.052, 0.456))
	elif Event.Category.COMPANION in event.categories:
		(%NameLabel as Label).add_theme_color_override('font_color', Color(0.078, 0.358, 0.02, 1.0))
	elif Event.Category.LANDMARK in event.categories:
		(%NameLabel as Label).add_theme_color_override('font_color', Color(0.0, 0.309, 0.52, 1.0))
	else:
		(%NameLabel as Label).add_theme_color_override('font_color', Color.BLACK)

func _make_tooltip_text() -> String:
	if Utils.is_in_editor():
		return ''

	var shop_type := event.get_associated_landmark()
	var text: String
	if shop_type:
		text = (tr('<related_term:shop><header_font_size>[b]Landmark: %s[/b][/font_size]\n\n%s') %
				[tr(event.event_name), shop_type.get_markedup_description()])
	else:
		text = tr('<related_term:event><header_font_size>[b]Event: %s[/b][/font_size]') % tr(event.event_name)
	var reqs_hint := event.get_markedup_requirements_hint()
	if reqs_hint:
		text += '\n\n'
		text += tr('[b]May require[/b]: %s') % reqs_hint
	var outcomes_hint := event.get_markedup_outcomes_hint()
	if outcomes_hint:
		text += '\n\n'
		text += tr('[b]May grant[/b]: %s') % outcomes_hint

	if Event.Category.MAIN_STORY in event.categories:
		text += '\n\n'
		text += tr('[b][color=#640d74]This event is part of the main story![/color][/b]')
	elif Event.Category.COMPANION in event.categories:
		text += '\n\n'
		text += tr('[b][color=#145b05]This event is part of a companion questline![/color][/b]')

	if GlobalSaveGame.has_seen_event(event):
		if Utils.is_museum_unlocked():
			text += '\n\n'
			text += tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)
	else:
		text += '\n\n'
		text += tr('[b]This event has not been discovered yet.[/b]')

	return text

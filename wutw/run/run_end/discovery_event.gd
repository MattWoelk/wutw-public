@tool
class_name Discovery_Event
extends Container

@export var event: Event:
	set(value):
		event = value
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
			MuseumBrowser.open_museum_entry(event, UI.Layer.STATE_MENU_SUBMENU)

func _update() -> void:
	if not event:
		return
	(%TitleLabel as Label).text = tr(event.event_name)
	(%BG as TextureRect).texture = await event.steps[0].background_image.get_texture_async()

func _make_tooltip_text() -> String:
	var text: String
	if Utils.get_active_run():
		text = tr('New outcome discovered for <term_lower:event> [b]%s[/b].') % tr(event.event_name)
	else:  # Past Run viewer
		text = '[b]%s[/b]' % tr(event.event_name)

	if event is Event_Stage:
		text += '\n\n'
		text += tr('This <term_lower:event> occurs in the [b]%s[/b] <term_lower:spot_upgrade>.') % tr((event as Event_Stage).default_spot_upgrade.name)
	var reqs_hint := event.get_markedup_requirements_hint()
	if reqs_hint:
		text += '\n\n'
		text += tr('This <term_lower:event> may require: %s') % reqs_hint
	var outcomes_hint := event.get_markedup_outcomes_hint()
	if outcomes_hint:
		text += '\n\n'
		text += tr('This <term_lower:event> may grant: %s') % outcomes_hint

	if Utils.is_museum_unlocked():
		text += '\n\n'
		text += tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)

	return text

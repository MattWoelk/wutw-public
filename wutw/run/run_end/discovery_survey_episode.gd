@tool
class_name Discovery_SurveyEpisode
extends Container

@export var episode: SurveyEpisode:
	set(value):
		episode = value
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
			MuseumBrowser.open_museum_entry(episode, UI.Layer.STATE_MENU_SUBMENU)

func _update() -> void:
	if not episode:
		return
	(%TitleLabel as Label).text = tr(episode.title)
	(%BG as TextureRect).texture = await episode.background_image.get_texture_async()

func _make_tooltip_text() -> String:
	var text: String
	if Utils.get_active_run():
		text = tr('New outcome discovered for <term_lower:survey> <term_lower:encounter> [b]%s[/b].') % tr(episode.title)
	else:  # Past Run viewer
		text = '[b]%s[/b]' % tr(episode.title)

	if Utils.is_museum_unlocked():
		text += '\n\n'
		text += tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)

	return text

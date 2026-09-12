class_name SurveyPreviewEntry
extends HBoxContainer

var episodes: Array[SurveyEpisode]:
	set(value):
		episodes = value
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
			for episode in episodes:
				if GlobalSaveGame.has_seen_survey(episode):
					MuseumBrowser.open_museum_entry(episode, UI.Layer.GAME_MENU)
					return
			GlobalUI.show_error(tr('None of these <term_lower:survey> <term_lower:encounter>s have been discovered yet.'))

func _update() -> void:
	if not episodes:
		(%CountLabel as Label).text = tr('No survey possible here.')
		return
	(%CountLabel as Label).text = tr('%d possible encounters') % episodes.size()

	var num_new := 0
	for episode in episodes:
		if not GlobalSaveGame.has_seen_survey(episode):
			num_new += 1
	if num_new > 0:
		(%NewIcon as Control).visible = true
		(%NewCountLabel as Control).visible = true
		(%NewCountLabel as Label).text = str(num_new)
	else:
		(%NewIcon as Control).visible = false
		(%NewCountLabel as Control).visible = false

func _make_tooltip_text() -> String:
	if Utils.is_in_editor():
		return ''

	var num_new := 0
	for episode in episodes:
		if not GlobalSaveGame.has_seen_survey(episode):
			num_new += 1

	var text := '<related_term:survey>'
	if num_new == episodes.size():
		text += tr('None of the %d possible <term_lower:encounter>s has been discovered.') % num_new
	else:
		text += tr('Includes the following possible <term_lower:encounter>s:')
		text += '[ul]\n'
		for episode in episodes:
			if GlobalSaveGame.has_seen_survey(episode):
				text += tr(episode.title) + '\n'
		text += '[/ul]'
		if num_new > 0:
			text += '\n'
			text += tr('As well as %d undiscovered ones.') % num_new

	if num_new < episodes.size() and Utils.is_museum_unlocked():
		text += '\n\n'
		text += tr('[i]%s to open museum.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)

	return text

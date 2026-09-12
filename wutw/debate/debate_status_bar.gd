class_name DebateStatusBar
extends Control

signal on_speech_requested

var _starting_scribe: int
var _starting_historian: int
var _total: int = 0

func _ready() -> void:
	_update(true)
	GlobalSaveGame.changed.connect(_update)
	GlobalTooltipSystem.attach(%SpeechButton as Control,
			_make_tooltip_text,
			[Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.ABOVE],
			[Tooltip.Alignment.CENTERED])

func _update(starting: bool = false) -> void:
	if Utils.is_debate_in_progress():
		if _total == 0:  # First time around.
			# Here instead of in _ready() to avoid loading resources before the debate is active.
			for argument: DebateArgument in DebateArgument.get_all_arguments().values():
				_total += argument.impact

		var scribe := 0
		var historian := 0
		var any_available := false
		for argument: DebateArgument in DebateArgument.get_all_arguments().values():
			if GlobalSaveGame.is_argument_used(argument):
				if argument.faction == DebateArgument.Faction.SCRIBE:
					scribe += argument.impact
				else:
					historian += argument.impact
			elif GlobalSaveGame.is_argument_unlocked(argument):
				any_available = true
		(%ScribeLabel as Label).text = ' %d%%' % scribe
		(%HistorianLabel as Label).text = '%d%% ' % historian
		if starting or not visible:
			_starting_scribe = scribe
			_starting_historian = historian
			_update_progress(_starting_scribe, _starting_scribe, %ScribeProgress as TextureRect)
			_update_progress(_starting_historian, _starting_historian, %HistorianProgress as TextureRect)
		else:
			if scribe != _starting_scribe:
				var tween := create_tween()
				tween.tween_method(
					_update_progress.bind(_starting_scribe, %ScribeProgress),
					_starting_scribe as float, scribe as float, 1.0)
				tween.play()
			if historian != _starting_historian:
				var tween := create_tween()
				tween.tween_method(
					_update_progress.bind(_starting_historian, %HistorianProgress),
					_starting_historian as float, historian as float, 1.0)
				tween.play()
		(%SpeechButton as Button).disabled = not any_available
		visible = true
	else:
		visible = false

func _update_progress(progress: float, start: float, bar: TextureRect) -> void:
	(bar.material as ShaderMaterial).set_shader_parameter('progress', progress / _total)
	(bar.material as ShaderMaterial).set_shader_parameter('damage_progress', (progress - start) / _total)

func _on_speech_button_pressed() -> void:
	on_speech_requested.emit()

func _make_tooltip_text() -> String:
	if (%SpeechButton as Button).disabled:
		return tr('No speech topics are available.\n\nFind topics by sending the Explorer to previously settled shards.')
	else:
		return tr('Select a speech topic for the debate between the Scribe and the Historian.\n\nMore topics can be found by sending the Explorer to previously settled shards.')

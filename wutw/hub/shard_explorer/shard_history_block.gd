@tool
class_name ShardHistoryBlock
extends UkiyoePanelContainer

@export var shard_type: ShardType
@export var history_index: int

var _reveal_tween: Tween
var _sfx_playing_id: int = 0

func _ready() -> void:
	super._ready()

	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)

	if not Utils.is_in_editor():
		var progress := GlobalSaveGame.get_shard_type_progress(shard_type)
		var past_run := GlobalSaveGame.get_past_run_by_shard_type(shard_type)
		if progress.is_history_completed(history_index):
			var text := shard_type.format_history_text(history_index, past_run)
			(%Label as MarkedUpLabel).set_markedup_text(text)
			if progress.is_history_seen(history_index):
				(%Label as MarkedUpLabel).visible_ratio = 1.0
				(%RevealButton as Button).visible = false
				self_modulate.a = 0
			else:
				(%Label as MarkedUpLabel).visible_ratio = 0.0
				(%RevealButton as Button).visible = true
		else:
			(%RevealButton as Button).visible = false
			(%Label as MarkedUpLabel).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			(%Label as MarkedUpLabel).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if shard_type.history[history_index].min_main_quest <= GlobalSaveGame.get_main_quest_progress():
				(%Label as MarkedUpLabel).set_markedup_text(
					tr('[b]Further history will be revealed as you complete more expeditions.[/b]'))
			else:
				(%Label as MarkedUpLabel).set_markedup_text(
					tr('[b]Further history will be revealed in a future era.[/b]'))

func _exit_tree() -> void:
	_stop_sfx()  # Just in case.

func _update_font_size() -> void:
	Utils._scale_font_size(%Label as RichTextLabel, false, 16)

func _on_reveal_button_pressed() -> void:
	GlobalSaveGame.mark_shard_type_history_seen(shard_type, history_index)
	GlobalSaveGame.save_game()

	(%RevealButton as Button).mouse_filter = Control.MOUSE_FILTER_IGNORE
	(%SkipButton as Button).visible = true
	_reveal_tween = create_tween()
	_reveal_tween.tween_callback(_start_sfx)
	_reveal_tween.tween_property(%RevealButton, 'modulate:a', 0.0, 0.5)
	_reveal_tween.tween_property(%Label, 'visible_ratio', 1.0, (%Label as MarkedUpLabel).get_total_character_count() * DialogueDisplay.TIME_PER_CHAR)
	_reveal_tween.tween_property(self, 'self_modulate:a', 0.0, 0.3)
	_reveal_tween.tween_property(%SkipButton, 'visible', false, 0.01)
	_reveal_tween.tween_callback(_stop_sfx)
	_reveal_tween.play()

func _on_skip_button_pressed() -> void:
	(%SkipButton as Button).visible = false
	assert(_reveal_tween)
	_reveal_tween.set_speed_scale(25)

func _start_sfx() -> void:
	GlobalAudioSystem.set_parameter(AK.GAME_PARAMETERS.TEXT_SPEED, DialogueDisplay.DIALOGUE_TEXT_SPEED)
	_stop_sfx()
	_sfx_playing_id = GlobalAudioSystem.start_loop(AK.EVENTS.UI_DIALOGUE_TEXT_LOOP)

func _stop_sfx() -> void:
	if _sfx_playing_id:
		GlobalAudioSystem.stop_loop(_sfx_playing_id)
		_sfx_playing_id = 0

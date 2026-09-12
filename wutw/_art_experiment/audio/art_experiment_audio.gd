@tool
extends Node2D

@export var specific_event: WwiseEvent

var _event_ids: Array[int]
var _playing_id: int = -1

func _ready() -> void:
	var script := AK.EVENTS as Script
	(%OptionButton as OptionButton).clear()
	var constants := script.get_script_constant_map()
	for event_name: String in constants:
		(%OptionButton as OptionButton).add_item(event_name)
		_event_ids.append(constants[event_name])
	if not Utils.is_in_editor():
		GlobalGameSettings.read_only = true
		await get_tree().process_frame
		# Start at full volume by default, regardless of game settings.
		GlobalAudioSystem.set_ui_volume(1)
		GlobalAudioSystem.set_music_volume(1)
		GlobalAudioSystem.set_ambience_volume(1)
		GlobalAudioSystem.set_effects_volume(1)
		GlobalAudioSystem.set_master_volume(1)

func _on_button_pressed() -> void:
	var event_id := _event_ids[(%OptionButton as OptionButton).get_selected_id()]
	_playing_id = Wwise.post_event_id(event_id, self)

func _on_button_predefined_pressed() -> void:
	if specific_event:
		specific_event.post(self)

func _on_h_slider_value_changed(value: float) -> void:
	GlobalAudioSystem.set_master_volume(value)

func _on_button_stop_pressed() -> void:
	Wwise.stop_event(_playing_id, 100, AkUtils.AkCurveInterpolation.AK_CURVE_LINEAR)

func _on_button_stop_predefined_pressed() -> void:
	if specific_event:
		specific_event.stop(self, 100, AkUtils.AkCurveInterpolation.AK_CURVE_LINEAR)

class_name MapScrollTransition
extends Node2D

@export var roll_sound: WwiseEvent
@export var roll_end_sound: WwiseEvent

var _sfx_playing_id: int = 0

func _ready() -> void:
	var viewport_image := get_viewport().get_texture().get_image()
	(%Image as TextureRect).texture = ImageTexture.create_from_image(viewport_image)

	_start_sfx()
	(%AnimationPlayer as AnimationPlayer).speed_scale = Utils.anim_speed()
	(%AnimationPlayer as AnimationPlayer).play('roll')
	(%AnimationPlayer as AnimationPlayer).animation_finished.connect(func(_anim_name: String) -> void:
		_stop_sfx()
		_play_end_sfx()
		queue_free()
	)

	await get_tree().create_timer(Utils.anim_duration(
		(%AnimationPlayer as AnimationPlayer).current_animation_length / 2.0
	)).timeout
	(%MouseBlocker as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _exit_tree() -> void:
	_stop_sfx()  # Safeguard

func _start_sfx() -> void:
	if not Utils.is_in_editor():
		_stop_sfx()
		_sfx_playing_id = GlobalAudioSystem.start_loop(roll_sound.id)

func _stop_sfx() -> void:
	if _sfx_playing_id:
		GlobalAudioSystem.stop_loop(_sfx_playing_id)
		_sfx_playing_id = 0

func _play_end_sfx() -> void:
	GlobalAudioSystem.play(roll_end_sound.id)

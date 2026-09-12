@tool
extends Node2D

var _tween: Tween

@export_tool_button('Animate') @warning_ignore('unused_private_class_variable')
var _animate_shards_tool := _animate_shards

func _ready() -> void:
	if Utils.is_in_editor():
		return

	GlobalGameSettings.read_only = true
	GameSettings.Audio.master_volume.set_value(0.75)
	GameSettings.Audio.ambience_volume.set_value(1.0)
	GameSettings.Audio.effects_volume.set_value(1.0)
	GameSettings.Audio.ui_volume.set_value(1.0)
	var loop_playing_id := GlobalAudioSystem.start_loop(AK.EVENTS.AMB_ZONE_CLOUD_LOOP)
	get_tree().create_timer(0.5).timeout.connect(GlobalAudioSystem.play.bind(AK.EVENTS.SFX_MAP_CLOUD))

	#(%AnimationPlayer as AnimationPlayer).play('spread')
	#await (%AnimationPlayer as AnimationPlayer).animation_finished
	_animate_shards()
	await _tween.finished

	GlobalAudioSystem.stop_loop(loop_playing_id)
	await get_tree().create_timer(1).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

func _animate_shards() -> void:
	if _tween:
		_tween.kill()

	var starting_positions : Dictionary[Node2D, Vector2]
	var starting_scales : Dictionary[Node2D, Vector2]
	var starting_speeds : Dictionary[Node2D, float]
	seed(1342)
	for shard: Node2D in %Shards.get_children():
		starting_positions[shard] = shard.position
		starting_scales[shard] = shard.scale
		starting_speeds[shard] = randf_range(90, 110) * remap(shard.position.y, 540, 1080, 0.4, 1.0)
	_tween = create_tween()
	_tween.tween_method(func(t: float) -> void:
		#t = ease(t, 1.5)
		for shard in starting_positions:
			var pos := starting_positions[shard]
			var direction := Vector2(960, 1080).direction_to(pos)
			direction.x *= 1.5
			shard.position = pos + t * direction * starting_speeds[shard]
			shard.scale = starting_scales[shard] * lerpf(1.0, 0.8, t)
	, 0.0, 1.0, 4)
	_tween.play()

	if Utils.is_in_editor():
		await _tween.finished
		await get_tree().create_timer(1).timeout
		for shard in starting_positions:
			shard.position = starting_positions[shard]
			shard.scale = starting_scales[shard]

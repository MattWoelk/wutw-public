class_name StageLocationTarget
extends ColorRect

var confirmed: bool = false:
	set(value):
		if confirmed == value:
			return
		confirmed = value
		_animate_confirm()

var _confirm_tween: Tween
var _default_thickness: float
var _default_highlight_thickness: float

func _ready() -> void:
	material = material.duplicate()  # Make sure these are independent
	var mat := material as ShaderMaterial
	_default_thickness = mat.get_shader_parameter('thickness')
	_default_highlight_thickness = mat.get_shader_parameter('thickness_highlighted')
	var map := Utils.get_typed_ancestor(self, Map) as Map
	if not map:
		return
	mat.set_shader_parameter('landmass_sdf', map.generated_map.blurred_biome_sdfs[0])
	mat.set_shader_parameter('size', size.x)
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		mat.set_shader_parameter('thickness', value * _default_thickness)
		mat.set_shader_parameter('thickness_highlighted', value * _default_highlight_thickness)
	, 0.0, 1.0, 0.2)
	tween.play()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		(material as ShaderMaterial).set_shader_parameter('size', size.x)

func remove() -> void:
	var mat := material as ShaderMaterial
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		mat.set_shader_parameter('thickness', value * _default_thickness)
		mat.set_shader_parameter('thickness_highlighted', value * _default_highlight_thickness)
	, 1.0, 0.0, 0.75)
	tween.play()
	await tween.finished
	queue_free()

func _process(_delta: float) -> void:
	var map := Utils.get_typed_ancestor(self, Map) as Map
	if not map:
		return
	var map_size := Vector2(map.get_map_size())
	var relative_position := map.get_map_object_location(self)
	var start_coord := relative_position / map_size
	var end_coord := (relative_position + size / map.get_map_scale()) / map_size
	(material as ShaderMaterial).set_shader_parameter(
		'global_rect', Vector4(start_coord.x, start_coord.y, end_coord.x, end_coord.y))

func _animate_confirm() -> void:
	if _confirm_tween:
		_confirm_tween.kill()
	_confirm_tween = create_tween()
	var start := (material as ShaderMaterial).get_shader_parameter('highlight_progress') as float
	GlobalAudioSystem.play(AK.EVENTS.UI_MAP_POTENTIAL_YIELD_CIRCLE)
	_confirm_tween.tween_method(func(value: float) -> void:
		(material as ShaderMaterial).set_shader_parameter('highlight_progress', value)
	, start, 1.0 if confirmed else 0.0, 0.4 if confirmed else 0.2)
	_confirm_tween.play()

@tool
class_name ScrollPanel
extends Control

@export_range(0, 200, 1, "or_greater") var top_margin: float = 0
@export_range(0, 200, 1, "or_greater") var bottom_margin: float = 0
@export var min_height: float = 40
@export var default_roll_duration: float = 1.0
@export var default_unroll_duration: float = 1.5

@export var roll_sound: WwiseEvent
@export var roll_end_sound: WwiseEvent

@export_tool_button('Test Roll')
@warning_ignore('unused_private_class_variable')
var _tool_animate_roll := animate_roll

@export_tool_button('Test Unroll')
@warning_ignore('unused_private_class_variable')
var _tool_animate_unroll := animate_unroll

var _top_dowel_material: ShaderMaterial
var _bottom_dowel_material: ShaderMaterial
var _unroll_tween: Tween
var _sfx_playing_id: int = 0

func _ready() -> void:
	# Could use instance shader params for better perf, but the material is reused in other places
	# with AnimationPlayers and such, and there are few enough instances that it isn't a huge deal.
	_top_dowel_material = ((%TopDowelWood as TextureRect).material as ShaderMaterial).duplicate()
	(%TopDowelWood as TextureRect).material = _top_dowel_material
	_bottom_dowel_material = ((%BottomDowelWood as TextureRect).material as ShaderMaterial).duplicate()
	(%BottomDowelWood as TextureRect).material = _bottom_dowel_material

func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	(%ScrollMargin as Control).size.x = (%ContentPanel as Control).get_combined_minimum_size().x
	custom_minimum_size.x = max(200, (%ScrollMargin as Control).size.x)
	_update_material()

func _update_material() -> void:
	_top_dowel_material.set_shader_parameter('size', (%TopDowelWood as Control).get_global_rect().size)
	_bottom_dowel_material.set_shader_parameter('size', (%BottomDowelWood as Control).get_global_rect().size)
	var height := (%ContentPanel as Control).size.y
	(%Scroller as Control).custom_minimum_size.y = max(min_height, height - top_margin - bottom_margin)
	(%ScrollMargin as Control).position.x = 0
	(%ScrollMargin as Control).position.y = -top_margin
	_top_dowel_material.set_shader_parameter('scroll_offset', (1.0 - top_margin / height))
	_bottom_dowel_material.set_shader_parameter('scroll_offset', (1.0 - bottom_margin / height))

func _exit_tree() -> void:
	_stop_sfx()  # Precaution

func animate_roll(duration: float = default_roll_duration, fade_out: bool = true) -> void:
	if _unroll_tween:
		_unroll_tween.kill()
	_stop_sfx()
	var height := (%ContentPanel as Control).size.y
	_unroll_tween = create_tween()
	_unroll_tween.set_trans(Tween.TRANS_SINE)
	_unroll_tween.set_ease(Tween.EASE_IN)
	_unroll_tween.tween_callback(_start_sfx)
	_unroll_tween.tween_property(self, 'top_margin', 0, duration)
	_unroll_tween.parallel().tween_property(self, 'bottom_margin', height - min_height, duration)
	if fade_out:
		_unroll_tween.parallel().tween_property(self, 'modulate:a', 0, duration * 0.2).set_delay(duration * 0.8)
	if not Utils.is_in_editor():
		_unroll_tween.parallel().tween_callback(GlobalAudioSystem.play.bind(roll_end_sound.id)).set_delay(duration * 0.8)
	_unroll_tween.tween_callback(_stop_sfx)
	_unroll_tween.set_speed_scale(Utils.anim_speed())
	_unroll_tween.play()

	await _unroll_tween.finished

func _start_sfx() -> void:
	_sfx_playing_id = GlobalAudioSystem.start_loop(roll_sound.id)

func _stop_sfx() -> void:
	if _sfx_playing_id:
		GlobalAudioSystem.stop_loop(_sfx_playing_id)
		_sfx_playing_id = 0

func animate_unroll(duration: float = default_unroll_duration, fade_in: bool = true) -> void:
	if _unroll_tween:
		_unroll_tween.kill()
	_stop_sfx()
	_unroll_tween = create_tween()
	_unroll_tween.tween_callback(_start_sfx)
	_unroll_tween.set_trans(Tween.TRANS_SINE)
	_unroll_tween.set_ease(Tween.EASE_OUT)
	var height := (%ContentPanel as Control).size.y
	if fade_in:
		modulate.a = 0
	top_margin = 0
	bottom_margin = height - min_height
	_update_material()  # Make sure we start in fully rolled state instantly.
	if fade_in:
		_unroll_tween.tween_property(self, 'modulate:a', 1, duration * 0.2)
		_unroll_tween.parallel()
	_unroll_tween.tween_property(self, 'bottom_margin', 0, duration)
	_unroll_tween.tween_callback(_stop_sfx)
	_unroll_tween.set_speed_scale(Utils.anim_speed())
	_unroll_tween.play()
	await _unroll_tween.finished

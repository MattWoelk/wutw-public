@tool
class_name UkiyoeProgressBar
extends UkiyoePanelContainer

@export var max_value: float = 100
@export var value: float = 50
@export var damage_value: float = 0
@export var is_negative: bool = false:
	set(v):
		is_negative = v
		if is_node_ready():
			_bar_material.set_shader_parameter('is_negative', is_negative)
@export_range(0.1, 10, 0.01) var tween_speed: float = 0.8
@export var font_size: float = 0:
	set(v):
		font_size = v
		if is_node_ready():
			(%Label as Label).add_theme_font_size_override('font_size', roundi(font_size))
@export var animate_when_full: bool = false

var _bar_material: ShaderMaterial
var _was_full: bool = false
var _full_tween: Tween

func _ready() -> void:
	super._ready()

	_bar_material = (%TextureRect as Control).material.duplicate()
	(%TextureRect as Control).material = _bar_material

	await get_tree().process_frame  # Wait for parent to set up.
	if animate_when_full:
		_was_full = value >= max_value
		_bar_material.set_shader_parameter('full_anim_progress', 1 if _was_full else 0)
	_process(100000)  # Instantly update progress.

	is_negative = is_negative  # Force color update.
	font_size = font_size  # Force font size update.
	pivot_offset = size / 2

func _process(delta: float) -> void:
	_bar_material.set_shader_parameter('size', (%TextureRect as Control).get_global_rect().size)

	var speed := Utils.anim_speed(tween_speed)
	var displayed_value: float = _bar_material.get_shader_parameter('progress') * max_value
	var new_value: float = displayed_value
	if value < displayed_value:
		new_value -= max_value * speed * delta
		if new_value < value:
			new_value = value
	else:
		new_value += max_value * speed * delta
		if new_value > value:
			new_value = value

	var damage_displayed_value: float = _bar_material.get_shader_parameter('damage_progress') * max_value
	var damage_new_value: float = damage_displayed_value
	damage_new_value += sign(damage_value - damage_displayed_value) * max_value * speed * delta
	damage_new_value = clamp(damage_new_value, 0, max(damage_value, damage_displayed_value))

	# On some systems setting the parameter each frame can cause flicker.
	if _bar_material.get_shader_parameter('progress') != new_value / max_value:
		_bar_material.set_shader_parameter('progress', new_value / max_value)
	if _bar_material.get_shader_parameter('is_negative') != is_negative:
		_bar_material.set_shader_parameter('is_negative', is_negative)
	if _bar_material.get_shader_parameter('damage_progress') != damage_new_value / max_value:
		_bar_material.set_shader_parameter('damage_progress', damage_new_value / max_value)
	(%Label as Label).text = ' %s%d / %d ' % ['-' if is_negative else '', round(new_value), max_value]

	# Play the "became full" / "stopped being full" animation.
	var is_full := new_value >= max_value
	if animate_when_full:
		if is_full != _was_full and not is_negative:
			if _full_tween:
				_full_tween.kill()
			_full_tween = create_tween()
			_full_tween.tween_property(self, 'scale', Vector2(1.03, 1.07), 0.6)
			var full_anim_progress_start := _bar_material.get_shader_parameter('full_anim_progress') as float
			_full_tween.parallel().tween_method(func(full_anim_progress: float) -> void:
				_bar_material.set_shader_parameter('full_anim_progress', full_anim_progress)
			, full_anim_progress_start, 1 if is_full else 0, 0.6)
			_full_tween.tween_property(self, 'scale', Vector2(1.0, 1.0), 0.6)
			_full_tween.set_speed_scale(Utils.anim_speed())
			_full_tween.play()
		elif is_negative:
			_bar_material.set_shader_parameter('full_anim_progress', 0)
	_was_full = is_full

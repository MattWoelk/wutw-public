@tool
class_name MapEffect_Butterfly
extends MapEffect

# TODO: This is an experimental mess that I never cleaned up...
#       It is definitely wrong, but it's just butterflies; who cares.

const FADEOUT_TIME: float = 1.0
const MAX_ATTRACTORS: int = 20

@export var enable_movement: bool = false
@export var anim_speed: float = 15.0
@export var speed: float = 15.0  # Base drift speed.
@export var hover_radius: float = 12.0  # Distance to slow down and hover.
@export var arrive_time: float = 5  # Time to spend hovering when close.
@export var noise_scale := 10.0  # How wiggly the noise is.
@export var attractor_sprites: Array[MapSpriteType] = []

var _attractors: Array[MapSpritePlacement] = []

var _noise: FastNoiseLite = FastNoiseLite.new()
var _target_index: int = 0
var _timer: float = 0.0
var _arrive_timer: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _is_hovering: bool = false
var _flutter_phase := 0.0
var _accum: float = 0
var _frame_dir: int = 1

func start(map: Map) -> void:
	if not map:
		assert(Utils.is_in_editor())
		return
	for placement in map.get_sprite_renderer().placements:
		if placement.sprite_type in attractor_sprites:
			_attractors.append(placement)
	_attractors.sort_custom(func(a: MapSpritePlacement, b: MapSpritePlacement) -> bool:
		return position.distance_to(a.location) < position.distance_to(b.location)
	)
	if _attractors.size() > MAX_ATTRACTORS:
		_attractors.resize(MAX_ATTRACTORS)
	# TODO: Listen to sprites being added.
	if not _attractors:
		visible = false
		set_process(false)

func animate_destroy() -> void:
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0, FADEOUT_TIME)
	tween.play()
	await tween.finished
	queue_free()

func _process(delta: float) -> void:
	if not enable_movement:
		return

	_animate(delta)

	if _attractors.is_empty():
		return

	if _is_hovering:
		_hover_motion(delta)
		return

	var target := _attractors[_target_index].location
	var to_target := target - position
	var distance := to_target.length()

	if distance < hover_radius:
		_is_hovering = true
		_arrive_timer = arrive_time
		return

	# Directional drift with normalized bias
	var dir := to_target.normalized()

	# Add wobbly noise offsets (time-driven)
	_timer += delta
	var flutter_offset := Vector2(
		_noise.get_noise_2d(_timer, 0.0),
		_noise.get_noise_2d(_timer, 100.0)
	) * noise_scale # Amount of wiggle

	# Optional: add flutter sine component
	_flutter_phase += delta * 8.0
	flutter_offset.y += sin(_flutter_phase) * 0.5 * scale.x

	# Move toward target with additive drift
	_velocity = dir * speed + flutter_offset
	position += _velocity * delta

	# Face movement direction (optional)
	(%Sprite2D as Sprite2D).flip_h = dir.x < 0

func _hover_motion(delta: float) -> void:
	_arrive_timer -= delta
	if _arrive_timer <= 0:
		_is_hovering = false
		_target_index = (_target_index + 1) % _attractors.size()
		return

	# Gentle hovering loop
	var hover_offset := Vector2(
		sin(_timer * 2.0),
		cos(_timer * 3.5)
	) * 2.5 * scale.x

	position += hover_offset * delta

func _animate(delta: float) -> void:
	var frame_count := (%Sprite2D as Sprite2D).hframes * (%Sprite2D as Sprite2D).vframes
	_accum += delta * anim_speed * _frame_dir
	var next_frame := floori(_accum)
	if next_frame < 0:
		next_frame = 0
		_frame_dir = 1
	elif next_frame > frame_count - 1:
		next_frame = frame_count - 1
		_frame_dir = -1
	(%Sprite2D as Sprite2D).frame = next_frame

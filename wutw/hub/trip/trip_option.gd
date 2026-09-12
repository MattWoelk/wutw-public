@tool
class_name TripOption
extends UkiyoeButton

@export var past_run: PastRun:
	set(value):
		past_run = value
		if is_node_ready():
			_update()

func _ready() -> void:
	if not Utils.is_in_editor():
		if not Utils.is_compatibility_renderer():
			material = load('res://hub/trip/trip_option_button_mat.tres').duplicate()
	super._ready()
	assert(past_run or Utils.is_in_editor())
	_update()

func _process(delta: float) -> void:
	super._process(delta)
	if not Utils.is_in_editor():
		var current_state_variant: Variant
		if Utils.is_compatibility_renderer():
			current_state_variant = (material as ShaderMaterial).get_shader_parameter('state')
		else:
			current_state_variant = get_instance_shader_parameter('state')
		var state := current_state_variant as float if current_state_variant else 0.0
		state = clampf(state, -1, 2)  # If GPU buffers get overfilled, these can get nonsense data.
		var offset := 2.0 * absf(state - 1.0)
		(%Offset as Control).position.y = offset

func _update() -> void:
	if not past_run:
		return
	(%NameLabel as Label).text = past_run.get_shard_display_name()
	(%TypeLabel as Label).text = tr(past_run.shard_type.name) if past_run.shard_type else ''

	(material as ShaderMaterial).set_shader_parameter('decor_tex', past_run.shard_type.illustration if past_run.shard_type else load('res://visuals/transparent.png'))

@tool
class_name ShardTypeButton
extends UkiyoeButton

@export var shard_type: ShardType:
	set(value):
		shard_type = value
		_update()
@export var materials: Dictionary[ShardType.Tier, ShaderMaterial]
@export var materials_compatibility: Dictionary[ShardType.Tier, ShaderMaterial]

var _tooltip_attached: bool

func _ready() -> void:
	super._ready()
	if not Utils.is_in_editor():
		if Utils.is_compatibility_renderer():
			material = materials_compatibility[shard_type.tier].duplicate()
			(material as ShaderMaterial).set_shader_parameter('background_offset', Vector2(randf(), randf()))
		else:
			material = materials[shard_type.tier]
			set_instance_shader_parameter('background_offset', Vector2(randf(), randf()))

		_update()
		GlobalSaveGame.changed.connect(_update)

func _process(delta: float) -> void:
	super._process(delta)
	if not Utils.is_in_editor():
		var current_state_variant : Variant
		if Utils.is_compatibility_renderer():
			current_state_variant = (material as ShaderMaterial).get_shader_parameter('state')
		else:
			current_state_variant = get_instance_shader_parameter('state')
		var state := current_state_variant as float if current_state_variant else 0.0
		state = clampf(state, -1, 2)  # If GPU buffers get overfilled, these can get nonsense data.
		var offset := 2.0 * absf(state - 1.0)
		(%Offset as Control).position.y = offset

func _update() -> void:
	if not shard_type or not is_node_ready():
		return
	text = tr(shard_type.name)
	if GlobalSaveGame.is_shard_type_unlocked(shard_type):
		var progress := GlobalSaveGame.get_shard_type_progress(shard_type)
		var completed := progress.get_num_histories_completed()
		var seen := progress.get_num_histories_seen()
		(%ProgressBar as UkiyoeProgressBar).value = completed
		(%ProgressBar as UkiyoeProgressBar).max_value = shard_type.history.size()
		(%ProgressBar as Control).visible = true
		(%NewIcon as Control).visible = completed > seen
		if (%NewIcon as Control).visible and not _tooltip_attached:
			GlobalTooltipSystem.attach(self, func() -> String: return tr('New history fragment!'),
				[Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.ABOVE],
				[Tooltip.Alignment.CENTERED, Tooltip.Alignment.BEGIN])
			_tooltip_attached = true
		elif not (%NewIcon as Control).visible and _tooltip_attached:
			GlobalTooltipSystem.detach(self)
			_tooltip_attached = false
		(%PinnedIcon as Control).visible = false
	else:
		(%ProgressBar as Control).visible = false
		(%NewIcon as Control).visible = false
		(%PinnedIcon as Control).visible = GlobalSaveGame.get_pinned_shard_type() == shard_type

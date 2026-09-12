class_name Tutorial_HauntingScaling
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().signals.foray_started.connect(_on_stage_started)

func stop_listening() -> void:
	Utils.get_active_run().signals.foray_started.disconnect(_on_stage_started)

func _on_stage_started() -> void:
	if _get_scaled_haunting():
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	await run.get_tree().create_timer(1.5).timeout  # Let stage UI finish animating.

	var haunting := _get_scaled_haunting()
	var text := tr('''
This <term:haunting> has extra <term_lower:aspect_slot>s.

<term:haunting>s increase in difficulty as you gain more <term_lower:bonus>s. This particular <term_lower:haunting> gains an extra slot for every %d %s the shard produces.

The chance of encountering any <term_lower:haunting> in a <term_lower:spot> increases by 1%% for every %d of total shard yields.
''').strip_edges() % [
	run.scaling.haunting_bonus_per_slot,
	haunting.haunting_type.scaling_bonus_type.get_term_tag(),
	run.scaling.haunting_bonus_per_extra_chance,
]

	var stage := run.get_current_stage()
	stage.ensure_slot_visible(haunting.get_aspect_slots()[0])
	_outline_controls([haunting])
	_show_tooltip(haunting, text, [Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.RIGHT])

func get_skip_id() -> String:
	return 'haunting_scaling'

func _get_scaled_haunting() -> HauntingBase:
	var hauntings := Utils.get_active_run().get_current_stage().get_hauntings()
	for haunting in hauntings:
		if haunting.get_aspect_slots().size() > haunting.haunting_type.base_aspect_types.size():
			return haunting
	return null

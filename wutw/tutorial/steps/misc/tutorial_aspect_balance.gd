class_name Tutorial_AspectBalance
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().state_changed.connect(_on_state_changed)

func stop_listening() -> void:
	Utils.get_active_run().state_changed.disconnect(_on_state_changed)

func _on_state_changed() -> void:
	var run := Utils.get_active_run()
	if run.get_state() == RunData.State.STAGE_CARD_REWARD:
		var aspect_counts: Dictionary[AspectType, int]
		for card_type in run.get_deck_cards():
			for aspect_type in card_type.aspects:
				aspect_counts[aspect_type] = aspect_counts.get(aspect_type, 0) + 1

		var min_basic := 10
		for aspect_type: AspectType in aspect_counts:
			if not aspect_type.is_advanced:
				min_basic = min(min_basic, aspect_counts[aspect_type])

		for aspect_type: AspectType in aspect_counts:
			if aspect_type.is_advanced and aspect_counts[aspect_type] > min_basic:
				# The player has too many advanced essences. Warn them.
				ready_to_trigger.emit()
				return

func trigger() -> void:
	var run := Utils.get_active_run()
	await run.get_tree().create_timer(Utils.anim_duration(1.5)).timeout  # Wait for animation.

	var aspect_counts: Dictionary[AspectType, int]
	for card_type in run.get_deck_cards():
		for aspect_type in card_type.aspects:
			aspect_counts[aspect_type] = aspect_counts.get(aspect_type, 0) + 1

	var min_basic := 10
	var min_basic_type: AspectType
	var max_advanced := 0
	var max_advanced_type: AspectType
	for aspect_type: AspectType in aspect_counts:
		if aspect_type.is_advanced:
			if aspect_counts[aspect_type] > max_advanced:
				max_advanced = aspect_counts[aspect_type]
				max_advanced_type = aspect_type
		else:
			if aspect_counts[aspect_type] < min_basic:
				min_basic = aspect_counts[aspect_type]
				min_basic_type = aspect_type
	assert(min_basic_type)
	assert(max_advanced_type)

	var text := tr('''
Your <term_lower:card_deck> has {advanced_count} {advanced_type} <term_lower:aspect>s, \
and {basic_count} {basic_type} <term_lower:aspect>s.

{basic_type} is a <term:basic_aspect>, which is crucial for starting initial <term_lower:spot_upgrade>s.

Having too many <term:advanced_aspect>s may leave you unable to activate desired \
<term_lower:spot_upgrade>s before redrawing.
''').strip_edges().format({
	'advanced_type': max_advanced_type.get_term_tag(),
	'advanced_count': max_advanced,
	'basic_type': min_basic_type.get_term_tag(),
	'basic_count': min_basic,
})
	var card_reward_choice := run.get_current_scene() as CardRewardChoice
	assert(card_reward_choice)  # HACK: Error out and avoid marking as skipped if we managed to close the UI.
	var aspect_counters := card_reward_choice.get_node('%AspectCountersPanel') as AspectCountersPanel
	_outline_controls([aspect_counters])
	_show_tooltip(aspect_counters, text, [Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'aspect_balance'

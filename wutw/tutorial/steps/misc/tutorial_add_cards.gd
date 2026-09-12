class_name Tutorial_AddCards
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
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	await run.get_tree().create_timer(Utils.anim_duration(1.5)).timeout  # Wait for animation.

	var text := tr('''
	The <term_lower:glyph>s you choose here stay for the rest of the <term_lower:run>.

Ones with more <term_lower:aspect>s are usually better, \
but sometimes the <term_lower:card_ability>s matter more.

Pay attention to your <term_lower:aspect> counts, as keeping them balanced is important. \
Sometimes removing a weak <term_lower:glyph> is the best choice.
''').strip_edges()
	var card_reward_choice := run.get_current_scene() as CardRewardChoice
	assert(card_reward_choice)  # HACK: Error out and avoid marking as skipped if we managed to close the UI.
	var choices := card_reward_choice.get_node('%Choices') as Control
	var remove_button := card_reward_choice.get_node('%RemoveButton') as Control
	var aspect_counters := card_reward_choice.get_node('%AspectCountersPanel') as AspectCountersPanel
	_outline_controls([choices, remove_button, aspect_counters])
	_show_tooltip(aspect_counters, text, [Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'add_cards'

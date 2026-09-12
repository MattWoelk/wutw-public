class_name Tutorial_Settlements
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func get_tutorial_order() -> int:
	return 20

func _on_run_state_changed() -> void:
	if Utils.get_active_run().get_state() == RunData.State.CAPITAL_PLACEMENT:
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	var settlement := run.get_settlements()[0]
	var text := tr('''
These are your <term:settlement>s. Clicking on one of these will take you to it on the map. You can also zoom and pan the map freely during <term:harmonization>!

Each <term_lower:settlement> has a [b]<term_lower:lack>[/b] of one type of <term_lower:bonus>.

For example, your [b]%s[/b] settlement has a <term_lower:lack> of %s.
''').strip_edges() % [settlement.state.settlement_name.get_native_display_name(),
					 settlement.get_unsatisfied_lacks()[0].get_term_tag()]

	var settlements_list := run.get_map().get_node('%SettlementsList').get_node('ScrollPanel') as Control
	_outline_controls([settlements_list])
	_show_tooltip(settlements_list, text, [Tooltip.RelativeDirection.LEFT])

func get_skip_id() -> String:
	return 'harmonization_settlements'

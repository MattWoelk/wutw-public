@tool
class_name EventOutcome_ConnectSettlement
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/event_outcome_widget_message.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

func apply(_event: Event) -> EventOutcomeWidget:
	var run := Utils.get_active_run()
	var settlement := run.get_current_settlement()
	assert(settlement)
	run.signals.foray_finished.connect(func(_settlement_state: SettlementState) -> void:
		# Need to delay until we know what the lacks are.
		settlement.connect_to_capital()
	, ConnectFlags.CONNECT_ONE_SHOT)

	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_Message
	widget.text = tr('<term:connect_settlement>ed the current settlement to the <term:capital>.')
	return widget

func describe(_run: Run) -> String:
	return tr('Connect a <term:settlement> to the <term:capital>')

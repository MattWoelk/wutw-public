@tool
class_name EventOutcome_Inspiration
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/event_outcome_widget_message.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var delta: int

func apply(_event: Event) -> EventOutcomeWidget:
	assert(delta != 0)
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_Message
	widget.starting.connect(func() -> void:
		var actual_change := Utils.get_active_run().modify_inspiration(
			delta, Run.InspirationChangeReason.EVENT)
		if delta < 0 and Utils.ensure(actual_change <= 0):
			widget.text = tr('%d <term_lower:inspiration> lost.') % -actual_change
		else:
			widget.text = tr('%d <term_lower:inspiration> restored.') % actual_change
	)
	return widget

func describe(_run: Run) -> String:
	if delta > 0:
		return tr('Restore %d <term_lower:inspiration>') % delta
	else:
		return tr('Lose %d <term_lower:inspiration>') % -delta

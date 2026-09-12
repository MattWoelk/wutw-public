@tool
class_name EventOutcome_Insights
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/event_outcome_widget_message.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var amount: int

func apply(_event: Event) -> EventOutcomeWidget:
	assert(amount > 0)
	Utils.get_active_run().grant_insights(amount)
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_Message
	widget.text = tr('%d <term:insight>s gained.') % amount
	return widget

func describe(_run: Run) -> String:
	return tr('Gain %d <term_lower:insight>s') % amount

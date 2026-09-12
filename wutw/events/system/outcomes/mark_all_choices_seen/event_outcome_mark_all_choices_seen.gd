@tool
class_name EventOutcome_MarkAllChoicesSeen
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/event_outcome_widget_message.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var seen_event: Event

func apply(event: Event) -> EventOutcomeWidget:
	if not seen_event:
		seen_event = event
	seen_event.mark_all_choices_seen()
	return null

func describe(_run: Run) -> String:
	return ''

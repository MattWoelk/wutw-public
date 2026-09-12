@tool
class_name EventOutcome_UnlockCompanion
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/unlock_companion/event_outcome_widget_unlock_companion.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var companion: Companion

func apply(_event: Event) -> EventOutcomeWidget:
	assert(companion)
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_UnlockCompanion
	widget.companion = companion
	return widget

func describe(_run: Run) -> String:
	return tr('Unlock the %s <term:companion>') % companion.get_term_tag()

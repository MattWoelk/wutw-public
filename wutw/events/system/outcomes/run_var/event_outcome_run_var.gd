@tool
class_name EventOutcome_RunVar
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/event_outcome_widget_message.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var run_var: RunVars.Var
@export var delta: int
@export var preview_description: String
@export var outcome_description: String

func apply(event: Event) -> EventOutcomeWidget:
	if not outcome_description:
		push_warning('Event run_var outcome has no outcome_description. Event ID: ' + event.event_id)
	var guid := Utils.generate_guid()
	Utils.get_active_run().get_vars().add_modifier(run_var, delta, guid)
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_Message
	widget.text = tr(outcome_description)
	return widget

func describe(_run: Run) -> String:
	if not preview_description:
		push_warning('Event run_var outcome has no preview_description.')
	return tr(preview_description)

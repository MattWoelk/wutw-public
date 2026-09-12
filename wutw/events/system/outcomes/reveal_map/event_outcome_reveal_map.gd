@tool
class_name EventOutcome_RevealMap
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/event_outcome_widget_message.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

func apply(_event: Event) -> EventOutcomeWidget:
	Utils.get_active_run().get_map().clear_all_fow()
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_Message
	widget.text = tr('The map of the shard has been revealed.')
	return widget

func describe(_run: Run) -> String:
	return tr('Reveal the whole map')

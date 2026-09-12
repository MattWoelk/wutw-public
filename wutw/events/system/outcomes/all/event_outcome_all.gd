@tool
class_name EventOutcome_All
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/all/event_outcome_widget_all.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var suboutcomes: Array[EventOutcome]

func apply(event: Event) -> EventOutcomeWidget:
	var widgets: Array[EventOutcomeWidget]

	for outcome in suboutcomes:
		var result := outcome.apply(event)
		if result is EventOutcomeWidget_All:
			widgets.append_array((result as EventOutcomeWidget_All).widgets)
		elif result:
			widgets.append(result)

	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_All
	widget.widgets = widgets
	return widget

func describe(run: Run) -> String:
	var texts: Array[String]
	for outcome in suboutcomes:
		var description := outcome.describe(run)
		if description:
			texts.append(description)
	return tr(', ').join(texts)

class_name EventOutcomeWidget_All
extends EventOutcomeWidget

@export var widgets: Array[EventOutcomeWidget]

func _ready() -> void:
	Utils.ensure(not widgets.is_empty())
	for widget in widgets:
		(%VBoxContainer as VBoxContainer).add_child(widget)
		await widget.finished

	finished.emit()

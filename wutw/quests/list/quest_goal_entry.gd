@tool
class_name QuestGoalEntry
extends HBoxContainer

@export var text: String:  # Already translated.
	set(value):
		text = value
		if is_node_ready():
			_update()
@export var completed: bool = false:
	set(value):
		completed = value
		if is_node_ready():
			_update()
@export var failed: bool = false:
	set(value):
		failed = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update()
	Utils._scale_font_size(%Text as MarkedUpLabel, true, 16)

func _update() -> void:
	if failed:
		(%CompletionMark as Control).visible = false
		(%InProgressMark as Control).visible = false
		(%FailedMark as Control).visible = true
		modulate.a = 1
	elif completed:
		(%CompletionMark as Control).visible = true
		(%InProgressMark as Control).visible = false
		(%FailedMark as Control).visible = false
		modulate.a = 0.6
	else:
		(%CompletionMark as Control).visible = false
		(%InProgressMark as Control).visible = true
		(%FailedMark as Control).visible = false
		modulate.a = 1
	(%Text as MarkedUpLabel).set_markedup_text(text, MarkedUpLabel.LinkMode.LINK)

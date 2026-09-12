@tool
class_name BonusProgress
extends HBoxContainer

@export var bonus_type: BonusType:
	set(value):
		bonus_type = value
		if is_node_ready():
			_update()
@export var goal_value: int = 10:
	set(value):
		goal_value = value
		if is_node_ready():
			_update()
@export var current_value: int = 4:
	set(value):
		current_value = value
		if is_node_ready():
			_update()
@export var custom_icon_size: Vector2 = Vector2.ZERO:
	set(value):
		custom_icon_size = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update()
	if not Utils.is_in_editor():
		GlobalContextHighlight.request_on_hover(ContextHighlight.bonuses(self, [bonus_type]))

func _update() -> void:
	(%Bonus as Bonus).bonus_type = bonus_type
	(%Bonus as Bonus).custom_minimum_size = custom_icon_size
	(%ProgressBar as UkiyoeProgressBar).max_value = goal_value
	(%ProgressBar as UkiyoeProgressBar).value = abs(current_value)
	(%ProgressBar as UkiyoeProgressBar).is_negative = current_value < 0
	(%ProgressBar as UkiyoeProgressBar).font_size = custom_icon_size.y / 2

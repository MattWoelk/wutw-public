@tool
class_name BonusCounter
extends HBoxContainer

@export var bonus_type: BonusType:
	set(value):
		if bonus_type == value:
			return
		bonus_type = value
		if is_node_ready():
			_update()
@export var current_value: int = 0:
	set(value):
		if current_value == value:
			return
		current_value = value
		if is_node_ready():
			_update()
@export var label_first: bool = false:
	set(value):
		if label_first == value:
			return
		label_first = value
		if is_node_ready():
			_update()
@export var display_as_delta: bool = false:
	set(value):
		if display_as_delta == value:
			return
		display_as_delta = value
		if is_node_ready():
			_update()
@export var highlight_type: Bonus.HighlightType = Bonus.HighlightType.NONE:
	set(value):
		if highlight_type == value:
			return
		highlight_type = value
		if is_node_ready():
			_update()
@export var emit_request: bool = false

func _ready() -> void:
	_update()
	if emit_request and not Utils.is_in_editor():
		GlobalContextHighlight.request_on_hover(ContextHighlight.bonuses(self, [bonus_type]))

func get_bonus() -> Bonus:
	return %Bonus as Bonus

func _get_minimum_size() -> Vector2:
	return Vector2(32, 24)

func _update() -> void:
	if not bonus_type:
		return
	(%Bonus as Bonus).bonus_type = bonus_type
	(%Bonus as Bonus).highlight_type = highlight_type
	var label := %Label as Label
	if display_as_delta:
		label.text = '%+d' % current_value
		label.add_theme_constant_override('outline_size', 5)
	else:
		label.text = '%d' % current_value
		label.add_theme_constant_override('outline_size', 0)

	if highlight_type == Bonus.HighlightType.POSITIVE:
		var green := Color.GREEN if display_as_delta else Color.DARK_GREEN
		label.add_theme_color_override('font_color', green if current_value >= 0 else Color.RED)
	elif highlight_type == Bonus.HighlightType.NEGATIVE:
		label.add_theme_color_override('font_color', Color.BLACK if current_value >= 0 else Color.RED)
	else:
		label.add_theme_color_override('font_color', Color.BLACK if current_value >= 0 else Color.RED)

	if label_first:
		label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
		move_child(label, 0)
	else:
		label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		move_child(label, 1)

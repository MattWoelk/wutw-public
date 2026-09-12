@tool
class_name ArtTimeline
extends PanelContainer

@export var min_year: int = 800:
	set(value):
		min_year = value
		_update()
@export var max_year: int = 2026:
	set(value):
		max_year = value
		_update()
@export var start_year: int = 1930:
	set(value):
		start_year = value
		_update()
@export var end_year: int = 1950:
	set(value):
		end_year = value
		_update()

func _ready() -> void:
	await get_tree().process_frame  # Let size update.
	_update()

func _update() -> void:
	if not is_node_ready():
		return
	var year_range := float(max_year - min_year)
	var start_relative := maxf(0, (start_year - min_year) / year_range)
	var end_relative := minf(1, (end_year - min_year) / year_range)
	var line_size := (%BaseLine as Control).size

	(%StartBracketLabel as Label).position.x = start_relative * line_size.x
	(%StartBracketLabel as Control).visible = start_year > 0
	(%EndBracketLabel as Label).position.x = end_relative * line_size.x
	(%EndBracketLabel as Control).visible = start_year > 0

	(%StartLabel as Label).text = '%d' % start_year
	(%StartLabel as Label).position.x = start_relative * line_size.x - (%StartLabel as Label).size.x / 2
	(%StartLabel as Label).visible = start_year > 0

	(%EndLabel as Label).text = '%d' % end_year
	(%EndLabel as Label).visible = end_year > 0 and start_year != end_year
	(%EndLabel as Label).position.x = end_relative * line_size.x - (%EndLabel as Label).size.x / 2

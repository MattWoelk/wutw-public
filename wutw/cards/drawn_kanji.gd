@tool
class_name DrawnKanji
extends Control

const STROKE_DATA_CANVAS_SIZE := 109.0

@export var shape: KanjiShape:
	set(value):
		shape = value
		if is_node_ready():
			_update()

@export var line_width := 10.0
@export var color := Color.BLACK
@export var width_curve: Curve
@export var line_texture: Texture2D

func _ready() -> void:
	_update()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update()

func _update() -> void:
	Utils.clear_node(self)
	if shape:
		for stroke in _rescale_shape().stroke_shapes:
			_add_line().points = stroke.points

func _rescale_shape() -> KanjiShape:
	var ratio := minf(size.x, size.y) / STROKE_DATA_CANVAS_SIZE
	var result := shape.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as KanjiShape
	for stroke_shape in result.stroke_shapes:
		for i in stroke_shape.points.size():
			stroke_shape.points[i] *= ratio
	return result

func _add_line() -> Line2D:
	var line := Line2D.new()
	line.width = line_width
	line.default_color = color
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.width_curve = width_curve
	line.antialiased = true
	line.texture = line_texture
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	line.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	add_child(line)
	return line

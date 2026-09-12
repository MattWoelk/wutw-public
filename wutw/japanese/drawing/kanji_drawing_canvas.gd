@tool
class_name KanjiDrawingCanvas
extends Control

signal error_start
signal error_end
signal stroke_started
signal succeeded(shape: KanjiShape)

const STROKE_DATA_CANVAS_SIZE := 109.0
const DRAW_DISTANCE := 2.0
const RESAMPLE_POINT_COUNT := 60
const START_TOLERANCE := 10.0
const MAX_DISTANCE_FACTOR := 0.5
const JUDGING_TOLERANCE := 50.0
const MIN_SUCCESS_SCORE := 0.4
const SMOOTHING_ALPHA := 0.7

enum HintLevel { START_POINT, DASHED, FULL }
enum State { BLANK, PREVIEW, STARTED, FINISHED }

@export var line_width := 10.0
@export var color_drawing := Color.DIM_GRAY
@export var color_correct := Color.BLACK
@export var color_hint := Color(0.831, 0.439, 0.298, 0.847)
@export var dash_texture: Texture2D
@export var width_curve: Curve

var _shape: KanjiShape
var _current_stroke_index := 0
var _start_point_hint: Line2D
var _active_line: Line2D
var _hint_level := HintLevel.START_POINT
var _state := State.BLANK
var _last_raw_point := Vector2(0, 0)

func show_preview(shape: KanjiShape) -> void:
	_shape = _rescale_shape(shape)

	_state = State.PREVIEW
	Utils.clear_node(self)
	for stroke in _shape.stroke_shapes:
		_add_line(color_correct).points = stroke.points

func restart_drawing(shape: KanjiShape) -> void:
	_shape = _rescale_shape(shape)

	_state = State.STARTED
	Utils.clear_node(self)
	_current_stroke_index = 0
	_start_stroke()

func _on_gui_input(event: InputEvent) -> void:
	if _state != State.STARTED:
		return

	var mouse_button_event := event as InputEventMouseButton
	if mouse_button_event:
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			if (_active_line != null) != mouse_button_event.pressed:
				if mouse_button_event.pressed:
					if _try_start_drawing(mouse_button_event.position):
						_last_raw_point = _active_line.points[0]
				else:
					_end_drawing()

	if _active_line:
		var mouse_move_event := event as InputEventMouseMotion
		if mouse_move_event:
			if _last_raw_point.distance_to(mouse_move_event.position) >= DRAW_DISTANCE:
				var smoothed := lerp(_active_line.points[-1], mouse_move_event.position, SMOOTHING_ALPHA) as Vector2
				_active_line.add_point(smoothed)
				_last_raw_point = mouse_move_event.position

func _start_stroke() -> void:
	_hint_level = HintLevel.START_POINT
	_show_hint()
	stroke_started.emit()

func _show_hint() -> void:
	if _start_point_hint:
		_start_point_hint.queue_free()
	_start_point_hint = _add_line(color_hint)
	var correct_points := _get_current_stroke_points()
	match _hint_level:
		HintLevel.START_POINT:
			_start_point_hint.add_point(correct_points[0])
			_start_point_hint.add_point(correct_points[0] + 3 * (correct_points[1] - correct_points[0]).normalized())
			_start_point_hint.texture = null
		HintLevel.DASHED:
			_start_point_hint.points = correct_points
			_start_point_hint.texture = dash_texture
		HintLevel.FULL:
			_start_point_hint.points = correct_points
			_start_point_hint.texture = null

func _get_current_stroke_points() -> Array[Vector2]:
	return _shape.stroke_shapes[_current_stroke_index].points

func _try_start_drawing(start_point: Vector2) -> bool:
	Utils.ensure(not _active_line)
	var correct_start_point := _get_current_stroke_points()[0]
	if start_point.distance_to(correct_start_point) > START_TOLERANCE:
		error_start.emit()
		return false
	_active_line = _add_line(color_drawing)
	_active_line.add_point(correct_start_point)  # Snap to correct start.
	return true

func _end_drawing() -> void:
	assert(_active_line)
	var correct_points := _get_current_stroke_points()
	var score := _judge_stroke(
		_active_line.points, correct_points, RESAMPLE_POINT_COUNT, JUDGING_TOLERANCE)
	if score >= MIN_SUCCESS_SCORE:
		_active_line.default_color = color_correct
		_active_line = null
		_current_stroke_index += 1
		if _current_stroke_index >= _shape.stroke_shapes.size():
			_start_point_hint.queue_free()
			_state = State.FINISHED
			succeeded.emit(_get_drawn_shape())
		else:
			_start_stroke()
	else:
		_active_line.queue_free()
		_active_line = null
		if _hint_level < HintLevel.FULL:
			_hint_level = (_hint_level + 1) as HintLevel
			_show_hint()
		error_end.emit()

func _rescale_shape(shape: KanjiShape, to_canvas: bool = true) -> KanjiShape:
	var ratio := minf(size.x, size.y) / STROKE_DATA_CANVAS_SIZE
	shape = shape.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	for stroke_shape in shape.stroke_shapes:
		for i in stroke_shape.points.size():
			if to_canvas:
				stroke_shape.points[i] *= ratio
			else:
				stroke_shape.points[i] /= ratio
	return shape

func _add_line(color: Color) -> Line2D:
	var line := Line2D.new()
	line.width = line_width
	line.default_color = color
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.width_curve = width_curve
	line.antialiased = true
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(line)
	return line

static func _judge_stroke(user_points: Array[Vector2], correct_points: Array[Vector2], target_n: int, tolerance: float) -> float:
	user_points = _resample_points(user_points, target_n)
	correct_points = _resample_points(correct_points, target_n)

	var total_distance := 0.0
	var max_distance := 0.0
	var n := correct_points.size()
	for i in range(n):
		var user_point := user_points[i]
		var correct_point := correct_points[i]
		var distance := user_point.distance_to(correct_point)
		max_distance = maxf(max_distance, distance)
		total_distance += distance

	var average_error := maxf(max_distance / MAX_DISTANCE_FACTOR, total_distance / n)
	var score := 1.0 - (average_error / tolerance)
	return maxf(0.0, minf(1.0, score))

static func _resample_points(points: Array[Vector2], target_n: int) -> Array[Vector2]:
	if not Utils.ensure(not points.is_empty()):
		return []

	var resampled: Array[Vector2]
	if points.size() == 1:
		for i in target_n:
			resampled.append(points[0])
		return resampled

	var total_length := 0.0
	for i in points.size() - 1:
		total_length += points[i].distance_to(points[i+1])
	var segment_length := total_length / (target_n - 1)

	var src_points: Array[Vector2] = points.duplicate()
	var current_distance := 0.0
	resampled.append(points[0])
	var i := 1
	while i < src_points.size():
		var p1 := src_points[i - 1]
		var p2 := src_points[i]
		var d := p1.distance_to(p2)

		if current_distance + d >= segment_length:
			# Current segment goes beyond segment_length; cut.
			var t := (segment_length - current_distance) / d
			var new_point := p1 + t * (p2 - p1)
			resampled.append(new_point)
			src_points.insert(i, new_point)
			current_distance = 0.0
		else:
			current_distance += d
		i += 1

	# Floating point shenanigans.
	if resampled.size() < target_n:
		resampled.append(points[-1])
	elif resampled.size() > target_n:
		resampled.resize(target_n)

	return resampled

func _get_drawn_shape() -> KanjiShape:
	var result := KanjiShape.new()
	for line: Line2D in get_children():
		var stroke := StrokeShape.new()
		stroke.points.assign(line.points)
		result.stroke_shapes.append(stroke)
	return _rescale_shape(result, false)

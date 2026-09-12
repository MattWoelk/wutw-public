@tool
class_name KanjiShape
extends Resource

@export var stroke_shapes: Array[StrokeShape]

func encode() -> Array:
	var result: Array[Array]
	for stroke in stroke_shapes:
		var points: Array
		for point in stroke.points:
			points.append(int(point.x))
			points.append(int(point.y))
		result.append(points)
	return result

static func decode(input: Array) -> KanjiShape:
	var result := KanjiShape.new()
	for stroke_points: Array in input:
		var stroke := StrokeShape.new()
		for i in range(0, stroke_points.size(), 2):
			stroke.points.append(Vector2(stroke_points[i] as int, stroke_points[i + 1] as int))
		result.stroke_shapes.append(stroke)
	return result

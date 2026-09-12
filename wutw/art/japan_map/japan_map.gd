@tool
class_name JapanMap
extends Node2D

signal clicked(point: Vector2)  # Only if hovering a province.

@export var poly_material: Material:
	set(value):
		poly_material = value
		if Utils.is_in_editor():
			for child in get_children():
				if child is JapanProvinceArea:
					(child as JapanProvinceArea).poly_material = poly_material
@export var poly_material_highlighted: Material
@export var poly_material_hovered: Material
@export var poly_material_hovered_highlighted: Material
@export var line_color: Color = Color(0.016, 0.243, 0.478, 0.5):
	set(value):
		line_color = value
		if Utils.is_in_editor():
			for child in get_children():
				if child is JapanProvinceArea:
					(child as JapanProvinceArea).line_color = line_color
@export var line_color_highlighted: Color = Color(0.016, 0.243, 0.478)
@export var line_width: float = 1.0:
	set(value):
		line_width = value
		if Utils.is_in_editor():
			for child in get_children():
				if child is JapanProvinceArea:
					(child as JapanProvinceArea).line_width = line_width
@export var selected_provice: JapanProvinceArea.Province:
	set(value):
		selected_provice = value
		_update_highlighted()

var _hovered_area: JapanProvinceArea

func _ready() -> void:
	for child in get_children():
		var area := child as JapanProvinceArea
		if area:
			area.hovered.connect(_on_province_entered.bind(area))
			area.unhovered.connect(_on_province_exited.bind(area))

func _input(event: InputEvent) -> void:
	if not _hovered_area:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	clicked.emit(to_local(mouse_event.position))

func get_distance_to(point: Vector2, target_province: JapanProvinceArea.Province) -> float:
	Utils.ensure(target_province != JapanProvinceArea.Province.UNSPECIFIED)
	target_province = _get_effective_province(target_province)
	for child in get_children():
		var province_node := child as JapanProvinceArea
		if province_node and province_node.province == target_province:
			var dist := INF
			for grandchild in province_node.get_children():
				if grandchild is Polygon2D:
					dist = minf(dist, _get_distance_point_poly(
						point - province_node.position, grandchild as Polygon2D))
			return dist
	Utils.ensure(false)
	return INF

func _update_highlighted() -> void:
	var effective_selected_province := _get_effective_province(selected_provice)

	for child in get_children():
		var area := child as JapanProvinceArea
		if area:
			if area.province == effective_selected_province:
				if _hovered_area == area:
					area.poly_material = poly_material_hovered_highlighted
				else:
					area.poly_material = poly_material_highlighted
				area.line_color = line_color_highlighted
			else:
				if _hovered_area == area:
					area.poly_material = poly_material_hovered
				else:
					area.poly_material = poly_material
				area.line_color = line_color

	(%LegendLabel as Label).text = JapanProvinceArea.new().get_province_label(selected_provice)

func _on_province_entered(area: JapanProvinceArea) -> void:
	_hovered_area = area
	_update_highlighted()

func _on_province_exited(area: JapanProvinceArea) -> void:
	if _hovered_area == area:
		_hovered_area = null
		_update_highlighted()

func _get_effective_province(province: JapanProvinceArea.Province) -> JapanProvinceArea.Province:
	if province == JapanProvinceArea.Province.SPECIAL_KYOTO:
		return JapanProvinceArea.Province.YAMASHIRO
	elif province == JapanProvinceArea.Province.SPECIAL_EDO:
		return JapanProvinceArea.Province.MUSASHI
	elif province == JapanProvinceArea.Province.SPECIAL_TOKYO:
		return JapanProvinceArea.Province.MUSASHI
	elif province == JapanProvinceArea.Province.SPECIAL_HOKKAIDOU:
		return JapanProvinceArea.Province.EZO
	elif province == JapanProvinceArea.Province.SPECIAL_YAMANASHI:
		return JapanProvinceArea.Province.KAI
	elif province == JapanProvinceArea.Province.SPECIAL_OSAKA:
		return JapanProvinceArea.Province.SETTSU
	elif province == JapanProvinceArea.Province.SPECIAL_NARA:
		return JapanProvinceArea.Province.YAMATO
	else:
		return province

func _get_distance_point_poly(point: Vector2, polygon: Polygon2D) -> float:
	Utils.ensure(polygon.offset.is_zero_approx())
	point -= polygon.position
	var points := polygon.polygon
	if not Utils.ensure(points.size() >= 3):
		return 0.0

	if Geometry2D.is_point_in_polygon(point, points):
		return 0.0

	var min_distance := INF
	var point_count := points.size()
	for i in range(point_count):
		var closest := Geometry2D.get_closest_point_to_segment(
			point, points[i], points[(i + 1) % point_count])
		var dist := point.distance_to(closest)
		if dist < min_distance:
			min_distance = dist

	return min_distance

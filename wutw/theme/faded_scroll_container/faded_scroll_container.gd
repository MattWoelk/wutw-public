@tool
class_name FadedScrollContainer
extends ScrollContainer

@export var fade_size: float = 16.0:
	set(value):
		fade_size = value
		queue_redraw()
@export var fade_enabled: bool = true:
	set(value):
		fade_enabled = value
		clip_children = CanvasItem.CLIP_CHILDREN_ONLY if fade_enabled else CanvasItem.CLIP_CHILDREN_DISABLED
		queue_redraw()
@export var fade_even_if_no_bar: bool = false:
	set(value):
		fade_even_if_no_bar = value
		queue_redraw()

func _ready() -> void:
	fade_enabled = fade_enabled  # Trigger clip setting update.

	resized.connect(queue_redraw)

	var v_scroll := get_v_scroll_bar()
	v_scroll.value_changed.connect(func(_value: float) -> void: queue_redraw())
	v_scroll.changed.connect(queue_redraw)

	var h_scroll := get_h_scroll_bar()
	h_scroll.value_changed.connect(func(_value: float) -> void: queue_redraw())
	h_scroll.changed.connect(queue_redraw)

func _draw() -> void:
	if not fade_enabled:
		return

	var h_scroll := get_h_scroll_bar()
	var v_scroll := get_v_scroll_bar()

	var h_fade_size := minf(fade_size, size.x / 2.0) if h_scroll.visible else 0.0
	var v_fade_size := minf(fade_size, size.y / 2.0) if v_scroll.visible or fade_even_if_no_bar else 0.0

	# Top
	if v_scroll.visible or fade_even_if_no_bar:
		var top_transparency := clampf(v_scroll.value / v_fade_size, 0, 1)
		var top_rect := Rect2(0, 0, size.x, v_fade_size)
		_draw_v_gradient(top_rect, Color(1, 1, 1, 1.0 - top_transparency), Color.WHITE)

	# Left
	if h_scroll.visible:
		var left_transparency := clampf(h_scroll.value / h_fade_size, 0, 1)
		var left_rect := Rect2(0, 0, h_fade_size, size.y)
		_draw_h_gradient(left_rect, Color(1, 1, 1, 1.0 - left_transparency), Color.WHITE)

	# Middle
	var mid_rect := Rect2(h_fade_size, v_fade_size, size.x - h_fade_size * 2, size.y - v_fade_size * 2)
	draw_rect(mid_rect, Color.WHITE)

	# Bottom
	if v_scroll.visible or fade_even_if_no_bar:
		var bottom_transparency := clampf(((v_scroll.max_value - v_scroll.page) - v_scroll.value) / v_fade_size, 0, 1)
		var bot_rect := Rect2(0, size.y - v_fade_size, size.x, v_fade_size)
		_draw_v_gradient(bot_rect, Color.WHITE, Color(1, 1, 1, 1.0 - bottom_transparency))

	# Right
	if h_scroll.visible:
		var right_transparency := clampf(((h_scroll.max_value - h_scroll.page) - h_scroll.value) / h_fade_size, 0, 1)
		var right_rect := Rect2(size.x - h_fade_size, 0, h_fade_size, size.y)
		_draw_h_gradient(right_rect, Color.WHITE, Color(1, 1, 1, 1.0 - right_transparency))

	# Scrollbar
	if v_scroll.visible:
		draw_rect(v_scroll.get_rect(), Color.WHITE)
	if h_scroll.visible:
		draw_rect(h_scroll.get_rect(), Color.WHITE)

func _draw_v_gradient(rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	var pts := PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	])
	var colors := PackedColorArray([
		top_color,
		top_color,
		bottom_color,
		bottom_color,
	])
	draw_polygon(pts, colors)

func _draw_h_gradient(rect: Rect2, left_color: Color, right_color: Color) -> void:
	var pts := PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	])
	var colors := PackedColorArray([
		left_color,
		right_color,
		right_color,
		left_color,
	])
	draw_polygon(pts, colors)

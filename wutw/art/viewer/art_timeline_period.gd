class_name ArtTimelinePeriod
extends Panel

@export var era_name: String
@export var start_year: int
@export var end_year: int
@export_multiline var tooltip: String

var _highlight_tween: Tween

func _ready() -> void:
	var tooltip_anchor := Control.new()
	add_child(tooltip_anchor)

	tooltip_anchor.position = Vector2(0, -20)
	tooltip_anchor.size = size + Vector2(0, 40)
	tooltip_anchor.mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_anchor.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_anchor.mouse_entered.connect(_highlight)
	tooltip_anchor.mouse_exited.connect(_unhighlight)

	GlobalTooltipSystem.attach(tooltip_anchor, _make_tooltip_text,
		[Tooltip.RelativeDirection.ABOVE], [Tooltip.Alignment.CENTERED])

func _make_tooltip_text() -> String:
	return tr('<header_font_size>[b]The {name} Period ({start}–{end})[/b][/font_size]\n\n{description}\n ').format({
		'name': tr(era_name),
		'start': start_year,
		'end': str(end_year) if end_year < 2026 else 'Present',
		'description': tr(tooltip),
	})

func _highlight() -> void:
	if _highlight_tween:
		_highlight_tween.kill()
	_highlight_tween = create_tween()
	_highlight_tween.tween_property(self, 'self_modulate', Color(1.3, 1.3, 1.3, 1.3), 0.3)
	_highlight_tween.play()

func _unhighlight() -> void:
	if _highlight_tween:
		_highlight_tween.kill()
	_highlight_tween = create_tween()
	_highlight_tween.tween_property(self, 'self_modulate', Color.WHITE, 0.3)
	_highlight_tween.play()

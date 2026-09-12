class_name HubFacility
extends Node2D

signal clicked
signal hovered
signal unhovered

const HIGHLIGHT_TIME: float = 0.25

@export_multiline var tooltip_text: String
@export var highlighted: bool:
	set(value):
		if highlighted != value:
			highlighted = value
			if highlighted:
				_highlight()
			else:
				_unhighlight()
@export var hoverable: bool = true
@export var highlight_modulate := Color(1.2, 1.2, 1.2, 1.0)

var _highlight_tween: Tween

func _ready() -> void:
	add_to_group('HubFacilities')
	if tooltip_text:
		GlobalTooltipSystem.attach(%TooltipAnchor as Control,
				_make_tooltip_text,
				[Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.ABOVE],
				[Tooltip.Alignment.CENTERED])

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not highlighted:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event or not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()

func _on_area_2d_mouse_entered() -> void:
	if hoverable:
		hovered.emit()

func _on_area_2d_mouse_exited() -> void:
	if hoverable:
		unhovered.emit()

func _highlight() -> void:
	if _highlight_tween:
		_highlight_tween.kill()
	_highlight_tween = create_tween()
	_highlight_tween.set_ease(Tween.EaseType.EASE_IN_OUT)
	_highlight_tween.tween_property(self, 'modulate', highlight_modulate, HIGHLIGHT_TIME)
	_highlight_tween.play()
	Input.set_default_cursor_shape(Input.CursorShape.CURSOR_POINTING_HAND)
	(%TooltipAnchor as Control).mouse_entered.emit()

func _unhighlight() -> void:
	if _highlight_tween:
		_highlight_tween.kill()
	_highlight_tween = create_tween()
	_highlight_tween.set_ease(Tween.EaseType.EASE_IN_OUT)
	_highlight_tween.tween_property(self, 'modulate', Color(1.0, 1.0, 1.0, 1.0), HIGHLIGHT_TIME)
	_highlight_tween.play()
	Input.set_default_cursor_shape(Input.CursorShape.CURSOR_ARROW)
	(%TooltipAnchor as Control).mouse_exited.emit()

func _make_tooltip_text() -> String:
	return tr(tooltip_text)

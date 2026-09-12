@tool
class_name CreditsIcon
extends MarginContainer

@export var icon_size: Vector2 = Vector2(48, 48):
	set(value):
		icon_size = value
		(%Icon as Control).custom_minimum_size = icon_size
		(%Icon as Control).size = icon_size
		(%HoverIcon as Control).custom_minimum_size = icon_size
		(%HoverIcon as Control).size = icon_size
@export var art_piece: ArtPiece:
	set(value):
		art_piece = value
		visible = art_piece and not (art_piece is ArtPiece_Placeholder or art_piece is ArtPiece_None)

var _tween: Tween

func _ready() -> void:
	GlobalTooltipSystem.attach(%Icon as Control, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.END])
	await get_tree().process_frame
	if not art_piece and not Utils.is_in_editor() and is_node_ready():
		push_warning('Art credit missing in node: ', get_parent(), ' (%s)' % get_parent().get_path())

func _process(_delta: float) -> void:
	var parent := get_parent() as Control
	if parent:
		size = parent.size

func _make_tooltip_text() -> String:
	assert(art_piece)
	return art_piece.get_attribution() + tr('\n\n[i]%s to learn more...[/i]') % InputPrompts.get_input_markup(
		InputPrompts.InputType.LEFT_CLICK)

func _on_icon_mouse_entered() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var duration := minf(0.5, Tooltip.DEFAULT_DELAY_TIME / GameSettings.Interface.tooltip_speed.value())
	_tween.tween_property(%HoverIcon, 'modulate:a', 1.0, duration)

func _on_icon_mouse_exited() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var duration := minf(0.5, Tooltip.DEFAULT_DELAY_TIME / GameSettings.Interface.tooltip_speed.value())
	_tween.tween_property(%HoverIcon, 'modulate:a', 0.0, duration)

func _on_icon_gui_input(event: InputEvent) -> void:
	assert(art_piece)
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			ArtViewer.open_art_resource(art_piece)

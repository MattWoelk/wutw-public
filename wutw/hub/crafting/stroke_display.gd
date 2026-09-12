@tool
class_name StrokeDisplay
extends Control

@export var stroke: Stroke:
	set(value):
		stroke = value
		if is_node_ready():
			_update()
@export var count: int = 1:
	set(value):
		count = value
		if is_node_ready():
			_update()
@export var count_required: int = -1:
	set(value):
		count_required = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.ABOVE], [Tooltip.Alignment.CENTERED])

func _update() -> void:
	(%Icon as TextureRect).texture = stroke.image if stroke else null
	var label := %CountLabel as Label
	if count_required == -1:
		label.text = '×' + str(count)
		label.add_theme_color_override('font_color', Color.BLACK)
	else:
		label.text = '%d / %d' % [count, count_required]
		label.add_theme_color_override('font_color', Color.DARK_GREEN if count >= count_required else Color.DARK_RED)

func _on_mouse_entered() -> void:
	(%PanelContainer as Control).modulate = Color.WHITE * 1.3
	GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_BUTTON_HOVER)

func _on_mouse_exited() -> void:
	(%PanelContainer as Control).modulate = Color.WHITE

func _make_tooltip_text() -> String:
	if Utils.is_in_editor():
		return ''
	var term := load('res://glossary/terms/standalone/term_stroke.tres') as Term
	return ('<header_font_size>[b]%s %s[/b][/font_size]\n\n%s' %
			[(tr(stroke.name) if stroke else '?'), term.get_term_name(false), term.get_markedup_description()])

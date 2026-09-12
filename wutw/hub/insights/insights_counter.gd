class_name InsightsCounter
extends Control

func _ready() -> void:
	_update()
	GlobalSaveGame.changed.connect(_update)
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.BEGIN])

func _update() -> void:
	(%CountLabel as Label).text = str(GlobalSaveGame.insights)

func _make_tooltip_text() -> String:
	var term := load('res://glossary/terms/standalone/term_insight.tres') as Term
	return ('<header_font_size>[b]%s[/b][/font_size]\n\n%s' %
			[term.get_term_name(true), term.get_markedup_description()])

class_name NewIndicator
extends TextureRect

func _ready() -> void:
	GlobalTooltipSystem.attach(self, func() -> String: return tr('This is a new discovery!'),
		[Tooltip.RelativeDirection.ABOVE, Tooltip.RelativeDirection.RIGHT],
		[Tooltip.Alignment.CENTERED, Tooltip.Alignment.BEGIN])

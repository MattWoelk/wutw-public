@tool
class_name PauseButton
extends UkiyoeButton

func _ready() -> void:
	super._ready()
	GlobalTooltipSystem.attach(
		self,
		func() -> String: return tr('Pause Menu'),
		[Tooltip.RelativeDirection.BELOW],
		[Tooltip.Alignment.END])

func _on_pressed() -> void:
	GlobalUI.toggle_pause_menu()

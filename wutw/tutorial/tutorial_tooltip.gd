@tool
class_name TutorialTooltip
extends Tooltip

signal continued

func _clear_extras() -> void:
	# No extras to setup, so skip parent's method.
	pass

func _ensure_extras_created() -> void:
	# No extras to setup, so skip parent's method.
	pass

func _place_extras(_direction: RelativeDirection) -> void:
	# No extras to setup, so skip parent's method.
	pass

func _get_link_mode() -> MarkedUpLabel.LinkMode:
	return MarkedUpLabel.LinkMode.LINK

func _on_continue_button_pressed() -> void:
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	continued.emit()

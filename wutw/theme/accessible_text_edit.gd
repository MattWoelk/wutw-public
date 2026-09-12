class_name AccessibleTextEdit
extends TextEdit

func _ready() -> void:
	if Utils.is_steam_deck():
		selecting_enabled = false
		drag_and_drop_selection_enabled = false
		focus_entered.connect(func() -> void:
			var rect := Utils.get_screen_rect(self)
			var left := roundi(rect.position.x * 1280 / 1920)
			var top := roundi(rect.position.y * 800 / 1080)
			var width := roundi(rect.size.x * 1280 / 1920)
			var height := roundi(rect.size.y * 800 / 1080)
			Steam.showFloatingGamepadTextInput(
				Steam.FLOATING_GAMEPAD_TEXT_INPUT_MODE_MULTIPLE_LINES, left, top, width, height)
		)
		focus_exited.connect(func() -> void:
			Steam.dismissFloatingGamepadTextInput()
		)
		Steam.floating_gamepad_text_input_dismissed.connect(func() -> void:
			release_focus()
		)

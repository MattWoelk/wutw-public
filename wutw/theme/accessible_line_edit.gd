class_name AccessibleLineEdit
extends LineEdit

func _ready() -> void:
	if Utils.is_steam_deck():
		editing_toggled.connect(func(toggled_on: bool) -> void:
			if toggled_on:
				var rect := Utils.get_screen_rect(self)
				var left := roundi(rect.position.x * 1280 / 1920)
				var top := roundi(rect.position.y * 800 / 1080)
				var width := roundi(rect.size.x * 1280 / 1920)
				var height := roundi(rect.size.y * 800 / 1080)
				Steam.showFloatingGamepadTextInput(
					Steam.FLOATING_GAMEPAD_TEXT_INPUT_MODE_SINGLE_LINE, left, top, width, height)
			else:
				Steam.dismissFloatingGamepadTextInput()
		)
		Steam.floating_gamepad_text_input_dismissed.connect(func() -> void:
			unedit()
			release_focus()
		)

class_name UkiyoeSlider
extends HSlider

func _ready() -> void:
	drag_started.connect(func() -> void:
		GlobalAudioSystem.play(AK.EVENTS.UI_MENU_SLIDER_ONESHOT)
	)
	drag_ended.connect(func(_value_changed: bool) -> void:
		GlobalAudioSystem.play(AK.EVENTS.UI_MENU_SLIDER_ONESHOT)
	)

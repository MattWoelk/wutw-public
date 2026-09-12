class_name CreditsMenu
extends Node2D

var _closing := false

func _ready() -> void:
	(%ScrollPanel as ScrollPanel).animate_unroll()

func _handle_esc() -> bool:
	close()
	return true

func close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		queue_free()

func _on_close_button_pressed() -> void:
	close()

@tool
class_name ConfirmDialog
extends Control

signal confirmed
signal canceled
signal extra_selected

@export var title: String = tr('Title')
@export var text: String = tr('Would you like to continue?')
@export var confirm_text: String = tr('Ok')
@export var cancel_text: String = tr('Cancel')
@export var extra_button_text: String = ''

static var SCENE := AsyncLoadedResource.new('res://theme/confirm_dialog/confirm_dialog.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

var _closing := false

func _ready() -> void:
	(%TitleLabel as Label).text = title
	(%TextLabel as Label).text = text
	(%ConfirmButton as Button).text = confirm_text

	if cancel_text:
		(%CancelButton as Button).text = cancel_text
		(%CancelButton as Button).visible = true
	else:
		(%CancelButton as Button).visible = false

	if extra_button_text:
		(%ExtraButton as Button).text = extra_button_text
		(%ExtraButton as Button).visible = true
	else:
		(%ExtraButton as Button).visible = false

	offset_transform_scale = Vector2.ONE * GameSettings.Interface.paragraph_font_scale.value()

	(%ScrollPanel as ScrollPanel).animate_unroll()

func _handle_esc() -> bool:
	if not (cancel_text or extra_button_text):
		if not _closing:
			_on_confirm_button_pressed()
	return true

func _close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled((%ScrollPanel as ScrollPanel), false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		queue_free()

func _on_cancel_button_pressed() -> void:
	canceled.emit()
	_close()

func _on_extra_button_pressed() -> void:
	extra_selected.emit()
	_close()

func _on_confirm_button_pressed() -> void:
	confirmed.emit()
	_close()

class_name RunSetupChoiceDialog
extends Control

signal selected(button: RunSetupButtonBase)
signal closed

@export var buttons: Array[RunSetupButtonBase]:
	set(value):
		buttons = value
		_update()
@export var title: String = tr('Select a Choice'):
	set(value):
		title = value
		if is_node_ready():
			_update()

var _closing := false

func _ready() -> void:
	_update()
	(%ScrollPanel as ScrollPanel).animate_unroll()

func _handle_esc() -> bool:
	close()
	return true

func close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled(self, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		queue_free()
		closed.emit()

func _update() -> void:
	if not is_node_ready():
		return

	(%TitleLabel as Label).text = title

	Utils.clear_node(%List)
	for button in buttons:
		button.pressed.connect(_on_button_selected.bind(button))
		%List.add_child(button)

func _on_button_selected(button: Button) -> void:
	selected.emit(button)

func _on_search_input_text_changed(query_text: String) -> void:
	for button in buttons:
		button.visible = Utils.matches_query(button.get_search_text(), query_text)

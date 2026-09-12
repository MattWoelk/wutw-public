@tool
class_name ControlBindingSetting
extends HBoxContainer

@export var action_name: String:
	set(value):
		action_name = value
		if is_node_ready():
			update()
@export var action_label: String:
	set(value):
		action_label = value
		if is_node_ready():
			update()
@export var steam_deck_default: String:
	set(value):
		steam_deck_default = value
		if is_node_ready():
			update()

func _ready() -> void:
	update()
	set_process_input(false)

func _input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if not key_event or key_event.pressed:
		return
	if key_event.physical_keycode != KEY_ESCAPE:
		var config_input_event := InputMap.action_get_events(action_name)[0] as InputEventKey
		config_input_event.physical_keycode = (key_event.physical_keycode & ~KEY_MODIFIER_MASK) as Key
		config_input_event.ctrl_pressed = key_event.ctrl_pressed
		config_input_event.alt_pressed = key_event.alt_pressed
		config_input_event.shift_pressed = key_event.shift_pressed
		config_input_event.meta_pressed = key_event.meta_pressed
		GameSettings.Controls.set_binding(action_name, config_input_event.get_physical_keycode_with_modifiers(), true)
	set_process_input(false)
	update()
	get_viewport().set_input_as_handled()

func update() -> void:
	(%Label as Label).text = tr(action_label)
	(%Label_DeckDefault as MarkedUpLabel).set_markedup_text(steam_deck_default)
	if Utils.is_steam_deck():
		(%Label_DeckDefault as MarkedUpLabel).visible = true
		(%Button as Button).visible = false
	else:
		(%Label_DeckDefault as MarkedUpLabel).visible = false
		(%Button as Button).visible = true
		var input_events := InputMap.action_get_events(action_name)
		if not input_events:
			assert(Utils.is_in_editor())
			return
		var input_event := input_events[0] as InputEventKey
		(%Button as Button).text = OS.get_keycode_string(input_event.get_physical_keycode_with_modifiers())

func _on_button_pressed() -> void:
	set_process_input(true)
	(%Button as Button).text = tr('...')

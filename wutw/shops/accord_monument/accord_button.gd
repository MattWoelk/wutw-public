@tool
class_name AccordButton
extends UkiyoeButton

const EVENT_ID := '_accord_monument'

@export var markedup_text: String:
	set(value):
		markedup_text = value
		if is_node_ready():
			_update()
@export var available: bool = true:
	set(value):
		available = value
		if is_node_ready():
			_update()
@export var save_data_var_name: String

func _ready() -> void:
	super._ready()
	_update()

func is_fulfilled() -> bool:
	assert(save_data_var_name)
	return Utils.get_active_run().get_events_state().get_bool_or_default(
		EVENT_ID, save_data_var_name, false)

func _update() -> void:
	(%MarkedUpLabel as MarkedUpLabel).set_markedup_text(markedup_text)
	if is_fulfilled():
		disabled = true
		icon = load('res://shops/accord_monument/checkmark_dark.png')
		(%MarkedUpLabel as MarkedUpLabel).modulate.a = 0.5
	else:
		disabled = not available
		icon = null
		(%MarkedUpLabel as MarkedUpLabel).modulate.a = 1

func mark_fulfilled() -> void:
	assert(save_data_var_name)
	Utils.get_active_run().get_events_state().set_bool(EVENT_ID, save_data_var_name, true)
	_update()
	GlobalSaveGame.save_game()

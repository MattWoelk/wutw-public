@tool
class_name Dropdown
extends UkiyoeButton

static var OPTION_SCENE := AsyncLoadedResource.new('res://theme/dropdown/dropdown_option.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

signal selected(item: DropdownItem)

@export var initial_items: Array[DropdownItem]

var _items: Array[DropdownItem]
var _selected_item: DropdownItem
var _mouse_blocker: Button
var _list: VBoxContainer

func _ready() -> void:
	super._ready()
	for item in initial_items:
		item.text = tr(item.text)
		_items.append(item)
	_update()

func _process(delta: float) -> void:
	super._process(delta)
	(%Label as MarkedUpLabel).anchor_left = ANCHOR_BEGIN
	(%Label as MarkedUpLabel).anchor_right = ANCHOR_END
	(%Label as MarkedUpLabel).anchor_top = ANCHOR_BEGIN
	(%Label as MarkedUpLabel).anchor_bottom = ANCHOR_END
	(%Label as MarkedUpLabel).position.x = 10
	if not Utils.is_in_editor():
		var current_state_variant: Variant
		if Utils.is_compatibility_renderer():
			current_state_variant = (material as ShaderMaterial).get_shader_parameter('state')
		else:
			current_state_variant = get_instance_shader_parameter('state')
		var state := current_state_variant as float if current_state_variant else 0.0
		var offset := 2.0 * absf(state - 1.0)
		(%Label as Control).position.y = offset
		if _list:
			var control_global_rect := Utils.get_screen_rect(self)
			_list.global_position.x = control_global_rect.position.x
			_list.global_position.y = control_global_rect.end.y
			_list.custom_minimum_size.x = control_global_rect.size.x
			_list.scale = get_global_transform().get_scale()

func _exit_tree() -> void:
	close()

func _pressed() -> void:
	open()

func clear() -> void:
	close()
	_items.clear()
	_update()

func add_item(item_text: String, item_value: Variant) -> void:  # Input already translated.
	var item := DropdownItem.new()
	item.text = item_text
	item.value = item_value
	_items.append(item)
	close()
	_update()

func open() -> void:
	_mouse_blocker = Button.new()
	_mouse_blocker.self_modulate.a = 0
	_mouse_blocker.custom_minimum_size = Vector2(1920, 1080)
	_mouse_blocker.pressed.connect(_mouse_blocker_clicked)
	GlobalUI.add_layer_content(_mouse_blocker, UI.Layer.MODAL)
	_mouse_blocker.grab_focus.call_deferred(true)

	_list = VBoxContainer.new()
	var control_global_rect := Utils.get_screen_rect(self)
	_list.global_position.x = control_global_rect.position.x
	_list.global_position.y = control_global_rect.end.y
	_list.custom_minimum_size.x = control_global_rect.size.x
	_list.add_theme_constant_override('separation', -4)

	for item in _items:
		var option := OPTION_SCENE.instantiate_loaded_scene() as DropdownOption
		option.markedup_text = item.text  # Already translated.
		option.toggle_mode = true
		option.button_pressed = item == _selected_item
		option.pressed.connect(func() -> void:
			set_selected_item(item)
			selected.emit(item)
			close()
		)
		_list.add_child(option)

	_mouse_blocker.add_child(_list)

func close() -> void:
	if _list:
		_list.queue_free()
		_list = null
		_mouse_blocker.queue_free()
		_mouse_blocker = null

func is_open() -> bool:
	return _list != null

func get_selected_value() -> Variant:
	return _selected_item.value if _selected_item else null

func set_selected_item(item: DropdownItem) -> void:
	if not Utils.ensure(item in _items):
		return
	_selected_item = item
	_update()

func get_num_items() -> int:
	return _items.size()

func set_selected_value(item_value: Variant) -> void:
	for item in _items:
		if item.value == item_value:
			set_selected_item(item)
			return
	Utils.ensure(false)

func _update() -> void:
	text = ''
	if not _selected_item and _items:
		_selected_item = _items[0]
	(%Label as MarkedUpLabel).set_markedup_text(_selected_item.text if _selected_item else '')

func _mouse_blocker_clicked() -> void:
	close()

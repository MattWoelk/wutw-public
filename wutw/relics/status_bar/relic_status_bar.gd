class_name RelicStatusBar
extends Control

static var RELIC_ICON_SCENE := AsyncLoadedResource.new('res://relics/selector/relic_icon.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

@export var max_visible_relics: int = 5

# Key is relic ID, to not keep refs.
# Value is a time index (_current_trigger_index at time of last trigger).
var _last_trigger_time: Dictionary[String, int]
var _current_trigger_index := 0

@onready var _visible_list := %VisibleList as Container
@onready var _hidden_list := %HiddenList as Container
@onready var _more_button := %MoreRelicsButton as Button
@onready var _hidden_box := %HiddenBox as Control

# TODO: Only show the more button if more than max_visible_relics + 1, replacing the last relic.

func _ready() -> void:
	Utils.clear_node(_visible_list)
	Utils.clear_node(_hidden_list)

	var run := Utils.get_active_run()
	# Wait until the relics list is initialized when loading.
	while not run.is_node_ready() or run.get_state() == RunData.State.INITIAL:
		await get_tree().process_frame

	run.signals.relic_added.connect(_on_relic_added)
	run.signals.relic_removed.connect(_on_relic_removed)
	for relic in run.get_current_relics():
		_on_relic_added(relic)
	_update_more_button_label()
	_hidden_box.z_index = Utils.get_absolute_z_index(self) + 1
	_hidden_box.visible = false

	set_process(false)

func _process(_delta: float) -> void:
	if Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
		return
	if Rect2(Vector2.ZERO, _hidden_box.size).has_point(_hidden_box.get_local_mouse_position()):
		return
	_hidden_box.visible = false
	set_process(false)

func _on_relic_added(relic: Relic) -> void:
	# Assume new is relevant.
	_last_trigger_time[relic.relic_id] = _current_trigger_index
	_current_trigger_index += 1

	var icon := _create_icon(relic)
	if _visible_list.get_child_count() < max_visible_relics:
		_visible_list.add_child(icon)
	else:
		var min_priority_icon := _get_lowest_priority_visible()
		var min_priority := _get_relic_priority(min_priority_icon.relic)
		var priority := _get_relic_priority(relic)
		if priority > min_priority:
			min_priority_icon.add_sibling(icon)
			_visible_list.remove_child(min_priority_icon)
			_hidden_list.add_child(min_priority_icon)
		else:
			_hidden_list.add_child(icon)
		_update_more_button_label()

func _on_relic_removed(relic: Relic) -> void:
	relic.state_changed.disconnect(_on_relic_state_changed.bind(relic))
	relic.triggered.disconnect(_on_relic_triggered.bind(relic))
	relic.counter_changed.disconnect(_on_relic_triggered.bind(relic))

	for icon: RelicIcon in _visible_list.get_children():
		if icon.relic.relic_id == relic.relic_id:
			icon.queue_free()
			_update_more_button_label()
			return

	var max_hidden := _get_highest_priority_hidden()
	for icon: RelicIcon in _hidden_list.get_children():
		if icon.relic.relic_id == relic.relic_id:
			_hidden_list.remove_child(max_hidden)
			icon.add_sibling(max_hidden)
			icon.queue_free()
			_update_more_button_label()
			return

	Utils.ensure(false, 'Removed relic in neither hidden nor visible list.')

func _on_relic_state_changed(relic: Relic) -> void:
	_on_priority_changed(relic)

func _on_relic_triggered(relic: Relic) -> void:
	_last_trigger_time[relic.relic_id] = _current_trigger_index
	_current_trigger_index += 1
	_on_priority_changed(relic)

func _on_priority_changed(relic: Relic) -> void:
	if _hidden_list.get_child_count() == 0:
		return

	var min_visible := _get_lowest_priority_visible()
	var max_hidden := _get_highest_priority_hidden()
	if _get_relic_priority(min_visible.relic) < _get_relic_priority(max_hidden.relic):
		_hidden_list.remove_child(max_hidden)
		min_visible.add_sibling(max_hidden)
		_visible_list.remove_child(min_visible)
		_hidden_list.add_child(min_visible)

func _create_icon(relic: Relic) -> RelicIcon:
	var relic_icon := RELIC_ICON_SCENE.instantiate_loaded_scene() as RelicIcon
	relic_icon.relic = relic
	relic_icon.forced_size = 72
	relic_icon.mouse_filter = Control.MOUSE_FILTER_PASS
	relic.state_changed.connect(_on_relic_state_changed.bind(relic))
	relic.triggered.connect(_on_relic_triggered.bind(relic))
	relic.counter_changed.connect(_on_relic_triggered.bind(relic))
	return relic_icon

func _get_relic_priority(relic: Relic) -> int:
	var result := 0
	match relic.get_state():
		Relic.State.ACTIVE: result += 1
		Relic.State.EXPIRED: result -= 100_000
	result += _last_trigger_time.get(relic.relic_id, 0)
	return result

func _get_lowest_priority_visible() -> RelicIcon:
	var min_priority: int
	var min_priority_icon: RelicIcon = null
	for icon: RelicIcon in _visible_list.get_children():
		var priority := _get_relic_priority(icon.relic)
		if not min_priority_icon or priority < min_priority:
			min_priority = priority
			min_priority_icon = icon
	return min_priority_icon

func _get_highest_priority_hidden() -> RelicIcon:
	var max_priority: int
	var max_priority_icon: RelicIcon = null
	for icon: RelicIcon in _hidden_list.get_children():
		var priority := _get_relic_priority(icon.relic)
		if not max_priority_icon or priority > max_priority:
			max_priority = priority
			max_priority_icon = icon
	return max_priority_icon

func _update_more_button_label() -> void:
	_more_button.text = '+' + str(_hidden_list.get_child_count())
	_more_button.visible = _hidden_list.get_child_count() > 0

func _on_more_relics_button_mouse_entered() -> void:
	_hidden_box.position = position + Vector2(0, size.y)
	_hidden_box.size.x = size.x
	_hidden_box.size.y = 0  # Force minimum.
	_hidden_box.visible = true
	set_process(true)

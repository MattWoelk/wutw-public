@tool
class_name GenericRecipe
extends Recipe

enum State { AVAILABLE, ACTIVE, UNAVAILABLE }

signal activated

static var ASPECT_SLOT_SCENE := AsyncLoadedResource.new('res://aspects/slot/aspect_slot.tscn')

@export var title: String:
	set(value):
		title = value
		if is_node_ready():
			_recreate()
@export var aspect_types: Array[AspectType]:
	set(value):
		aspect_types = value
		if is_node_ready():
			_recreate()
@export var state: State:
	set(value):
		if state == value:
			return
		state = value
		if is_node_ready():
			_update_state_style()
@export var faded_out: bool = false:
	set(value):
		faded_out = value
		if is_node_ready():
			_update_state_style()

var _fadeout_tween: Tween

func _ready() -> void:
	_recreate()
	super._ready()  # After slots are created.
	if not Utils.is_in_editor():
		GlobalContextHighlight.request_changed.connect(func(requested: ContextHighlight.Context) -> void:
			if requested and load('res://glossary/terms/standalone/term_spot_upgrade.tres') in requested.terms:
				(%HighlightOutline as Control).visible = true
			else:
				(%HighlightOutline as Control).visible = false
		)

func _enter_tree() -> void:
	UI.register_zoomable(self, 0.5, 0.5)

func _process(_delta: float) -> void:
	(%HighlightOutline as Control).size = (%HBox as Control).size

func get_aspect_slots() -> Array[AspectSlot]:
	var aspect_slots: Array[AspectSlot]
	for aspect_slot in %AspectsList.get_children():
		aspect_slots.append(aspect_slot as AspectSlot)
	return aspect_slots

func set_faded_out(is_faded_out: bool) -> void:
	faded_out = is_faded_out

func is_available() -> bool:
	return state == State.AVAILABLE

func _update_state_style() -> void:
	var aspects_panel := %AspectsPanel as Control
	(%HBox as Control).modulate = Color.WHITE
	match state:
		State.ACTIVE:
			aspects_panel.self_modulate = Color(1.2, 1.2, 1.2, 1)
		State.AVAILABLE:
			aspects_panel.self_modulate = Color(0.9, 0.9, 0.9, 1)
		State.UNAVAILABLE:
			aspects_panel.self_modulate = Color(0.7, 0.7, 0.7, 1)
	(%NamePanel as Control).self_modulate = aspects_panel.self_modulate

	if _fadeout_tween:
		_fadeout_tween.kill()
	_fadeout_tween = create_tween()
	_fadeout_tween.tween_property(%HBox, 'modulate:a', 0.35 if faded_out else 1.0, FADEOUT_ANIM_DURATION)
	_fadeout_tween.play()

	for aspect_slot: AspectSlot in %AspectsList.get_children():
		aspect_slot.display_as_inaccessible = state == State.UNAVAILABLE

	if faded_out:
		mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	else:
		mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED

func _recreate() -> void:
	(%NameLabel as Label).text = title

	Utils.clear_node(%AspectsList)
	var sorted_aspects := aspect_types.duplicate()
	sorted_aspects.sort_custom(AspectType.compare)
	for aspect_type: AspectType in sorted_aspects:
		var aspect_slot := ASPECT_SLOT_SCENE.instantiate_loaded_scene() as AspectSlot
		aspect_slot.aspect_type = aspect_type
		aspect_slot.detach_glow_on_anim = true
		aspect_slot.filled.connect(_on_aspect_filled)
		%AspectsList.add_child(aspect_slot)

	_update_state_style()

func _on_aspect_filled() -> void:
	var all_filled := true
	for slot in %AspectsList.get_children():
		if not (slot as AspectSlot).is_filled:
			all_filled = false
			break
	if all_filled:
		state = State.ACTIVE
		activated.emit()

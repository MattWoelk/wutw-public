@tool
class_name HarmonizationRecipe
extends Recipe

enum State { AVAILABLE, ACTIVE, UNAVAILABLE }

signal activated
signal slot_filled

static var ASPECT_SLOT_SCENE := AsyncLoadedResource.new('res://aspects/slot/aspect_slot.tscn')
static var BONUS_SCENE := AsyncLoadedResource.new('res://bonuses/bonus.tscn')

@export var title: String:
	set(value):
		title = value
		if is_node_ready():
			_recreate(false)
@export_multiline var description: String:
	set(value):
		description = value
		if is_node_ready():
			_recreate(false)
@export var aspect_types: Array[AspectType]:
	set(value):
		if aspect_types == value:
			return
		aspect_types = value
		if is_node_ready():
			_recreate(true)
@export var filled_slots: Array[int]:
	set(value):
		if filled_slots == value:
			return
		filled_slots = value
		if is_node_ready():
			_recreate(true)
@export var bonus_types: Array[BonusType]:
	set(value):
		bonus_types = value
		if is_node_ready():
			_recreate(false)
@export var show_lack_label: bool:
	set(value):
		show_lack_label = value
		if is_node_ready():
			_recreate(false)
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
@export var play_activate_vfx: bool = false

func _ready() -> void:
	_recreate(true)
	super._ready()  # After slots are created.
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.CENTERED])

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
	match state:
		State.ACTIVE:
			(%Panel as Control).self_modulate = Color(1.2, 1.2, 1.2, 1)
			(%NameLabel as Label).add_theme_color_override('font_color', Color(0, 0.5, 0, 1))
		State.AVAILABLE:
			(%Panel as Control).self_modulate = Color(1, 1, 1, 1)
			(%NameLabel as Label).add_theme_color_override('font_color', Color(0, 0, 0, 1))
		State.UNAVAILABLE:
			(%Panel as Control).self_modulate = Color(0.7, 0.7, 0.7, 1)
			(%NameLabel as Label).add_theme_color_override('font_color', Color(0, 0, 0, 1))
	modulate.a = 0.3 if faded_out else 1.0

func _recreate(update_slots: bool) -> void:
	(%NameLabel as Label).text = tr(title)

	if update_slots:
		Utils.clear_node(%AspectsList)
		var sorted_aspects := aspect_types
		sorted_aspects.sort_custom(AspectType.compare)
		var i := 0
		for aspect_type in sorted_aspects:
			var aspect_slot := ASPECT_SLOT_SCENE.instantiate_loaded_scene() as AspectSlot
			aspect_slot.aspect_type = aspect_type
			if i in filled_slots:
				aspect_slot.is_filled = true
			aspect_slot.filled.connect(_on_aspect_filled)
			%AspectsList.add_child(aspect_slot)
			i += 1

	Utils.clear_node(%BonusesList)
	for bonus_type in bonus_types:
		var bonus := BONUS_SCENE.instantiate_loaded_scene() as Bonus
		bonus.bonus_type = bonus_type
		bonus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		%BonusesList.add_child(bonus)

	(%LackLabel as Label).visible = show_lack_label

	_update_state_style()

func _on_aspect_filled() -> void:
	slot_filled.emit()
	var all_filled := true
	for slot in %AspectsList.get_children():
		if not (slot as AspectSlot).is_filled:
			all_filled = false
			break
	if all_filled and state != State.ACTIVE:
		state = State.ACTIVE
		activated.emit()
		if play_activate_vfx:
			(%VFX_Activated as GPUParticles2D).emitting = true
			GlobalAudioSystem.play(AK.EVENTS.UI_GENERIC_GLITTER)
		Utils.get_active_run().signals.harmonization_recipe_activated.emit(self)

func _make_tooltip_text() -> String:
	if Utils.is_in_editor():
		return ''
	var text := '<header_font_size>[b]%s (<term:harmonization_recipe>)[/b][/font_size]' % tr(title)
	text += '\n\n%s' % tr(description)
	if state == State.ACTIVE:
		text += '\n\n' + tr('[b]This task has been completed.[/b]')
	return text

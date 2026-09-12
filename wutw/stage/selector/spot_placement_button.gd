@tool
class_name SpotPlacementButton
extends UkiyoeButton

signal placement_started
signal placement_finished(success: bool)

@export var spot_type: SpotType
@export var sprites: Array[MapSpriteType]:
	set(value):
		sprites = value
		if is_node_ready():
			_update()
@export var run_var: RunVars.Var:
	set(value):
		run_var = value
		if is_node_ready():
			_update()
@export var inset_factor: float = 0.9:
	set(value):
		inset_factor = value
		if is_node_ready():
			_update()

var _placement_preview: MapSpritePlacement
var _variant_index := 0

func _ready() -> void:
	super._ready()
	_update()
	if Utils.is_steam_deck():
		(%MarkedUpLabel as Control).visible = false
		(%MarkedUpLabel_SteamDeck as Control).visible = true
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
		[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.CENTERED, Tooltip.Alignment.END])
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)

func _update_font_size() -> void:
	Utils._scale_font_size(%MarkedUpLabel as MarkedUpLabel, true, 16)
	Utils._scale_font_size(%MarkedUpLabel_SteamDeck as MarkedUpLabel, true, 16)

func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.is_pressed() and mouse_event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
		accept_event()
		MuseumBrowser.open_museum_entry(spot_type, UI.Layer.STATE_MENU_SUBMENU)

func _input(event: InputEvent) -> void:
	if not _placement_preview:
		return

	var key_event := event as InputEventKey
	if key_event and key_event.pressed and key_event.keycode == KEY_ESCAPE:
		accept_event()
		_finish_placement(false)
		return

	var mouse_event := event as InputEventMouseButton
	if not mouse_event or not mouse_event.is_pressed():
		return
	match mouse_event.button_index:
		MouseButton.MOUSE_BUTTON_MIDDLE:
			accept_event()
			_finish_placement(false)
		MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			if mouse_event.ctrl_pressed:
				accept_event()
				_variant_index = (_variant_index + 1) % sprites.size()
				_placement_preview.sprite_type = sprites[_variant_index]
		MouseButton.MOUSE_BUTTON_WHEEL_UP:
			if mouse_event.ctrl_pressed:
				accept_event()
				_variant_index = (_variant_index - 1) % sprites.size()
				_placement_preview.sprite_type = sprites[_variant_index]

func _update() -> void:
	if not sprites:
		Utils.ensure(Utils.is_in_editor())
		return

	var run := Utils.get_active_run()
	var num_charges := run.get_var(run_var) if run else 1  # No run is editor
	if num_charges > 0:
		visible = true
	else:
		visible = false
		return

	(%SpotUpgradePreview as SpotUpgradePreview).inset_factor = inset_factor
	(%SpotUpgradePreview as SpotUpgradePreview).override_sprite = sprites[0]
	(%CountLabel as Label).text = str(num_charges)
	(%CountLabel as Label).visible = num_charges > 1
	(%HintPanel as Control).visible = _placement_preview != null

func _pressed() -> void:
	assert(Utils.get_active_run().get_var(run_var) > 0)
	_start_placement()

func _start_placement() -> void:
	assert(not _placement_preview)
	disabled = true

	_placement_preview = MapSpritePlacement.new()
	_placement_preview.sprite_type = sprites[0]
	_variant_index = 0
	_placement_preview.scale = _placement_preview.sprite_type.default_scale
	var map := Utils.get_active_run().get_map()
	var placement_renderer := map.get_placement_sprite_renderer()
	placement_renderer.add_placement(_placement_preview)
	placement_renderer.live_debug = true

	map.clicked.connect(_handle_map_clicked)
	get_tree().process_frame.connect(_tick_targeting)

	(%HintPanel as Control).visible = true

	placement_started.emit()

func _finish_placement(success: bool) -> void:
	assert(_placement_preview)
	disabled = false

	_placement_preview = null
	var map := Utils.get_active_run().get_map()
	var placement_renderer := map.get_placement_sprite_renderer()
	placement_renderer.placements.clear()
	placement_renderer.live_debug = false

	map.clicked.disconnect(_handle_map_clicked)
	get_tree().process_frame.disconnect(_tick_targeting)

	(%HintPanel as Control).visible = false

	_update()

	placement_finished.emit(success)

func _tick_targeting() -> void:
	assert(_placement_preview)

	var map := Utils.get_active_run().get_map()
	var location := map.get_location_at_screen_position(get_global_mouse_position())
	_placement_preview.location = location
	var placement_renderer := map.get_placement_sprite_renderer()
	(placement_renderer.material as ShaderMaterial).set_shader_parameter(
		'invalid_highlight', not _can_place(location))

func _handle_map_clicked(location: Vector2) -> void:
	assert(_placement_preview)
	if _can_place(location):
		var mod := MapModification_PlaceManual.new()
		mod.location = location
		mod.sprite_type = _placement_preview.sprite_type

		var run := Utils.get_active_run()
		var map := run.get_map()
		@warning_ignore('redundant_await')
		if await mod.apply(map, true):
			run.get_run_data().map_modifications.append(mod)
			run.get_vars().modify_base_value(run_var, -1)
			GlobalSaveGame.save_game()
			_finish_placement(true)
			return

	# Would have returned on success.
	GlobalUI.show_error(tr('Could not be placed here.'))

func _can_place(location: Vector2) -> bool:
	assert(_placement_preview)
	var map := Utils.get_active_run().get_map()

	if map.is_in_fow(location):
		return false

	var radius := _placement_preview.sprite_type.footprint_radius * _placement_preview.scale
	var biomes := map.get_biomes_in_radius(location, radius)
	if MapBiomes.Biome.CLOUDS in biomes or MapBiomes.Biome.SEA in biomes:
		return false

	var placer := map.generated_map.sprite_placer
	for intersecting in placer.get_intersecting_sprites(_placement_preview.sprite_type, location):
		if not intersecting.sprite_type.removable:
			return false

	return true

func _make_tooltip_text() -> String:
	return tr('%s to place a [b]<spot:%s>[/b].\n\n[i]%s to open the museum.[/i]') % [
		InputPrompts.get_input_markup(InputPrompts.InputType.LEFT_CLICK),
		spot_type.spot_type_id,
		InputPrompts.get_input_markup(InputPrompts.InputType.RIGHT_CLICK),
	]

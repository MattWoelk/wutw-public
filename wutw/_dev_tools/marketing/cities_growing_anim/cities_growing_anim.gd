extends Node2D

@export var location: Vector2
@export var zoom: float
@export var run_seed: int = 1644

var _run: Run
var _settlement_index: int = 3

func _ready() -> void:
	GlobalSaveGame.init_new_game(2)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P115_GATHERED_RELICS)

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = SaveGame.get_starter_cards()
	_run.run_config.run_seed = run_seed
	GlobalUI.add_layer_content(_run, UI.Layer.GAME)
	await get_tree().create_timer(2).timeout

	# Setup initial view.
	_run.get_inspiration_display().visible = false
	_run.get_run_bonus_listing().visible = false
	_run.get_quest_hud().visible = false
	(_run.get_current_scene() as StageSelector)._state = StageSelector.State.IDLE
	(_run.get_current_scene() as Node2D).visible = false
	_run.get_map().clear_all_fow()
	await get_tree().create_timer(2).timeout
	_run.get_map().instant_focus_location(location, zoom)

	# Setup settlements.
	await add_settlement(190, 60, [
		load('res://stage/spots/desert/upgrade_desert_1_cactus_forest.tres'),
		load('res://stage/spots/brushland/upgrade_brushland_1_mulching_shed.tres'),
	])
	await add_settlement(220, 85, [
		load('res://stage/spots/wasteland/upgrade_wasteland_1_salt_flat.tres'),
		load('res://stage/spots/wasteland/upgrade_wasteland_2_wreck.tres'),
	])
	await add_settlement(260, 75, [
		load('res://stage/spots/river/upgrade_river_1_weeping_willows.tres'),
		load('res://stage/spots/river/upgrade_river_2_sakura_riverbank.tres'),
	])

	# Start convergence.
	_run._current_capital = Run.CAPITAL_SCENE.instantiate_loaded_scene() as Capital
	_run._current_capital.map_location = location
	_run.get_map().add_map_object(_run._current_capital)
	_run.get_map().set_map_object_location(_run._current_capital, _run._current_capital.map_location)
	await _run._current_capital.reveal()

	if OS.has_feature('movie'):
		await get_tree().create_timer(2).timeout
		get_tree().quit()

# Utilities

func add_settlement(x: int, y: int, upgrades: Array[SpotUpgrade] = []) -> void:
	var settlement := _run.debug_create_settlement(
		Vector2i(x, y), 13 + _run.get_map().get_map_objects().size(), 2, false)
	for upgrade in upgrades:
		settlement.add_spot_upgrade_sprite(upgrade)
		await get_tree().create_timer(1.5).timeout
	var settlement_names := (load('res://stage/settlement_names.tres') as SettlementNameSet).options
	settlement.state.settlement_name = settlement_names[randi_range(0, settlement_names.size() - 1)]
	_settlement_index += 1
	settlement.state = settlement.state  # Force update
	await settlement.reveal()

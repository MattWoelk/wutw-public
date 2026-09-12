extends Node2D

var _run: Run

func _ready() -> void:
	seed(50)
	GlobalSaveGame.init_new_game(2)
	GlobalSaveGame.unlock_skill(load('res://skills/craft/skill_craft_1_common.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/craft/skill_craft_2_uncommon.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/craft/skill_craft_3_rare.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/craft/skill_craft_4_epic.tres') as Skill)
	for stroke in Stroke.get_all_strokes():
		GlobalSaveGame.add_stroke(stroke, randi_range(2, 8))

	var custom_cards: Array[CardType] = [
		load('res://cards/tier2/card_three.tres'),
		load('res://cards/tier4/card_echo.tres'),
		load('res://cards/tier5/card_loop.tres'),
		load('res://cards/tier4/card_righteousness.tres'),
		load('res://cards/tier3/card_chat.tres'),
		load('res://cards/tier3/card_koto.tres'),
	]

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = custom_cards + SaveGame.get_starter_cards()
	_run.run_config.run_seed = 40
	add_child(_run)
	await get_tree().process_frame

	add_bonus('harmony', 45)
	add_bonus('food', 160)
	add_bonus('safety', 35)
	add_bonus('productivity', 115)
	add_bonus('adventure', 30)
	add_bonus('knowledge', 80)
	add_bonus('beauty', 80)
	_run.get_map().clear_all_fow()
	_run.set_state(RunData.State.SEASON_END)

	await get_tree().create_timer(2).timeout

	var salvage := (load('res://cards/salvage/salvage.tscn') as PackedScene).instantiate() as Salvage
	salvage.z_index = 1000
	_run.add_child(salvage)
	await get_tree().process_frame
	(salvage.get_node('%BG') as FadedBackground).visible = false
	(salvage.get_node('%CardList').get_child(3) as Card).is_selected = true

	await get_tree().create_timer(2).timeout

	Utils.take_screenshot(self, 'C:/users/max99/wutw/screenshots/salvage.png')

	await get_tree().process_frame

	get_tree().quit()

# Preamble Utilities

func add_card(card_name: String) -> void:
	_run.add_card_to_deck(CardType.get_card_type_by_name_or_symbol(card_name))

func add_relic(relic_id: String) -> void:
	_run.add_relic(Relic.get_relic_by_id(relic_id))

func add_bonus(bonus_id: String, amount: int) -> void:
	_run.gain_bonus(BonusGain.new(BonusType.get_bonus_type_by_id(bonus_id), amount, GlobalConsoleCommands))

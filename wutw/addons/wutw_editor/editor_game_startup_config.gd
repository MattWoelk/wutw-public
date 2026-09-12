@tool
class_name EditorGameStartupConfig
extends Resource

@export var load_savegame: bool = false
@export var use_temporary_savegame: bool = false
@export var start_state: Main.State = Main.State.MAIN_MENU
@export var main_quest_state: SaveGame.MainQuestProgress = -1
@export var stages_per_season: int = -1
@export var stages_before_survey: int = -1
@export var haunting_probability: float = -1
@export var companion: Companion = null
@export var run_seed: int = -1
@export var map_seed: int = 8962
@export var custom_skills: bool = false
@export var skills: Array[Skill] = []
@export var starting_quest: Quest = null
@export var starting_quest_active: bool = false
@export var full_museum_unlocks: bool = false

func apply(main: Main) -> void:
	var save_slot := 42 if use_temporary_savegame else 0
	if load_savegame:
		assert(GlobalSaveGame.savegame_exists(save_slot))
		GlobalSaveGame.load_game(save_slot)
		if GlobalSaveGame.get_run_data():
			main.starting_state = Main.State.RUN
		else:
			main.starting_state = Main.State.HUB
	elif start_state != Main.State.MAIN_MENU:
		GlobalSaveGame.init_new_game(save_slot)
		main.starting_state = start_state

		if main_quest_state >= 0:
			GlobalSaveGame.set_main_quest_progress(main_quest_state)

		if starting_quest:
			var quest_instance := starting_quest.instantiate(
				QuestInstance.STATE_ACTIVE if starting_quest_active else QuestInstance.STATE_INACTIVE)
			GlobalSaveGame.add_quest_instance(quest_instance)

		if start_state == Main.State.RUN:
			var run_config := RunConfig.new()
			run_config.starting_cards = SaveGame.get_starter_cards()
			run_config.run_type = RunSetup.get_default_run_type()
			if stages_per_season >= 0 or haunting_probability >= 0 or stages_before_survey >= 0:
				run_config.run_type.scaling_override = load('res://run/scaling/run_scaling.tres').duplicate()
				if stages_per_season >= 0:
					assert(stages_per_season > 0)
					run_config.run_type.scaling_override.stages_per_season = stages_per_season
				if haunting_probability >= 0:
					assert(haunting_probability >= 0 and haunting_probability <= 1)
					run_config.run_type.scaling_override.haunting_base_probability = haunting_probability
				if stages_before_survey >= 0:
					assert(stages_before_survey > 0)
					run_config.run_type.scaling_override.stages_before_survey = stages_before_survey

			if companion:
				run_config.companion = companion
				GlobalSaveGame.unlock_companion(companion)
				GlobalSaveGame.set_current_companion(companion)

			if run_seed < 0:
				run_config.run_seed = randi_range(1, 10000)
			else:
				run_config.run_seed = run_seed
			run_config.debug_map_seed = map_seed
			main._requested_run_config = run_config

		if custom_skills:
			for skill in skills:
				if not GlobalSaveGame.has_unlocked_skill(skill):  # Roots
					if skill.revealed_manually:
						GlobalSaveGame.reveal_skill(skill)
					GlobalSaveGame.unlock_skill(skill)

		if full_museum_unlocks:
			for card in CardType.get_all_card_types():
				GlobalSaveGame.mark_card_seen(card)
			for relic in Relic.get_all_relics():
				GlobalSaveGame.mark_relic_seen(relic)
			for spot_upgrade in SpotUpgrade.get_all_spot_upgrades():
				GlobalSaveGame.mark_upgrade_seen(spot_upgrade)
			for shop_type in ShopType.get_all_shop_types():
				GlobalSaveGame.mark_shop_seen(shop_type)
			for haunting_type in HauntingType.get_all_haunting_types():
				GlobalSaveGame.mark_haunting_seen(haunting_type)
				GlobalSaveGame.mark_haunting_pacified(haunting_type)
			for event: Event in Event.get_all_events().values():
				GlobalSaveGame.get_events_state().set_bool(event.event_id, Event.TRIGGERED_EVER_VAR, true)
				event.mark_all_choices_seen()
			for companion in Companion.get_all_companions():
				if not GlobalSaveGame.has_unlocked_companion(companion):
					GlobalSaveGame.unlock_companion(companion)
			for dialogue: Dialogue in Dialogue.get_all_dialogues().values():
				GlobalSaveGame.mark_dialogue_seen(dialogue)
			for quest: Quest in Quest.get_all_quests().values():
				if quest is Quest_Settler:
					GlobalSaveGame.mark_settler_quest_seen(quest as Quest_Settler)
					GlobalSaveGame.mark_settler_quest_completed(quest as Quest_Settler)
			for episode: SurveyEpisode in SurveyEpisode.get_all_episodes().values():
				GlobalSaveGame.mark_survey_seen(episode)
				for i in 8:
					GlobalSaveGame.mark_survey_choice_seen(episode, i)

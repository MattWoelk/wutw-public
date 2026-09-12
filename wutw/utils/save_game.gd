class_name SaveGame
extends Node

signal changed
signal save_started
signal save_failed
signal save_finished
signal save_loaded

@warning_ignore_start('unused_signal')  # Emitted by Main.
signal run_entered(run: Run)
signal run_exited(run: Run)
signal hub_entered(hub: Hub)
signal hub_exited(hub: Hub)
@warning_ignore_restore('unused_signal')

@warning_ignore_start('unused_signal')  # Emitted by QuestInstance.
signal quest_started(quest_instance: QuestInstance)
signal quest_finished(quest_instance: QuestInstance)
@warning_ignore_restore('unused_signal')

@warning_ignore_start('unused_signal')  # Emitted by the final quest.
signal game_finished
@warning_ignore_restore('unused_signal')

# Mainly for achievements.
signal main_quest_state_changed
signal card_discovered
signal card_unlocked
signal relic_discovered
signal shop_discovered
signal spot_upgrade_discovered
signal event_choice_discovered(event: Event)
signal survey_discovered
signal survey_choice_discovered
signal skill_unlocked
signal companion_unlocked
signal new_haunting_pacified
signal shard_settled
signal settled_shard_explored
signal settler_quest_finished

enum MainQuestProgress {
	P000_INTRO = 0,

	P100_STARTED_RELIGION = 100,
	P101_CASTING_ENABLED = 101,
	P102_COMPLETED_STARTER_TUTORIAL = 102,
	P105_SETTLED_ONCE = 105,
	P110_COMPLETED_TUTORIAL = 110,
	P115_GATHERED_RELICS = 115,
	P116_UNLOCKED_SURVEY = 116,
	P117_COMPLETED_SURVEY = 117,
	P118_REACHED_CONVERGENCE = 118,
	P120_ESTABLISHED_CAPITAL = 120,
	P125_CRAFTED_GLYPH = 125,
	P130_ESTABLISHED_SHRINES = 130,
	P140_DEDICATED_STATUE = 140,

	P200_STARTED_MAGIC = 200,
	P210_FOUND_PLACES_OF_POWER = 210,
	P220_HAUNTINGS_STUDIED = 220,
	P230_PREPARED_RITUAL = 230,

	P300_STARTED_LEADERSHIP = 300,
	P310_ESTABLISHED_CONTACT = 310,
	P320_ESTABLISHED_MONASTERY = 320,
	P330_BEFRIENDED_COMPANION = 330,
	P340_SUMMONED_DRAGON = 340,
	P350_SIGNED_ACCORD = 350,

	P400_STARTED_DEPRESSION = 400,
	P410_FOUND_KID = 410,
	P420_SENT_OFF_KID = 420,
	P430_STARTED_DEBATE = 430,
	P435_TRANSLATED_COMMANDMENTS = 435,
	P440_FINISHED_DEBATE = 440,

	P500_STARTED = 500,
	P510_FINISHED_OUTRO_CUTSCENE = 510,

	NEVER_REACHED = 1000,
}

const VERSION := 1
const BASE_PATH: String = 'user://save_slot_%d/'
const DATA_FILENAME: String = 'main_state.json'
const PAST_RUN_BASENAME: String = 'past_run_%d'
const MAX_RECENT_SURVEY_EPISODES := 20
static var STARTER_CARDSET := AsyncLoadedResource.new('res://cards/cardset_starter.tres')
static var AUTO_SEEN_CARDSET := AsyncLoadedResource.new('res://cards/cardset_auto_seen.tres')
static var AUTO_UNLOCKED_CARDSET := AsyncLoadedResource.new('res://cards/cardset_auto_unlocked.tres')

var read_only: bool = false  # Used for debugging and dev tools.

## The currently loaded savegame slot. The game will be saved to this slot whenever save_game() is called.
var _current_slot: int = -1

## The last time this save was written to disk, as a Unix timestamp.
var _last_saved_timestamp: int = -1
## The total playtime (regardless of whether it is in a run or not), in seconds.
var _total_playtime: float = 0
## A seed used as a global playthrough so that different playthroughs gon't get identical shards.
var _playthrough_seed: int = 0
## The global date, used to track things like past shard population.
var _current_date: int = 0
## The cards that the player has "inscribed" and which can be selected at run start and in some landmarks.
var _unlocked_cards: Dictionary[CardType, bool] = {}
## The extra cards the player has selected to start runs with. The current cards for the run in progress are in Run.
var _signature_cards: Array[CardType] = []
## The starter cards the player has replaced.
var _replaced_cards: Dictionary[CardType, CardType] = {}
## card the player has inherited from the last run.
var _inherited_card: CardType = null
## The companion which the player has last selected.
var _current_companion: Companion
## The run seed to use for the next run.
var _next_run_seed: int = -1
## The relic which the player has last selected as a starting relic.
var _starting_relic: Relic
## The hauntings that the player has banned for the current/next run.
var _banned_hauntings: Array[HauntingType]
## The events that the player has pinned to be guaranteed for the current/next run.
var _pinned_events: Array[Event]
## A resource used for most meta-progression.
var insights: int = 0:
	set(value):
		insights = value
		_changed_this_frame = true
## The strokes which the player has in their inventory, used for crafting cards.
var _strokes: Dictionary[Stroke, int] = {}
## The skills which the player has unlocked.
var _unlocked_skills: Dictionary[Skill, bool] = {}
## Non-default-revealed skills which the player has revealed.
var _revealed_skills: Array[Skill] = []
## The companions which the player has unlocked.
var _unlocked_companions: Dictionary[Companion, bool] = {}
## The state of events stored permanently.
var _events_state: EventsState = EventsState.new()
## The state of the current run. Null if not in a run.
var _run_data: RunData
## All active and finished quests.
var _quest_instances: Array[QuestInstance]

## Used for Hub NPCs and similar.
var _hub_random: RandomState = RandomState.new()
## All the cards the player has encountered.
## Used as a Set. The value is always true.
var _seen_cards: Dictionary[CardType, bool]
## All the relics the player has encountered.
## Uses relic IDs as keys, as relics are duplicated.
## Used as a Set. The value is always true.
var _seen_relics: Dictionary[String, bool]
## All the shops the player has ever established.
## Used as a Set. The value is always true.
var _seen_shops: Dictionary[ShopType, bool]
## All the SpotUpgrades the player has ever activated.
## Used as a Set. The value is always true.
var _seen_upgrades: Dictionary[SpotUpgrade, bool]
## All the hauntintgs the player has established.
## The value indicates whether they were ever pacified.
var _seen_hauntings: Dictionary[HauntingType, bool]
## All event choices the player has seen the consequences of.
## Values are bitfields of seen choice indices.
var _seen_event_choices: Dictionary[Event, int]
## The skills that the player has seen.
## Used to show a prompt about new skills veing available.
var _seen_skills: Dictionary[Skill, bool]
## All the dialogues the player has seen.
## In the order the player has encountered them.
var _seen_dialogues: Dictionary[Dialogue, MainQuestProgress]
## All surveys the player has encountered.
var _seen_surveys: Dictionary[SurveyEpisode, bool]
## All survey choices the player has seen the consequences of.
## Values are bitfields of seen choice indices.
var _seen_survey_choices: Dictionary[SurveyEpisode, int]
## The settler quests that the player has seen.
## The value indicates whether they were completed.
var _seen_settler_quests: Dictionary[Quest_Settler, bool]

## All past runs, tagged with shard name and type. Keyed by past run UID.
var _past_runs: Dictionary[int, PastRun]
## The number of seasons since a given shard type has been established.
var _shard_type_progress: Dictionary[ShardType, ShardTypeProgress]
## The shard type pinned to be shown in the quests UI.
var _pinned_shard_type: ShardType
## The UIDs of the shards (past runs) which have already been explored.
var _explored_shards: Array[int]
## The UIDs of PastRuns which the explorer is scheduled to visit.
var _queued_trip_uids: Array[int]
## The UIDs of PastRuns which the explorer has visited but whose results haven't been claimed.
var _finished_trip_uids: Array[int]
## Arguments that have been unlocked and are ready to be used..
var _unlocked_arguments: Array[DebateArgument]
## Arguments that have already been used.
var _used_arguments: Array[DebateArgument]
## Recently-encountered survey episodes. Older entries are discarded. Only used to avoid them.
var _recent_survey_episodes: Array[SurveyEpisode]

## The exhibits selected to be displayed in the museum. Keyed by ID (managed in HubMuseum).
var _displayed_museum_exhibit: Dictionary[int, LazyTextureResource]

## User-drawn shapes for each kanji.
var _drawn_kanji_shapes: Dictionary[String, KanjiShape]

## A flag that disables achievements if the player ever uses cheats.
var _used_cheats: bool = false

# Internal state
var _changed_this_frame := false

func _process(delta: float) -> void:
	_total_playtime += delta
	if _run_data:
		_run_data.playtime += delta
	if _changed_this_frame:
		changed.emit()
		_changed_this_frame = false

static func get_starter_cards() -> Array[CardType]:
	return (STARTER_CARDSET.get_loaded() as CardSet).card_types.duplicate()

static func get_auto_unlocked_cards() -> Array[CardType]:
	return (AUTO_UNLOCKED_CARDSET.get_loaded() as CardSet).card_types.duplicate()

func init_new_game(slot: int) -> void:
	clear()
	_playthrough_seed = randi_range(1, 10000)
	_current_slot = slot
	_unlock_default_cards()
	for stroke in Stroke.get_all_strokes():
		add_stroke(stroke, 3)
	if not _events_state.changed.is_connected(_mark_changed):
		_events_state.changed.connect(_mark_changed)

static func savegame_exists(slot: int) -> bool:
	var path := _get_slot_base_path(slot) + '/' + DATA_FILENAME
	return FileAccess.file_exists(path)

static func is_savegame_accessible(slot: int) -> bool:
	# On the Steam Deck, other profiles have separate savegames which we can see but
	# can't access.
	var path := _get_slot_base_path(slot) + '/' + DATA_FILENAME
	if not FileAccess.file_exists(path):
		return true  # Not blocked.
	var file := FileAccess.open(path, FileAccess.READ_WRITE)
	if file != null:
		file.close()
		return true
	print('No access to existing savegame for slot %d.' % slot)
	return false

static func delete(slot: int) -> void:
	OS.move_to_trash(ProjectSettings.globalize_path(_get_slot_base_path(slot)))

func get_current_slot() -> int:
	return _current_slot

func save_game(slot: int = -1) -> void:
	if read_only or get_main_quest_progress() < SaveGame.MainQuestProgress.P110_COMPLETED_TUTORIAL:
		return  # Saving before the tutorial leaves the game in a weird state.

	if slot == -1:
		slot = _current_slot
		if slot == -1:
			save_failed.emit()
			return
	else:
		_current_slot = slot
	if not savegame_exists(slot):
		DirAccess.make_dir_absolute(_get_slot_base_path(slot))
	if not is_savegame_accessible(slot):
		push_error('Attempted to write a savegame without access to slot %d.' % slot)
		return

	# Backup just in case.
	var final_save_path := _get_slot_base_path(slot) + '/' + DATA_FILENAME
	if FileAccess.get_size(final_save_path) > 0:
		DirAccess.copy_absolute(final_save_path, final_save_path + '.backup')

	save_started.emit()
	if slot == -1:
		slot = _current_slot
		if slot == -1:
			save_failed.emit()
			return
	else:
		_current_slot = slot
	_last_saved_timestamp = floori(Time.get_unix_time_from_system())
	var encoded_data := _encode_save_data()
	var temp_file := FileAccess.create_temp(FileAccess.WRITE, 'wutw_save_temp_', 'json')
	if not temp_file:
		save_failed.emit()
		return
	# Can fail if drive is full!
	var write_suceeded := temp_file.store_line(
		JSON.stringify(encoded_data, '' if Utils.is_packaged() else '\t'))
	if not write_suceeded:
		save_failed.emit()
		return
	var temp_path := temp_file.get_path_absolute()
	temp_file.close()
	if not FileAccess.file_exists(temp_path) or FileAccess.get_size(temp_path) <= 0:
		save_failed.emit()
		return
	DirAccess.rename_absolute(temp_path, final_save_path)

	for past_run: PastRun in _past_runs.values():
		# Assume immutable, so only needs to be saved once.
		if past_run and not FileAccess.file_exists(_get_past_run_file_path(past_run.uid)):
			if not _save_past_run(past_run):
				save_failed.emit()
				return

	save_finished.emit()

func load_game(slot: int) -> bool:
	if not savegame_exists(slot):
		return false
	if not is_savegame_accessible(slot):
		return false
	var save_file := FileAccess.open(_get_slot_base_path(slot) + '/' + DATA_FILENAME, FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(save_file.get_as_text())
	if parse_result != OK:
		return false
	_decode_save_data(json.data as Dictionary)
	_current_slot = slot
	if not _events_state.changed.is_connected(_mark_changed):
		_events_state.changed.connect(_mark_changed)
	save_loaded.emit()
	# Don't load past runs until requested.
	return true

func get_last_saved_timestamp() -> int:
	return _last_saved_timestamp

func get_total_playtime() -> float:
	return _total_playtime

func get_playthrough_seed() -> int:
	return _playthrough_seed

func get_unlocked_cards() -> Array[CardType]:
	return _unlocked_cards.keys()

func get_num_unlocked_cards() -> int:
	return _unlocked_cards.size()

func has_unlocked_card(card_type: CardType) -> bool:
	return card_type in _unlocked_cards

func unlock_card(card_type: CardType) -> void:
	_unlocked_cards[card_type] = true
	_changed_this_frame = true
	card_unlocked.emit()

func get_run_starting_deck() -> Array[CardType]:
	var result: Array[CardType]
	result.append_array(SaveGame.get_starter_cards())
	for replaced in _replaced_cards:
		if Utils.ensure(replaced in result):
			result.erase(replaced)
			result.append(_replaced_cards[replaced])
	result.append_array(GlobalSaveGame.get_signature_cards())
	if _inherited_card:
		result.append(_inherited_card)
	return result

func get_signature_cards() -> Array[CardType]:
	return _signature_cards.duplicate()

func set_signature_cards(new_signature_cards: Array[CardType]) -> void:
	_signature_cards = new_signature_cards
	_changed_this_frame = true

func get_replaced_cards() -> Dictionary[CardType, CardType]:
	return _replaced_cards.duplicate()

func set_replaced_cards(replaced: Dictionary[CardType, CardType]) -> void:
	_replaced_cards = replaced.duplicate()
	_changed_this_frame = true

func get_inherited_card() -> CardType:
	return _inherited_card

func set_inherited_card(new_card: CardType) -> void:
	_inherited_card = new_card
	_changed_this_frame = true

func get_stroke_count(stroke: Stroke) -> int:
	return _strokes.get(stroke, 0)

func get_stroke_counts() -> Dictionary[Stroke, int]:
	return _strokes.duplicate()

func add_stroke(stroke: Stroke, count: int) -> void:
	_strokes[stroke] += count
	_changed_this_frame = true

func get_unlocked_skills() -> Array[Skill]:
	return _unlocked_skills.keys()

func has_unlocked_skill(skill: Skill) -> bool:
	return skill in _unlocked_skills

func unlock_skill(skill: Skill) -> void:
	if not Utils.ensure(skill not in _unlocked_skills):
		return
	_unlocked_skills[skill] = true
	_changed_this_frame = true
	skill_unlocked.emit()

func has_revealed_skill(skill: Skill) -> bool:
	return skill in _revealed_skills

func reveal_skill(skill: Skill) -> void:
	if not Utils.ensure(skill.revealed_manually):
		return
	if not Utils.ensure(skill not in _revealed_skills):
		return
	_revealed_skills.append(skill)
	_changed_this_frame = true

func get_unlocked_companions() -> Array[Companion]:
	return _unlocked_companions.keys()

func get_num_unlocked_companions() -> int:
	return _unlocked_companions.size()

func has_unlocked_companion(companion: Companion) -> bool:
	return companion in _unlocked_companions

func unlock_companion(companion: Companion) -> void:
	if not Utils.ensure(companion and companion not in _unlocked_companions):
		return
	_unlocked_companions[companion] = true
	_changed_this_frame = true
	companion_unlocked.emit()

func get_current_companion() -> Companion:
	return _current_companion

func set_current_companion(companion: Companion) -> void:
	_current_companion = companion
	_changed_this_frame = true

func get_next_run_seed() -> int:
	return _next_run_seed

func set_next_run_seed(next_run_seed: int) -> void:
	_next_run_seed = next_run_seed
	_changed_this_frame = true

func get_starting_relic() -> Relic:
	return _starting_relic

func set_starting_relic(relic: Relic) -> void:
	_starting_relic = relic

func get_banned_hauntings() -> Array[HauntingType]:
	return _banned_hauntings

func set_banned_hauntings(hauntings: Array[HauntingType]) -> void:
	_banned_hauntings = hauntings
	_changed_this_frame = true

func get_pinned_events() -> Array[Event]:
	return _pinned_events

func set_pinned_events(events: Array[Event]) -> void:
	_pinned_events = events
	_changed_this_frame = true

func get_events_state() -> EventsState:
	return _events_state

func get_run_data() -> RunData:
	return _run_data

func start_run(run_config: RunConfig) -> RunData:
	_run_data = RunData.create(run_config)
	_next_run_seed = -1
	_changed_this_frame = true
	return _run_data

func clear_run() -> void:
	_run_data = null
	_changed_this_frame = true

func get_all_quest_instances() -> Array[QuestInstance]:
	return _quest_instances.duplicate()

func get_quest_instance(quest: Quest) -> QuestInstance:
	if not Utils.ensure(quest != null):
		return
	for instance in _quest_instances:
		if instance.get_quest() == quest:
			return instance
	return null

func add_quest_instance(quest_instance: QuestInstance) -> void:
	if not Utils.ensure(quest_instance != null):
		return
	if not Utils.ensure(not get_quest_instance(quest_instance.get_quest())):
		return
	_quest_instances.append(quest_instance)
	if quest_instance.get_quest() is Quest_Settler:
		mark_settler_quest_seen(quest_instance.get_quest() as Quest_Settler)
	quest_instance.changed.connect(func() -> void: _changed_this_frame = true)
	_changed_this_frame = true

func remove_quest_instance(quest_instance: QuestInstance) -> void:
	if not Utils.ensure(quest_instance != null):
		return
	if not Utils.ensure(get_quest_instance(quest_instance.get_quest()) != null):
		return
	_quest_instances.erase(quest_instance)
	quest_instance.free.call_deferred()
	_changed_this_frame = true

func get_main_quest_progress() -> MainQuestProgress:
	var progress := get_events_state().get_int_or_default('global', 'main_quest_state', 0) as MainQuestProgress
	return progress

func set_main_quest_progress(progress: MainQuestProgress) -> void:
	if not Utils.ensure(progress >= get_main_quest_progress()):
		return
	get_events_state().set_int('global', 'main_quest_state', progress as int)
	_check_autounlocked_skills()
	_changed_this_frame = true
	main_quest_state_changed.emit()

func get_hub_random() -> RandomState:
	return _hub_random

func mark_card_seen(card_type: CardType) -> void:
	# Don't mark tutorial cards as seen.
	if get_main_quest_progress() < MainQuestProgress.P110_COMPLETED_TUTORIAL:
		return

	if card_type not in _seen_cards:
		_seen_cards[card_type] = true
		if _run_data:
			if Utils.ensure(card_type not in _run_data.newly_seen_cards):
				_run_data.newly_seen_cards.append(card_type)
		_changed_this_frame = true
		card_discovered.emit()

func has_seen_card(card_type: CardType) -> bool:
	return _seen_cards.get(card_type, false)

func get_seen_cards() -> Array[CardType]:
	return _seen_cards.keys()

func get_num_seen_cards() -> int:
	return _seen_cards.size()

func mark_relic_seen(relic: Relic) -> void:
	if relic.relic_id not in _seen_relics:
		if _run_data:
			if Utils.ensure(relic not in _run_data.newly_seen_relics):
				_run_data.newly_seen_relics.append(relic)
		_seen_relics[relic.relic_id] = true
		_changed_this_frame = true
		relic_discovered.emit()

func has_seen_relic(relic: Relic) -> bool:
	return _seen_relics.get(relic.relic_id, false)

func get_seen_relics() -> Array[Relic]:
	var result: Array[Relic] = []
	for relic_id in _seen_relics:
		result.append(Relic.get_relic_by_id(relic_id))
	return result

func get_num_seen_relics() -> int:
	return _seen_relics.size()

func mark_shop_seen(shop_type: ShopType) -> void:
	if shop_type not in _seen_shops:
		if _run_data:
			if Utils.ensure(shop_type not in _run_data.newly_seen_shops):
				_run_data.newly_seen_shops.append(shop_type)
		_seen_shops[shop_type] = true
		_changed_this_frame = true
		shop_discovered.emit()

func has_seen_shop(shop_type: ShopType) -> bool:
	return _seen_shops.get(shop_type, false)

func get_seen_shops() -> Array[ShopType]:
	return _seen_shops.keys()

func get_num_seen_shops() -> int:
	return _seen_shops.size()

func mark_dialogue_seen(dialogue: Dialogue) -> void:
	if dialogue not in _seen_dialogues:
		_seen_dialogues[dialogue] = get_main_quest_progress()
		_changed_this_frame = true

func has_seen_dialogue(dialogue: Dialogue) -> bool:
	return dialogue in _seen_dialogues

func get_seen_dialogues() -> Array[Dialogue]:
	var result: Array[Dialogue]
	result.assign(_seen_dialogues.keys())
	return result

func get_seen_dialogue_mq_state(dialogue: Dialogue) -> MainQuestProgress:
	return _seen_dialogues.get(dialogue, MainQuestProgress.P100_STARTED_RELIGION)

func mark_upgrade_seen(upgrade: SpotUpgrade) -> void:
	if upgrade not in _seen_upgrades:
		if _run_data:
			if Utils.ensure(upgrade not in _run_data.newly_seen_upgrades):
				_run_data.newly_seen_upgrades.append(upgrade)
		_seen_upgrades[upgrade] = true
		_changed_this_frame = true
		spot_upgrade_discovered.emit()

func has_seen_upgrade(upgrade: SpotUpgrade) -> bool:
	return _seen_upgrades.get(upgrade, false)

func get_seen_upgrades() -> Array[SpotUpgrade]:
	return _seen_upgrades.keys()

func get_num_seen_upgrades() -> int:
	return _seen_upgrades.size()

func mark_haunting_seen(haunting: HauntingType) -> void:
	if haunting not in _seen_hauntings:
		if _run_data:
			if Utils.ensure(haunting not in _run_data.newly_seen_hauntings):
				_run_data.newly_seen_hauntings.append(haunting)
		_seen_hauntings[haunting] = false
		_changed_this_frame = true

func mark_haunting_pacified(haunting: HauntingType) -> void:
	if not _seen_hauntings.get(haunting, false):
		Utils.ensure(haunting in _seen_hauntings)
		if _run_data:
			if Utils.ensure(haunting not in _run_data.newly_pacified_hauntings):
				_run_data.newly_pacified_hauntings.append(haunting)
		_seen_hauntings[haunting] = true
		_changed_this_frame = true
		new_haunting_pacified.emit()

func has_seen_haunting(haunting: HauntingType) -> bool:
	return haunting in _seen_hauntings

func has_pacified_haunting(haunting: HauntingType) -> bool:
	return _seen_hauntings.get(haunting, false)

func get_seen_hauntings() -> Array[HauntingType]:
	return _seen_hauntings.keys()

func mark_settler_quest_seen(quest: Quest_Settler) -> void:
	if quest not in _seen_settler_quests:
		_seen_settler_quests[quest] = false
		_changed_this_frame = true

func mark_settler_quest_completed(quest: Quest_Settler) -> void:
	if not _seen_settler_quests.get(quest, false):
		Utils.ensure(quest in _seen_settler_quests)
		if _run_data:
			if Utils.ensure(quest not in _run_data.newly_completed_settler_quests):
				_run_data.newly_completed_settler_quests.append(quest)
		_seen_settler_quests[quest] = true
		_changed_this_frame = true
		settler_quest_finished.emit()

func has_seen_settler_quest(quest: Quest_Settler) -> bool:
	return quest in _seen_settler_quests

func has_completed_settler_quest(quest: Quest_Settler) -> bool:
	return _seen_settler_quests.get(quest, false)

func get_seen_settler_quests() -> Array[Quest_Settler]:
	return _seen_settler_quests.keys()

func mark_event_choice_seen(event: Event, choice_index: int) -> void:
	var existing := _seen_event_choices.get(event, 0) as int
	var new := existing | (1 << choice_index)
	if existing != new:
		_seen_event_choices[event] = new
		if _run_data and event not in _run_data.newly_seen_event_outcomes:
			_run_data.newly_seen_event_outcomes.append(event)
		_changed_this_frame = true
		event_choice_discovered.emit(event)

func has_seen_event_choice(event: Event, choice_index: int) -> bool:
	return (_seen_event_choices.get(event, 0) & (1 << choice_index)) > 0

func has_seen_event(event: Event) -> bool:
	return _events_state.get_bool_or_default(event.event_id, Event.TRIGGERED_EVER_VAR, false)

func get_seen_event_choices() -> Dictionary[Event, int]:
	return _seen_event_choices.duplicate()

func has_seen_survey(episode: SurveyEpisode) -> bool:
	return _seen_surveys.get(episode, false)

func get_seen_surveys() -> Dictionary[SurveyEpisode, bool]:
	return _seen_surveys.duplicate()

func mark_survey_seen(episode: SurveyEpisode) -> void:
	_seen_surveys[episode] = true
	survey_discovered.emit()

func mark_survey_choice_seen(episode: SurveyEpisode, choice_index: int) -> void:
	var existing := _seen_survey_choices.get(episode, 0) as int
	var new := existing | (1 << choice_index)
	if existing != new:
		_seen_survey_choices[episode] = new
		_changed_this_frame = true
		if _run_data and episode not in _run_data.newly_seen_survey_outcomes:
			_run_data.newly_seen_survey_outcomes.append(episode)
		survey_choice_discovered.emit()

func has_seen_survey_choice(episode: SurveyEpisode, choice_index: int) -> bool:
	return (_seen_survey_choices.get(episode, 0) & (1 << choice_index)) > 0

func mark_skill_seen(skill: Skill) -> void:
	if skill not in _seen_skills:
		_seen_skills[skill] = true
		_changed_this_frame = true

func has_seen_skill(skill: Skill) -> bool:
	return skill in _seen_skills

func get_seen_skills() -> Array[SpotUpgrade]:
	return _seen_skills.keys()

func add_past_run(past_run: PastRun) -> void:
	if not Utils.ensure(past_run != null):
		return
	past_run.validate()
	if not Utils.ensure(past_run.uid not in _past_runs):
		return
	_past_runs[past_run.uid] = past_run
	if past_run.shard_type:
		if Utils.ensure(past_run.shard_type not in _shard_type_progress):
			_shard_type_progress[past_run.shard_type] = ShardTypeProgress.new(past_run.shard_type)
			if _pinned_shard_type == past_run.shard_type:
				_pinned_shard_type = null
	if FileAccess.file_exists(_get_past_run_file_path(past_run.uid)):
		# In case a past savegame wasn't cleaned up.
		DirAccess.remove_absolute(_get_past_run_file_path(past_run.uid))
		DirAccess.remove_absolute(_get_past_run_screenshot_file_path(past_run.uid))
	_changed_this_frame = true
	shard_settled.emit()

func get_past_run_ids() -> Array[int]:
	var result: Array[int]
	result.assign(_past_runs.keys())
	return result

func get_num_past_runs() -> int:
	return _past_runs.size()

func get_past_run(uid: int) -> PastRun:
	var result := _past_runs[uid]  # Intentional error on invalid ID
	if not result:
		result = _load_past_run(uid)
		_past_runs[uid] = result
	return result

func is_past_run_loaded(uid: int) -> bool:
	return _past_runs[uid] != null  # Intentional error on invalid ID

func get_past_run_by_shard_type(shard_type: ShardType) -> PastRun:
	for uid in _past_runs:
		var past_run := get_past_run(uid)
		if past_run.shard_type == shard_type:
			return past_run
	return null

func get_current_date() -> int:
	return _current_date

func increment_date() -> void:
	_current_date += 1
	for progress: ShardTypeProgress in _shard_type_progress.values():
		progress.increment_progress()
	if _queued_trip_uids:
		_finished_trip_uids.append(_queued_trip_uids.pop_front())
	_changed_this_frame = true

func is_shard_type_unlocked(shard_type: ShardType) -> bool:
	return shard_type in _shard_type_progress

func get_shard_type_progress(shard_type: ShardType) -> ShardTypeProgress:
	if Utils.ensure(is_shard_type_unlocked(shard_type)):
		return _shard_type_progress[shard_type]
	else:
		return ShardTypeProgress.new(shard_type)

func get_num_shard_types_unlocked() -> int:
	return _shard_type_progress.size()

func mark_shard_type_history_seen(shard_type: ShardType, history_index: int) -> void:
	get_shard_type_progress(shard_type).set_history_seen(history_index)
	_changed_this_frame = true

func pin_shard_type(shard_type: ShardType) -> void:
	_pinned_shard_type = shard_type
	_changed_this_frame = true

func get_pinned_shard_type() -> ShardType:
	if is_shard_type_unlocked(_pinned_shard_type):
		push_warning('Pinned shard type already unlocked. Returning null.')
		return null
	return _pinned_shard_type

func is_shard_explored(past_run_uid: int) -> bool:
	return past_run_uid in _explored_shards

func get_num_explored_shards() -> int:
	return _explored_shards.size()

func queue_trip(past_run: PastRun) -> void:
	if not Utils.ensure(not is_shard_explored(past_run.uid)):
		return
	_queued_trip_uids.append(past_run.uid)
	_changed_this_frame = true

func mark_trip_result_claimed(past_run_uid: int) -> void:
	if Utils.ensure(past_run_uid in _finished_trip_uids):
		_finished_trip_uids.erase(past_run_uid)

	if Utils.ensure(past_run_uid not in _explored_shards):
		_explored_shards.append(past_run_uid)
		settled_shard_explored.emit()

	_changed_this_frame = true

func is_trip_in_progress() -> bool:
	return not _queued_trip_uids.is_empty()

func has_trip_results_pending() -> bool:
	return not _finished_trip_uids.is_empty()

func get_queued_trip_uids() -> Array[int]:
	return _queued_trip_uids.duplicate()

func get_finished_trip_uids() -> Array[int]:
	return _finished_trip_uids.duplicate()

func is_argument_unlocked(argument: DebateArgument) -> bool:
	return argument in _unlocked_arguments

func unlock_argument(argument: DebateArgument) -> void:
	_unlocked_arguments.append(argument)
	_changed_this_frame = true

func get_usable_arguments() -> Array[DebateArgument]:
	var result: Array[DebateArgument]
	for argument in _unlocked_arguments:
		if argument not in _used_arguments:
			result.append(argument)
	return result

func get_used_arguments() -> Array[DebateArgument]:
	return _used_arguments.duplicate()

func use_argument(argument: DebateArgument) -> void:
	Utils.ensure(argument in _unlocked_arguments)
	if not Utils.ensure(argument not in _used_arguments):
		return
	_used_arguments.append(argument)
	_changed_this_frame = true

func is_argument_used(argument: DebateArgument) -> bool:
	return argument in _used_arguments

func add_recent_survey_episode(episode: SurveyEpisode) -> void:
	_recent_survey_episodes.append(episode)
	if _recent_survey_episodes.size() > MAX_RECENT_SURVEY_EPISODES:
		_recent_survey_episodes.remove_at(0)

func get_recent_survey_episodes() -> Array[SurveyEpisode]:
	return _recent_survey_episodes

func set_displayed_museum_exhibit(index: int, image: LazyTextureResource) -> void:
	_displayed_museum_exhibit[index] = image
	_changed_this_frame = true

func get_displayed_museum_exhibit(index: int) -> LazyTextureResource:
	return _displayed_museum_exhibit.get(index, null)

func get_displayed_museum_exhibits() -> Dictionary[int, LazyTextureResource]:
	return _displayed_museum_exhibit.duplicate()

func get_drawn_kanji_shape(symbol: String) -> KanjiShape:
	return _drawn_kanji_shapes.get(symbol, null)

func set_drawn_kanji_shape(symbol: String, shape: KanjiShape) -> void:
	if not Utils.ensure(symbol.length() == 1):
		return
	if not Utils.ensure(shape != null):
		return
	_drawn_kanji_shapes[symbol] = shape
	_changed_this_frame = true

func mark_used_cheats() -> void:
	_used_cheats = true

func has_used_cheats() -> bool:
	return _used_cheats

static func _get_slot_base_path(slot: int) -> String:
	return BASE_PATH % (slot + 1)

func _get_past_run_file_path(uid: int) -> String:
	return _get_slot_base_path(_current_slot) + '/' + (PAST_RUN_BASENAME % uid) + '.json'

func _get_past_run_screenshot_file_path(uid: int) -> String:
	return _get_slot_base_path(_current_slot) + '/' + (PAST_RUN_BASENAME % uid) + '.jpg'

func get_encoded_save_data() -> String:
	# Only used for bug reports.
	return JSON.stringify(_encode_save_data(), '\t')

func get_written_save_data() -> String:
	# Only used for bug reports.
	var save_file := FileAccess.open(_get_slot_base_path(_current_slot) + '/' + DATA_FILENAME, FileAccess.READ)
	return save_file.get_as_text() if save_file else ''

func clear() -> void:
	_last_saved_timestamp = -1
	_total_playtime = 0
	_current_date = 0
	_unlocked_cards.clear()
	_signature_cards.clear()
	_replaced_cards.clear()
	_inherited_card = null
	_current_companion = null
	_next_run_seed = -1
	_starting_relic = null
	_banned_hauntings.clear()
	_pinned_events.clear()
	insights = 0
	for stroke in Stroke.get_all_strokes():
		_strokes[stroke] = 0
	_unlocked_skills.clear()
	_revealed_skills.clear()
	_unlocked_companions.clear()
	_events_state.clear()
	if _events_state.changed.is_connected(_mark_changed):
		_events_state.changed.disconnect(_mark_changed)
	_run_data = null
	for instance in _quest_instances:
		instance.free()
	_quest_instances.clear()
	_hub_random.reseed(0)
	_seen_cards.clear()
	_seen_relics.clear()
	_seen_shops.clear()
	_seen_upgrades.clear()
	_seen_hauntings.clear()
	_seen_event_choices.clear()
	_seen_surveys.clear()
	_seen_survey_choices.clear()
	_seen_skills.clear()
	_seen_dialogues.clear()
	_seen_settler_quests.clear()
	_past_runs.clear()
	_shard_type_progress.clear()
	_pinned_shard_type = null
	_explored_shards.clear()
	_queued_trip_uids.clear()
	_finished_trip_uids.clear()
	_unlocked_arguments.clear()
	_used_arguments.clear()
	_recent_survey_episodes.clear()
	_displayed_museum_exhibit.clear()
	_drawn_kanji_shapes.clear()
	_used_cheats = false
	_changed_this_frame = true

func _encode_save_data() -> Dictionary[String, Variant]:
	var save_data := {} as Dictionary[String, Variant]

	save_data['version'] = VERSION
	save_data['timestamp'] = _last_saved_timestamp
	save_data['total_playtime'] = _total_playtime
	save_data['playthrough_seed'] = _playthrough_seed
	save_data['current_date'] = _current_date

	var unlocked_card_symbols := PackedStringArray()
	for card_type in _unlocked_cards:
		unlocked_card_symbols.append(card_type.symbol)
	save_data['unlocked_cards'] = ''.join(unlocked_card_symbols)

	var signature_card_symbols := PackedStringArray()
	for card_type in _signature_cards:
		signature_card_symbols.append(card_type.symbol)
	save_data['signature_cards'] = ''.join(signature_card_symbols)

	var encoded_replaced_cards: Dictionary[String, String] = {}
	for starter_card_type in _replaced_cards:
		encoded_replaced_cards[starter_card_type.symbol] = _replaced_cards[starter_card_type].symbol
	save_data['replaced_cards'] = encoded_replaced_cards

	if _inherited_card:
		save_data['inherited_card'] = _inherited_card.symbol

	save_data['insights'] = insights

	var stroke_counts: Dictionary[String, int] = {}
	for stroke in _strokes:
		stroke_counts[stroke.character] = _strokes[stroke]
	save_data['strokes'] = stroke_counts

	var skill_ids := PackedStringArray()
	for skill in _unlocked_skills:
		skill_ids.append(skill.skill_id)
	save_data['skills'] = skill_ids

	var revealed_skill_ids := PackedStringArray()
	for skill in _revealed_skills:
		revealed_skill_ids.append(skill.skill_id)
	save_data['revealed_skills'] = revealed_skill_ids

	var companion_ids := PackedStringArray()
	for companion in _unlocked_companions:
		companion_ids.append(companion.companion_id)
	save_data['companions'] = companion_ids
	save_data['current_companion'] = _current_companion.companion_id if _current_companion else ''

	save_data['next_run_seed'] = _next_run_seed

	save_data['starting_relic'] = _starting_relic.relic_id if _starting_relic else ''
	save_data['banned_hauntings'] = _banned_hauntings.map(func(h: HauntingType) -> String: return h.haunting_id)
	save_data['pinned_events'] = _pinned_events.map(func(e: Event) -> String: return e.event_id)

	save_data['events_state'] = _events_state.to_flat()

	if _run_data:
		save_data['run_data'] = _run_data.encode()

	var encoded_quest_state := {}
	for instance in _quest_instances:
		encoded_quest_state[instance.get_quest().quest_id] = [instance.get_state()]
		for goal in instance.get_current_goals():
			(encoded_quest_state[instance.get_quest().quest_id] as Array).append(goal.completed)
	save_data['quests'] = encoded_quest_state

	save_data['hub_random'] = _hub_random.encode()

	var seen_card_symbols := PackedStringArray()
	for card_type in _seen_cards:
		seen_card_symbols.append(card_type.symbol)
	save_data['seen_cards'] = ''.join(seen_card_symbols)

	save_data['seen_relics'] = _seen_relics.keys()

	var seen_shop_ids := PackedStringArray()
	for shop_type in _seen_shops:
		seen_shop_ids.append(shop_type.shop_id)
	save_data['seen_shops'] = seen_shop_ids

	var seen_dialogues := {}
	for dialogue in _seen_dialogues:
		seen_dialogues[dialogue.dialogue_id] = _seen_dialogues[dialogue]
	save_data['seen_dialogues'] = seen_dialogues

	var seen_upgrade_ids := PackedStringArray()
	for spot_upgrade in _seen_upgrades:
		seen_upgrade_ids.append(spot_upgrade.spot_upgrade_id)
	save_data['seen_upgrades'] = seen_upgrade_ids

	var seen_hauntings_by_id: Dictionary[String, bool] = {}
	for haunting_type in _seen_hauntings:
		seen_hauntings_by_id[haunting_type.haunting_id] = _seen_hauntings[haunting_type]
	save_data['seen_hauntings'] = seen_hauntings_by_id

	var seen_event_choices_by_id: Dictionary[String, int] = {}
	for event in _seen_event_choices:
		seen_event_choices_by_id[event.event_id] = _seen_event_choices[event]
	save_data['seen_event_choices'] = seen_event_choices_by_id

	var seen_survey_ids: Array[String] = []
	for episode in _seen_surveys:
		seen_survey_ids.append(episode.episode_id)
	save_data['seen_surveys'] = seen_survey_ids

	var seen_survey_choices_by_id: Dictionary[String, int] = {}
	for episode in _seen_survey_choices:
		seen_survey_choices_by_id[episode.episode_id] = _seen_survey_choices[episode]
	save_data['seen_survey_choices'] = seen_survey_choices_by_id

	var seen_skill_ids := PackedStringArray()
	for skill in _seen_skills:
		seen_skill_ids.append(skill.skill_id)
	save_data['seen_skills'] = seen_skill_ids

	var seen_settler_quests_by_id: Dictionary[String, bool] = {}
	for settler_quest in _seen_settler_quests:
		seen_settler_quests_by_id[settler_quest.quest_id] = _seen_settler_quests[settler_quest]
	save_data['seen_settler_quests'] = seen_settler_quests_by_id

	var past_run_ids := PackedStringArray()
	for uid: int in _past_runs.keys():
		past_run_ids.append(str(uid))
	save_data['past_run_ids'] = past_run_ids

	var shard_type_progress_by_id: Dictionary[String, Dictionary] = {}
	for shard_type in _shard_type_progress:
		shard_type_progress_by_id[shard_type.shard_type_id] = _shard_type_progress[shard_type].encode()
	save_data['shard_type_progress'] = shard_type_progress_by_id

	if _pinned_shard_type:
		save_data['pinned_shard_type'] = _pinned_shard_type.shard_type_id

	save_data['explored_shards'] = _explored_shards

	save_data['queued_trip_uids'] = _queued_trip_uids
	save_data['finished_trip_uids'] = _finished_trip_uids

	var unlocked_argument_ids := PackedStringArray()
	for argument in _unlocked_arguments:
		unlocked_argument_ids.append(argument.argument_id)
	save_data['unlocked_arguments'] = unlocked_argument_ids

	var used_argument_ids := PackedStringArray()
	for argument in _used_arguments:
		used_argument_ids.append(argument.argument_id)
	save_data['used_arguments'] = used_argument_ids

	var recent_survey_episode_ids := PackedStringArray()
	for episode in _recent_survey_episodes:
		recent_survey_episode_ids.append(episode.episode_id)
	save_data['recent_survey_episodes'] = recent_survey_episode_ids

	var encoded_displayed_museum_exhibit: Dictionary[int, String] = {}
	for exhibit_index in _displayed_museum_exhibit:
		var path: String = ''
		if _displayed_museum_exhibit[exhibit_index]:
			path = _displayed_museum_exhibit[exhibit_index]._texture_path
		encoded_displayed_museum_exhibit[exhibit_index] = path
	save_data['displayed_museum_exhibit'] = encoded_displayed_museum_exhibit

	var encoded_drawn_kanji_shapes: Dictionary[String, Array] = {}
	for symbol in _drawn_kanji_shapes:
		encoded_drawn_kanji_shapes[symbol] = _drawn_kanji_shapes[symbol].encode()
	save_data['drawn_kanji_shapes'] = encoded_drawn_kanji_shapes

	save_data['used_cheats'] = _used_cheats

	return save_data

func _decode_save_data(save_data: Dictionary) -> void:
	clear()

	if save_data.get('version', 0) < VERSION:
		push_warning('Savegame uses outdated version. Not loading.')
		return

	_last_saved_timestamp = save_data.get('timestamp', -1) as int
	_total_playtime = save_data.get('total_playtime', 0.0) as float
	_playthrough_seed = save_data.get('playthrough_seed', 42) as int
	_current_date = save_data.get('current_date', (save_data.get('past_run_ids', []) as Array).size()) as int

	for card_symbol: String in save_data.get('unlocked_cards', ''):
		var card_type := CardType.get_card_type_by_name_or_symbol(card_symbol)
		if not card_type:
			push_warning('Savegame contains unrecognized unlocked card (%s). Skipping.' % card_symbol)
			continue
		_unlocked_cards[card_type] = true

	for card_symbol: String in save_data.get('signature_cards', ''):
		var card_type := CardType.get_card_type_by_name_or_symbol(card_symbol)
		if not card_type:
			push_warning('Savegame contains unrecognized signature card (%s). Skipping.' % card_symbol)
			continue
		_signature_cards.append(card_type)

	var encoded_replaced_cards := save_data.get('replaced_cards', {}) as Dictionary

	var used_cards: Dictionary[CardType, bool]
	for starter_card_type in get_starter_cards():
		used_cards[starter_card_type] = true
		for replaced_original: String in encoded_replaced_cards:
			used_cards[CardType.get_card_type_by_name_or_symbol(replaced_original)] = false
	for card_symbol: String in encoded_replaced_cards:
		var starter_type := CardType.get_card_type_by_name_or_symbol(card_symbol)
		if not Utils.ensure(starter_type in get_starter_cards()):
			continue
		var new_type := CardType.get_card_type_by_name_or_symbol(encoded_replaced_cards[card_symbol] as String)
		if not new_type:
			push_warning('Savegame contains unrecognized card replacement (%s). Skipping.' % card_symbol)
			continue
		if new_type.rarity > CardType.Rarity.COMMON:
			push_warning('Skipping card replacement of too high rarity (%s).' % card_symbol)
			continue
		if used_cards.get(new_type, false):
			push_warning('Skipping duplicate replacement card (%s->%s).' % [card_symbol, new_type])
			continue
		used_cards.erase(starter_type)
		_replaced_cards[starter_type] = new_type
		used_cards[new_type] = true

	var inherited_card_symbol := save_data.get('inherited_card', '') as String
	if inherited_card_symbol:
		_inherited_card = CardType.get_card_type_by_name_or_symbol(inherited_card_symbol)
		if not _inherited_card:
			push_warning('Savegame contains unrecognized inherited card (%s). Skipping.' % inherited_card_symbol)

	insights = save_data.get('insights', 0)

	var stroke_counts := save_data.get('strokes', {}) as Dictionary
	for stroke in Stroke.get_all_strokes():
		_strokes[stroke] = stroke_counts.get(stroke.character, 0) as int

	for skill_id: String in save_data.get('skills', []):
		var skill := Skill.get_skill_by_id(skill_id)
		if not skill:
			push_warning('Savegame contains unrecognized skill (%s). Skipping.' % skill_id)
			continue
		_unlocked_skills[skill] = true

	for skill_id: String in save_data.get('revealed_skills', []):
		var skill := Skill.get_skill_by_id(skill_id)
		if not skill:
			push_warning('Savegame contains unrecognized skill (%s). Skipping.' % skill_id)
			continue
		_revealed_skills.append(skill)

	for companion_id: String in save_data.get('companions', []):
		var companion := Companion.get_companion_by_id(companion_id)
		if not companion:
			push_warning('Savegame contains unrecognized companion (%s). Skipping.' % companion_id)
			continue
		_unlocked_companions[companion] = true
	_current_companion = Companion.get_companion_by_id(save_data.get('current_companion', '') as String)

	_next_run_seed = save_data.get('next_run_seed', -1) as int

	_starting_relic = Relic.get_relic_by_id(save_data.get('starting_relic', '') as String)
	_banned_hauntings.assign((save_data.get('banned_hauntings', []) as Array).map(HauntingType.get_haunting_type_by_id))
	_pinned_events.assign((save_data.get('pinned_events', []) as Array).map(Event.get_event_by_id))

	_events_state.load_from_flat(save_data.get('events_state', {}) as Dictionary)

	if save_data.get('run_data', null):
		_run_data = RunData.decode(save_data.get('run_data') as Dictionary)
	else:
		_run_data = null

	var encoded_quest_state := save_data.get('quests', {}) as Dictionary
	for quest_id: String in encoded_quest_state:
		var quest := Quest.get_quest_by_id(quest_id)
		var quest_data := encoded_quest_state[quest_id] as Array
		var goal_state: Array[bool]
		goal_state.assign(quest_data.slice(1))
		_quest_instances.append(quest.instantiate(quest_data[0] as int, goal_state))

	if 'hub_random' in save_data:
		_hub_random.decode(save_data['hub_random'] as String)
	else:
		_hub_random.reseed(42)  # Old savegame.

	for card_symbol: String in save_data.get('seen_cards', ''):
		var card_type := CardType.get_card_type_by_name_or_symbol(card_symbol)
		if not card_type:
			push_warning('Savegame contains unrecognized seen card (%s). Skipping.' % card_symbol)
			continue
		_seen_cards[card_type] = true

	for relic_id: String in save_data.get('seen_relics', []):
		if not Relic.get_relic_by_id(relic_id):
			push_warning('Savegame contains unrecognized seen relic (%s). Skipping.' % relic_id)
			continue
		_seen_relics[relic_id] = true

	for shop_id: String in save_data.get('seen_shops', []):
		var shop_type := ShopType.get_shop_type_by_id(shop_id)
		if not shop_type:
			push_warning('Savegame contains unrecognized seen shop type (%s). Skipping.' % shop_id)
			continue
		_seen_shops[shop_type] = true

	var encoded_seen_dialogues: Variant = save_data.get('seen_dialogues', {})
	if encoded_seen_dialogues is Array:  # Backward-compatiblity, best effort
		var converted := {}
		var regex := RegEx.create_from_string(r'_(\d)_(\d{2})_')
		for dialogue_id: String in (encoded_seen_dialogues as Array):
			if dialogue_id.begins_with('debate_'):
				converted[dialogue_id] = MainQuestProgress.P430_STARTED_DEBATE
				continue
			var m := regex.search(dialogue_id)
			if m:
				var mq_progress := (m.get_string(1) + m.get_string(2)).to_int()
				if mq_progress < MainQuestProgress.NEVER_REACHED:
					converted[dialogue_id] = mq_progress as MainQuestProgress
					continue
			converted[dialogue_id] = get_main_quest_progress()  # Fallback; state loaded earlier.
		encoded_seen_dialogues = converted
	for dialogue_id: String in encoded_seen_dialogues:
		var dialogue := Dialogue.get_dialogue_by_id(dialogue_id)
		if not dialogue:
			push_warning('Savegame contains unrecognized seen dialogue (%s). Skipping.' % dialogue_id)
			continue
		_seen_dialogues[dialogue] = encoded_seen_dialogues[dialogue_id]

	for spot_upgrade_id: String in save_data.get('seen_upgrades', []):
		var spot_upgrade := SpotUpgrade.get_spot_upgrade_by_id(spot_upgrade_id)
		if not spot_upgrade:
			push_warning('Savegame contains unrecognized seen upgrade (%s). Skipping.' % spot_upgrade_id)
			continue
		_seen_upgrades[spot_upgrade] = true

	var seen_hauntings_by_id := save_data.get('seen_hauntings', {}) as Dictionary
	for haunting_id: String in seen_hauntings_by_id:
		var haunting := HauntingType.get_haunting_type_by_id(haunting_id)
		if not haunting:
			push_warning('Savegame contains unrecognized haunting (%s). Skipping.' % haunting_id)
			continue
		_seen_hauntings[haunting] = seen_hauntings_by_id[haunting_id]

	var seen_event_choices_by_id := save_data.get('seen_event_choices', {}) as Dictionary
	for event_id: String in seen_event_choices_by_id:
		var event := Event.get_event_by_id(event_id)
		if not event:
			push_warning('Savegame contains unrecognized event (%s). Skipping.' % event_id)
			continue
		_seen_event_choices[event] = seen_event_choices_by_id[event_id] as int

	for episode_id: String in save_data.get('seen_surveys', []):
		var episode := SurveyEpisode.get_episode_by_id(episode_id)
		if not episode:
			push_warning('Savegame contains unrecognized seen survey episode (%s). Skipping.' % episode_id)
			continue
		_seen_surveys[episode] = true

	var seen_survey_choices_by_id := save_data.get('seen_survey_choices', {}) as Dictionary
	for episode_id: String in seen_survey_choices_by_id:
		var episode := SurveyEpisode.get_episode_by_id(episode_id)
		if not episode:
			push_warning('Savegame contains unrecognized survey episode (%s). Skipping.' % episode_id)
			continue
		_seen_survey_choices[episode] = seen_survey_choices_by_id[episode_id] as int

	for skill_id: String in save_data.get('seen_skills', []):
		var skill := Skill.get_skill_by_id(skill_id)
		if not skill:
			push_warning('Savegame contains unrecognized seen skill (%s). Skipping.' % skill_id)
			continue
		_seen_skills[skill] = true

	var seen_settler_quests_by_id := save_data.get('seen_settler_quests', {}) as Dictionary
	for settler_quest_id: String in seen_settler_quests_by_id:
		var settler_quest := Quest.get_quest_by_id(settler_quest_id)
		if settler_quest is not Quest_Settler:
			push_warning('Savegame contains unrecognized settler quest (%s). Skipping.' % settler_quest_id)
			continue
		_seen_settler_quests[settler_quest as Quest_Settler] = seen_settler_quests_by_id[settler_quest_id]

	for past_run_id: String in save_data.get('past_run_ids', []):
		_past_runs[int(past_run_id)] = null  # Loaded on demand.

	var shard_type_progress_by_id := save_data.get('shard_type_progress', {}) as Dictionary
	for shard_type_id: String in shard_type_progress_by_id:
		var shard_type := ShardType.get_shard_type_by_id(shard_type_id)
		if not shard_type:
			push_warning('Savegame contains unrecognized unlocked shard_type (%s). Skipping.' % shard_type_id)
			continue
		var shard_type_progress_data: Variant = shard_type_progress_by_id[shard_type_id]
		if shard_type_progress_data is int or shard_type_progress_data is float:
			# COMPATIBILITY: Lossily convert old format.
			_shard_type_progress[shard_type] = ShardTypeProgress.new(shard_type)
			for _i in (shard_type_progress_data as int):
				_shard_type_progress[shard_type].increment_progress()
		else:
			if Utils.ensure(shard_type_progress_data is Dictionary):
				_shard_type_progress[shard_type] = ShardTypeProgress.decode(
					shard_type, shard_type_progress_data as Dictionary)

	var pinned_shard_type_id := save_data.get('pinned_shard_type', '') as String
	if pinned_shard_type_id:
		_pinned_shard_type = ShardType.get_shard_type_by_id(pinned_shard_type_id)

	_explored_shards.assign(save_data.get('explored_shards', []) as Array)

	_queued_trip_uids.assign(save_data.get('queued_trip_uids', []) as Array)
	_finished_trip_uids.assign(save_data.get('finished_trip_uids', []) as Array)
	if save_data.get('current_trip_uid', 0):  # Backward-compatibility.
		_queued_trip_uids.append(save_data['current_trip_uid'])
		if save_data.get('current_trip_finished', false):
			_finished_trip_uids.append(_queued_trip_uids.pop_back())

	for argument_id: String in save_data.get('unlocked_arguments', []):
		var argument := DebateArgument.get_argument_by_id(argument_id)
		if not argument:
			push_warning('Savegame contains unrecognized unlocked argument (%s). Skipping.' % argument_id)
			continue
		_unlocked_arguments.append(argument)
	for argument_id: String in save_data.get('used_arguments', []):
		var argument := DebateArgument.get_argument_by_id(argument_id)
		if not argument:
			push_warning('Savegame contains unrecognized used argument (%s). Skipping.' % argument_id)
			continue
		_used_arguments.append(argument)

	for episode_id: String in save_data.get('recent_survey_episodes', []):
		var episode := SurveyEpisode.get_episode_by_id(episode_id)
		if not episode:
			push_warning('Savegame contains unrecognized recent survey episode (%s). Skipping.' % episode_id)
			continue
		_recent_survey_episodes.append(episode)

	var encoded_displayed_museum_exhibit := save_data.get('displayed_museum_exhibit', {}) as Dictionary
	for exhibit_index_str: String in encoded_displayed_museum_exhibit:
		var exhibit_index := exhibit_index_str.to_int()
		var path := encoded_displayed_museum_exhibit[exhibit_index_str] as String
		if path:
			var texture := LazyTextureResource.new()
			texture._texture_path = path
			_displayed_museum_exhibit[exhibit_index] = texture
		else:
			_displayed_museum_exhibit[exhibit_index] = null

	var encoded_drawn_kanji_shapes := save_data.get('drawn_kanji_shapes', {}) as Dictionary
	for symbol: String in encoded_drawn_kanji_shapes:
		_drawn_kanji_shapes[symbol] = KanjiShape.decode(encoded_drawn_kanji_shapes[symbol] as Array)

	_used_cheats = save_data.get('used_cheats', false)

	# Backward-compatibility: unlock newly added basic/common cards.
	_unlock_default_cards()
	# Backward-compatibility: unlock newly added root skills (e.g. surveys).
	_check_autounlocked_skills()
	# Backward-compatibility: fix premature surveys unlock.
	_hotfix_premature_surveys()

func _save_past_run(past_run: PastRun) -> bool:
	past_run.validate()
	var f := FileAccess.open(_get_past_run_file_path(past_run.uid), FileAccess.WRITE)
	if not f:
		return false
	var encoded_data := {} as Dictionary[String, Variant]
	encoded_data['uid'] = str(past_run.uid)  # JSON stores floats!
	encoded_data['run_data'] = past_run.run_data.encode()
	encoded_data['shard_name'] = past_run.shard_name
	encoded_data['shard_name_jp'] = past_run.shard_name_jp
	encoded_data['shard_name_meaning'] = past_run.shard_name_meaning
	if past_run.shard_type:
		encoded_data['shard_type'] = past_run.shard_type.shard_type_id
	past_run.screenshot.save_jpg(_get_past_run_screenshot_file_path(past_run.uid))
	encoded_data['date_settled'] = past_run.date_settled
	f.store_line(JSON.stringify(encoded_data, '' if Utils.is_packaged() else '\t'))
	f.close()
	return true

func _load_past_run(uid: int) -> PastRun:
	var f := FileAccess.open(_get_past_run_file_path(uid), FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(f.get_as_text())
	if parse_result != OK:
		return null
	var encoded_data := json.data as Dictionary
	if not Utils.ensure(int(encoded_data['uid'] as String) == uid):
		return null
	var past_run := PastRun.new()
	past_run.uid = uid
	past_run.run_data = RunData.decode(encoded_data['run_data'] as Dictionary)
	past_run.shard_name = encoded_data['shard_name']
	past_run.shard_name_jp = encoded_data.get('shard_name_jp', '')
	past_run.shard_name_meaning = encoded_data.get('shard_name_meaning', '')
	var shard_type_id := encoded_data.get('shard_type', '') as String
	if shard_type_id:
		past_run.shard_type = ShardType.get_shard_type_by_id(shard_type_id)
	past_run.screenshot = Image.load_from_file(_get_past_run_screenshot_file_path(uid))
	past_run.date_settled = encoded_data.get('date_settled', 0) as int
	if not past_run.date_settled:  # Old savegames
		var all_uids := get_past_run_ids()
		all_uids.sort()
		past_run.date_settled = min(all_uids.find(uid), _current_date)
	return past_run

func _unlock_default_cards() -> void:
	for card_type in get_starter_cards():
		_unlocked_cards[card_type] = true
		_seen_cards[card_type] = true
	for card_type in (AUTO_SEEN_CARDSET.get_loaded() as CardSet).card_types:
		_seen_cards[card_type] = true
	for card_type in get_auto_unlocked_cards():
		_unlocked_cards[card_type] = true

func _check_autounlocked_skills() -> void:
	for skill: Skill in Skill.get_all_skills().values():
		if not skill.requirement and not has_unlocked_skill(skill):
			if get_main_quest_progress() >= skill.min_main_quest_progress:
				unlock_skill(skill)

func _hotfix_premature_surveys() -> void:
	if get_main_quest_progress() < MainQuestProgress.P116_UNLOCKED_SURVEY:
		_unlocked_skills.erase(Skill.get_skill_by_id('survey_root'))
		if _run_data and _run_data.state in [RunData.State.SURVEY, RunData.State.SURVEY_SELECTOR, RunData.State.SURVEY_END]:
			_run_data.state = RunData.State.STAGE_SELECTOR

func _has_pacify_ability(card_type: CardType) -> bool:
	for ability in card_type.abilities:
		if ability is CardAbility_Pacify:
			return true
	return false

func _mark_changed() -> void:
	_changed_this_frame = true

class ShardTypeProgress extends RefCounted:
	var shard_type: ShardType
	var history_progress: Array[ShardTypeHistoryProgress]

	func _init(init_shard_type: ShardType) -> void:
		shard_type = init_shard_type
		for _i in shard_type.history.size():
			history_progress.append(ShardTypeHistoryProgress.new())

	func is_history_started(index: int) -> bool:
		if index > 0 and not is_history_completed(index - 1):
			return false
		return GlobalSaveGame.get_main_quest_progress() >= shard_type.history[index].min_main_quest

	func is_history_completed(index: int) -> bool:
		if GlobalSaveGame.get_main_quest_progress() < shard_type.history[index].min_main_quest:
			return false
		return history_progress[index].num_seasons_since_started >= shard_type.history[index].time_taken

	func is_history_seen(index: int) -> bool:
		return history_progress[index].is_seen

	func increment_progress() -> void:
		for i in history_progress.size():
			if is_history_started(i) and not is_history_completed(i):
				history_progress[i].num_seasons_since_started += 1
				break

	func set_history_seen(index: int) -> void:
		if not Utils.ensure(is_history_completed(index)):
			return
		history_progress[index].is_seen = true

	func get_num_histories() -> int:
		return history_progress.size()

	func get_num_histories_completed() -> int:
		var completed := 0
		for i in history_progress.size():
			if is_history_completed(i):
				completed += 1
			else:
				break
		return completed

	func are_all_histories_completed() -> bool:
		return get_num_histories_completed() >= get_num_histories()

	func get_num_histories_seen() -> int:
		var seen := 0
		for i in history_progress.size():
			if is_history_seen(i):
				seen += 1
			else:
				break
		return seen

	func encode() -> Dictionary:
		var result: Dictionary
		var histories: Array[Dictionary]
		for progress in history_progress:
			histories.append({'progress': progress.num_seasons_since_started, 'seen': progress.is_seen})
		result['histories'] = histories
		return result

	static func decode(in_shard_type: ShardType, encoded_data: Dictionary) -> ShardTypeProgress:
		var histories := encoded_data.get('histories', []) as Array
		if not Utils.ensure(histories.size() <= in_shard_type.history.size()):
			histories.resize(in_shard_type.history.size())
		var result := ShardTypeProgress.new(in_shard_type)
		for i in histories.size():
			result.history_progress[i].num_seasons_since_started = histories[i]['progress'] as int
			result.history_progress[i].is_seen = histories[i]['seen'] as bool
		return result

class ShardTypeHistoryProgress extends RefCounted:
	var num_seasons_since_started: int
	var is_seen: bool

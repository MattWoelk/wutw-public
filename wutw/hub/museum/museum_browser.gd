class_name MuseumBrowser
extends Node2D

signal closed

static var TILE_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_tile.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var DETAIL_HAUNTING_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_detail_haunting.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var DETAIL_EVENT_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_detail_event.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var DETAIL_SURVEY_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_detail_survey.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var DETAIL_RELIC_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_detail_relic.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var DETAIL_SHOP_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_detail_shop.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var DETAIL_DIALOGUE_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_detail_dialogue.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var DETAIL_HISTORICAL_RECORD_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_detail_historical_record.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var DETAIL_COMPANION_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_detail_companion.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var DETAIL_SPOT_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_detail_spot.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var DETAIL_SETTLER_QUEST_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_detail_settler_quest.tscn', false, AsyncLoadedResource.LoadPhase.UNLIKELY)
static var MUSEUM_BROWSER_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_browser.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

static var _active_instance: MuseumBrowser  # Singleton - needed for handling links.

var _initial_resource_to_open: Resource
var _closing := false
var _exhibits_button_group: ButtonGroup
var _showing_cutscene := false

func _ready() -> void:
	_exhibits_button_group = ButtonGroup.new()
	(%TabButton_Spots as Button).button_pressed = true  # Doesn't emit pressed.

	if not Utils.are_surveys_unlocked():
		(%TabButton_Surveys as Button).disabled = true
		(%TabButton_Surveys as Button).text = tr('???')

	if not Utils.are_hauntings_unlocked():
		(%TabButton_Hauntings as Button).disabled = true
		(%TabButton_Hauntings as Button).text = tr('???')
	else:
		(%TabButton_Hauntings as Button).text = tr('Challenges') if Utils.is_realistic_era() else tr('Hauntings')

	if not Utils.are_animal_companions_unlocked():
		(%TabButton_Companions as Button).disabled = true
		(%TabButton_Companions as Button).text = tr('???')

	if not Utils.is_settler_questing_unlocked():
		(%TabButton_SettlerQuests as Button).disabled = true
		(%TabButton_SettlerQuests as Button).text = tr('???')

	(%ScrollPanel as ScrollPanel).animate_unroll()

	if _initial_resource_to_open:
		_select_query_result(_initial_resource_to_open)
		_initial_resource_to_open = null
	else:
		_on_tab_button_spots_pressed()

func _enter_tree() -> void:
	assert(not _active_instance)
	_active_instance = self

func _exit_tree() -> void:
	assert(_active_instance)
	_active_instance = null

func _handle_esc() -> bool:
	if _showing_cutscene:
		return false
	else:
		_close()
		return true

static func open_museum_entry(resource: Resource, layer: UI.Layer) -> MuseumBrowser:
	if _active_instance:
		_active_instance._select_query_result(resource)
	elif Utils.get_active_hub():
		# HACK: Hub needs to track open menus.
		Utils.get_active_hub().open_museum(resource, layer)
	else:
		var viewer := MUSEUM_BROWSER_SCENE.instantiate_loaded_scene() as MuseumBrowser
		viewer._initial_resource_to_open = resource
		await GlobalUI.get_tree().process_frame  # Spread load across frames.
		GlobalUI.add_layer_content(viewer, layer)
	return _active_instance

static func get_active_instance() -> MuseumBrowser:
	return _active_instance

static func open_link(query: String) -> void:
	var pieces := query.split(':', true, 1)
	assert(pieces.size() == 2)
	var exhibit_id := pieces[1].to_lower()
	var layer := GlobalUI.choose_dynamic_menu_layer()
	match pieces[0]:
		'museum_companion':
			open_museum_entry(Companion.get_companion_by_id(exhibit_id), layer)
		'museum_spot':
			open_museum_entry(SpotType.get_spot_type_by_id(exhibit_id), layer)
		'museum_spot_upgrade':
			open_museum_entry(SpotUpgrade.get_spot_upgrade_by_id(exhibit_id), layer)
		'museum_relic':
			open_museum_entry(Relic.get_relic_by_id(exhibit_id), layer)
		'museum_event':
			open_museum_entry(Event.get_event_by_id(exhibit_id), layer)
		'museum_encounter':
			open_museum_entry(SurveyEpisode.get_episode_by_id(exhibit_id), layer)
		'museum_haunting':
			open_museum_entry(HauntingType.get_haunting_type_by_id(exhibit_id), layer)
		'museum_shop':
			open_museum_entry(ShopType.get_shop_type_by_id(exhibit_id), layer)
		'museum_settler_quest':
			open_museum_entry(Quest.get_quest_by_id(exhibit_id), layer)
		_:
			assert(false)

func _on_close_button_pressed() -> void:
	_close()

func _close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		closed.emit()
		queue_free()

func _on_tab_button_companions_pressed() -> void:
	_fill_list(Companion.get_all_companions(),
			   func(c: Companion) -> Texture2D: return c.image,
			   GlobalSaveGame.has_unlocked_companion)

func _on_tab_button_spots_pressed() -> void:
	var spot_types := SpotType.get_all_spot_types()
	spot_types.sort_custom(func(a: SpotType, b: SpotType) -> bool:
		return a.sort_order < b.sort_order
	)
	_fill_list(spot_types,
			   func(s: SpotType) -> Texture2D: return s.preview_image,
			   func(s: SpotType) -> bool: return s.get_all_upgrades().any(GlobalSaveGame.has_seen_upgrade))

func _on_tab_button_relics_pressed() -> void:
	var relics := Relic.get_all_relics().duplicate()
	relics.sort_custom(func(a: Relic, b: Relic) -> bool:
		if a.rarity != b.rarity:
			return a.rarity < b.rarity
		elif ('talisman_' in a.relic_id) != ('talisman_' in b.relic_id):
			return 'talisman_' in b.relic_id
		else:
			return a.default_name < b.default_name
	)
	_fill_list(relics,
			   func(r: Relic) -> Texture2D: return r.icon,
			   GlobalSaveGame.has_seen_relic)

func _on_tab_button_events_pressed() -> void:
	var events: Array[Event]
	# Exclude dialogue-only events.
	for event: Event in Event.get_all_events().values():
		if event.steps and not Event.Category.SECRET in event.categories:
			events.append(event)
	_fill_list(events,
			   func(e: Event) -> LazyTextureResource: return e.steps[0].background_image,
			   GlobalSaveGame.has_seen_event)

func _on_tab_button_surveys_pressed() -> void:
	_fill_list(SurveyEpisode.get_all_episodes().values(),
			   func(e: SurveyEpisode) -> LazyTextureResource: return e.background_image,
			   GlobalSaveGame.has_seen_survey)

func _on_tab_button_hauntings_pressed() -> void:
	_fill_list(HauntingType.get_all_haunting_types(),
			   func(h: HauntingType) -> Texture2D:
					return h.image_small_realistic if Utils.is_realistic_era() else h.image_small,
			   GlobalSaveGame.has_seen_haunting)

func _on_tab_button_shops_pressed() -> void:
	_fill_list(ShopType.get_all_shop_types(),
			   func(s: ShopType) -> Texture2D: return s.background_texture,
			   GlobalSaveGame.has_seen_shop)

func _on_tab_button_settler_quests_pressed() -> void:
	var settler_quests: Array[Quest_Settler]
	for quest: Quest in Quest.get_all_quests().values():
		if quest is Quest_Settler:
			settler_quests.append(quest as Quest_Settler)
	_fill_list(settler_quests,
			   func(_s: Quest_Settler) -> Texture2D: return null,  # MuseumTile handles this exceptional case natively.
			   GlobalSaveGame.has_seen_settler_quest)

func _on_tab_button_records_pressed() -> void:
	var entries: Array[HistoricalRecordEntry]
	entries.append(HistoricalRecordEntry.new(
		load('res://hub/museum/historical_record_cutscene_intro.tres') as HistoricalRecord,
		SaveGame.MainQuestProgress.P000_INTRO))
	if GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P200_STARTED_MAGIC:
		entries.append(HistoricalRecordEntry.new(
			load('res://hub/museum/historical_record_cutscene_1to2.tres') as HistoricalRecord,
			SaveGame.MainQuestProgress.P200_STARTED_MAGIC))
	if GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P300_STARTED_LEADERSHIP:
		entries.append(HistoricalRecordEntry.new(
			load('res://hub/museum/historical_record_cutscene_2to3.tres') as HistoricalRecord,
			SaveGame.MainQuestProgress.P300_STARTED_LEADERSHIP))
	if GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P400_STARTED_DEPRESSION:
		entries.append(HistoricalRecordEntry.new(
			load('res://hub/museum/historical_record_cutscene_3to4.tres') as HistoricalRecord,
			SaveGame.MainQuestProgress.P400_STARTED_DEPRESSION))
	if GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P435_TRANSLATED_COMMANDMENTS:
		entries.append(HistoricalRecordEntry.new(
			load('res://hub/museum/historical_record_commandments.tres') as HistoricalRecord,
			SaveGame.MainQuestProgress.P435_TRANSLATED_COMMANDMENTS))
	if GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P500_STARTED:
		entries.append(HistoricalRecordEntry.new(
			load('res://hub/museum/historical_record_cutscene_outro.tres') as HistoricalRecord,
			SaveGame.MainQuestProgress.P500_STARTED))
	for dialogue in GlobalSaveGame.get_seen_dialogues():
		entries.append(HistoricalRecordEntry.new(
			dialogue,
			GlobalSaveGame.get_seen_dialogue_mq_state(dialogue)))
	entries.sort_custom(func(a: HistoricalRecordEntry, b: HistoricalRecordEntry) -> bool:
		# HACK
		if a.mq_state != b.mq_state:
			return a.mq_state < b.mq_state
		if a.record is Dialogue and b.record is Dialogue:
			if (a.record as Dialogue).dialogue_id.ends_with('_begin'):
				return true
			if (b.record as Dialogue).dialogue_id.ends_with('_begin'):
				return false
			if (a.record as Dialogue).dialogue_id.ends_with('_end'):
				return false
			if (b.record as Dialogue).dialogue_id.ends_with('_end'):
				return true
		return a.record is HistoricalRecord
	)
	var records: Array
	for entry in entries:
		records.append(entry.record)
	var get_record_image := func(r: Resource) -> Texture2D:
		if r is HistoricalRecord:
			return (r as HistoricalRecord).icon
		else:
			return null # MuseumTile handles this exceptional case natively.
	_fill_list(records, get_record_image, func(_r: Resource) -> bool: return true)

func _fill_list(objects: Array, get_image: Callable, is_discovered: Callable) -> void:
	Utils.clear_node(%MainList)
	var selected := false
	for exhibit: Resource in objects:
		var tile := TILE_SCENE.instantiate_loaded_scene() as MuseumTile
		tile.button_group = _exhibits_button_group
		tile.exhibit = exhibit
		tile.is_tall = exhibit is Event or exhibit is ShopType
		tile.is_wide = exhibit is SurveyEpisode
		var image: Variant = get_image.call(exhibit)
		if image is LazyTextureResource:
			tile.image_lazy = image
		else:
			tile.image = image
		tile.discovered = is_discovered.call(exhibit)
		tile.pressed.connect(_on_exhibit_selected.bind(exhibit))
		%MainList.add_child(tile)
		if not selected:
			tile.button_pressed = true
			_on_exhibit_selected(exhibit)
			selected = true
	_apply_search()
	if not selected:
		_on_exhibit_selected(null)

func _select_query_result(exhibit: Resource) -> void:
	var exhibit_to_choose := exhibit
	var button: BaseButton
	if exhibit is Companion:
		button = %TabButton_Companions
	elif exhibit is SpotType:
		button = %TabButton_Spots
	elif exhibit is SpotUpgrade:
		exhibit_to_choose = (exhibit as SpotUpgrade).spot
		button = %TabButton_Spots
	elif exhibit is Relic:
		button = %TabButton_Relics
		# In a run, relics are copies.
		exhibit_to_choose = Relic.get_relic_by_id((exhibit as Relic).relic_id)
	elif exhibit is Event:
		button = %TabButton_Events
	elif exhibit is SurveyEpisode:
		button = %TabButton_Surveys
	elif exhibit is HauntingType:
		button = %TabButton_Hauntings
	elif exhibit is ShopType:
		button = %TabButton_Shops
	elif exhibit is Quest_Settler:
		button = %TabButton_SettlerQuests
	elif exhibit is HistoricalRecord or exhibit is Dialogue:
		button = %TabButton_Records
	else:
		assert(false)
		return
	button.button_pressed = true
	button.pressed.emit()
	for tile: MuseumTile in %MainList.get_children():
		if tile.exhibit == exhibit_to_choose:
			tile.button_pressed = true
			_on_exhibit_selected(exhibit_to_choose)
			if exhibit is SpotUpgrade:
				(%DetailsScroller.get_child(0) as MuseumDetail_Spot).select_upgrade(exhibit as SpotUpgrade)
			await get_tree().process_frame
			(%ScrollContainer as ScrollContainer).ensure_control_visible(tile)
			return
	assert(false)

func _on_exhibit_selected(exhibit: Resource) -> void:
	(%DetailsScroller as FadedScrollContainer).fade_enabled = true
	Utils.clear_node(%DetailsScroller)
	var details: Control
	if exhibit is Companion:
		details = _show_companion_details(exhibit as Companion)
	elif exhibit is SpotType:
		details = _show_spot_details(exhibit as SpotType)
	elif exhibit is Relic:
		details = _show_relic_details(exhibit as Relic)
	elif exhibit is Event:
		details = _show_event_details(exhibit as Event)
	elif exhibit is SurveyEpisode:
		details = _show_survey_details(exhibit as SurveyEpisode)
	elif exhibit is HauntingType:
		details = _show_haunting_details(exhibit as HauntingType)
	elif exhibit is ShopType:
		details = _show_shop_details(exhibit as ShopType)
	elif exhibit is Dialogue:
		details = _show_dialogue_details(exhibit as Dialogue)
	elif exhibit is Quest_Settler:
		details = _show_settler_quest_details(exhibit as Quest_Settler)
	elif exhibit is HistoricalRecord:
		details = _show_historical_record_details(exhibit as HistoricalRecord)
	else:
		assert(exhibit == null)
		return
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	%DetailsScroller.add_child(details)

func _show_companion_details(companion: Companion) -> Control:
	var details := DETAIL_COMPANION_SCENE.instantiate_loaded_scene() as MuseumDetail_Companion
	details.companion = companion
	return details

func _show_spot_details(spot_type: SpotType) -> Control:
	var details := DETAIL_SPOT_SCENE.instantiate_loaded_scene() as MuseumDetail_Spot
	details.spot_type = spot_type
	return details

func _show_relic_details(relic: Relic) -> Control:
	var details := DETAIL_RELIC_SCENE.instantiate_loaded_scene() as MuseumDetail_Relic
	details.relic = relic
	return details

func _show_event_details(event: Event) -> Control:
	var details := DETAIL_EVENT_SCENE.instantiate_loaded_scene() as MuseumDetail_Event
	details.event = event
	return details

func _show_survey_details(episode: SurveyEpisode) -> Control:
	var details := DETAIL_SURVEY_SCENE.instantiate_loaded_scene() as MuseumDetail_Survey
	details.episode = episode
	return details

func _show_haunting_details(haunting_type: HauntingType) -> Control:
	var details := DETAIL_HAUNTING_SCENE.instantiate_loaded_scene() as MuseumDetail_Haunting
	details.haunting_type = haunting_type
	return details

func _show_shop_details(shop_type: ShopType) -> Control:
	var details := DETAIL_SHOP_SCENE.instantiate_loaded_scene() as MuseumDetail_Shop
	details.shop_type = shop_type
	return details

func _show_dialogue_details(dialogue: Dialogue) -> Control:
	(%DetailsScroller as FadedScrollContainer).fade_enabled = false
	var details := DETAIL_DIALOGUE_SCENE.instantiate_loaded_scene() as MuseumDetail_Dialogue
	details.dialogue = dialogue
	return details

func _show_settler_quest_details(settler_quest: Quest_Settler) -> Control:
	var details := DETAIL_SETTLER_QUEST_SCENE.instantiate_loaded_scene() as MuseumDetail_SettlerQuest
	details.quest = settler_quest
	return details

func _show_historical_record_details(historical_record: HistoricalRecord) -> Control:
	var details := DETAIL_HISTORICAL_RECORD_SCENE.instantiate_loaded_scene() as MuseumDetail_HistoricalRecord
	details.historical_record = historical_record
	details.cutscene_started.connect(func() -> void: _showing_cutscene = true)
	details.cutscene_finished.connect(func() -> void: _showing_cutscene = false)
	return details

func _on_art_viewer_button_pressed() -> void:
	ArtViewer.open_art_resource(null)

func _on_search_input_text_changed(_new_text: String) -> void:
	_apply_search()

func _apply_search() -> void:
	for tile: MuseumTile in %MainList.get_children():
		tile.visible = Utils.matches_query(_extract_text(tile.exhibit), (%SearchInput as LineEdit).text)

func _extract_text(exhibit: Resource) -> Array[String]:
	if exhibit is Companion:
		var companion := exhibit as Companion
		return [tr(companion.companion_name)]
	elif exhibit is SpotType:
		var spot_type := exhibit as SpotType
		var result: Array[String] = [tr(spot_type.name)]
		for upgrade in spot_type.get_all_upgrades():
			result.append(tr(upgrade.name))
		return result
	elif exhibit is Relic:
		var relic := exhibit as Relic
		return [relic.get_relic_name(false), relic.get_description()]
	elif exhibit is Event:
		return (exhibit as Event).get_search_text()
	elif exhibit is SurveyEpisode:
		var episode := exhibit as SurveyEpisode
		var result: Array[String] = [tr(episode.title), tr(episode.text)]
		for choice in episode.choices:
			result.append(tr(choice.label))
		return result
	elif exhibit is HauntingType:
		var haunting_type := exhibit as HauntingType
		return [tr(haunting_type.name), tr(haunting_type.name_realistic), haunting_type.name_japanese, tr(haunting_type.name_translation), tr(haunting_type.description_long)]
	elif exhibit is ShopType:
		var shop_type := exhibit as ShopType
		return [tr(shop_type.title), shop_type.shop_id]
	elif exhibit is Dialogue:
		var dialogue := exhibit as Dialogue
		return [tr(dialogue.record_title), tr(dialogue.text)]
	elif exhibit is Quest_Settler:
		var settler_quest := exhibit as Quest_Settler
		var result: Array[String] = [tr(settler_quest.name), tr(settler_quest.intro_text)]
		for reward in settler_quest.rewards:
			result.append(reward.describe())
		for challenge in settler_quest.challenges:
			result.append(challenge.describe())
		return result
	elif exhibit is HistoricalRecord:
		var result: Array[String]
		for page in (exhibit as HistoricalRecord).pages:
			result.append(tr(page))
		return result
	else:
		Utils.ensure(false)
		return []

class HistoricalRecordEntry extends RefCounted:
	var record: Resource  # HistoricalRecord or Dialogue
	var mq_state: SaveGame.MainQuestProgress

	func _init(in_record: Resource, in_mq_state: SaveGame.MainQuestProgress) -> void:
		record = in_record
		mq_state = in_mq_state

class_name PastRunDetails
extends Control

signal request_shard_type

static var DECK_VIEWER_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var RELIC_ICON_SCENE := AsyncLoadedResource.new('res://relics/selector/relic_icon.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var PAST_RUN_SETTLEMENT_SCENE := AsyncLoadedResource.new('res://hub/shard_explorer/past_run_settlement.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var PAST_RUN_SURVEY_SCENE := AsyncLoadedResource.new('res://hub/shard_explorer/past_run_survey.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var past_run: PastRun:
	set(value):
		past_run = value
		_update()

func _ready() -> void:
	_update()

func _update() -> void:
	if not past_run:
		return

	(%ShardNameLabel as Label).text = past_run.get_shard_display_name()
	if not GlobalTooltipSystem.has_attached_tooltip(%ShardNameLabel as Control):
		if past_run.shard_name_jp:  # Old savegames don't have JP names.
			GlobalTooltipSystem.attach(%ShardNameLabel as Control, _make_name_tooltip_text,
					[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.CENTERED])

	(%Image as TextureRect).texture = ImageTexture.create_from_image(past_run.screenshot)
	for counter: BonusCounter in %BonusesList.get_children():
		counter.current_value = past_run.run_data.bonus_amounts.get_amount(counter.bonus_type)
	(%CountLabel as Label).text = tr_n(
		'%d Settlement',
		'%d Settlements',
		past_run.run_data.settlement_states.size()) % past_run.run_data.settlement_states.size()
	var population := past_run.get_population(GlobalSaveGame.get_current_date())
	(%PopulationLabel as Label).text = tr('Population: %s') % Utils.format_number(population)
	if past_run.shard_type:
		(%TypeButton as Button).text = tr(past_run.shard_type.name)
		(%TypeButton as Button).visible = true
	else:
		(%TypeButton as Button).visible = false

	(%AspectCountersPanel as AspectCountersPanel).card_types = past_run.run_data.deck_cards

	Utils.clear_node(%RelicsList)
	for relic in past_run.run_data.current_relics:
		var relic_icon: RelicIcon = RELIC_ICON_SCENE.instantiate_loaded_scene()
		relic_icon.relic = relic
		relic_icon.forced_size = 80
		%RelicsList.add_child(relic_icon)

	var settler_quests: Array[Quest_Settler]
	for quest in past_run.run_data.quests_affecting_map:
		if quest is Quest_Settler:
			settler_quests.append(quest)
	if settler_quests:
		(%QuestsBlock as Control).visible = true
		var quests_links: Array[String]
		for quest in settler_quests:
			quests_links.append('<quest:%s>' % quest.quest_id)
		(%QuestsLabel as MarkedUpLabel).set_markedup_text('\n'.join(quests_links), MarkedUpLabel.LinkMode.LINK)
	else:
		(%QuestsBlock as Control).visible = false

	Utils.clear_node(%SettlementsList)
	var iterated_past_run := past_run  # If this is changed while we wait, bail.
	for i in past_run.run_data.settlement_states.size():
		var survey := past_run.run_data.finished_episodes.get(i, []) as Array
		if survey:
			var survey_widget := PAST_RUN_SURVEY_SCENE.instantiate_loaded_scene() as PastRunSurvey
			survey_widget.episodes.assign(survey)
			%SettlementsList.add_child(survey_widget)

			await get_tree().process_frame
			if iterated_past_run != past_run:
				break

		var settlement_state := past_run.run_data.settlement_states[i]
		var settlement := PAST_RUN_SETTLEMENT_SCENE.instantiate_loaded_scene() as PastRunSettlement
		settlement.settlement_state = settlement_state
		settlement.events = _get_events(i)
		%SettlementsList.add_child(settlement)

		await get_tree().process_frame
		if iterated_past_run != past_run:
			break

func _on_type_button_pressed() -> void:
	request_shard_type.emit()

func _make_name_tooltip_text() -> String:
	var text: String
	match GameSettings.Japanese.shard_names.value():
		GameSettings.ShardNameDisplayType.ROMAJI:
			text = tr(past_run.shard_name_meaning)
		GameSettings.ShardNameDisplayType.KANJI:
			text = JapaneseUtils.romaji_to_hiragana(past_run.shard_name) + '\n' + tr(past_run.shard_name_meaning)
		GameSettings.ShardNameDisplayType.HIRAGANA:
			text = past_run.shard_name_jp + '\n' + tr(past_run.shard_name_meaning)
		GameSettings.ShardNameDisplayType.MEANING:
			text = tr(past_run.shard_name)
	return '[center]' + text + '[/center]'

func _on_view_deck_button_pressed() -> void:
	var viewer := DECK_VIEWER_SCENE.instantiate_loaded_scene() as CardDeckViewer
	viewer.title = tr('Final Deck')
	viewer.cards = past_run.run_data.deck_cards.duplicate()
	viewer.cards.sort_custom(CardType.compare)
	GlobalUI.add_layer_content(viewer, UI.Layer.GAME_MENU_SUBMENU)

func _get_events(index: int) -> Array[Event]:
	var result: Array[Event]
	var events_state := past_run.run_data.events_state.to_flat()
	for key in events_state:
		if key.ends_with(':TRIGGERED_STAGE_INDEX'):
			if events_state[key] == index:
				var event_id := key.left(-':TRIGGERED_STAGE_INDEX'.length())
				result.append(Event.get_event_by_id(event_id))
	return result

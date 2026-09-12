class_name RunSetup
extends Node2D

signal run_requested(run_config: RunConfig)
signal closed

static var DEFAULT_RUN_TYPE := AsyncLoadedResource.new('res://run/types/run_type_standard.tres')
static var SIGNATURE_CARD_SELECTOR_SCENE := AsyncLoadedResource.new('res://hub/run_setup/signature_card_selector.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var STARTER_CARD_REPLACER_SCENE := AsyncLoadedResource.new('res://hub/run_setup/starter_card_replacer.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var HAUNTING_BUTTON_SCENE := AsyncLoadedResource.new('res://hub/run_setup/run_setup_haunting_button.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var EVENT_BUTTON_SCENE := AsyncLoadedResource.new('res://hub/run_setup/run_setup_event_button.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var COMPANION_BUTTON_SCENE := AsyncLoadedResource.new('res://hub/run_setup/run_setup_companion_button.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var RELIC_BUTTON_SCENE := AsyncLoadedResource.new('res://hub/run_setup/run_setup_relic_button.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var CHOICE_DIALOG_SCENE := AsyncLoadedResource.new('res://hub/run_setup/run_setup_choice_dialog.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var MAP_PREVIEW_DIALOG_SCENE := AsyncLoadedResource.new('res://hub/run_setup/map_preview_dialog.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var latest_map_generation_config: MapGenerationConfig

var _closing := false

static func get_default_run_type() -> RunType:
	return DEFAULT_RUN_TYPE.get_loaded() as RunType

func _ready() -> void:
	Utils.clear_node(%CardsBox, 1)

	# Kept cards.
	var inherited_card_type := GlobalSaveGame.get_inherited_card()
	if inherited_card_type:
		(%InheritedCard as Card).card_type = inherited_card_type
		(%InheritedCard as Card).visible = true
	else:
		(%InheritedCard as Card).visible = false

	# Signature cards.
	var num_signature_cards := Skill.get_skill_var(Skill.Var.SIGNATURE_CARDS)
	var signature_cards := GlobalSaveGame.get_signature_cards()
	for i in range(num_signature_cards):
		var signature_card_selector := SIGNATURE_CARD_SELECTOR_SCENE.instantiate_loaded_scene() as SignatureCardSelector
		if not signature_cards.is_empty():
			signature_card_selector.selected_card_type = signature_cards.pop_front()
		%CardsBox.add_child(signature_card_selector)

	# Starter cards.
	var replaced_cards := GlobalSaveGame.get_replaced_cards()
	for card_type in SaveGame.get_starter_cards():
		var replacer := STARTER_CARD_REPLACER_SCENE.instantiate_loaded_scene() as StarterCardReplacer
		replacer.original_card_type = card_type
		replacer.selected_card_type = replaced_cards.get(card_type, null)
		replacer.card_changed.connect(_save_selection)
		%CardsBox.add_child(replacer)

	# Relic.
	if Skill.get_skill_var(Skill.Var.SELECTED_STARTING_RELIC):
		(%RelicPanel as Control).visible = true
		(%RelicButton as RunSetupRelicButton).relic = GlobalSaveGame.get_starting_relic()
	else:
		(%RelicPanel as Control).visible = false
		(%RelicButton as RunSetupRelicButton).relic = null

	# Companion.
	if GlobalSaveGame.get_unlocked_companions():
		(%CompanionPanel as Control).visible = true
		(%CompanionButton as RunSetupCompanionButton).companion = GlobalSaveGame.get_current_companion()
	else:
		(%CompanionPanel as Control).visible = false
		(%CompanionButton as RunSetupCompanionButton).companion = null

	# Banned hauntings.
	var haunting_ban_count := Skill.get_skill_var(Skill.Var.HAUNTING_BANS)
	var banned_hauntings := GlobalSaveGame.get_banned_hauntings().duplicate()
	Utils.clear_node(%BannedHauntingsList)
	if haunting_ban_count:
		Utils.ensure(not GlobalSaveGame.get_seen_hauntings().is_empty())
		(%HauntingsPanel as Control).visible = true
		(%HauntingsLabel as Label).text = tr('Prevented Challenges') if Utils.is_realistic_era() else tr('Warded Hauntings')
		for _i in haunting_ban_count:
			var button := HAUNTING_BUTTON_SCENE.instantiate_loaded_scene() as RunSetupHauntingButton
			if banned_hauntings:
				button.haunting_type = banned_hauntings.pop_front()
			button.pressed.connect(_on_ban_haunting_pressed.bind(button))
			%BannedHauntingsList.add_child(button)
	else:
		(%HauntingsPanel as Control).visible = false

	# Pinned events.
	var pinned_event_count := Skill.get_skill_var(Skill.Var.PINNED_EVENTS)
	var pinned_events := GlobalSaveGame.get_pinned_events()
	Utils.clear_node(%PinnedEventsList)
	if pinned_event_count:
		Utils.ensure(not GlobalSaveGame.get_seen_event_choices().is_empty())
		(%EventsPanel as Control).visible = true
		for _i in pinned_event_count:
			var button := EVENT_BUTTON_SCENE.instantiate_loaded_scene() as RunSetupEventButton
			if pinned_events:
				button.event = pinned_events.pop_front()
			button.pressed.connect(_on_pin_event_pressed.bind(button))
			%PinnedEventsList.add_child(button)
	else:
		(%EventsPanel as Control).visible = false

	# Map preview/reroll.
	(%MapPreviewButon as Control).visible = Skill.get_skill_var(Skill.Var.PREVIEW_MAP) > 0

	(%ScrollPanel as ScrollPanel).animate_unroll()

func _process(_delta: float) -> void:
	(%AspectCountersPanel as AspectCountersPanel).card_types = _get_starting_cards()

func _handle_esc() -> bool:
	_close()
	return true

func _on_ban_haunting_pressed(button: RunSetupHauntingButton) -> void:
	var dialog := CHOICE_DIALOG_SCENE.instantiate_loaded_scene() as RunSetupChoiceDialog
	dialog.title = (
		tr('Choose a Challenge to Prevent') if Utils.is_realistic_era()
		else tr('Choose a Haunting to Ward Against'))
	for haunting_type in GlobalSaveGame.get_seen_hauntings():
		var choice := HAUNTING_BUTTON_SCENE.instantiate_loaded_scene() as RunSetupHauntingButton
		choice.empty_state_text = tr('None')
		choice.haunting_type = haunting_type
		choice.pressed.connect(func() -> void:
			button.haunting_type = choice.haunting_type
			dialog.close()
		)
		dialog.buttons.append(choice)
	var empty_choice := HAUNTING_BUTTON_SCENE.instantiate_loaded_scene() as RunSetupHauntingButton
	empty_choice.empty_state_text = tr('None')
	empty_choice.pressed.connect(func() -> void:
		button.haunting_type = null
		dialog.close()
	)
	dialog.buttons.append(empty_choice)
	GlobalUI.add_layer_content(dialog, UI.Layer.GAME_MENU_SUBMENU)

func _on_pin_event_pressed(button: RunSetupEventButton) -> void:
	var dialog := CHOICE_DIALOG_SCENE.instantiate_loaded_scene() as RunSetupChoiceDialog
	dialog.title = tr('Choose an Event to Guarantee')

	var empty_choice := EVENT_BUTTON_SCENE.instantiate_loaded_scene() as RunSetupEventButton
	empty_choice.empty_state_text = tr('None')
	empty_choice.pressed.connect(func() -> void:
		button.event = null
		dialog.close()
	)
	dialog.buttons.append(empty_choice)

	for event: Event in GlobalSaveGame.get_seen_event_choices().keys():
		if Event.Category.MAIN_STORY in event.categories:
			continue
		if Event.Category.RECORD in event.categories:
			continue
		if Event.Category.COMPANION in event.categories:
			continue
		if Event.Category.LANDMARK in event.categories:
			continue
		if not event.steps:
			continue
		if event is not Event_Stage:
			continue
		var stage_event := event as Event_Stage
		if stage_event.repeatability == Event_Stage.Repeatability.ONCE_EVER:
			continue
		var choice := EVENT_BUTTON_SCENE.instantiate_loaded_scene() as RunSetupEventButton
		choice.empty_state_text = tr('None')
		choice.event = event
		choice.pressed.connect(func() -> void:
			button.event = choice.event
			dialog.close()
		)
		dialog.buttons.append(choice)
	GlobalUI.add_layer_content(dialog, UI.Layer.GAME_MENU_SUBMENU)

func _on_companion_button_pressed() -> void:
	var dialog := CHOICE_DIALOG_SCENE.instantiate_loaded_scene() as RunSetupChoiceDialog
	dialog.title = tr('Choose a Companion')
	for companion in GlobalSaveGame.get_unlocked_companions():
		var choice := COMPANION_BUTTON_SCENE.instantiate_loaded_scene() as RunSetupCompanionButton
		choice.companion = companion
		choice.pressed.connect(func() -> void:
			(%CompanionButton as RunSetupCompanionButton).companion = choice.companion
			dialog.close()
		)
		dialog.buttons.append(choice)
	var empty_choice := COMPANION_BUTTON_SCENE.instantiate_loaded_scene() as RunSetupCompanionButton
	empty_choice.empty_state_text = tr('None')
	empty_choice.pressed.connect(func() -> void:
		(%CompanionButton as RunSetupCompanionButton).companion = null
		dialog.close()
	)
	dialog.buttons.append(empty_choice)
	GlobalUI.add_layer_content(dialog, UI.Layer.GAME_MENU_SUBMENU)

func _on_relic_button_pressed() -> void:
	var relic_options: Array[Relic]
	var allow_uncommon := Skill.get_skill_var(Skill.Var.UNCOMMON_STARTING_RELIC) > 0
	for relic in GlobalSaveGame.get_seen_relics():
		if relic.rarity == Relic.Rarity.COMMON or (allow_uncommon and relic.rarity == Relic.Rarity.UNCOMMON):
			relic_options.append(relic)

	var dialog := CHOICE_DIALOG_SCENE.instantiate_loaded_scene() as RunSetupChoiceDialog
	dialog.title = tr('Choose a Starting Relic')
	for relic in relic_options:
		var choice := RELIC_BUTTON_SCENE.instantiate_loaded_scene() as RunSetupRelicButton
		choice.relic = relic
		choice.pressed.connect(func() -> void:
			(%RelicButton as RunSetupRelicButton).relic = choice.relic
			dialog.close()
		)
		dialog.buttons.append(choice)
	var empty_choice := RELIC_BUTTON_SCENE.instantiate_loaded_scene() as RunSetupRelicButton
	empty_choice.empty_state_text = tr('None')
	empty_choice.pressed.connect(func() -> void:
		(%RelicButton as RunSetupRelicButton).relic = null
		dialog.close()
	)
	dialog.buttons.append(empty_choice)
	GlobalUI.add_layer_content(dialog, UI.Layer.GAME_MENU_SUBMENU)

func _save_selection() -> void:
	var signature_cards: Array[CardType] = []
	var replaced_cards: Dictionary[CardType, CardType] = {}
	for child in %CardsBox.get_children():
		if child is SignatureCardSelector:
			var selected_card_type := (child as SignatureCardSelector).selected_card_type
			if selected_card_type:
				signature_cards.append(selected_card_type)
		elif child is StarterCardReplacer:
			var replacer := child as StarterCardReplacer
			if replacer.selected_card_type:
				replaced_cards[replacer.original_card_type] = replacer.selected_card_type
		else:
			Utils.ensure(child is Card)  # Inherited card.

	var banned_hauntings: Array[HauntingType] = []
	for child: RunSetupHauntingButton in %BannedHauntingsList.get_children():
		if child.haunting_type:
			banned_hauntings.append(child.haunting_type)

	var pinned_events: Array[Event] = []
	for child: RunSetupEventButton in %PinnedEventsList.get_children():
		if child.event:
			pinned_events.append(child.event)

	GlobalSaveGame.set_signature_cards(signature_cards)
	GlobalSaveGame.set_replaced_cards(replaced_cards)
	GlobalSaveGame.set_starting_relic((%RelicButton as RunSetupRelicButton).relic)
	GlobalSaveGame.set_current_companion((%CompanionButton as RunSetupCompanionButton).companion)
	GlobalSaveGame.set_banned_hauntings(banned_hauntings)
	GlobalSaveGame.set_pinned_events(pinned_events)
	GlobalSaveGame.save_game()

func _get_starting_cards() -> Array[CardType]:
	var result := SaveGame.get_starter_cards()
	for child in %CardsBox.get_children():
		if child is SignatureCardSelector:
			var selected_card_type := (child as SignatureCardSelector).selected_card_type
			if selected_card_type:
				result.append(selected_card_type)
		elif child is StarterCardReplacer:
			var replacer := child as StarterCardReplacer
			if replacer.selected_card_type:
				result.erase(replacer.original_card_type)
				result.append(replacer.selected_card_type)
		elif Utils.ensure(child is Card):  # Inherited card.
			if (child as Card).card_type:
				result.append((child as Card).card_type)
	return result

func _on_start_buton_pressed() -> void:
	_save_selection()
	var run_config := RunConfig.new()
	run_config.run_type = get_default_run_type()
	run_config.run_seed = _get_effective_run_seed()
	run_config.starting_cards = GlobalSaveGame.get_run_starting_deck()
	run_config.companion = GlobalSaveGame.get_current_companion()
	run_config.map_generation_config = latest_map_generation_config
	run_requested.emit(run_config)
	_close()

func _get_effective_run_seed() -> int:
	if GlobalSaveGame.get_next_run_seed() == -1:
		return GlobalSaveGame.get_playthrough_seed() + GlobalSaveGame.get_past_run_ids().size()
	else:
		return GlobalSaveGame.get_next_run_seed()

func _on_cancel_button_pressed() -> void:
	_close()

func _close() -> void:
	if not _closing:
		_closing = true
		_save_selection()  # Odd, but that's what playtesters seem to expect.
		Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		closed.emit()
		queue_free()

func _make_companion_tooltip_text(companion: Companion) -> String:
	return (tr('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s') %
			[tr(companion.companion_name), tr(companion.ability_description)])

func _on_inherited_card_selected() -> void:
	(%InheritedCard as Card).is_selected = false

func _on_map_preview_buton_pressed() -> void:
	var dialog := MAP_PREVIEW_DIALOG_SCENE.instantiate_loaded_scene() as MapPreviewDialog
	dialog.map_seed = _get_effective_run_seed()
	dialog.map_generation_config = latest_map_generation_config
	dialog.map_seed_confirmed.connect(func(new_map_seed: int) -> void:
		GlobalSaveGame.set_next_run_seed(new_map_seed)
	)
	GlobalUI.add_layer_content(dialog, UI.Layer.GAME_MENU_SUBMENU)

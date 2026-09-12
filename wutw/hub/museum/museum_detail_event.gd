@tool
class_name MuseumDetail_Event
extends Control

static var EVENT_CHOICE_SCENE := AsyncLoadedResource.new('res://events/system/scenes/event_choice_scene.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

@export var event: Event:
	set(value):
		if event == value:
			return
		event = value
		if is_node_ready():
			_recreate()

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_recreate()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainText as RichTextLabel, false, 18)
	Utils._scale_font_size(%HintText as RichTextLabel, false, 18)

func _recreate() -> void:
	if not event:
		return

	if Utils.is_in_editor() or GlobalSaveGame.has_seen_event(event):
		(%HintText as Control).visible = false
		(%DetailsContainer as Control).visible = true

		(%TitleLabel as Label).text = tr(event.event_name)
		(%Illustration as TextureRect).visible = true
		(func() -> void:
			(%Illustration as TextureRect).texture = await event.steps[0].background_image.get_texture_async()
		).call()  # Await without blocking.
		(%CreditsIcon as CreditsIcon).art_piece = event.steps[0].background_credit

		assert(event.steps)
		var step := event.steps[0]
		(%MainText as MarkedUpLabel).set_markedup_text(
			tr(step.markedup_text), MarkedUpLabel.LinkMode.LINK)

		Utils.clear_node(%ChoicesList)
		var all_choices: Array[EventChoice] = event.steps[0].choices.duplicate()
		if step.exit_choice:
			all_choices.append(step.exit_choice)
		for choice in all_choices:
			if choice.show_condition and not choice.show_condition.is_satisfied(null, event):
				continue
			var choice_scene := EVENT_CHOICE_SCENE.instantiate_loaded_scene() as EventChoiceScene
			choice_scene.event = event
			choice_scene.event_step = step
			choice_scene.event_choice = choice
			var choice_buttom := choice_scene.get_node('%Button') as Button
			choice_buttom.mouse_filter = Control.MOUSE_FILTER_IGNORE
			choice_buttom.mouse_default_cursor_shape = Control.CURSOR_ARROW
			%ChoicesList.add_child(choice_scene)

		var description := ''
		if event is Event_Stage:
			var stage_event := event as Event_Stage
			var spot_upgrade := stage_event.default_spot_upgrade
			var spot := SpotType.get_spot_type_by_upgrade(spot_upgrade)
			description = '<spot:%s> - <spot_upgrade:%s>' % [spot.spot_type_id, spot_upgrade.spot_upgrade_id]
			if stage_event.default_probability_weight == Event_Stage.Probability.LOW:
				description += tr(' (Rare)')
			elif stage_event.default_probability_weight == Event_Stage.Probability.VERY_LOW:
				description += tr(' (Very Rare)')
			var landmark := stage_event.get_associated_landmark()
			if landmark:
				description += tr('\nUnlocks Landmark: <shop:%s>') % landmark.shop_id

		if Event.Category.MAIN_STORY in event.categories:
			description += tr('\nMain Story Event')
		elif Event.Category.COMPANION in event.categories:
			description += tr('\nCompanion Event')
		elif Event.Category.CHAIN in event.categories:
			description += tr('\nPart of a Chain')

		(%ExtraText as MarkedUpLabel).set_markedup_text(description, MarkedUpLabel.LinkMode.LINK)
	else:
		(%HintText as Control).visible = true
		(%DetailsContainer as Control).visible = false
		(%TitleLabel as Label).text = tr('???')
		(%Illustration as TextureRect).visible = false
		(%CreditsIcon as CreditsIcon).art_piece = event.steps[0].background_credit  # To avoid warning.

		var description: String
		if Event.Category.MAIN_STORY in event.categories:
			description = tr('This event is part of the main story.')
		elif event is Event_Stage:
			var stage_event := event as Event_Stage
			var spot_upgrade := stage_event.default_spot_upgrade
			var spot := SpotType.get_spot_type_by_upgrade(spot_upgrade)
			description = tr('This event can be encountered in <spot:%s> - <spot_upgrade:%s>.') % [spot.spot_type_id, spot_upgrade.spot_upgrade_id]
			if stage_event.default_probability_weight == Event_Stage.Probability.LOW:
				description += tr('\n\nThis event is rare.')
			elif stage_event.default_probability_weight == Event_Stage.Probability.VERY_LOW:
				description += tr('\n\nThis event is very rare.')

			if Event.Category.CHAIN in event.categories:
				description += tr('\n\nThis event is part of a chain.')
		else:
			Utils.ensure(false)

		if _get_min_main_quest() > GlobalSaveGame.get_main_quest_progress():
			description += tr('\n\nThis event will be available once the main story has progressed further.')

		(%HintText as MarkedUpLabel).set_markedup_text(description, MarkedUpLabel.LinkMode.LINK)

func _get_min_main_quest() -> SaveGame.MainQuestProgress:
	return _get_min_main_quest_from_req(event.requirement)

func _get_min_main_quest_from_req(requirement: EventRequirement) -> SaveGame.MainQuestProgress:
	if requirement is EventRequirement_MainQuestProgress:
		return (requirement as EventRequirement_MainQuestProgress).min_progress
	elif requirement is EventRequirement_All:
		for subreq in (requirement as EventRequirement_All).all_requirements:
			var min_mq_state := _get_min_main_quest_from_req(subreq)
			if min_mq_state > SaveGame.MainQuestProgress.P000_INTRO:
				return min_mq_state
	return SaveGame.MainQuestProgress.P000_INTRO

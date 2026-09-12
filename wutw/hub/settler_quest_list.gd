class_name SettlerQuestList
extends Node2D

signal closed
signal quest_accepted(hub_character: HubCharacter)

var _closing: bool

func _ready() -> void:
	_update()
	(%ScrollPanel as ScrollPanel).animate_unroll()

func _update() -> void:
	var quest_characters: Array[HubCharacter]
	var hub := Utils.get_active_hub()
	for character in hub.get_spawned_characters():
		if character.offered_quest:
			quest_characters.append(character)

	quest_characters.sort_custom(func(a: HubCharacter, b: HubCharacter) -> bool:
		var a_is_old := GlobalSaveGame.has_completed_settler_quest(a.offered_quest)
		var b_is_old := GlobalSaveGame.has_completed_settler_quest(b.offered_quest)
		if a_is_old != b_is_old:
			return b_is_old
		return tr(a.offered_quest.name) < tr(b.offered_quest.name)
	)

	Utils.clear_node(%List)
	var group := ButtonGroup.new()
	for character in quest_characters:
		var button := UkiyoeButton.new()
		button.text = tr(character.offered_quest.name)
		button.toggled.connect(func(toggled_on: bool) -> void:
			if toggled_on:
				(%Description as SettlerQuestDescription).hub_character = character
		)
		button.toggle_mode = true
		button.button_group = group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.set_meta('character', character)
		var is_old_quest := GlobalSaveGame.has_completed_settler_quest(character.offered_quest)
		button.modulate.a = 0.75 if is_old_quest else 1.0
		%List.add_child(button)

	if %List.get_child_count() > 0:
		(%EmptyLabel as Control).visible = false
		(%Description as Control).visible = true
		(%List.get_child(0) as Button).button_pressed = true
	else:
		(%EmptyLabel as Control).visible = true
		(%Description as Control).visible = false

	(%AcceptButton as Button).disabled = not (%Description as SettlerQuestDescription).can_accept_more_quests()

func _handle_esc() -> bool:
	_close()
	return true

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

func _on_accept_button_pressed() -> void:
	var character := (%Description as SettlerQuestDescription).hub_character
	if not Utils.ensure(character and character.offered_quest):
		return
	# Instantiating as already started to avoid showing the quest announcement.
	var quest_instance := character.offered_quest.instantiate(QuestInstance.STATE_ACTIVE)
	GlobalSaveGame.add_quest_instance(quest_instance)
	quest_accepted.emit(character)
	_update()

func _on_search_input_text_changed(query_text: String) -> void:
	for button: Button in %List.get_children():
		var character := button.get_meta('character') as HubCharacter
		var search_text: Array[String]
		search_text.append(tr(character.first_name))
		if character.job:
			search_text.append(tr(character.job.job_name))
		search_text.append(tr(character.offered_quest.name))
		search_text.append(tr(character.offered_quest.intro_text))
		search_text.append_array(character.offered_quest.get_decorated_goals())
		for challenge in character.offered_quest.challenges:
			search_text.append(challenge.describe())
		for reward in character.offered_quest.rewards:
			search_text.append(reward.describe())
		button.visible = Utils.matches_query([Term.parse(' '.join(search_text)).bbcode_text], query_text)

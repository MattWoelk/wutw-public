class_name SettlerQuestOffer
extends Node2D

signal closed
signal quest_accepted

var hub_character: HubCharacter

var _closing: bool

func _ready() -> void:
	if not Utils.ensure(hub_character != null and hub_character.offered_quest != null):
		_close()
		return
	(%Description as SettlerQuestDescription).hub_character = hub_character
	(%AcceptButton as Button).disabled = not (%Description as SettlerQuestDescription).can_accept_more_quests()
	(%ScrollPanel as ScrollPanel).animate_unroll()

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
	# Instantiating as already started to avoid showing the quest announcement.
	var quest_instance := hub_character.offered_quest.instantiate(QuestInstance.STATE_ACTIVE)
	GlobalSaveGame.add_quest_instance(quest_instance)
	quest_accepted.emit()
	_close()

class_name QuestHud
extends Button

static var QUEST_LIST_TOOLTIP_SCENE := AsyncLoadedResource.new('res://quests/hud/quest_list_tooltip.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

const HOVER_ANIM_DURATION := 0.2

var _tooltip: QuestListTooltip
var _hover_tween: Tween
var _notify_tween: Tween

func _ready() -> void:
	for quest_instance in GlobalSaveGame.get_all_quest_instances():
		if quest_instance.is_active():
			_on_quest_started(quest_instance)
	GlobalSaveGame.quest_started.connect(_on_quest_started)
	if Utils.get_active_run():
		Utils.get_active_run().signals.settler_quest_challenge_triggered.connect(_on_challenge_triggered)

func _exit_tree() -> void:
	if _tooltip:
		_tooltip.queue_free()

func _shortcut_input(event: InputEvent) -> void:
	if GlobalUI.is_higher_level_active(self):
		return
	if event.is_action_pressed('view_quests', false):
		if _tooltip:
			_tooltip.close_requested.emit()
		else:
			_on_mouse_entered()
			_on_pressed()
		get_viewport().set_input_as_handled()

func _on_quest_started(quest_instance: QuestInstance) -> void:
	quest_instance.goal_finished.connect(_on_goal_finished.bind(quest_instance))

func _on_goal_finished(quest_instance: QuestInstance) -> void:
	await get_tree().process_frame  # Wait to check if the quest is finished now.
	if quest_instance.is_finished():
		return

	if _notify_tween and not _notify_tween.is_running():
		return
	_notify_tween = create_tween()
	_notify_tween.set_ease(Tween.EASE_IN)
	_notify_tween.tween_property(%Glow, 'modulate:a', 1.0, 0.4)
	_notify_tween.set_ease(Tween.EASE_OUT)
	_notify_tween.tween_property(%Glow, 'modulate:a', 0.0, 0.8)
	_notify_tween.set_ease(Tween.EASE_IN)
	_notify_tween.tween_property(%Glow, 'modulate:a', 1.0, 0.6)
	_notify_tween.play()

func _on_mouse_entered() -> void:
	if _tooltip and _tooltip.interactive:
		return
	GlobalAudioSystem.play(AK.EVENTS.UI_GENERIC_SELECT_WOOD_HEAVY)
	_tooltip = Tooltip.create(
			self, '',
			[Tooltip.RelativeDirection.BELOW],
			[Tooltip.Alignment.CENTERED, Tooltip.Alignment.END],
			null, QUEST_LIST_TOOLTIP_SCENE.get_loaded_scene())
	_tooltip.z_index = Utils.get_absolute_z_index(self) + UI.LAYER_SPACING
	_tooltip._markedup_text = ' '
	_tooltip.close_requested.connect(func() -> void:
		var tooltip_being_removed := _tooltip
		_tooltip = null
		await tooltip_being_removed.hide_tooltip()
		tooltip_being_removed.destroy()
	, CONNECT_ONE_SHOT)
	_tooltip.show_tooltip()

	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, 'scale', Vector2(1.1, 1.1), HOVER_ANIM_DURATION)
	_hover_tween.play()

	var clear_notify_tween := create_tween()
	clear_notify_tween.tween_property(%Glow, 'modulate:a', 0.0, 0.4)
	clear_notify_tween.play()

func _on_mouse_exited() -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, 'scale', Vector2.ONE, HOVER_ANIM_DURATION)
	_hover_tween.play()

	if _tooltip and not _tooltip.interactive:
		await _tooltip.hide_tooltip()
		_tooltip.destroy()
		_tooltip = null

func _on_pressed() -> void:
	if not _tooltip:
		_on_mouse_entered()
	_tooltip.interactive = true

func _on_challenge_triggered(_challenge: SettlerQuestChallenge) -> void:
	GlobalAudioSystem.play(AK.EVENTS.UI_GENERIC_SELECT_TAIKO_LOW)
	(%AnimationPlayer as AnimationPlayer).play('trigger')

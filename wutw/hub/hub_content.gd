class_name HubContents
extends Node2D

signal main_gate_clicked
signal shrine_clicked
signal studio_clicked
signal museum_clicked
signal museum_exhibit_clicked(index: int, exhibit: MuseumExhibit)
signal portal_network_clicked
signal lookout_tower_clicked
signal scroll_clicked
signal notice_board_clicked
signal companion_clicked(companion: Companion)
signal character_clicked(character: HubCharacter)

const KOI_SPEED := 0.015

var _hovered_facilities: Array[HubFacility] = []
var _hovering_enabled: bool = true:
	set(value):
		_hovering_enabled = value
		_update_facility_hover()

func _unhandled_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if not mouse_event or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if _hovered_facilities and _hovered_facilities[-1] is HubCharacter:
		return  # Let the character handle it.
	for character in (%HubCharacterManager as HubCharacterManager).get_spawned_characters():
		var speech_bubble := character.get_speech_bubble()
		if speech_bubble:
			if speech_bubble.get_state() == SpeechBubble.State.REVEALING_TEXT:
				speech_bubble.fast_forward()
			else:
				speech_bubble.hide_tooltip()

func _on_main_gate_clicked() -> void:
	if _hovering_enabled:
		main_gate_clicked.emit()

func _on_shrine_clicked() -> void:
	if _hovering_enabled:
		shrine_clicked.emit()

func _on_studio_clicked() -> void:
	if _hovering_enabled:
		studio_clicked.emit()

func _on_hub_museum_clicked() -> void:
	if _hovering_enabled:
		museum_clicked.emit()

func _on_hub_museum_exhibit_clicked(index: int, exhibit: MuseumExhibit) -> void:
	if _hovering_enabled:
		museum_exhibit_clicked.emit(index, exhibit)

func _on_tower_clicked() -> void:
	if _hovering_enabled:
		lookout_tower_clicked.emit()

func _on_portal_network_clicked() -> void:
	if _hovering_enabled:
		portal_network_clicked.emit()

func _on_scroll_clicked() -> void:
	if _hovering_enabled:
		scroll_clicked.emit()

func _on_notice_board_clicked() -> void:
	if _hovering_enabled:
		notice_board_clicked.emit()

func setup() -> void:
	# We snapshot the random state so if the game is saved while in the hub, reloading doesn't
	# scramble the NPCs. It is manually advanced when leaving the hub.
	(%HubCharacterManager as HubCharacterManager).spawn(GlobalSaveGame.get_hub_random().snapshot())
	_update()
	for facility in Utils.get_all_hub_facilities_within(self):
		facility.hovered.connect(_on_facility_hovered.bind(facility))
		facility.unhovered.connect(_on_facility_unhovered.bind(facility))
		if facility is HubCompanion:
			facility.clicked.connect(func() -> void:
				companion_clicked.emit((facility as HubCompanion).companion)
			)
		elif facility is HubCharacter:
			facility.clicked.connect(character_clicked.emit.bind(facility as HubCharacter))

func spawn_character(character: HubCharacter) -> bool:
	if (%HubCharacterManager as HubCharacterManager).spawn_specific(character):
		character.hovered.connect(_on_facility_hovered.bind(character))
		character.unhovered.connect(_on_facility_unhovered.bind(character))
		character.clicked.connect(character_clicked.emit.bind(character))
		return true
	else:
		return false

func get_spawned_characters() -> Array[HubCharacter]:
	return (%HubCharacterManager as HubCharacterManager).get_spawned_characters()

func get_dialogue_player() -> HubDialoguePlayer:
	return get_node('%HubDialoguePlayer') as HubDialoguePlayer

func get_ambient_sounds() -> Array[HubAmbientSound]:
	var result: Array[HubAmbientSound]
	result.assign(%Ambiance.get_children())
	return result

func _process(delta: float) -> void:
	for follow: PathFollow2D in [%PathFollow_Koi_1, %PathFollow_Koi_2, %PathFollow_Koi_3, %PathFollow_Koi_4]:
		follow.progress_ratio += delta * KOI_SPEED

func _enter_tree() -> void:
	GlobalSaveGame.changed.connect(_update)

func _exit_tree() -> void:
	GlobalSaveGame.changed.disconnect(_update)

func _update() -> void:
	var mq_progress := GlobalSaveGame.get_main_quest_progress()

	(%Studio as HubFacility).visible = Skill.get_skill_var(Skill.Var.INSCRIBE_COMMON)
	(%HubMuseum as HubFacility).visible = Utils.is_museum_unlocked()
	(%HubPathsMuseum as Node2D).visible = (%HubMuseum as HubFacility).visible
	(%HubPaths_NoMuseum as Node2D).visible = not (%HubMuseum as HubFacility).visible

	(%Tower as HubFacility).visible = Utils.are_shard_types_unlocked()
	(%PortalNetwork as HubFacility).visible = Utils.is_portal_network_unlocked()
	(%NoticeBoard as HubFacility).visible = mq_progress >= SaveGame.MainQuestProgress.P500_STARTED

	(%HubSpawner_Special_Scribe as HubSpawner).visible = mq_progress != SaveGame.MainQuestProgress.P420_SENT_OFF_KID
	(%HubSpawner_Special_Historian as HubSpawner).visible = Utils.is_museum_unlocked()
	(%HubSpawner_Special_Explorer as HubSpawner).visible = Utils.is_explorer_unlocked() and not GlobalSaveGame.is_trip_in_progress()
	(%HubSpawner_Special_Avatar_Child as HubSpawner).visible = mq_progress >= SaveGame.MainQuestProgress.P410_FOUND_KID and mq_progress < SaveGame.MainQuestProgress.P420_SENT_OFF_KID
	(%HubSpawner_Special_Avatar_Adult as HubSpawner).visible = mq_progress >= SaveGame.MainQuestProgress.P430_STARTED_DEBATE and mq_progress < SaveGame.MainQuestProgress.P440_FINISHED_DEBATE

	(%Stall_Books as Node2D).visible = not (%HubSpawner_Vendor_Books as HubSpawner).get_spawned_characters().is_empty()
	(%Stall_Pottery as Node2D).visible = not (%HubSpawner_Vendor_Pottery as HubSpawner).get_spawned_characters().is_empty()
	(%Stall_Food as Node2D).visible = not (%HubSpawner_Vendor_Food as HubSpawner).get_spawned_characters().is_empty()
	(%PicnicBlanket as Node2D).visible = (not (%HubSpawner_Picnic as HubSpawner).get_spawned_characters().is_empty()
										  or not (%HubSpawner_Picnic2 as HubSpawner).get_spawned_characters().is_empty())

func _on_facility_hovered(facility: HubFacility) -> void:
	_hovered_facilities.append(facility)
	_update_facility_hover()

func _on_facility_unhovered(facility: HubFacility) -> void:
	if _hovered_facilities:
		_hovered_facilities[-1].highlighted = false
		_hovered_facilities.erase(facility)
		if _hovered_facilities:
			_update_facility_hover()

func _update_facility_hover() -> void:
	if _hovered_facilities.is_empty():
		return

	# Area detection runs even if outside the window of if unfocused, so guard against that.
	if not GlobalUI.get_window().has_focus():
		return
	var mouse_pos: Vector2 = GlobalUI.get_viewport().get_mouse_position()
	var window_rect: Rect2 = GlobalUI.get_viewport().get_visible_rect()
	if not window_rect.has_point(mouse_pos):
		return

	_hovered_facilities.sort_custom(func(a: HubFacility, b: HubFacility) -> bool:
		var z_a := Utils.get_absolute_z_index(a)
		var z_b := Utils.get_absolute_z_index(b)
		if z_a != z_b:
			return z_a < z_b
		return _is_drawn_after(b, a)
	)
	for i in _hovered_facilities.size() - 1:
		_hovered_facilities[i].highlighted = false
	_hovered_facilities[-1].highlighted = _hovering_enabled
	if _hovering_enabled:
		GlobalAudioSystem.play(AK.EVENTS.UI_MAP_HUB_BUILDING_CLICK)

func _is_drawn_after(a: HubFacility, b: HubFacility) -> bool:
	var path_a := _get_tree_index_path(a)
	var path_b := _get_tree_index_path(b)

	var length := mini(path_a.size(), path_b.size())
	for i in range(length):
		if path_a[i] != path_b[i]:
			return path_a[i] > path_b[i]

	if path_a.size() == path_b.size():
		# Y-sort into account.
		return a.position.y > b.position.y
	else:
		# If one is a direct ancestor of the other, the deeper one is drawn later.
		return path_a.size() > path_b.size()

func _get_tree_index_path(node: Node) -> Array[int]:
	var path: Array[int] = []
	var curr := node
	while curr != get_tree().root:
		path.insert(0, curr.get_index())
		curr = curr.get_parent()
	return path

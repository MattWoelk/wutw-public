class_name ShardExplorer
extends Node2D

signal closed

static var SHARD_TYPE_BUTTON_SCENE := AsyncLoadedResource.new('res://hub/shard_explorer/shard_type_button.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

static var _active_instance: ShardExplorer

var _closing: bool
var _types_button_group: ButtonGroup
var _runs_button_group: ButtonGroup

func _ready() -> void:
	_setup_types_tab()
	Utils.clear_node(%RunsList)

	(%ScrollPanel as ScrollPanel).animate_unroll()

	# Load all past runs, throttled.
	for uid in GlobalSaveGame.get_past_run_ids():
		if not GlobalSaveGame.is_past_run_loaded(uid):
			GlobalSaveGame.get_past_run(uid)
			await get_tree().process_frame
	if %RunsList.get_child_count() == 0:  # If still not opened, prefill it.
		_setup_runs_tab()

func _enter_tree() -> void:
	Utils.ensure(not _active_instance)
	_active_instance = self

func _exit_tree() -> void:
	Utils.ensure(_active_instance != null)
	_active_instance = null

func _handle_esc() -> bool:
	_close()
	return true

static func open_link(query: String) -> void:
	var pieces := query.split(':', true, 1)
	assert(pieces.size() == 2)
	assert(pieces[0] == 'shard_type')
	var layer := GlobalUI.choose_dynamic_menu_layer()
	if not _active_instance:
		if Utils.get_active_hub():
			# HACK: Hub needs to track open menus.
			Utils.get_active_hub().open_shard_explorer(layer)
		else:
			var viewer := (load('res://hub/shard_explorer/shard_explorer.tscn') as PackedScene).instantiate() as ShardExplorer
			GlobalUI.add_layer_content(viewer, layer)
	_active_instance._select_shard_type(pieces[1].to_lower())

func _on_close_button_pressed() -> void:
	GlobalSaveGame.save_game()  # In case we pined something different.
	_close()

func _close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		closed.emit()
		queue_free()

func _setup_types_tab() -> void:
	_types_button_group = ButtonGroup.new()
	Utils.clear_node(%TypesList)
	var shard_types := ShardType.get_all_shard_types().values()
	shard_types.sort_custom(func(a: ShardType, b: ShardType) -> bool:
		var a_unlocked := GlobalSaveGame.is_shard_type_unlocked(a)
		var b_unlocked := GlobalSaveGame.is_shard_type_unlocked(b)
		if a_unlocked != b_unlocked:
			return a_unlocked
		elif a.tier != b.tier:
			return a.tier < b.tier
		else:
			return tr(a.name) < tr(b.name)
	)
	for shard_type: ShardType in shard_types:
		if shard_type.min_main_quest_progress > GlobalSaveGame.get_main_quest_progress():
			continue  # Not possible yet, so hide it.
		var button := SHARD_TYPE_BUTTON_SCENE.instantiate_loaded_scene() as ShardTypeButton
		button.shard_type = shard_type
		button.pressed.connect(_on_shard_type_selected.bind(shard_type))
		button.button_group = _types_button_group
		(%TypesList as VBoxContainer).add_child(button)

	var first_button := %TypesList.get_child(0) as ShardTypeButton
	first_button.button_pressed = true  # Doesn't emit pressed.
	_on_shard_type_selected(first_button.shard_type)

	var num_unlocked := GlobalSaveGame.get_num_shard_types_unlocked()
	(%EarnedRarityLabel as Label).text = tr('Bonus Glyph Rarity: %s%d%%') % ['+' if num_unlocked else '', num_unlocked]
	GlobalTooltipSystem.attach(%EarnedRarityLabel as Label, _make_earned_rarity_tooltip_text,
			[Tooltip.RelativeDirection.ABOVE], [Tooltip.Alignment.CENTERED])

func _setup_runs_tab() -> void:
	_runs_button_group = ButtonGroup.new()
	Utils.clear_node(%RunsList)
	var run_uids := GlobalSaveGame.get_past_run_ids()
	run_uids.sort()
	run_uids.reverse()
	for uid in run_uids:
		var past_run := GlobalSaveGame.get_past_run(uid)
		var button := UkiyoeButton.new()
		button.text = past_run.get_shard_display_name()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.pressed.connect(_on_run_selected.bind(uid))
		button.button_group = _runs_button_group
		button.set_meta('past_run', past_run)
		(%RunsList as VBoxContainer).add_child(button)

	if %RunsList.get_child_count():  # Can only be 0 in test saves.
		var first_button := %RunsList.get_child(0) as UkiyoeButton
		first_button.button_pressed = true  # Doesn't emit pressed.
		_on_run_selected(run_uids[0])

func _on_shard_type_selected(shard_type: ShardType) -> void:
	(%ShardDetails as ShardDetails).shard_type = shard_type

func _on_run_selected(run_uid: int) -> void:
	(%PastRunDetails as PastRunDetails).past_run = GlobalSaveGame.get_past_run(run_uid)

func _make_earned_rarity_tooltip_text() -> String:
	return tr('Every culture adds to the civilization\'s vault of knowledge.\n\n' +
			'Gain +1% <term:card_rarity_tier> for each unlocked <term:shard_type>.')

func _on_tab_button_types_toggled(toggled_on: bool) -> void:
	if toggled_on:
		(%TabButton_Runs as Button).button_pressed = false
		(%Tab_Types as Control).visible = true
		(%Tab_Runs as Control).visible = false

func _on_tab_button_runs_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if %RunsList.get_child_count() == 0:
			_setup_runs_tab()
		(%TabButton_Types as Button).button_pressed = false
		(%Tab_Types as Control).visible = false
		(%Tab_Runs as Control).visible = true

func _on_shard_details_request_past_run() -> void:
	(%TabButton_Runs as Button).button_pressed = true
	var past_run := GlobalSaveGame.get_past_run_by_shard_type((%ShardDetails as ShardDetails).shard_type)
	for button: Button in %RunsList.get_children():
		var button_past_run := button.get_meta('past_run') as PastRun
		if button_past_run.uid == past_run.uid:
			button.button_pressed = true
			_on_run_selected(past_run.uid)
			break

func _on_past_run_details_request_shard_type() -> void:
	_select_shard_type((%PastRunDetails as PastRunDetails).past_run.shard_type.shard_type_id)

func _select_shard_type(shard_type_id: String) -> void:
	(%TabButton_Types as Button).button_pressed = true
	for button: ShardTypeButton in %TypesList.get_children():
		if button.shard_type.shard_type_id == shard_type_id:
			button.button_pressed = true
			_on_shard_type_selected(button.shard_type)
			break

func _on_search_input_text_changed(query_text: String) -> void:
	for button: ShardTypeButton in %TypesList.get_children():
		var search_text := button.shard_type.describe_requirements().duplicate()
		search_text.append(tr(button.shard_type.name))
		if GlobalSaveGame.is_shard_type_unlocked(button.shard_type):
			var progress := GlobalSaveGame.get_shard_type_progress(button.shard_type)
			for i in button.shard_type.history.size():
				if progress.is_history_completed(i):
					# Ok not to format to save some perf.
					search_text.append(tr(button.shard_type.history[i].text))
				else:
					break
		button.visible = Utils.matches_query(search_text, query_text)

	for button: Button in %RunsList.get_children():
		var past_run := button.get_meta('past_run') as PastRun
		var search_text: Array[String]
		search_text.append(tr(past_run.shard_name))
		search_text.append(past_run.shard_name_jp)
		search_text.append(tr(past_run.shard_name_meaning))
		for settlement_state in past_run.run_data.settlement_states:
			search_text.append(tr(settlement_state.settlement_name.name))
			search_text.append(settlement_state.settlement_name.name_jp)
			search_text.append(tr(settlement_state.settlement_name.translation))
		button.visible = Utils.matches_query(search_text, query_text)

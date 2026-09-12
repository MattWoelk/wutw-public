class_name ShardDetails
extends Control

signal request_past_run

static var SHARD_HISTORY_BLOCK_SCENE := AsyncLoadedResource.new('res://hub/shard_explorer/shard_history_block.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var shard_type: ShardType:
	set(value):
		shard_type = value
		_update()

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_update()
	GlobalTooltipSystem.attach(%PinButton as Control, _make_pin_tooltip_text,
			[Tooltip.RelativeDirection.ABOVE], [Tooltip.Alignment.BEGIN])

func _update_font_size() -> void:
	Utils._scale_font_size(%RequirementsLabel as RichTextLabel, false, 16)
	Utils._scale_font_size(%TripLabel as RichTextLabel, false, 16)

func _update() -> void:
	if not shard_type:
		return

	_setup_requirements()

	(%Illustration as TextureRect).texture = shard_type.illustration
	(%CreditsIcon as CreditsIcon).art_piece = shard_type.illustration_credit
	(%ShardNameLabel as Label).text = tr(shard_type.name)

	if GlobalSaveGame.is_shard_type_unlocked(shard_type):
		var past_run := GlobalSaveGame.get_past_run_by_shard_type(shard_type)
		(%ShardNameLabel as Label).text += ' - ' + past_run.get_shard_display_name()

		Utils.clear_node(%VBox_Histories)
		for i in shard_type.history.size():
			var block := SHARD_HISTORY_BLOCK_SCENE.instantiate_loaded_scene() as ShardHistoryBlock
			block.shard_type = shard_type
			block.history_index = i
			(%VBox_Histories as VBoxContainer).add_child(block)

		(%HistoriesContainer as Control).visible = true
		(%PinButton as Button).visible = false
		(%PastRunButton as Button).visible = true

		(%ReqsContainer as Control).size_flags_horizontal = Control.SIZE_SHRINK_END
		(%RequirementsLabel as MarkedUpLabel).modulate.a = 0.5

		if shard_type.trip_reward and Utils.is_explorer_trips_unlocked():
			(%TripContainer as Control).visible = true
			if GlobalSaveGame.is_shard_explored(past_run.uid):
				var reward := shard_type.trip_reward
				var overridden := false
				for override in past_run.shard_type.trip_reward_overrides:
					if override.requirement.is_satisfied(null, null):
						reward = override.trip_reward
						if overridden:
							push_warning('Multiple trip reward  overrides apply. Taking the last one. ID: ', past_run.shard_type.shard_type_id)
						overridden = true
				(%TripLabel as MarkedUpLabel).set_markedup_text(
					tr('[center][b]Explorer\'s Trip Report[/b][/center]') + '\n\n' +
					past_run.shard_type.format_history_text(0, past_run, tr(reward.text)))
			else:
				(%TripLabel as MarkedUpLabel).set_markedup_text(
					tr('[center][b]The Explorer will be able to retrieve news from this shard.[/b][/center]'))
		else:
			(%TripContainer as Control).visible = false
	else:
		(%HistoriesContainer as Control).visible = false
		(%TripContainer as Control).visible = false
		(%PinButton as Button).visible = true
		(%PastRunButton as Button).visible = false

		(%ReqsContainer as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		(%RequirementsLabel as MarkedUpLabel).modulate.a = 1
		(%PinButton as Button).set_pressed_no_signal(GlobalSaveGame.get_pinned_shard_type() == shard_type)
		_update_pin_button_text()

func _setup_requirements() -> void:
	var text := tr('[b]Requirements:[/b]\n[ul]\n')
	for req in shard_type.describe_requirements():
		text += '%s\n' % req
	text += '[/ul]'
	if shard_type.tier == ShardType.Tier.MAIN_QUEST:
		text += '\n\n' + tr('[b]Revealed as part of the main story and takes precedence over other cultures.[/b]')
	(%RequirementsLabel as MarkedUpLabel).set_markedup_text(text, MarkedUpLabel.LinkMode.LINK)

func _on_pin_button_toggled(toggled_on: bool) -> void:
	GlobalSaveGame.pin_shard_type(shard_type if toggled_on else null)
	_update_pin_button_text()

func _update_pin_button_text() -> void:
	if (%PinButton as Button).button_pressed:
		if Utils.is_steam_deck():
			(%PinButton as Button).text = tr('Pinned!')
		else:
			(%PinButton as Button).text = tr('Pinned! - Click to Unpin')
	else:
		(%PinButton as Button).text = tr('Pin to Quests')

func _on_past_run_button_pressed() -> void:
	request_past_run.emit()

func _make_pin_tooltip_text() -> String:
	return tr('When toggled on, these requirements will appear in the quests list during <term_lower:run>s.\n\n'
			+ 'If you start an <term_lower:run> with a culture pinned,'
			+ ' settlers will try to pick a shard appropriate for fulfilling the requirements.\n\n'
			+ 'Only one <term_lower:shard_type> can be pinned at a time,'
			+ ' and unpinned cultures can still be achieved if the requirements for the pinned shard aren\'t met.')

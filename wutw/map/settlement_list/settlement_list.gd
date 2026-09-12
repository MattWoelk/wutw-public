@tool
class_name SettlementsList
extends PanelContainer

signal settlement_clicked(settlement: Settlement)
signal capital_clicked

static var BONUS_SCENE := AsyncLoadedResource.new('res://bonuses/bonus.tscn')
static var SETTLEMENT_LIST_ENTRY_SCENE := AsyncLoadedResource.new('res://map/settlement_list/settlement_list_entry.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

@export var zoom_pivot := Vector2(1, 0.5)

var _settlements: Array[Settlement]

func _ready() -> void:
	if Utils.is_in_editor():
		return

	(%ScrollPanel as Control).visible = false  # Will be shown in _update() if non-empty.

	await get_tree().process_frame  # Let the run register.
	var run := Utils.get_active_run()
	if not run:  # Pause menu in Hub is one case where this happens.
		return

	_update()
	GlobalGameSettings.changed.connect(_update)

	GlobalTooltipSystem.attach(%CapitalPanel as Control, _make_capital_tooltip_text,
			[Tooltip.RelativeDirection.LEFT, Tooltip.RelativeDirection.RIGHT],
			[Tooltip.Alignment.CENTERED])

	run.state_changed.connect(_update)
	run.signals.capital_bonuses_changed.connect(_update)

func _enter_tree() -> void:
	UI.register_zoomable(%ScrollPanel as Control, zoom_pivot.x, zoom_pivot.y)

func _update() -> void:
	var run := Utils.get_active_run()

	var capital_label := %CapitalLabel as Label
	match GameSettings.Japanese.town_names.value():
		GameSettings.TownNameDisplayType.ROMAJI, GameSettings.TownNameDisplayType.MEANING:
			# Romaji is the default, but setting it for the capital is confusing.
			capital_label.text = tr('Shard Capital')
		GameSettings.TownNameDisplayType.KANJI:
			capital_label.text = '京'
		GameSettings.TownNameDisplayType.HIRAGANA:
			capital_label.text = 'きょう'

	(%CapitalHBox as Control).visible = run.get_capital() != null
	if (%CapitalHBox as Control).visible:
		Utils.clear_node(%CapitalYieldsList)
		for bonus_type in BonusType.get_all_types():  # In standard order.
			if bonus_type in run.get_unlocked_capital_bonuses():
				var bonus := BONUS_SCENE.instantiate_loaded_scene() as Bonus
				bonus.bonus_type = bonus_type
				bonus.highlight_type = Bonus.HighlightType.POSITIVE
				bonus.mouse_filter = Control.MOUSE_FILTER_PASS
				%CapitalYieldsList.add_child(bonus)

	var settlements := run.get_settlements()
	if settlements == _settlements:
		return

	_settlements.clear()
	Utils.clear_node(%List)
	settlements.reverse()  # Most recent are most relevant, so put them at the top.
	for settlement in settlements:
		if settlement.state.settlement_name:
			var entry := SETTLEMENT_LIST_ENTRY_SCENE.instantiate_loaded_scene() as SettlementListEntry
			entry.settlement = settlement
			entry.clicked.connect(settlement_clicked.emit.bind(settlement))
			%List.add_child(entry)
			_settlements.append(settlement)

	(%ScrollPanel as Control).visible = not _settlements.is_empty()

func _on_capital_h_box_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		capital_clicked.emit()

func _on_list_resized() -> void:
	(%ScrollContainer as Control).custom_minimum_size.y = clampf((%List as Control).size.y, 15, 200)

func _on_capital_panel_mouse_entered() -> void:
	(%CapitalPanel as Control).self_modulate = Color(1, 1, 1, 0.2)

func _on_capital_panel_mouse_exited() -> void:
	(%CapitalPanel as Control).self_modulate = Color(1, 1, 1, 0.0)

func _make_capital_tooltip_text() -> String:
	var capital := Utils.get_active_run().get_capital()
	if capital:
		return capital._make_tooltip_text()
	else:
		var term := load('res://glossary/terms/standalone/term_capital.tres') as Term
		return ('<header_font_size>[b]%s[/b][/font_size]\n\n%s' %
				[term.get_term_name(true), term.get_markedup_description()])

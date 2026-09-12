class_name Salvage
extends Control

signal finished

static var CARD_SCENE := AsyncLoadedResource.new('res://cards/card.tscn')
static var STROKE_DISPLAY_SCENE := AsyncLoadedResource.new('res://hub/crafting/stroke_display.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var CRAFTING_SCENE := AsyncLoadedResource.new('res://hub/crafting/crafting.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

var _selected_card: Card
var _num_salvages_left := -1

func _ready() -> void:
	_num_salvages_left = 1 + Skill.get_skill_var(Skill.Var.EXTRA_SALVAGE_CARDS)
	_recreate()

	(%ScrollPanel as ScrollPanel).animate_unroll()

func _recreate() -> void:
	var run := Utils.get_active_run()
	Utils.clear_node(%CardList)
	var cards: Array[CardType] = run.get_deck_cards().duplicate()
	cards.sort_custom(func(a: CardType, b: CardType) -> bool:
		return CardType.compare(a, b, true)
	)
	for card_type in cards:
		var new_card := CARD_SCENE.instantiate_loaded_scene() as Card
		new_card.card_type = card_type
		new_card.playable = false
		new_card.allow_unselect = false
		new_card.selected.connect(_on_card_selected.bind(new_card))
		%CardList.add_child(new_card)

	# Need to suplicate or it doesn't update.
	(%AspectCountersPanel as AspectCountersPanel).card_types = run.get_deck_cards().duplicate()

	Utils.clear_node(%StrokesBox)
	if _num_salvages_left > 1:
		(%SalvageButton as Button).text = tr('Salvage') + ' (%d)' % _num_salvages_left
	else:
		(%SalvageButton as Button).text = tr('Salvage')
	(%SalvageButton as Button).disabled = true

	if run.get_deck_cards().size() > run.get_var(RunVars.Var.MIN_DECK_SIZE):
		(%SalvageButton as Button).visible = true
		(%Label_MinSizeReached as Control).visible = false
	else:
		(%SalvageButton as Button).visible = false
		(%Label_MinSizeReached as Control).visible = true

func _on_card_selected(card: Card) -> void:
	if _selected_card:
		_selected_card.is_selected = false
	_selected_card = card
	(%SalvageButton as Button).disabled = false

	var strokes := Stroke.get_strokes_for_kanji(_selected_card.card_type.symbol)
	Utils.ensure(not strokes.is_empty())
	Utils.clear_node(%StrokesBox)
	for stroke in strokes:
		var stroke_display := STROKE_DISPLAY_SCENE.instantiate_loaded_scene() as StrokeDisplay
		stroke_display.stroke = stroke
		stroke_display.count = strokes[stroke]
		%StrokesBox.add_child(stroke_display)

func _on_cancel_button_pressed() -> void:
	_close()

func _on_salvage_button_pressed() -> void:
	var multiplier := 2 if Skill.get_skill_var(Skill.Var.DOUBLE_SALVAGE_STROKES) else 1
	var strokes := Stroke.get_strokes_for_kanji(_selected_card.card_type.symbol)
	for stroke in strokes:
		GlobalSaveGame.add_stroke(stroke, strokes[stroke] * multiplier)
	var run := Utils.get_active_run()
	run.remove_card_from_deck(_selected_card.card_type)

	Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
	await _selected_card.tear_up()
	await get_tree().create_timer(Utils.anim_duration(0.5)).timeout
	Utils.set_input_enabled(%ScrollPanel as ScrollPanel, true)

	_num_salvages_left -= 1
	if _num_salvages_left > 0:
		_recreate()
	else:
		_close()

func _close() -> void:
	Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
	(%BG as FadedBackground).fade_out()
	await (%ScrollPanel as ScrollPanel).animate_roll()
	finished.emit()
	queue_free()

func _on_preview_button_pressed() -> void:
	var crafting := CRAFTING_SCENE.instantiate_loaded_scene() as Crafting
	crafting.preview_mode = true
	add_child(crafting)

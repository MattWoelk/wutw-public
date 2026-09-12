class_name SignatureCardSelector
extends Control

static var DECK_VIEWER_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

var selected_card_type: CardType:
	set(value):
		selected_card_type = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update()
	GlobalTooltipSystem.attach(%ChooseButton as Control, _make_tooltip_text,
			[Tooltip.RelativeDirection.RIGHT], [Tooltip.Alignment.BEGIN])

func _on_choose_button_pressed() -> void:
	var card_selector := DECK_VIEWER_SCENE.instantiate_loaded_scene() as CardDeckViewer
	card_selector.cards = GlobalSaveGame.get_unlocked_cards()
	card_selector.cards.sort_custom(CardType.compare)
	card_selector.title = tr('Choose Signature Glyph')
	card_selector.close_button_label = tr('Clear')
	card_selector.allow_card_selection = true
	card_selector.allow_quick_dismiss = true
	(card_selector.get_node('%AspectCountersPanel') as Control).visible = false
	card_selector.card_selected.connect(_on_card_selected.bind(card_selector))
	card_selector.canceled.connect(func() -> void: selected_card_type = null; _update())
	GlobalUI.add_layer_content(card_selector, UI.Layer.GAME_MENU_SUBMENU)

func _on_card_selected(card: Card, card_selector: CardDeckViewer) -> void:
	selected_card_type = card.card_type
	_update()
	card_selector.close()

func _update() -> void:
	if selected_card_type:
		(%UnknownCard as UnknownCard).visible = false
		(%SelectedCard as Card).visible = true
		(%SelectedCard as Card).card_type = selected_card_type
	else:
		(%UnknownCard as UnknownCard).visible = true
		(%SelectedCard as Card).visible = false

func _make_tooltip_text() -> String:
	var term := load('res://glossary/terms/standalone/term_signature_card.tres') as Term
	return ('<header_font_size>[b]%s[/b][/font_size]\n\n%s' %
			[term.get_term_name(true), term.get_markedup_description()])

func _on_selected_card_selected() -> void:
	(%SelectedCard as Card).is_selected = false

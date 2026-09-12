@tool
class_name StarterCardReplacer
extends Control

signal card_changed

static var DECK_VIEWER_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var original_card_type: CardType:
	set(value):
		original_card_type = value
		if is_node_ready():
			_update()
@export var selected_card_type: CardType:
	set(value):
		selected_card_type = value
		card_changed.emit()
		_update()

func _ready() -> void:
	_update()
	GlobalTooltipSystem.attach(%ChooseButton as Control, _make_tooltip_text,
			[Tooltip.RelativeDirection.RIGHT], [Tooltip.Alignment.BEGIN])

func _on_choose_button_pressed() -> void:
	var card_selector := DECK_VIEWER_SCENE.instantiate_loaded_scene() as CardDeckViewer
	var available_cards := (CardType.get_all_card_types_by_tier(CardType.Rarity.BASIC)
							+ CardType.get_all_card_types_by_tier(CardType.Rarity.COMMON))
	var used_replacements: Dictionary[CardType, bool]
	var replaced_cards := GlobalSaveGame.get_replaced_cards()
	for starter_card_type in SaveGame.get_starter_cards():
		if starter_card_type == original_card_type:
			continue
		if starter_card_type in replaced_cards:
			starter_card_type = replaced_cards[starter_card_type]
		used_replacements[starter_card_type] = true
	for card_type in available_cards:
		if not GlobalSaveGame.has_unlocked_card(card_type):
			continue
		if card_type in used_replacements:
			continue
		card_selector.cards.append(card_type)
	card_selector.cards.sort_custom(CardType.compare)
	card_selector.title = tr('Choose Starter Glyph')
	card_selector.allow_card_selection = true
	card_selector.allow_quick_dismiss = true
	(card_selector.get_node('%AspectCountersPanel') as Control).visible = false
	card_selector.card_selected.connect(_on_card_selected.bind(card_selector))
	GlobalUI.add_layer_content(card_selector, UI.Layer.GAME_MENU_SUBMENU)

func _on_card_selected(card: Card, card_selector: CardDeckViewer) -> void:
	if selected_card_type == original_card_type:
		selected_card_type = null
	else:
		selected_card_type = card.card_type
	card_selector.close()

func _on_card_clicked() -> void:
	(%Card as Card).is_selected = false

func _update() -> void:
	if not is_node_ready():
		return
	(%ChooseButton as Control).visible = Skill.get_skill_var(Skill.Var.REPLACE_STARTER_CARDS) > 0
	(%Card as Card).card_type = selected_card_type if selected_card_type else original_card_type

func _make_tooltip_text() -> String:
	return tr('Choose a starter <term:glyph>. It must be of Basic or Common <term:card_rarity_tier>.')

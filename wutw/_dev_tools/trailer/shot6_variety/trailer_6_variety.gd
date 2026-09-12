extends Node2D

@export var start_location: Vector2 = Vector2(220, 90)
@export var start_zoom: float = 2.5
@export var pan_offset: Vector2 = Vector2(60, 0)
@export var end_zoom: float = 2.5
@export var duration: float = 6.0
@export var cards: Array[CardType]
@export var draw_pile_count: int = 7

func _ready() -> void:
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P510_FINISHED_OUTRO_CUTSCENE)
	seed(0)

	# More reliably if manual. Not worth debugging for a one-off.
	#(%MapEditor as MapEditor)._manual_regenerate()
	#await (%MapEditor as MapEditor).cloud_generation_finished

	var deck := %CardDeck as CardDeck

	(deck.get_node('%DrawPileCount') as Label).text = str(draw_pile_count)
	(deck.get_node('%DiscardPileCount') as Control).visible = false

	var hand := %CardDeck.get_node('%HandList')
	Utils.clear_node(%CardDeck.get_node('%HandList'))
	for card_type in cards:
		var new_card := CardDeck.CARD_SCENE.instantiate_loaded_scene() as Card
		new_card.card_type = card_type
		hand.add_child(new_card)

	var all_card_types := CardType.get_all_card_types().duplicate() as Array[CardType]
	for _i in draw_pile_count:
		all_card_types.shuffle()
		deck._draw_pile.append(all_card_types[0])
	deck._update_indicators()

	(%MapEditor as MapEditor).instant_focus_location(start_location, start_zoom)
	(%MapEditor as MapEditor).focus_location(start_location + pan_offset, end_zoom, duration)
	await get_tree().create_timer(duration + 1).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

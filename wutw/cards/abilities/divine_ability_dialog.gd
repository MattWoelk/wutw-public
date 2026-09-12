class_name DivineAbilityDialog
extends CardDeckViewer

var _chosen_cards: Array[Card]
var _slashes: Dictionary[Card, TextureRect]
var _slash_tweens: Dictionary[Card, Tween]

func _ready() -> void:
	show_minimize_button = true
	super._ready()

func _update() -> void:
	Utils.clear_node(%CardList)
	for card_type in cards:
		var new_card := CARD_SCENE.instantiate_loaded_scene() as Card
		new_card.card_type = card_type
		new_card.playable = false
		new_card.selected.connect(_on_card_selected.bind(new_card))
		var slash := TextureRect.new()
		slash.material = ShaderMaterial.new()
		slash.texture = load('res://cards/abilities/discard_slash.png')
		slash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		(slash.material as ShaderMaterial).shader = load('res://cards/abilities/discard_slash.gdshader')
		slash.set_instance_shader_parameter('progress', 0)
		new_card.add_child(slash)
		slash.position.x = -7
		slash.size = Vector2(227, 255)
		_slashes[new_card] = slash
		%CardList.add_child(new_card)

	(%AspectCountersPanel as AspectCountersPanel).card_types = cards

func _on_card_selected(card: Card) -> void:
	card.is_selected = false  # Prevent selection.
	var end_progress: float
	if card in _chosen_cards:
		_chosen_cards.erase(card)
		end_progress = 0.0
	else:
		_chosen_cards.append(card)
		end_progress = 1.0

	if card in _slash_tweens:
		_slash_tweens[card].kill()
	var start_progress: Variant = _slashes[card].get_instance_shader_parameter('progress')
	_slash_tweens[card] = create_tween()
	_slash_tweens[card].tween_method(func(progress: float) -> void:
		_slashes[card].set_instance_shader_parameter('progress', progress)
	, (start_progress as float) if start_progress else 0.0, end_progress, Utils.anim_duration(0.3))
	_slash_tweens[card].play()
	match _chosen_cards.size():
		0: (%CloseButton as Button).text = tr('Keep All')
		1: (%CloseButton as Button).text = tr('Discard 1 Glyph')
		_: (%CloseButton as Button).text = tr('Discard %d Glyphs') % _chosen_cards.size()

func _on_close_button_pressed() -> void:
	var deck := Utils.get_active_run().get_current_stage().get_card_deck()
	var indices: Array[int]
	for i in %CardList.get_child_count():
		var card := %CardList.get_child(i) as Card
		if card in _chosen_cards:
			indices.push_front(i)  # IMPORTANT: Ends up in reverse order.
	for i in indices:
		deck.move_card_from_draw_to_discard(i)
	close()

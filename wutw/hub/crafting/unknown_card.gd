@tool
class_name UnknownCard
extends Control

signal hovered
signal unhovered
signal selected
signal unselected

@export var rarity: CardType.Rarity:
	set(value):
		rarity = value
		if is_node_ready():
			_recreate()
@export var count: int = 1:
	set(value):
		count = value
		if is_node_ready():
			_recreate()

var is_selected: bool = false:
	set(value):
		is_selected = value
		if is_node_ready():
			if is_selected:
				selected.emit()
			else:
				unselected.emit()
			_update_select_effect()
			_update_highlight()

var _is_hovered: bool = false
var _highlight_tween: Tween
var _select_tween: Tween

func _ready() -> void:
	(%Dowel as Control).material = (%Dowel as Control).material.duplicate()
	_recreate()
	set_process(false)
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.BEGIN], %MainContainer as Control)

func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if not mouse_event:
		return
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		is_selected = not is_selected

func animate_appear(delay: float = 0) -> void:
	modulate.a = 0
	if delay:
		get_tree().create_timer(delay).timeout.connect(animate_appear)
	else:
		(%AnimationPlayer as AnimationPlayer).play('appear')
		await get_tree().process_frame  # HACK: Avoid a flash of the card being visible.
		modulate.a = 1

func animate_disappear() -> void:
	modulate.a = 1
	Utils.set_input_enabled(self, false)
	(%AnimationPlayer as AnimationPlayer).play('disappear')
	await (%AnimationPlayer as AnimationPlayer).animation_finished
	queue_free()

func animate_roll() -> void:
	(%AnimationPlayer as AnimationPlayer).play('rollup')
	await (%AnimationPlayer as AnimationPlayer).animation_finished

func animate_unroll() -> void:
	(%AnimationPlayer as AnimationPlayer).play('rollup', -1, -1, true)
	await (%AnimationPlayer as AnimationPlayer).animation_finished

func get_disappear_anim_duration() -> float:
	return (%AnimationPlayer as AnimationPlayer).get_animation('disappear').length

func is_animating() -> bool:
	return modulate.a < 0.1 or (%AnimationPlayer as AnimationPlayer).is_playing()

func _recreate() -> void:
	(%RarityOverlay as Control).self_modulate = Card.RARITY_COLORS[rarity]
	(%RarityOverlay2 as Control).self_modulate = Card.RARITY_COLORS[rarity]
	(%RarityOverlay as Control).material = (%RarityOverlay as Control).material.duplicate()
	(%RarityOverlay2 as Control).material = (%RarityOverlay as Control).material

	# Equivalent to Card.DisplayState.DISABLED
	(%MainContainer as Control).modulate = Color(0.67, 0.67, 0.67, 1.0)

	(%CountLabel as Label).text = ('⨯' + str(count)) if count else ''

	_update_highlight()

func _make_tooltip_text() -> String:
	var glyphs_label := tr_n(
		'%d Unknown <term:glyph>',
		'%d Unknown <term:glyph>s',
		count
	) % count
	return (tr('<header_font_size>[b]%s (%s)[/b][/font_size]\n\n' +
			 '[i]Encounter these <term_lower:glyph>s during <term:run>s to reveal.[/i]') %
			[glyphs_label, CardType.get_rarity_name_static(rarity)])

func _update_highlight() -> void:
	var is_focused := (is_selected or _is_hovered)
	if _highlight_tween:
		_highlight_tween.kill()
	_highlight_tween = create_tween()
	_highlight_tween.tween_property(%HoverOverlay, 'modulate:a8', Card.HOVER_BOOST * float(is_focused), Card.HOVER_EFFECT_DURATION)
	_highlight_tween.parallel().tween_property(%NameLabel, 'modulate:a', float(is_focused), Card.HOVER_EFFECT_DURATION)
	_highlight_tween.play()

func _update_select_effect() -> void:
	if _select_tween:
		_select_tween.kill()
	_select_tween = create_tween()
	var rarity_material := (%RarityOverlay as Control).material as ShaderMaterial
	var start_factor: Variant = rarity_material.get_shader_parameter('factor')
	_select_tween.tween_method(
		func(v: float) -> void: rarity_material.set_shader_parameter('factor', v),
		start_factor as float if start_factor else 0.0,
		Card.SELECT_BRIGHTNESS * float(is_selected),
		Card.SELECT_EFFECT_DURATION)
	_select_tween.play()

func _on_mouse_entered() -> void:
	_is_hovered = true
	hovered.emit()
	_update_highlight()

func _on_mouse_exited() -> void:
	_is_hovered = false
	unhovered.emit()
	_update_highlight()

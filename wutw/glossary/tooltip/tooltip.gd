@tool
class_name Tooltip
extends UkiyoePanelContainer

enum RelativeDirection {
	BELOW,
	RIGHT,
	ABOVE,
	LEFT,
	FORCE_CENTER,
	UNDER_CURSOR,
	ABOVE_CURSOR,
}

enum Alignment {
	CENTERED,
	BEGIN,
	END,
}

static var CARD_SCENE := AsyncLoadedResource.new('res://cards/card.tscn')
static var RELIC_PREVIEW_SCENE := AsyncLoadedResource.new('res://relics/selector/relic_preview.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var DEFAULT_TOOLTIP_SCENE := AsyncLoadedResource.new('res://glossary/tooltip/tooltip.tscn')

static var _serial_index := 0  # Just used for naming nodes to help debug.

const DEFAULT_DELAY_TIME := 0.4
const ANIM_DURATION := 0.2
const MAX_RESIZE_ATTEMPTS := 4
const TOP_MARGIN := 75

var max_width: int = 500
var max_height: int = 1000
var margin: int = 0
var preferred_extras_directions: Array[RelativeDirection]
var hide_expand_hint := false
var avoid_top_bar := false

var _attached_to: Control
var _markedup_text: String
var _preferred_directions: Array[RelativeDirection]
var _preferred_alignments: Array[Alignment]
var _rect_control: Control
# Dynamic state.
var _appear_tween: Tween
var _disappear_tween: Tween
var _in_detailed_mode: bool = false:
	set(value):
		if _in_detailed_mode == value:
			return
		_in_detailed_mode = value
		_clear_extras()
		if not _disappear_tween:
			GlobalTooltipSystem.pre_tooltip_shown.emit(_attached_to, self)
			show_tooltip()
var _linked_terms: Array[Term]
var _attached_extras: Array[Control]
var _hiding := false

static func create(control: Control, markedup_text: String,
				  preferred_directions: Array[RelativeDirection] = [],
				  preferred_alignments: Array[Alignment] = [],
				  rect_control: Control = null,
				  tooltip_scene: PackedScene = null,
				  add_to_tree: bool = true) -> Tooltip:
	for i in RelativeDirection.FORCE_CENTER:  # Not including FORCE_CENTER.
		if i not in preferred_directions:
			preferred_directions.append(i)
	for i in Alignment.END + 1:
		if i not in preferred_alignments:
			preferred_alignments.append(i)

	if not tooltip_scene:
		tooltip_scene = DEFAULT_TOOLTIP_SCENE.get_loaded()
	var tooltip := tooltip_scene.instantiate() as Tooltip
	tooltip.name = 'Tooltip_' + str(_serial_index)
	_serial_index += 1
	tooltip._attached_to = control
	tooltip._markedup_text = markedup_text
	tooltip._preferred_directions = preferred_directions
	tooltip._preferred_alignments = preferred_alignments
	tooltip._rect_control = rect_control
	tooltip.z_as_relative = false
	tooltip.z_index = Utils.get_absolute_z_index(control) + UI.LAYER_SPACING
	tooltip.modulate.a = 0.0
	if add_to_tree:
		control.get_tree().root.add_child.call_deferred(tooltip)

	return tooltip

func destroy() -> void:
	queue_free()

func set_markedup_text(markedup_text: String) -> void:
	_markedup_text = markedup_text
	_clear_extras()

func get_markedup_text() -> String:
	return _markedup_text

func _ready() -> void:
	super._ready()
	if not Utils.is_in_editor():
		set_process(false)

func _process(_delta: float) -> void:
	if not Utils.is_in_editor() and _get_link_mode() in [MarkedUpLabel.LinkMode.HINT, MarkedUpLabel.LinkMode.EXPAND]:
		_in_detailed_mode = Input.is_key_pressed(KEY_CTRL)
	if not _attached_to and not _hiding:
		hide_tooltip()

func _get_link_mode() -> MarkedUpLabel.LinkMode:
	if _in_detailed_mode:
		return MarkedUpLabel.LinkMode.EXPAND
	else:
		if hide_expand_hint:
			return MarkedUpLabel.LinkMode.NONE
		else:
			return MarkedUpLabel.LinkMode.HINT

func _setup_text() -> void:
	var label := %MarkedUpLabel as MarkedUpLabel
	Utils._scale_font_size(label, true, 16)
	for _i in MAX_RESIZE_ATTEMPTS:
		# Let the rich text wrap at unlimited size first.
		label.custom_minimum_size = Vector2.ZERO
		var parsed := label.set_markedup_text(_markedup_text, _get_link_mode())
		_linked_terms.assign(parsed.linked_terms.keys())
		await get_tree().create_timer(1.0 / 60.0).timeout

	 	# Let the layout update within maximums.
		size = Vector2.ZERO
		label.custom_minimum_size = Vector2(max_width, max_height)
		await get_tree().create_timer(1.0 / 60.0).timeout

		# Did we need all that space?
		label.custom_minimum_size.x = min(label.get_content_width(), max_width)
		label.custom_minimum_size.y = min(label.get_content_height(), max_height)
		label.size = Vector2.ZERO
		size = Vector2.ZERO
		if label.size.y <= label.size.x:  # We should avoid vertical tooltips.
			break

func _clear_extras() -> void:
	for extra in _attached_extras:
		extra.get_parent().remove_child(extra)
		extra.queue_free()
	_attached_extras.clear()

func _ensure_extras_created() -> void:
	if _attached_extras:
		return

	var relics: Array[Relic] = []
	var card_types: Array[CardType] = []
	for term in _linked_terms:
		if term is Relic:
			relics.append(term)
		elif term is CardType:
			card_types.append(term)
	for relic in relics:
		var relic_preview := RELIC_PREVIEW_SCENE.instantiate_loaded_scene() as RelicPreview
		relic_preview.relic = relic
		_attached_extras.append(relic_preview)
	for card_type in card_types:
		var card := CARD_SCENE.instantiate_loaded_scene() as Card
		card.card_type = card_type
		var card_margin := MarginContainer.new()
		if not GameSettings.Interface.show_card_names.value():
			card_margin.add_theme_constant_override('margin_top', -20)
		card_margin.add_child(card)
		_attached_extras.append(card_margin)

func _place_extras(direction: RelativeDirection) -> void:
	(%Extras_Above as Control).visible = false
	(%Extras_Below as Control).visible = false
	(%Extras_Left as Control).visible = false
	(%Extras_Right as Control).visible = false

	var container: Container
	match direction:
		RelativeDirection.ABOVE:
			container = %Extras_Above
		RelativeDirection.BELOW:
			container = %Extras_Below
		RelativeDirection.LEFT:
			container = %Extras_Left
		RelativeDirection.RIGHT:
			container = %Extras_Right
		_:
			container = %Extras_Below
	container.visible = true

	for extra in _attached_extras:
		if extra.is_inside_tree():
			extra.get_parent().remove_child(extra)
			container.add_child(extra)
			# HACK: Re-adding resets unchanged ability labels, so make sure to update them.
			if extra is Card and (extra as Card).card_type.abilities.size() < 2:
				(extra as Card).card_type = (extra as Card).card_type
		else:
			container.add_child(extra)

func show_tooltip() -> void:
	if not _markedup_text:
		assert(false)
		return
	if _disappear_tween:
		_disappear_tween.kill()
		_disappear_tween = null
	_appear_tween = create_tween()
	_appear_tween.tween_callback(func() -> void: modulate.a = 0.0)  # Hide it while calculating size.
	_appear_tween.tween_callback(_setup_text)
	_appear_tween.tween_interval(3.0 / 30)  # HACK: Wait for size to be calculated.
	_appear_tween.tween_callback(show)
	_appear_tween.tween_interval(DEFAULT_DELAY_TIME / GameSettings.Interface.tooltip_speed.value())  # Also lets the layout update.
	_appear_tween.tween_callback(_position)
	_appear_tween.tween_callback(set_process.bind(true))
	_appear_tween.tween_callback(GlobalAudioSystem.play.bind(AK.EVENTS.UI_POPUP_EVENT))
	_appear_tween.tween_property(self, 'modulate:a', 1.0, ANIM_DURATION)
	_appear_tween.play()
	await _appear_tween.finished

func hide_tooltip(stop_processing: bool = true) -> void:
	if _hiding:
		return
	if _appear_tween:
		_appear_tween.kill()
		_appear_tween = null
	_disappear_tween = create_tween()
	if stop_processing:
		_disappear_tween.tween_callback(set_process.bind(false))
	_disappear_tween.tween_callback(func() -> void: _in_detailed_mode = false)
	_disappear_tween.tween_property(self, 'modulate:a', 0.0, ANIM_DURATION)
	_disappear_tween.tween_callback(hide)
	_disappear_tween.play()
	await _disappear_tween.finished
	_hiding = false

func _position() -> void:
	if not _attached_to:  # Tween callback called after the node is freed.
		return
	var control_global_rect := Utils.get_screen_rect(_rect_control if _rect_control else _attached_to)
	var viewport_rect := _attached_to.get_viewport_rect()

	var extras_directions: Array[RelativeDirection]
	extras_directions.append_array(preferred_extras_directions)
	for direction in _preferred_directions:
		match direction:
			RelativeDirection.RIGHT: extras_directions.append(RelativeDirection.RIGHT)
			RelativeDirection.LEFT: extras_directions.append(RelativeDirection.LEFT)
			RelativeDirection.BELOW: extras_directions.append(RelativeDirection.RIGHT)
			RelativeDirection.ABOVE: extras_directions.append(RelativeDirection.RIGHT)
	if (_preferred_directions.find(RelativeDirection.LEFT) != -1
		and _preferred_directions.find(RelativeDirection.LEFT) > _preferred_directions.find(RelativeDirection.RIGHT)):
		extras_directions.append(RelativeDirection.RIGHT)
		extras_directions.append(RelativeDirection.LEFT)
	else:
		extras_directions.append(RelativeDirection.LEFT)
		extras_directions.append(RelativeDirection.RIGHT)
	extras_directions.append(RelativeDirection.ABOVE)
	extras_directions.append(RelativeDirection.BELOW)

	_ensure_extras_created()

	for extras_direction: RelativeDirection in extras_directions:
		_place_extras(extras_direction)
		for direction in _preferred_directions:
			for alignment in _preferred_alignments:
				var tooltip_size := get_combined_minimum_size()
				var pos := _try_compute_position(control_global_rect, viewport_rect, tooltip_size, direction, alignment)
				if viewport_rect.has_point(pos) and viewport_rect.has_point(pos + tooltip_size):
					global_position = pos + _get_margin(direction)
					# Avoid top bar if possible.
					if avoid_top_bar:
						if pos.y < TOP_MARGIN and viewport_rect.has_point(pos + tooltip_size + Vector2(0, TOP_MARGIN)):
							global_position.y = TOP_MARGIN
					return

	# Fallback: center on screen.
	if Utils.is_dev():
		push_warning('Tooltip position fallback for %s at %s' % [str(_attached_to), str(control_global_rect)])
	global_position = (viewport_rect.size - get_combined_minimum_size()) / 2.0

func _get_margin(direction: RelativeDirection) -> Vector2:
	match direction:
		RelativeDirection.ABOVE:
			return Vector2(0, -margin)
		RelativeDirection.BELOW:
			return Vector2(0, margin)
		RelativeDirection.LEFT:
			return Vector2(-margin, 0)
		RelativeDirection.RIGHT:
			return Vector2(margin, 0)
		_:
			return Vector2.ZERO

func _try_compute_position(control_rect: Rect2, viewport_rect: Rect2, tooltip_size: Vector2,
 							direction: RelativeDirection, alignment: Alignment) -> Vector2:
	var pos := Vector2(-1, -1)

	if direction == RelativeDirection.UNDER_CURSOR:
		control_rect.position = get_global_mouse_position() - Vector2(8, 16)
		control_rect.size = Vector2(8, 32)
		direction = RelativeDirection.BELOW
	elif direction == RelativeDirection.ABOVE_CURSOR:
		control_rect.position = get_global_mouse_position() - Vector2(8, 16)
		control_rect.size = Vector2(8, 32)
		direction = RelativeDirection.ABOVE

	# Place on the correct side (primary axis).
	match direction:
		RelativeDirection.ABOVE:
			pos.y = control_rect.position.y - tooltip_size.y
		RelativeDirection.BELOW:
			pos.y = control_rect.position.y + control_rect.size.y
		RelativeDirection.LEFT:
			pos.x = control_rect.position.x - tooltip_size.x
		RelativeDirection.RIGHT:
			pos.x = control_rect.position.x + control_rect.size.x
		RelativeDirection.FORCE_CENTER:
			return (viewport_rect.size - tooltip_size) / 2.0  # This is the last resort, so don't clamp.

	# Align on the perpendicular axis, then clamp so it fits.
	if direction in [RelativeDirection.LEFT, RelativeDirection.RIGHT]:
		# Vertical alignment for left/right.
		match alignment:
			Alignment.BEGIN:
				pos.y = control_rect.position.y
			Alignment.CENTERED:
				pos.y = control_rect.position.y + (control_rect.size.y - tooltip_size.y) * 0.5
			Alignment.END:
				pos.y = control_rect.position.y + control_rect.size.y - tooltip_size.y
		# Clamp so tooltip never spills off the edge of the screen.
		pos.y = clamp(
			pos.y,
			viewport_rect.position.y,
			viewport_rect.position.y + viewport_rect.size.y - tooltip_size.y
		)
	else:
		# Horizontal alignment for above/below.
		match alignment:
			Alignment.BEGIN:
				pos.x = control_rect.position.x
			Alignment.CENTERED:
				pos.x = control_rect.position.x + (control_rect.size.x - tooltip_size.x) * 0.5
			Alignment.END:
				pos.x = control_rect.position.x + control_rect.size.x - tooltip_size.x
		# Clamp so tooltip never spills off the edge of the screen.
		pos.x = clamp(
			pos.x,
			viewport_rect.position.x,
			viewport_rect.position.x + viewport_rect.size.x - tooltip_size.x
		)

	return pos

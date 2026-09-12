@tool
class_name Spot
extends Control

signal upgrade_activated(recipe: SpotRecipe)

const CONNECT_MARGIN: float = 10
static var SPOT_RECIPE_SCENE := AsyncLoadedResource.new('res://stage/spots/spot_recipe.tscn')
static var UPGRADE_TREE_CONNECTION_SCENE := AsyncLoadedResource.new('res://stage/spots/upgrade_tree_connection.tscn')

@export var spot_type: SpotType:
	set(value):
		if spot_type == value:
			return
		spot_type = value
		if is_node_ready():
			_recreate()
@export var filter_to_requirements: Array[BonusType]:
	set(value):
		if filter_to_requirements == value:
			return
		filter_to_requirements = value
		if is_node_ready():
			_animate_scroll_to(0, _get_unscaled_global_rect(%UpgradesList as Control).end.y)
			_layout_nodes()
@export var is_locked: bool = false:
	set(value):
		if is_locked == value:
			return
		is_locked = value
		if is_node_ready():
			_refresh_locked()
@export var is_first_spot_copy: bool = false:
	set(value):
		if is_first_spot_copy == value:
			return
		is_first_spot_copy = value
		if is_node_ready():
			_recreate()

var _full_tree: RecipeNode = RecipeNode.new()
var _visible_tree: RecipeNode
var _all_nodes: Dictionary[SpotUpgrade, RecipeNode] = {}
var _ensure_available_upgrades: Array[SpotUpgrade] = []
var _active_upgrades: Array[SpotUpgrade] = []
var _events: Dictionary[SpotUpgrade, Event_Stage]
var _unroll_tween: Tween

# Collapse state.
var _collapsed := false
var _expanded_size: float = 0
var _expanded_bottom_margin: float = 0
var _collapse_tween : Tween
var _revealing_preview := false

func _ready() -> void:
	_recreate()
	_refresh_locked()

	(%CollapseButton as Control).visible = false
	(%ExpandButton as Control).visible = false
	var run := Utils.get_active_run()
	if run:  # Not in editor.
		run.signals.haunting_pacified.connect(_update_collapse_button.unbind(1))

	GlobalTooltipSystem.attach(%TitleLabel as Control, _make_tooltip_text,
			[Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.LEFT, Tooltip.RelativeDirection.BELOW],
			[Tooltip.Alignment.BEGIN, Tooltip.Alignment.END])

func _enter_tree() -> void:
	UI.register_zoomable(self)

func _exit_tree() -> void:
	for node: RecipeNode in _all_nodes.values():
		if Utils.ensure(node.recipe != null):
			node.recipe.queue_free()
		node.free()
	_all_nodes.clear()

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	assert(data is Card)
	return SlotUtils.match_slot(get_all_aspect_slots(), (data as Card).card_type.aspects) != null

func _drop_data(_pos: Vector2, data: Variant) -> void:
	assert(data is Card)
	var slot := SlotUtils.match_slot(get_all_aspect_slots(), (data as Card).card_type.aspects)
	assert(slot)
	slot.card_dropped.emit(data as Card)

func animate_unroll() -> void:
	await get_tree().process_frame
	(%ScrollPanel as ScrollPanel).animate_unroll()

func animate_roll(duration: float = 0.5) -> void:
	await (%ScrollPanel as ScrollPanel).animate_roll(Utils.anim_duration(duration), false)

func get_all_recipes() -> Array[SpotRecipe]:
	var result: Array[SpotRecipe] = []
	for node: RecipeNode in _all_nodes.values():
		if node.recipe.is_inside_tree():
			result.append(node.recipe)
	return result

func get_all_upgrades() -> Array[SpotUpgrade]:
	var result: Array[SpotUpgrade] = []
	for node: RecipeNode in _all_nodes.values():
		result.append(node.recipe.spot_upgrade)
	return result

func set_upgrade_event(upgrade: SpotUpgrade, event: Event_Stage) -> void:
	if _events.get(upgrade) == event:
		return
	_events[upgrade] = event
	if is_node_ready():
		for node: RecipeNode in _all_nodes.values():
			if node.recipe.spot_upgrade == upgrade:
				Utils.ensure(not node.recipe.event or not event)
				node.recipe.event = event
				if event and is_node_ready():  # Don't mess with the tree if it's just clearning an event.
					_layout_nodes()
				return
		Utils.ensure(false)

func get_upgrade_event(upgrade: SpotUpgrade) -> Event_Stage:
	return _events.get(upgrade, null)

func get_current_upgrades() -> Array[SpotUpgrade]:
	return _active_upgrades

func get_all_aspect_slots() -> Array[AspectSlot]:
	var result: Array[AspectSlot]
	for node: RecipeNode in _all_nodes.values():
		if node.recipe.is_inside_tree():
			result.append_array(node.recipe.get_aspect_slots())
	return result

func ensure_upgrade_available(upgrade: SpotUpgrade) -> void:
	if upgrade not in _ensure_available_upgrades:
		_ensure_available_upgrades.append(upgrade)
		if is_node_ready():
			_layout_nodes()

# Creation

func _recreate() -> void:
	if not spot_type: return
	for node: RecipeNode in _all_nodes.values():
		if Utils.ensure(node.recipe != null):
			node.recipe.queue_free()
	_all_nodes.clear()
	_full_tree.children.clear()
	var run := Utils.get_active_run()
	for upgrade in spot_type.upgrades:
		if upgrade.is_allowed(run, is_first_spot_copy):
			_full_tree.children.append(_create_recipe_node(upgrade))
			_full_tree.children[-1].parent = _full_tree
	_update_title()
	_update_all_recipe_states()
	_layout_nodes()
	if spot_type.panel_material:
		((%ScrollPanel as ScrollPanel).get_node('%ContentPanel') as Control).material = spot_type.panel_material.duplicate()

func _create_recipe_node(upgrade: SpotUpgrade) -> RecipeNode:
	var recipe := SPOT_RECIPE_SCENE.instantiate_loaded_scene() as SpotRecipe
	recipe.spot_upgrade = upgrade
	recipe.event = _events.get(upgrade, null)
	recipe.z_index = 1
	recipe.activated.connect(_on_upgrade_activated.bind(recipe))

	var recipe_node := RecipeNode.new()
	recipe_node.recipe = recipe
	var run := Utils.get_active_run()
	for child_upgrade in upgrade.child_upgrades:
		if child_upgrade.is_allowed(run, is_first_spot_copy):
			recipe_node.children.append(_create_recipe_node(child_upgrade))
			recipe_node.children[-1].parent = recipe_node

	_all_nodes[upgrade] = recipe_node
	return recipe_node

func _update_title() -> void:
	var tween := create_tween()
	var title_label := (%TitleLabel as Label)
	tween.tween_property(title_label, 'modulate:a', 0.0, 0.3)
	tween.tween_callback(func() -> void:
		title_label.text = tr(spot_type.name)
		if _active_upgrades and not _collapsed:
			title_label.text += ': ' + tr(_active_upgrades[-1].name)
	)
	tween.tween_property(title_label, 'modulate:a', 1.0, 0.3)
	tween.play()

func _make_tooltip_text() -> String:
	var text := '<header_font_size>[b]%s (<term:spot>)[/b][/font_size]' % tr(spot_type.name)
	text += '\n\n'
	text += tr('[i]“%s”[/i]') % tr(spot_type.description)
	if _active_upgrades:
		text += '\n\n'
		text += tr('[b]Active <term:spot_upgrade>[/b]: ') + tr(_active_upgrades[-1].name)
		text += '\n\n'
		text += tr('[i]“%s”[/i]') % tr(_active_upgrades[-1].description)
		text += '\n\n'
		text += tr('[b]Total <term:bonus>s:[/b]')
		text += '[ul]\n'
		var total_bonuses := BonusAmounts.new()
		for upgrade in _active_upgrades:
			for bonus_type in upgrade.granted_bonuses:
				total_bonuses.add_amount(bonus_type, upgrade.granted_bonuses[bonus_type])
		for bonus_type in total_bonuses.get_bonus_types():
			text += ' %s: %d\n' % [bonus_type.get_term_tag(), total_bonuses.get_amount(bonus_type)]
		text += '[/ul]'

	return text

# Recipe State Management

func _update_all_recipe_states() -> void:
	for node in _full_tree.children:
		_update_recipe_state(node, SpotRecipe.State.ACTIVE)

func _update_recipe_state(node: RecipeNode, parent_state: SpotRecipe.State) -> void:
	var siblings := node.parent.children.duplicate()
	siblings.erase(node)

	var recipe := node.recipe
	if recipe.spot_upgrade in _active_upgrades:
		# ACTIVE: self is active
		recipe.state = SpotRecipe.State.ACTIVE
	elif (parent_state == SpotRecipe.State.LOCKED_OUT
			or siblings.any(func(n: RecipeNode) -> bool: return n.recipe.state == SpotRecipe.State.ACTIVE)):
		# LOCKED_OUT: parent is locked out or sibling is active
		recipe.state = SpotRecipe.State.LOCKED_OUT
	elif parent_state == SpotRecipe.State.ACTIVE:
		# AVAILABLE: parent is active or (parent is null and no active) or current_upgrades.is_empty()
		recipe.state = SpotRecipe.State.AVAILABLE
	else:
		# UNAVAILABLE: parent is available
		Utils.ensure(parent_state in [SpotRecipe.State.AVAILABLE, SpotRecipe.State.UNAVAILABLE])
		recipe.state = SpotRecipe.State.UNAVAILABLE

	for child in node.children:
		_update_recipe_state(child, recipe.state)

func _on_upgrade_activated(recipe: SpotRecipe) -> void:
	_active_upgrades.append(recipe.spot_upgrade)
	_update_all_recipe_states()

	upgrade_activated.emit(recipe)

	var preview := (%SpotUpgradePreview as SpotUpgradePreview)
	preview.spot_upgrade = recipe.spot_upgrade
	var flavor_label := (%FlavorLabel as Label)
	if _active_upgrades.size() == 1:  # First upgrade.
		flavor_label.text = tr('“%s”') % tr(recipe.spot_upgrade.description)
		_revealing_preview = true
		await _reveal_preview()
		_revealing_preview = false
	else:
		while _revealing_preview:
			await get_tree().process_frame
		# Adjust size to account for flavor text difference.
		var tween := create_tween()
		tween.tween_property(flavor_label, 'modulate:a', 0.0, 0.3)
		tween.tween_callback(func() -> void:
			flavor_label.text = tr('“%s”') % tr(recipe.spot_upgrade.description)
		)
		tween.tween_property(flavor_label, 'modulate:a', 1.0, 0.3)
		var start_height := (%PreviewSizer as Control).custom_minimum_size.y
		tween.parallel().tween_method(func(value: float) -> void:
			var preview_size := lerpf(start_height, (%PreviewVBox as Control).size.y, value)
			(%PreviewSizer as Control).custom_minimum_size.y = preview_size
		, 0.0, 1.0, 0.5)
		tween.set_speed_scale(Utils.anim_speed())
		tween.play()
		await tween.finished

	_animate_scroll()
	_update_title()
	_update_collapse_button()

func _is_haunted() -> bool:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	for haunting in stage.get_hauntings():
		if haunting.get_spot() == self:
			return true
	return false

func _refresh_locked() -> void:
	(%UpgradesList as Control).modulate.a = 0.5 if is_locked else 1.0

# Layout

func _filter_tree(root: RecipeNode) -> RecipeNode:
	var visible_children: Array[RecipeNode] = []
	for child in root.children:
		var filtered_child := _filter_tree(child)
		if filtered_child:
			visible_children.append(filtered_child)

	var any_matched := false
	if root.recipe and root.recipe.event:
		any_matched = true
	elif filter_to_requirements:
		for bonus_type in filter_to_requirements:
			if root.recipe:
				if root.recipe.spot_upgrade.granted_bonuses.get(bonus_type, 0) > 0:
					any_matched = true
					break
		if root.recipe and root.recipe.spot_upgrade in _ensure_available_upgrades:
			any_matched = true
	else:
		any_matched = true

	var is_active := root.recipe and root.recipe.state == SpotRecipe.State.ACTIVE
	var is_top_level := root.parent and not root.parent.parent
	var should_show := false
	if _active_upgrades:
		if is_top_level:
			should_show = is_active
		else:
			should_show = is_active or visible_children or any_matched
	else:
		should_show = is_top_level or visible_children or any_matched

	if should_show:
		var copy := RecipeNode.new()
		copy.recipe = root.recipe
		copy.parent = root.parent
		copy.children = visible_children
		return copy
	else:
		return null

func _free_tree(root: RecipeNode) -> void:
	if root:
		for child in root.children:
			_free_tree(child)
		root.children.clear()
		root.free()

func _layout_nodes() -> void:
	if _unroll_tween and _unroll_tween.is_running():
		if not _unroll_tween.finished.is_connected(_layout_nodes):
			_unroll_tween.finished.connect(_layout_nodes)
		return

	# Clear old state.
	while %UpgradesList.get_child_count():
		# Important: Need to remove children manually for the check to update.
		var line := %UpgradesList.get_child(%UpgradesList.get_child_count() - 1) as HBoxContainer
		%UpgradesList.remove_child(line)
		while line.get_child_count():
			var grandchild := line.get_child(0)
			line.remove_child(grandchild)
			if not (grandchild is SpotRecipe):
				grandchild.queue_free()
		line.queue_free()

	# Update which recipes are visible.
	_free_tree(_visible_tree)
	_visible_tree = _filter_tree(_full_tree)
	if not _visible_tree:
		return

	# Lay out the visible nodes.
	for child_level1 in _visible_tree.children:
		var hbox1 := HBoxContainer.new()
		hbox1.add_child(child_level1.recipe)
		hbox1.visible = child_level1.recipe.visible
		%UpgradesList.add_child(hbox1)
		for child_level2 in child_level1.children:
			var hbox2 := HBoxContainer.new()
			var connector1 := UPGRADE_TREE_CONNECTION_SCENE.instantiate_loaded_scene() as Node
			hbox2.add_child(connector1)
			hbox2.add_child(child_level2.recipe)
			hbox2.visible = child_level2.recipe.visible
			%UpgradesList.add_child(hbox2)
			var is_last_l2_child := child_level1.children.find(child_level2) == child_level1.children.size() - 1
			if is_last_l2_child:
				(connector1.get_child(0) as TextureRect).texture = load('res://stage/spots/tree_connection_end.png')
			for child_level3 in child_level2.children:
				var hbox3 := HBoxContainer.new()
				var connector21 := UPGRADE_TREE_CONNECTION_SCENE.instantiate_loaded_scene() as Node
				var connector22 := UPGRADE_TREE_CONNECTION_SCENE.instantiate_loaded_scene() as Node
				(connector22 as Control).modulate = Color(1.533, 0.901, 0.69)
				hbox3.add_child(connector21)
				hbox3.add_child(connector22)
				hbox3.add_child(child_level3.recipe)
				%UpgradesList.add_child(hbox3)
				hbox3.visible = child_level3.recipe.visible
				if is_last_l2_child:
					(connector21.get_child(0) as TextureRect).texture = load('res://stage/spots/tree_connection_none.png')
				else:
					(connector21.get_child(0) as TextureRect).texture = load('res://stage/spots/tree_connection_outer.png')
				var is_last_l3_child := child_level2.children.find(child_level3) == child_level2.children.size() - 1
				if is_last_l3_child:
					(connector22.get_child(0) as TextureRect).texture = load('res://stage/spots/tree_connection_end.png')

	await get_tree().process_frame
	_animate_scroll()

func _reveal_preview() -> void:
	await _animate_scroll()

	var preview := (%SpotUpgradePreview as SpotUpgradePreview)
	preview.visible = true

	var tween := create_tween()

	# Fade out decor.
	var mat := ((%ScrollPanel as ScrollPanel).get_node('%ContentPanel') as Control).material as ShaderMaterial
	var decor_modulate := mat.get_shader_parameter('decor_modulate') as Color
	tween.tween_method(func(t: float) -> void:
		var c := decor_modulate
		c.a *= t
		mat.set_shader_parameter('decor_modulate', c)
	, 1.0, 0.0, 0.4)

	# Fade out and collapse recipes beyond the lowest visible.
	var container_rect := _get_unscaled_global_rect(%UpgradesList as Control)
	var max_bottom: float = container_rect.position.y
	for recipe in get_all_recipes():
		if recipe.state != SpotRecipe.State.LOCKED_OUT:
			var rect := _get_unscaled_global_rect(recipe as Control)
			max_bottom = max(max_bottom, rect.end.y)
	for recipe in get_all_recipes():
		if recipe.state == SpotRecipe.State.LOCKED_OUT:
			var rect := _get_unscaled_global_rect(recipe as Control)
			if rect.position.y >= max_bottom:
				var control := recipe as Control
				if recipe.get_parent() is HBoxContainer:
					control = recipe.get_parent()
				tween.parallel().tween_property(control, 'modulate:a', 0.0, 0.2)
				control.custom_maximum_size.y = control.size.y
				control.propagate_maximum_size = false
				tween.parallel().tween_property(control, 'custom_maximum_size:y', 0.0, 0.2)
	# Keep the scroll bottom matching the resizing recipes.
	tween.parallel().tween_method(func(_value: float) -> void:
		var container_rect2 := _get_unscaled_global_rect(%UpgradesList as Control)
		var max_bottom2: float = container_rect2.position.y
		for recipe in get_all_recipes():
			if recipe.state != SpotRecipe.State.LOCKED_OUT:
				var rect := _get_unscaled_global_rect(recipe as Control)
				max_bottom2 = max(max_bottom2, rect.end.y)
		var bottom_margin2 := container_rect2.end.y - max_bottom2
		(%ScrollPanel as ScrollPanel).bottom_margin = bottom_margin2
	, 0.0, 0.0, 0.2)

	tween.tween_interval(0.001)  # No-op to separate the two parallel groups

	# Hide the faded out recipes.
	for recipe in get_all_recipes():
		if recipe.state == SpotRecipe.State.LOCKED_OUT:
			var rect := _get_unscaled_global_rect(recipe as Control)
			if rect.position.y >= max_bottom:
				var control := recipe as Control
				if recipe.get_parent() is HBoxContainer:
					control = recipe.get_parent()
				tween.parallel().tween_property(control, 'visible', false, 0.001)

	# Resize horizontally.
	tween.tween_callback(func() -> void:
		(%PreviewVBox as Control).size.x = (%PreviewSizer as Control).size.x
		(%PreviewSizer as Control).custom_minimum_size.x = (%PreviewVBox as Control).size.x
	)

	# Expand the preview box vertically.
	tween.tween_method(func(value: float) -> void:
		(%PreviewVBox as Control).position = Vector2.ZERO
		(%PreviewVBox as Control).size.x = (%PreviewSizer as Control).size.x
		(%PreviewVBox as Control).size.y = 0  # minimum
		var preview_size := (%PreviewVBox as Control).size.y * value
		(%PreviewSizer as Control).custom_minimum_size.x = (%PreviewVBox as Control).size.x
		(%PreviewSizer as Control).custom_minimum_size.y = preview_size
		(%ScrollPanel as ScrollPanel).bottom_margin = preview_size
	, 0.0, 1.0, 1.0)

	tween.set_speed_scale(Utils.anim_speed())
	tween.play()
	await tween.finished

func _animate_scroll() -> void:
	var container_rect := _get_unscaled_global_rect(%UpgradesList as Control)
	var min_top: float = container_rect.end.y
	var max_bottom: float = container_rect.position.y
	for recipe in get_all_recipes():
		if recipe.state != SpotRecipe.State.LOCKED_OUT:
			var rect := _get_unscaled_global_rect(recipe as Control)
			min_top = min(min_top, rect.position.y)
			max_bottom = max(max_bottom, rect.end.y)
	var top_margin := min_top - container_rect.position.y
	var bottom_margin := container_rect.end.y - max_bottom
	if (%PreviewSizer as Control).custom_minimum_size.y > 0:  # Preview mode.
		bottom_margin = 0
	await _animate_scroll_to(top_margin, bottom_margin)

func _animate_scroll_to(top_margin: float, bottom_margin: float) -> void:
	var finished_connections: Array
	if _unroll_tween:
		if _unroll_tween.is_running():
			finished_connections = _unroll_tween.finished.get_connections()
		_unroll_tween.kill()
	_unroll_tween = create_tween()
	_unroll_tween.set_ease(Tween.EASE_IN_OUT)
	_unroll_tween.tween_property(%ScrollPanel, 'top_margin', top_margin, 0.5)
	_unroll_tween.parallel().tween_property(%ScrollPanel, 'bottom_margin', bottom_margin, 0.5)
	_unroll_tween.set_speed_scale(Utils.anim_speed())
	_unroll_tween.play()
	for c: Dictionary in finished_connections:
		_unroll_tween.finished.connect(c['callable'] as Callable)
	GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_SCROLL_ACTIVATE)
	await _unroll_tween.finished

func _get_unscaled_global_rect(node: Control) -> Rect2:
	var result: Rect2
	if offset_transform_enabled:
		offset_transform_enabled = false
		result = node.get_global_rect()
		offset_transform_enabled = true
	else:
		result = node.get_global_rect()
	return result

class RecipeNode extends Object:
	var recipe: SpotRecipe
	var children: Array[RecipeNode] = []
	var parent: RecipeNode

# Collapse/Expand

func _update_collapse_button() -> void:
	if _is_haunted():
		(%CollapseButton as Control).visible = false
	else:
		var any_recipe_available := false
		for recipe in get_all_recipes():
			if recipe.is_available():
				any_recipe_available = true
				break
		(%CollapseButton as Control).visible = not any_recipe_available

func _on_collapse_button_pressed() -> void:
	if _collapse_tween:
		return
	assert(not _collapsed)
	_expanded_size = size.x
	_expanded_bottom_margin = (%ScrollPanel as ScrollPanel).bottom_margin

	var container_rect := _get_unscaled_global_rect(%MainVBox as Control)
	var height := container_rect.end.y - container_rect.position.y
	var new_bottom_margin := height - (%ScrollPanel as ScrollPanel).top_margin

	_collapse_tween = create_tween()
	custom_minimum_size.x = size.x
	_collapse_tween.tween_property(%ScrollPanel, 'bottom_margin', new_bottom_margin, 0.3)
	_collapse_tween.parallel().tween_property(%ScrollPanel, 'modulate:a', 0, 0.1).set_delay(0.2)
	_collapse_tween.parallel().tween_callback(_update_title)
	_collapse_tween.tween_callback(func() -> void: _collapsed = true)
	_collapse_tween.tween_callback((%CollapseButton as Control).hide)
	_collapse_tween.tween_callback((%ExpandButton as Control).show)
	_collapse_tween.tween_callback((%ScrollPanel as ScrollPanel).hide)
	_collapse_tween.tween_property(self, 'custom_minimum_size:x', 0, 0.2)
	_collapse_tween.play()
	await _collapse_tween.finished
	_collapse_tween = null

func _on_expand_button_pressed() -> void:
	if _collapse_tween:
		return
	assert(_collapsed)

	_collapse_tween = create_tween()
	_collapse_tween.tween_property(self, 'custom_minimum_size:x', _expanded_size, 0.2)
	_collapse_tween.tween_callback((%ScrollPanel as ScrollPanel).show)
	_collapse_tween.tween_property(%ScrollPanel, 'bottom_margin', _expanded_bottom_margin, 0.3)
	_collapse_tween.parallel().tween_property(%ScrollPanel, 'modulate:a', 1, 0.1).set_delay(0.2)
	_collapse_tween.parallel().tween_callback(_update_title)
	_collapse_tween.tween_callback(func() -> void: _collapsed = false)
	_collapse_tween.tween_callback((%CollapseButton as Control).show)
	_collapse_tween.tween_callback((%ExpandButton as Control).hide)
	_collapse_tween.tween_callback(func() -> void: custom_minimum_size.x = 0)
	_collapse_tween.play()
	await _collapse_tween.finished
	_collapse_tween = null

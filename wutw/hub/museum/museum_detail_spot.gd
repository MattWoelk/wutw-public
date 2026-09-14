@tool
class_name MuseumDetail_Spot
extends Control

const CONNECT_MARGIN: float = 10
static var SPOT_RECIPE_SCENE := AsyncLoadedResource.new('res://stage/spots/spot_recipe.tscn')
static var UNKNOWN_SPOT_RECIPE_SCENE := AsyncLoadedResource.new('res://stage/spots/spot_recipe_unknown.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var UPGRADE_TREE_CONNECTION_SCENE := AsyncLoadedResource.new('res://stage/spots/upgrade_tree_connection.tscn')

@export var capital_provision_skill: Skill
@export var spot_type: SpotType:
	set(value):
		if spot_type == value:
			return
		spot_type = value
		if is_node_ready():
			_recreate()

var _recipes: Array[SpotRecipe]

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_recreate()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainText as RichTextLabel, false, 18)
	Utils._scale_font_size(%UpgradeText as RichTextLabel, false, 18)

func _recreate() -> void:
	if not spot_type:
		return

	(%TitleLabel as Label).text = tr(spot_type.name)
	var description: String

	if Utils.is_in_editor() or spot_type.get_all_upgrades().any(GlobalSaveGame.has_seen_upgrade):
		(%UpgradesContainer as Control).visible = true
		description = tr('[i]“%s”[/i]') % tr(spot_type.description)

		# Upgrades
		# Based on the logic in Spot._layout_nodes().
		_recipes.clear()
		Utils.clear_node(%UpgradesList)
		for upgrade1 in spot_type.upgrades:
			var child_level1 := _create_recipe_node(upgrade1)
			var hbox1 := HBoxContainer.new()
			hbox1.add_child(child_level1)
			%UpgradesList.add_child(hbox1)
			for upgrade2 in upgrade1.child_upgrades:
				var child_level2 := _create_recipe_node(upgrade2)
				var hbox2 := HBoxContainer.new()
				var connector1 := UPGRADE_TREE_CONNECTION_SCENE.instantiate_loaded_scene() as Node
				hbox2.add_child(connector1)
				hbox2.add_child(child_level2)
				%UpgradesList.add_child(hbox2)
				var is_last_l2_child := upgrade1.child_upgrades.find(upgrade2) == upgrade1.child_upgrades.size() - 1
				if is_last_l2_child:
					(connector1.get_child(0) as TextureRect).texture = load('res://stage/spots/tree_connection_end.png')
				for upgrade3 in upgrade2.child_upgrades:
					var child_level3 := _create_recipe_node(upgrade3)
					var hbox3 := HBoxContainer.new()
					var connector21 := UPGRADE_TREE_CONNECTION_SCENE.instantiate_loaded_scene() as Node
					var connector22 := UPGRADE_TREE_CONNECTION_SCENE.instantiate_loaded_scene() as Node
					hbox3.add_child(connector21)
					hbox3.add_child(connector22)
					hbox3.add_child(child_level3)
					%UpgradesList.add_child(hbox3)
					if is_last_l2_child:
						(connector21.get_child(0) as TextureRect).texture = load('res://stage/spots/tree_connection_none.png')
					else:
						(connector21.get_child(0) as TextureRect).texture = load('res://stage/spots/tree_connection_outer.png')
					var is_last_l3_child := upgrade2.child_upgrades.find(upgrade3) == upgrade2.child_upgrades.size() - 1
					if is_last_l3_child:
						(connector22.get_child(0) as TextureRect).texture = load('res://stage/spots/tree_connection_end.png')
		if Utils.ensure(not _recipes.is_empty()):
			select_upgrade(_recipes[0].spot_upgrade)

		# Warning about upgrade availability.
		description += tr('\n\nOnly <term_lower:spot_upgrade>s that contribute to foray goals are guaranteed to be available.')

		# Capital provision
		if GlobalSaveGame.has_unlocked_skill(capital_provision_skill):
			description += tr('\n\nA <term_lower:capital> founded on this <term_lower:spot> will provide %s.') % spot_type.granted_capital_bonus.get_term_tag()

		# Hauntings
		if Utils.are_hauntings_unlocked():
			var haunting_types: Array[HauntingType]
			var seen_any_haunting := false
			for haunting_type in HauntingType.get_all_haunting_types():
				if haunting_type.spot_type == spot_type:
					haunting_types.append(haunting_type)
					if GlobalSaveGame.has_seen_haunting(haunting_type):
						seen_any_haunting = true
			if haunting_types:
				if seen_any_haunting:
					description += '\n\n'
					description += tr('This site can feature the following special <term_lower:haunting>s:')
					description += '[ul]'
					for haunting_type in haunting_types:
						description += '<haunting:%s>\n' % haunting_type.haunting_id
					description += '[/ul]'
				else:
					description += '\n\n'
					description += tr('This site can feature not yet discovered <term_lower:haunting>s.')

	else:
		select_upgrade(null)
		(%UpgradesContainer as Control).visible = false
		description = tr('Look for this <term_lower:spot> out there on the shards...')

	(%MainText as MarkedUpLabel).set_markedup_text(description + '\n ', MarkedUpLabel.LinkMode.LINK)

func _create_recipe_node(upgrade: SpotUpgrade) -> Control:
	if Utils.is_in_editor() or GlobalSaveGame.has_seen_upgrade(upgrade):
		var recipe := SPOT_RECIPE_SCENE.instantiate_loaded_scene() as SpotRecipe
		recipe.spot_upgrade = upgrade
		recipe.state = SpotRecipe.State.AVAILABLE
		recipe.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		recipe.tooltip_direction = [
			Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.LEFT, Tooltip.RelativeDirection.RIGHT]
		recipe.clicked.connect(select_upgrade.bind(upgrade))
		_recipes.append(recipe)
		return recipe
	else:
		return UNKNOWN_SPOT_RECIPE_SCENE.instantiate_loaded_scene() as Control

func select_upgrade(upgrade: SpotUpgrade) -> void:
	(%EventsText as MarkedUpLabel).visible = false
	if not upgrade:
		return

	(%SpotUpgradePreview as SpotUpgradePreview).spot_upgrade = upgrade
	(%UpgradeText as MarkedUpLabel).set_markedup_text(tr(upgrade.description))
	for recipe in _recipes:
		if recipe.spot_upgrade == upgrade:
			recipe.state = SpotRecipe.State.ACTIVE
		else:
			recipe.state = SpotRecipe.State.AVAILABLE

	# Events
	var applicable_events: Array[Event_Stage]
	for event: Event in Event.get_all_events().values():
		if Event.Category.SECRET in event.categories:
			continue
		var event_stage := event as Event_Stage
		if event_stage and event_stage.default_spot_upgrade == upgrade:
			applicable_events.append(event_stage)
	if applicable_events:
		applicable_events.sort_custom(func(a: Event, b: Event) -> bool:
			var a_seen := GlobalSaveGame.has_seen_event(a)
			var b_seen := GlobalSaveGame.has_seen_event(b)
			if a_seen != b_seen:
				return a_seen
			var a_generic := Event.Category.GENERIC in a.categories
			var b_generic := Event.Category.GENERIC in b.categories
			if a_generic != b_generic:
				return a_generic
			return a.event_id < b.event_id
		)
		var description := ''
		var num_undiscovered := 0
		for event in applicable_events:
			if GlobalSaveGame.has_seen_event(event):
				description += '<event:%s>\n' % event.event_id
			else:
				num_undiscovered += 1
		if num_undiscovered:
			description += tr_n('%d Undiscovered Event', '%d Undiscovered Events', num_undiscovered) % num_undiscovered
		(%EventsText as MarkedUpLabel).visible = true
		(%EventsText as MarkedUpLabel).set_markedup_text(
			description.strip_edges(), MarkedUpLabel.LinkMode.LINK)

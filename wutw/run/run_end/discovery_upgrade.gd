@tool
class_name Discovery_Upgdrade
extends PanelContainer

static var ASPECT_SLOT_SCENE := AsyncLoadedResource.new('res://aspects/slot/aspect_slot.tscn')
static var BONUS_COUNTER_SCENE := AsyncLoadedResource.new('res://bonuses/bonus_counter.tscn')

@export var spot_upgrade: SpotUpgrade:
	set(value):
		spot_upgrade = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.ABOVE, Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.LEFT],
			[Tooltip.Alignment.CENTERED])

func _gui_input(input_event: InputEvent) -> void:
	var mouse_event := input_event as InputEventMouseButton
	if not mouse_event:
		return
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if Utils.is_museum_unlocked():
			MuseumBrowser.open_museum_entry(spot_upgrade, UI.Layer.STATE_MENU_SUBMENU)

func _update() -> void:
	if not spot_upgrade:
		return
	(%TitleLabel as Label).text = tr(spot_upgrade.name)
	(%SpotUpgradePreview as SpotUpgradePreview).spot_upgrade = spot_upgrade

	Utils.clear_node(%AspectsList)
	var sorted_aspects := spot_upgrade.required_aspects.duplicate()
	sorted_aspects.sort_custom(AspectType.compare)
	for aspect_type: AspectType in sorted_aspects:
		var aspect_slot := ASPECT_SLOT_SCENE.instantiate_loaded_scene() as AspectSlot
		aspect_slot.aspect_type = aspect_type
		%AspectsList.add_child(aspect_slot)

	Utils.clear_node(%BonusesList)
	for bonus_type: BonusType in spot_upgrade.granted_bonuses:
		var bonus_counter := BONUS_COUNTER_SCENE.instantiate_loaded_scene() as BonusCounter
		bonus_counter.bonus_type = bonus_type
		bonus_counter.current_value = spot_upgrade.granted_bonuses[bonus_type]
		%BonusesList.add_child(bonus_counter)

func _make_tooltip_text() -> String:
	var pieces: Array[String]
	pieces.append('<related_term:spot_upgrade>')
	pieces.append('<related_term:spot>')
	pieces.append('<header_font_size>[b]%s[/b][/font_size]' % tr(spot_upgrade.name))
	if spot_upgrade.unique_per_run:
		pieces.append(tr(' (Unique)'))

	pieces.append('\n\n')
	pieces.append(tr('Requires: '))
	var sorted_aspects: Array[AspectType] = spot_upgrade.required_aspects.duplicate()
	sorted_aspects.sort_custom(AspectType.compare)
	for i in range(sorted_aspects.size()):
		if i > 0:
			pieces.append(', ')
		pieces.append(sorted_aspects[i].get_term_tag())

	pieces.append('\n')
	pieces.append(tr('Provides: '))
	var bonuses: Array[BonusType] = spot_upgrade.granted_bonuses.keys()
	for i in range(bonuses.size()):
		if i > 0:
			pieces.append(', ')
		pieces.append(bonuses[i].get_term_tag())

	if spot_upgrade.unique_per_run:
		pieces.append('\n\n')
		pieces.append(tr('[b]This <term_lower:spot_upgrade> can only be activated once per expedition.[/b]'))

	pieces.append('\n\n')
	pieces.append(tr('[i]“%s”[/i]') % tr(spot_upgrade.description))

	if Utils.is_museum_unlocked():
		pieces.append('\n\n')
		pieces.append(tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK))

	return ''.join(pieces)

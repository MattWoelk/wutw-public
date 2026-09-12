@tool
class_name HauntingTrigger_UpgradeActivated
extends HauntingTrigger

@export var any_spot: bool = true

func get_description(mode: HauntingTrigger.Mode) -> String:
	var recipe: String
	var container: String
	match mode:
		HauntingTrigger.Mode.SPOT:
			recipe = '<term_lower:spot_upgrade>'
			container = '<term_lower:spot>'
		HauntingTrigger.Mode.HARMONIZATION:
			recipe = '<term_lower:task>'
			container = '<term_lower:settlement>'
		HauntingTrigger.Mode.UNIVERSAL:
			recipe = tr('<term_lower:spot_upgrade> or <term_lower:task>')
			container = tr('<term_lower:spot> or <term_lower:settlement>')
		_:
			Utils.ensure(false)
			return ''

	if any_spot:
		return tr('a %s is activated in any %s') % [recipe, container]
	else:
		if mode == HauntingTrigger.Mode.UNIVERSAL:
			return tr('a %s is activated in the associated %s') % [recipe, container]
		else:
			return tr('a %s is activated in this %s') % [recipe, container]

func get_short_description(mode: HauntingTrigger.Mode) -> String:
	var text := ''
	match mode:
		HauntingTrigger.Mode.SPOT:
			text += '<term:spot_upgrade>'
		HauntingTrigger.Mode.HARMONIZATION:
			text += '<term:task>'
		HauntingTrigger.Mode.UNIVERSAL:
			text += tr('<term:spot_upgrade> or <term:task>')
			Utils.ensure(false)
			return ''
	if any_spot:
		return tr('%s Activated') % text
	else:
		return tr('%s Activated Here') % text

func setup(spot: Spot, settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.spot_recipe_activated.connect(
		_on_spot_recipe_activated.bind(spot))
	run.signals.harmonization_recipe_activated.connect(
		_on_harmonization_recipe_activated.bind(settlement))

func cleanup(spot: Spot, settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.spot_recipe_activated.disconnect(
		_on_spot_recipe_activated.bind(spot))
	run.signals.harmonization_recipe_activated.disconnect(
		_on_harmonization_recipe_activated.bind(settlement))

func _on_spot_recipe_activated(spot_recipe: SpotRecipe, spot: Spot) -> void:
	if any_spot or spot_recipe in spot.get_all_recipes():
		triggered.emit(null, null, null)

func _on_harmonization_recipe_activated(harmonization_recipe: HarmonizationRecipe, settlement: Settlement) -> void:
	if not harmonization_recipe.is_visible_in_tree():
		# HACK: safeguard for hidden double-lack recipes.
		return
	if any_spot or harmonization_recipe in settlement.get_recipes():
		triggered.emit(null, null, null)

class_name SettlerQuestGoal_AnyUpgrade
extends SettlerQuestGoal

@export var upgrades: Array[SpotUpgrade]

func start_listening(run: Run) -> void:
	run.signals.spot_recipe_activated.connect(_on_spot_recipe_activated)

func stop_listening(run: Run) -> void:
	run.signals.spot_recipe_activated.disconnect(_on_spot_recipe_activated)

func _on_spot_recipe_activated(spot_recipe: SpotRecipe) -> void:
	if spot_recipe.spot_upgrade in upgrades:
		achieved.emit()

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return upgrades

func describe() -> String:
	assert(upgrades)
	if upgrades.size() == 1:
		return tr('Establish the <spot_upgrade:%s> <term_lower:spot_upgrade>.') % upgrades[0].spot_upgrade_id
	else:
		return tr('Establish any of the following <term_lower:spot_upgrade>s:[ul]%s[/ul]') % '\n'.join(
			upgrades.map(func(u: SpotUpgrade) -> String: return '<spot_upgrade:%s>' % u.spot_upgrade_id))

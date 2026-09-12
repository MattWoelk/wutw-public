class_name SettlerQuestGoal_SettlementUpgrades
extends SettlerQuestGoal

@export var upgrades: Array[SpotUpgrade]

func start_listening(run: Run) -> void:
	run.signals.spot_recipe_activated.connect(_on_spot_recipe_activated)

func stop_listening(run: Run) -> void:
	run.signals.spot_recipe_activated.disconnect(_on_spot_recipe_activated)

func _on_spot_recipe_activated(_spot_recipe: SpotRecipe) -> void:
	var stage := Utils.get_active_run().get_current_stage()
	assert(stage)

	var required_counts: Dictionary[SpotUpgrade, int]
	for upgrade in upgrades:
		required_counts[upgrade] = required_counts.get(upgrade, 0) + 1

	for spot in stage.get_spots():
		for upgrade in spot.get_current_upgrades():
			if upgrade in required_counts:
				required_counts[upgrade] -= 1
				if required_counts[upgrade] <= 0:
					required_counts.erase(upgrade)
					if not required_counts:
						achieved.emit()
						return

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return upgrades

func describe() -> String:
	assert(upgrades)
	if upgrades.size() == 1:
		return tr('Establish the <spot_upgrade:%s> <term_lower:spot_upgrade>.') % upgrades[0].spot_upgrade_id
	else:
		var counts: Dictionary[SpotUpgrade, int]
		for upgrade in upgrades:
			counts[upgrade] = counts.get(upgrade, 0) + 1
		if counts.size() == 1:
			return tr('Establish %d <spot_upgrade:%s> <term_lower:spot_upgrade>s [b]in one <term_lower:settlement>[/b].') % [
				upgrades.size(), upgrades[0].spot_upgrade_id]
		else:
			var text := tr('Establish all of the following <term_lower:spot_upgrade>s [b]in one <term_lower:settlement>[/b]:')
			text += '[ul]'
			for upgrade in counts:
				text += '\n<spot_upgrade:%s>' % upgrade.spot_upgrade_id
			text += '[/ul]'
			return text

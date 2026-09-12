@tool
class_name Relic_Talisman
extends Relic

@export var spot_upgrade_tag: SpotUpgrade.Tag
@export var amount_healed: int = 1

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.spot_recipe_activated.connect(_on_spot_recipe_activated)

func on_removed() -> void:
	_run.signals.spot_recipe_activated.disconnect(_on_spot_recipe_activated)
	super.on_removed()

func _on_spot_recipe_activated(spot_recipe: SpotRecipe) -> void:
	if spot_upgrade_tag in spot_recipe.spot_upgrade.tags:
		_run.modify_inspiration(amount_healed, Run.InspirationChangeReason.RELIC)
		triggered.emit()

func get_description() -> String:
	return tr(default_description) % amount_healed

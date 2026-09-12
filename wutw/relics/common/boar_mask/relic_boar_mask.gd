@tool
class_name Relic_BoarMask
extends Relic

static var CARD_REWARD_SCENE := AsyncLoadedResource.new('res://stage/card_reward_choice.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var upgrade: SpotUpgrade

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.spot_recipe_activated.connect(_on_spot_recipe_activated)

func on_removed() -> void:
	_run.signals.spot_recipe_activated.disconnect(_on_spot_recipe_activated)
	super.on_removed()

func _on_spot_recipe_activated(spot_recipe: SpotRecipe) -> void:
	if spot_recipe.spot_upgrade == upgrade:
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			var count := _run.get_var(RunVars.Var.CARD_REWARD_CHOICES)
			var tier_weights := _run.get_current_card_reward_weights()
			var card_reward := CARD_REWARD_SCENE.instantiate_loaded_scene() as CardRewardChoice
			card_reward.specific_card_types = Utils.choose_card_rewards(_run, tier_weights, count, true, func(card_type: CardType) -> bool:
				return CardType.Tag.THEME_ANIMAL in card_type.tags)
			card_reward.allow_removal = false
			card_reward.card_added.connect(func(card_type: CardType) -> void:
				_run.get_current_stage().get_card_deck().add_card_to_hand(card_type, CardDeck.CardDrawReason.EVENT)
				card_reward.close()
			)
			card_reward.canceled.connect(func() -> void:
				card_reward.close()
			)
			GlobalUI.add_layer_content(card_reward, GlobalUI.choose_dynamic_menu_layer())
			await card_reward.selection_finished
		)

func get_description() -> String:
	return tr(default_description) % upgrade.spot_upgrade_id

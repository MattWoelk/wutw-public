@tool
class_name CardAbility_Lock
extends CardAbility

static var DIALOG_SCENE := AsyncLoadedResource.new('res://cards/abilities/lock_ability_dialog.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var is_random: bool = false

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	if is_random:
		return tr('Lock Random', 'ABILITY')
	else:
		return tr('Lock', 'ABILITY')

func get_ability_tooltip(_card: Card) -> String:
	if is_random:
		return tr('Lock a random <term_lower:spot> for the rest of the <term_lower:foray>, preventing any more slots from being filled.')
	else:
		return tr('Lock a selected <term_lower:spot>, preventing any more slots from being filled.')

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_lock.tres')

func cast(_card: Card) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.queue_action(func() -> void:
		if stage.mode == Stage.Mode.REGULAR:
			if is_random:
				var options: Array[Spot]
				for spot in stage.get_spots():
					if not spot.is_locked:
						options.append(spot)
				var spot_to_lock := run.get_card_deck_random().pick(options) as Spot
				if spot_to_lock:
					spot_to_lock.is_locked = true
			else:
				var dialog_scene := DIALOG_SCENE.instantiate_loaded_scene() as LockAbilityDialog
				GlobalUI.add_layer_content(dialog_scene, UI.Layer.GAME_MENU)
				await dialog_scene.closed
		else:
			GlobalUI.show_error(tr('No sites available to lock.'))
	)

func estimate_power(_card_type: CardType) -> int:
	return 10

func scales_when_looped() -> bool:
	return false

@tool
class_name HauntingEffect_LockSpot
extends HauntingEffect

# TODO: Support locking settlements during convergence.

func get_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('prevent any <term_lower:spot_upgrade> in this <term_lower:spot> from being activated')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('Lock <term:spot>')

func scales() -> bool:
	return false

func triggered(_related_gain: BonusGain, _related_slot: AspectSlot, _related_card: CardType) -> void:
	pass  # Handled in setup()

func setup(spot: Spot, _settlement: Settlement) -> void:
	if spot:
		spot.is_locked = true

func cleanup(spot: Spot, _settlement: Settlement) -> void:
	if spot:
		spot.is_locked = false

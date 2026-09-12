@tool
class_name HauntingEffect_LoseGainedBonus
extends HauntingEffect

@export var is_half: bool = false

func get_description(_mode: HauntingTrigger.Mode) -> String:
	if is_half:
		return tr('lose half of the gain')
	else:
		return tr('lose it')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	if is_half:
		return tr('Lose Half')
	else:
		return tr('Lose It')

func scales() -> bool:
	return false

func triggered(related_gain: BonusGain, _related_slot: AspectSlot, _related_card: CardType) -> void:
	# WARNING: This one has to be instant.
	assert(related_gain)  # Non-bonus triggers make no sense with this effect.
	if is_half:
		@warning_ignore('integer_division')
		related_gain.amount /= 2
	else:
		related_gain.amount = 0

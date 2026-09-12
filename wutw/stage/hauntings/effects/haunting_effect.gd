@abstract @tool
class_name HauntingEffect
extends Resource

@abstract func get_description(mode: HauntingTrigger.Mode) -> String
@abstract func get_short_description(mode: HauntingTrigger.Mode) -> String
@abstract func triggered(related_gain: BonusGain, related_slot: AspectSlot, related_card: CardType) -> void
@abstract func scales() -> bool

func setup(_spot: Spot, _settlement: Settlement) -> void:
	pass  # Subclasses can implement.

func cleanup(_spot: Spot, _settlement: Settlement) -> void:
	pass  # Subclasses can implement.

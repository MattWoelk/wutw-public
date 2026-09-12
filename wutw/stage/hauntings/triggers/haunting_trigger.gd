@abstract @tool
class_name HauntingTrigger
extends Resource

enum Mode { SPOT, HARMONIZATION, UNIVERSAL }  # Universal is e.g. museum.

@warning_ignore('unused_signal')  # Emitted by subclasses.
signal triggered(related_gain: Dictionary[BonusType, int], related_slot: AspectSlot, related_card: CardType)

@abstract func get_description(mode: Mode) -> String
@abstract func get_short_description(mode: Mode) -> String
@abstract func setup(spot: Spot, settlement: Settlement) -> void
@abstract func cleanup(spot: Spot, settlement: Settlement) -> void

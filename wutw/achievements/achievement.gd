@abstract
class_name Achievement
extends Resource

@warning_ignore('unused_signal')  # Emitted by subclasses.
signal achieved
@warning_ignore('unused_signal')  # Emitted by subclasses.
signal stat_changed(new_value: int)

@export var achievement_id: String
@export var stat_id: String
@export var handled_by_higher_tier: bool = false

@abstract func start_listening() -> void
@abstract func stop_listening() -> void
@abstract func check() -> void  # Explicit, to guaranteed unmissable.

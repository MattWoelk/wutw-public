@abstract
class_name CompanionRecipe
extends Recipe

@export var faded_out: bool = false:
	set(value):
		faded_out = value
		if is_node_ready():
			_update_state_style()

var _fadeout_tween: Tween

func _ready() -> void:
	super._ready()

func _enter_tree() -> void:
	UI.register_zoomable(self, 1, 1)

@abstract
func get_aspect_slots() -> Array[AspectSlot]

func set_faded_out(is_faded_out: bool) -> void:
	faded_out = is_faded_out

func is_available() -> bool:
	for slot in get_aspect_slots():
		if not slot.is_filled:
			return true
	return false

func _update_state_style() -> void:
	if _fadeout_tween:
		_fadeout_tween.kill()
	_fadeout_tween = create_tween()
	_fadeout_tween.tween_property(%PanelContainer, 'modulate:a', 0.4 if faded_out else 1.0, FADEOUT_ANIM_DURATION)
	_fadeout_tween.parallel().tween_property(%CanvasGroup, 'self_modulate:a', 0.4 if faded_out else 1.0, FADEOUT_ANIM_DURATION)
	_fadeout_tween.play()

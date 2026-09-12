@tool
class_name ErrorNotification
extends UkiyoePanelContainer

const BASE_DURATION := 0.5
const TIME_PER_CHAR := 0.07

@export var message: String:  # Already translated.
	set(value):
		message = value
		if is_node_ready():
			_update()

var _remaining_duration: float = 999
var _exiting := false

func _ready() -> void:
	super._ready()
	Utils._scale_font_size(%Label as RichTextLabel, true, 16)
	_remaining_duration = BASE_DURATION + TIME_PER_CHAR * message.length()
	_update()
	animate_enter()

func _process(delta: float) -> void:
	if not _exiting and not Utils.is_in_editor():
		_remaining_duration -= delta  # Inaccurate, but fine.
		if _remaining_duration <= 0.0:
			animate_exit()

func animate_enter() -> void:
	GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_FAULSE_ALERT)
	var tween := create_tween()
	modulate.a = 0
	tween.tween_property(self, 'modulate:a', 1.0, 0.25)
	tween.play()

func animate_exit() -> void:
	assert(not _exiting)
	_exiting = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, 'modulate:a', 0.0, 0.25)
	tween.tween_method(func(value: float) -> void:
		(%MarginContainer as MarginContainer).add_theme_constant_override('margin_bottom', roundi(value))
	, 2, -24, 0.15)
	tween.play()
	await tween.finished
	queue_free()

func animate_swap(new_message: String) -> void:
	assert(not _exiting)
	_remaining_duration = BASE_DURATION + TIME_PER_CHAR * message.length()
	var tween := create_tween()
	tween.tween_property(%Label, 'modulate:a', 0.0, 0.25)
	message = new_message
	tween.tween_property(%Label, 'modulate:a', 1.0, 0.25)
	tween.play()

func is_exiting() -> bool:
	return _exiting

func _update() -> void:
	(%Label as MarkedUpLabel).set_markedup_text(message)

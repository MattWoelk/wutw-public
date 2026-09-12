@tool
class_name PracticeInspirationDisplay
extends UkiyoePanelContainer

signal exhausted

const ANIM_DURATION := 0.5

enum ChangeType { SET, INCREASE, REDUCE }

var max_inspiration: int = 50:
	set(value):
		max_inspiration = value
		reset()
var damage_amount: int = 5

var _current_inspiration: int
var _current_tween: Tween

func _ready() -> void:
	super._ready()
	reset()

	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.BEGIN])

func reset() -> void:
	_current_inspiration = max_inspiration
	_update(ChangeType.SET)

func get_current_inspiration() -> int:
	return _current_inspiration

func damage() -> void:
	_current_inspiration = maxi(0, _current_inspiration - damage_amount)
	_update(ChangeType.REDUCE)
	if not _current_inspiration:
		exhausted.emit()

func heal(amount: int) -> void:
	_current_inspiration = maxi(max_inspiration, _current_inspiration + amount)
	_update(ChangeType.INCREASE)

func _update(change_type: ChangeType) -> void:
	var current_value := _current_inspiration
	var max_value := max_inspiration

	var anim_color: Color
	var duration := ANIM_DURATION
	match change_type:
		ChangeType.SET:
			anim_color = Color(1, 1, 1, 1)
			duration = 0
		ChangeType.INCREASE:
			anim_color = Color(0, 1.5, 0, 1)
		ChangeType.REDUCE:
			anim_color = Color(1.5, 0, 0, 1)

	if _current_tween:
		_current_tween.kill()  # Not ideal, but makes sure we end up at the right final number.
	_current_tween = create_tween()
	(%ProgressBar as UkiyoeProgressBar).self_modulate = anim_color
	_current_tween.tween_property(%ProgressBar, 'value', current_value, duration)
	_current_tween.parallel().tween_property(%ProgressBar, 'max_value', max_value, duration)
	_current_tween.tween_property(%ProgressBar, 'self_modulate', Color(1, 1, 1, 1), 0)
	_current_tween.set_trans(Tween.TRANS_LINEAR)
	_current_tween.set_ease(Tween.EASE_OUT)
	_current_tween.set_speed_scale(Utils.anim_speed())
	_current_tween.play()

func _make_tooltip_text() -> String:
	var text := tr('<header_font_size>[b]Inspiration[/b][/font_size]')
	text += '\n\n'
	text += tr('For each incorrect guess, you lose %d points.') % damage_amount
	text += tr(' If you finish all your glyphs before it runs out, you will receive 10% bonus <term:insight>s at the end.')
	return text

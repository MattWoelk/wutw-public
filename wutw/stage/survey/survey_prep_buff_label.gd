class_name SurveyPrepBuffLabel
extends Label

@export var related_button: SurveyPrepButton
@export var label: String
@export var percentage: bool = false

func _ready() -> void:
	assert(related_button)
	_update()
	related_button.pressed.connect(_update)

func _update() -> void:
	if related_button.get_times_used() == 0:
		visible = false
		return

	visible = true
	text = tr(label)

	text += ' '
	var value := related_button.get_times_used() * related_button.run_var_delta
	if value > 0:
		text += '+' + str(value)
	else:
		text += str(value)

	if percentage:
		text += '%'

	if related_button.max_uses > 1:
		text += ' (%d/%d)' % [related_button.get_times_used(), related_button.max_uses]

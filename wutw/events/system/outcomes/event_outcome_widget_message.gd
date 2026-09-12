class_name EventOutcomeWidget_Message
extends EventOutcomeWidget

signal starting

var text: String  # Already translated

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)

	starting.emit()

	var tween := create_tween()
	(%MarkedUpLabel as MarkedUpLabel).set_markedup_text('➤ ' + text + '\n')
	(%MarkedUpLabel as MarkedUpLabel).visible_ratio = 0
	var duration := Utils.anim_duration(DialogueDisplay.TIME_PER_CHAR * text.length())
	tween.tween_property(%MarkedUpLabel, 'visible_ratio', 1.0, duration)
	tween.play()
	await tween.finished

	finished.emit()

func _process(_delta: float) -> void:
	(%MarkedUpLabel as MarkedUpLabel).custom_maximum_size.x = minf((%MarkedUpLabel as MarkedUpLabel).custom_maximum_size.x, size.x)
	(%MarkedUpLabel as MarkedUpLabel).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _update_font_size() -> void:
	Utils._scale_font_size(%MarkedUpLabel as RichTextLabel, false, 16)
	if GameSettings.Interface.paragraph_font_scale.value() > 1.0:
		(%MarkedUpLabel as RichTextLabel).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

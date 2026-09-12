@tool
class_name RelicIcon
extends Control

@export var relic: Relic:
	set(value):
		# Could allow switching at runtime, but never needed yet.
		assert(Utils.is_in_editor() or not relic)
		relic = value
		if is_node_ready():
			_update()
@export var forced_size: int = 128:
	set(value):
		forced_size = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update()
	if relic and not Utils.is_in_editor():
		relic.state_changed.connect(_update_state)
		relic.counter_changed.connect(_update_state)
		relic.triggered.connect(_on_relic_triggered)
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.RIGHT],
			[Tooltip.Alignment.CENTERED, Tooltip.Alignment.BEGIN])
	mouse_entered.connect(func() -> void:
		GlobalAudioSystem.play(AK.EVENTS.UI_GENERIC_SELECT_WOOD_HEAVY)
	)

func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if not mouse_event or not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT and Utils.is_museum_unlocked():
		if GlobalSaveGame.has_seen_relic(relic):
			MuseumBrowser.open_museum_entry(relic, UI.Layer.STATE_MENU_SUBMENU)
		else:
			GlobalUI.show_error(tr('The <term_lower:relic> hasn\'t been seen before.'))

func _update() -> void:
	custom_minimum_size = Vector2(forced_size, forced_size)
	@warning_ignore('integer_division')
	pivot_offset = Vector2(forced_size / 2, 0)
	(%MarginContainer as Control).custom_minimum_size = custom_minimum_size
	if not relic:
		return
	(%Icon as TextureRect).texture = relic.icon
	_update_state()

func _update_state() -> void:
	var state := relic.get_state()
	match state:
		Relic.State.EXPIRED: self_modulate = Color(0.5, 0.5, 0.6, 1)
		Relic.State.PASSIVE: self_modulate = Color(0.75, 0.75, 0.8, 1)
		Relic.State.ACTIVE: self_modulate = Color(1, 1, 1, 1)

	if Utils.get_active_run():
		var current := relic.get_current_counter()
		var maximum := relic.get_max_counter()
		if current == 0 and maximum == 0:
			(%CounterLabel as Label).text = ''
		elif maximum == 0:
			(%CounterLabel as Label).text = '%d ' % current
		else:
			(%CounterLabel as Label).text = '%d/%d ' % [current, maximum]
	else:
		(%CounterLabel as Label).text = ''

func _on_relic_triggered() -> void:
	GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_RELIC_TRIGGER)
	(%AnimationPlayer as AnimationPlayer).play('trigger')

func _make_tooltip_text() -> String:
	if Utils.is_in_editor():
		return ''
	var text := ('<related_term:relic><header_font_size>[b]%s[/b][/font_size]\n\n%s' %
			[relic.get_relic_name(true), relic.get_markedup_description()])
	if Utils.is_museum_unlocked() and GlobalSaveGame.has_seen_relic(relic):
		text += '\n\n'
		text += tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)
	return text

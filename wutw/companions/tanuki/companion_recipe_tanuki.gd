class_name CompanionRecipe_Tanuki
extends CompanionRecipe

static var ASPECT_SLOT_SCENE := AsyncLoadedResource.new('res://aspects/slot/aspect_slot.tscn')

const MAX_SLOTS := 6
const BASE_AMOUNT := 10
const AMOUNT_PER_SEASON := 5

signal bonus_selected

@export var bonus_highlight_color := Color.WHITE

var _waiting_for_bonus := false

func _ready() -> void:
	super._ready()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.END], %TooltipAnchor as Control)

	for aspect_slot: AspectSlot in get_aspect_slots():
		aspect_slot.filled.connect(_on_slot_filled)

	for bonus: Bonus in %BonusesList.get_children():
		bonus.gui_input.connect(_on_bonus_gui_input.bind(bonus))
		bonus.mouse_entered.connect(_on_bonus_mouse_entered.bind(bonus))
		bonus.mouse_exited.connect(_on_bonus_mouse_exited.bind(bonus))

	(%AnimationPlayer as AnimationPlayer).queue('idle')

	(%ChoiceContainer as Control).visible = false

func get_aspect_slots() -> Array[AspectSlot]:
	var result: Array[AspectSlot]
	result.assign(%AspectsList.get_children())
	return result

func _add_slot() -> void:
	var aspect_slot := ASPECT_SLOT_SCENE.instantiate_loaded_scene() as AspectSlot
	aspect_slot.is_universal = true
	aspect_slot.filled.connect(_on_slot_filled)
	%AspectsList.add_child(aspect_slot)

func _make_tooltip_text() -> String:
	var amount := BASE_AMOUNT + AMOUNT_PER_SEASON * Utils.get_active_run().get_current_season_index()
	var description := tr('Gain %d points of a <term:bonus> of your choice.') % amount
	var companion_resource := _get_companion()
	return (tr('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s') %
			[tr(companion_resource.companion_name), description])

func _on_slot_filled() -> void:
	for slot in get_aspect_slots():
		if not slot.is_filled:
			return

	_on_all_slots_filled()

func _on_bonus_gui_input(event: InputEvent, bonus: Bonus) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		_on_bonus_selected(bonus.bonus_type)

func _on_bonus_mouse_entered(bonus: Bonus) -> void:
	bonus.modulate = bonus_highlight_color

func _on_bonus_mouse_exited(bonus: Bonus) -> void:
	bonus.modulate = Color.WHITE

func _on_all_slots_filled() -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.queue_action(func() -> void:
		run.signals.companion_ability_started.emit(_get_companion())
		if (%AnimationPlayer as AnimationPlayer).current_animation != 'react':
			(%AnimationPlayer as AnimationPlayer).play('react', -1, Utils.anim_speed())
			(%AnimationPlayer as AnimationPlayer).queue('idle')
			GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_TANUKI)
		faded_out = false
		_waiting_for_bonus = true
		(%ChoiceContainer as Control).visible = true
		await bonus_selected
		run.signals.companion_ability_finished.emit(_get_companion())
	)

func _update_state_style() -> void:
	if not _waiting_for_bonus:
		super._update_state_style()

func _on_bonus_selected(bonus_type: BonusType) -> void:
	var run := Utils.get_active_run()
	var amount := BASE_AMOUNT + AMOUNT_PER_SEASON * run.get_current_season_index()
	run.gain_bonus(BonusGain.new(bonus_type, amount, self))
	(%ChoiceContainer as Control).visible = false

	var slots := get_aspect_slots()
	if slots.size() < MAX_SLOTS:
		# Make reusable.
		for aspect_slot: AspectSlot in slots:
			aspect_slot.animate_clear()
		# Increase cost.
		_add_slot()

	bonus_selected.emit()

func _get_companion() -> Companion:
	return load('res://companions/tanuki/companion_tanuki.tres') as Companion

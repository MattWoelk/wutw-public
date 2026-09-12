@tool
class_name Haunting_Spot
extends HauntingBase

static var ASPECT_SLOT_SCENE := AsyncLoadedResource.new('res://aspects/slot/aspect_slot.tscn')

const TRIGGER_ANIM_DURATION := 1.0

@export var attached_to_spot: Spot:
	set(value):
		attached_to_spot = value
		if is_node_ready():
			(%AttachmentContainer as Control).visible = attached_to_spot != null

var _fadeout_tween: Tween
var _trigger_tween: Tween

func _ready() -> void:
	super._ready()

	(%AttachmentContainer as Control).visible = attached_to_spot != null
	(%ScrollPanel as ScrollPanel).animate_unroll()
	if not Utils.is_in_editor():
		(%NewIcon as Control).visible = not GlobalSaveGame.has_seen_haunting(haunting_type)

	var run := Utils.get_active_run()
	if run:
		run.signals.haunting_pacified.connect(_update_pacify_button.unbind(1))

	await get_tree().process_frame
	pivot_offset.x = size.x / 2 # For the trigger animation.

func _enter_tree() -> void:
	UI.register_zoomable(self, -1, 0.0)

func get_spot() -> Spot:
	return attached_to_spot

func get_settlement() -> Settlement:
	return Utils.get_active_run().get_current_stage().settlement

func _recreate() -> void:
	if not haunting_type:
		return

	if Utils.is_realistic_era():
		(%TitleLabel as Label).text = tr(haunting_type.name_realistic)
		(%BG as TextureRect).texture = haunting_type.image_small_realistic
		(%CreditsIcon as CreditsIcon).art_piece = haunting_type.image_realistic_credit
	else:
		(%TitleLabel as Label).text = haunting_type.get_localized_name()
		(%BG as TextureRect).texture = haunting_type.image_small
		(%CreditsIcon as CreditsIcon).art_piece = haunting_type.image_credit
	(%EffectLabel as MarkedUpLabel).set_markedup_text('%s\n[b]↓[/b]\n%s' % [
		_haunting_trigger.get_short_description(HauntingTrigger.Mode.SPOT),
		_haunting_effect.get_short_description(HauntingTrigger.Mode.SPOT)])

	Utils.clear_node(%AspectsList)
	var run := Utils.get_active_run()
	var aspect_types := haunting_type.get_toal_aspect_slots(run, HauntingTrigger.Mode.SPOT)
	for aspect_type in aspect_types:
		var aspect_slot := ASPECT_SLOT_SCENE.instantiate_loaded_scene() as AspectSlot
		aspect_slot.aspect_type = aspect_type
		aspect_slot.detach_glow_on_anim = true
		aspect_slot.filled.connect(_on_aspect_filled)
		%AspectsList.add_child(aspect_slot)

	_update_pacify_button()

	await get_tree().process_frame  # Wait for label size to update.
	(%MainVBox as Control).custom_minimum_size.x = (%TitleLabel as Label).size.x - 30

func _get_mode() -> HauntingTrigger.Mode:
	return HauntingTrigger.Mode.SPOT

func _update_pacify_button() -> void:
	var run := Utils.get_active_run()
	if run:  # Could be in editor.
		var verb := tr('Mitigate') if Utils.is_realistic_era() else tr('Pacify')
		var pacifies_left := run.get_var(RunVars.Var.HAUNTING_PACIFIES)
		if pacifies_left == 0:
			(%PacifyButton as Button).visible = false
		elif pacifies_left == 1:
			(%PacifyButton as Button).text = verb
			(%PacifyButton as Button).visible = true
		else:
			(%PacifyButton as Button).text = '%s (%d)' % [verb, pacifies_left]
			(%PacifyButton as Button).visible = true

func _play_trigger_animation() -> void:
	if not _is_setup:  # Pacified by the time it's called.
		return
	var stage := Utils.get_active_run().get_current_stage()
	await stage.ensure_slot_visible(get_aspect_slots()[0])
	if _trigger_tween:
		_trigger_tween.kill()
	_trigger_tween = create_tween()
	GlobalAudioSystem.play(AK.EVENTS.UI_GENERIC_SELECT_TAIKO_LOW)
	_trigger_tween.tween_property(self, 'scale', Vector2(1.1, 1.1), TRIGGER_ANIM_DURATION / 2)
	_trigger_tween.tween_property(self, 'scale', Vector2(1.0, 1.0), TRIGGER_ANIM_DURATION / 2)
	_trigger_tween.set_speed_scale(Utils.anim_speed())
	_trigger_tween.play()
	await _trigger_tween.finished

func set_faded_out(is_faded_out: bool) -> void:
	if _fadeout_tween:
		_fadeout_tween.kill()
	_fadeout_tween = create_tween()
	_fadeout_tween.tween_property(%AspectsList, 'modulate:a', 0.35 if is_faded_out else 1.0, FADEOUT_ANIM_DURATION)
	_fadeout_tween.play()

func _close(duration: float = 1.0) -> void:
	Utils.set_input_enabled(self, false)
	var tween := create_tween()
	tween.tween_property(%AttachmentContainer, 'modulate:a', 0.0, 0.1)
	tween.tween_callback((%ScrollPanel as ScrollPanel).animate_roll.bind(Utils.anim_duration(duration)))
	tween.tween_interval((%ScrollPanel as ScrollPanel).default_roll_duration * duration)
	tween.tween_property(self, 'modulate:a', 0.0, 0.1)
	var width := floori((%ScrollPanel as ScrollPanel).size.x)
	tween.tween_method(func(value: int) -> void:
		(%CollapseMargin as MarginContainer).add_theme_constant_override('margin_left', value)
	, 0, -width, 0.2)
	tween.set_speed_scale(Utils.anim_speed() / duration)
	tween.play()
	await tween.finished
	queue_free()

func get_aspect_slots() -> Array[AspectSlot]:
	var aspect_slots: Array[AspectSlot]
	for aspect_slot in %AspectsList.get_children():
		aspect_slots.append(aspect_slot as AspectSlot)
	return aspect_slots

func _on_pacify_button_pressed() -> void:
	_pacify_manually()

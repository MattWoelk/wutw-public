class_name RunBonusListing
extends Control

static var BONUS_COUNTER_SCENE := AsyncLoadedResource.new('res://bonuses/bonus_counter.tscn')

const COLOR_POSITIVE := Color(0.573, 0.949, 0.22, 0.761)
const COLOR_NEGATIVE := Color(0.949, 0.22, 0.22, 0.761)

func _ready() -> void:
	await get_tree().process_frame  # Make sure the run is ready.

	var run := Utils.get_active_run()
	run.get_bonus_amounts().changed.connect(_update_run_listing)
	run.get_vars().modified.connect(func(_type: RunVars.Var, _old_value: int, _new_value: int) -> void:
		_update_run_listing()
	)
	run.signals.bonus_gained.connect(_on_bonus_changed)
	run.signals.bonus_lost.connect(_on_bonus_lost)
	_update_run_listing()

func _enter_tree() -> void:
	UI.register_zoomable(self, 1, 0)

func _update_run_listing() -> void:
	var run := Utils.get_active_run()
	for node in %BasicBonuses.get_children() + %AdvancedBonuses.get_children():
		var listing := node as BonusCounter
		listing.current_value = run.get_bonus_amounts().get_amount(listing.bonus_type)
		if run.get_var(listing.bonus_type.focus_var) > 0:
			(listing.get_node('%Bonus') as Bonus).highlight_type = Bonus.HighlightType.POSITIVE
			_get_vfx(listing).emitting = true
			_get_vfx(listing).modulate = COLOR_POSITIVE
		elif run.get_var(listing.bonus_type.focus_var) < 0:
			(listing.get_node('%Bonus') as Bonus).highlight_type = Bonus.HighlightType.NEGATIVE
			_get_vfx(listing).emitting = true
			_get_vfx(listing).modulate = COLOR_NEGATIVE
		else:
			(listing.get_node('%Bonus') as Bonus).highlight_type = Bonus.HighlightType.NONE
			_get_vfx(listing).emitting = false

func _on_bonus_lost(bonus_type: BonusType, amount: int, reason: BonusGain.Reason) -> void:
	_on_bonus_changed(bonus_type, -amount, reason)

func _on_bonus_changed(bonus_type: BonusType, amount: int, _reason: BonusGain.Reason) -> void:
	var existing_count := %ChangePivot.get_child_count()

	var listing := BONUS_COUNTER_SCENE.instantiate_loaded_scene() as BonusCounter
	listing.bonus_type = bonus_type
	listing.current_value = amount
	listing.label_first = true
	listing.display_as_delta = true
	listing.highlight_type = Bonus.HighlightType.POSITIVE if amount > 0 else Bonus.HighlightType.NEGATIVE
	%ChangePivot.add_child(listing)

	const COLUMNS := 3
	const X_MARGIN := 20
	const WIDTH := 80
	const HEIGHT := 30
	const END_Y := -HEIGHT

	var start_x := X_MARGIN + (existing_count % COLUMNS) * WIDTH
	@warning_ignore('integer_division')
	var start_y := (existing_count / COLUMNS) * HEIGHT
	var duration := (float(start_y - END_Y) / HEIGHT) * 0.5

	listing.position.x = start_x
	listing.position.y = start_y
	listing.modulate = Color.TRANSPARENT
	var tween := create_tween()
	tween.tween_property(listing, 'modulate', Color.WHITE, 0.2)
	tween.tween_interval(2)
	tween.tween_property(listing, 'position:y', END_Y, duration)
	tween.tween_callback(func() -> void: %ChangePivot.remove_child(listing))
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN)
	tween.play()

func _get_vfx(counter: BonusCounter) -> GPUParticles2D:
	for child in counter.get_children():
		if child.owner == self and child is GPUParticles2D:
			return child as GPUParticles2D
	Utils.ensure(false)
	return null

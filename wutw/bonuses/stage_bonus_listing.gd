class_name StageBonusListing
extends Control

func _ready() -> void:
	visible = false
	await get_tree().process_frame  # Make sure the run is ready.
	var run := Utils.get_active_run()
	run.state_changed.connect(_update_listing)
	run.get_bonus_amounts().changed.connect(_update_listing)
	run.get_vars().modified.connect(_update_listing.unbind(3))
	GlobalGameSettings.changed.connect(_update_listing)
	_update_listing()

func _enter_tree() -> void:
	UI.register_zoomable(self, 0.5, 0)

func _update_listing() -> void:
	var run := Utils.get_active_run()
	if not run:
		return
	var stage := run.get_current_stage()
	visible = stage and GameSettings.Interface.show_stage_bonuses.value()
	if not visible:
		return

	var bonus_amounts := stage.get_stage_bonus_amounts()
	if not bonus_amounts.changed.is_connected(_update_listing):
		bonus_amounts.changed.connect(_update_listing)

	for node in get_children():
		var listing := node as BonusCounter
		listing.current_value = bonus_amounts.get_amount(listing.bonus_type)
		if run.get_var(listing.bonus_type.focus_var) > 0:
			(listing.get_node('%Bonus') as Bonus).highlight_type = Bonus.HighlightType.POSITIVE
			_get_vfx(listing).emitting = true
			_get_vfx(listing).modulate = RunBonusListing.COLOR_POSITIVE
		elif run.get_var(listing.bonus_type.focus_var) < 0:
			(listing.get_node('%Bonus') as Bonus).highlight_type = Bonus.HighlightType.NEGATIVE
			_get_vfx(listing).emitting = true
			_get_vfx(listing).modulate = RunBonusListing.COLOR_NEGATIVE
		else:
			(listing.get_node('%Bonus') as Bonus).highlight_type = Bonus.HighlightType.NONE
			_get_vfx(listing).emitting = false

func _get_vfx(counter: BonusCounter) -> GPUParticles2D:
	for child in counter.get_children():
		if child.owner == self and child is GPUParticles2D:
			return child as GPUParticles2D
	Utils.ensure(false)
	return null

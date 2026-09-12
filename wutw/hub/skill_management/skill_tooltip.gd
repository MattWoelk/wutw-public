@tool
class_name SkillTooltip
extends Tooltip

signal close_requested

var skill: Skill
var interactive: bool = false:
	set(value):
		interactive = value
		if is_node_ready():
			if interactive:
				_setup_interactive()
			else:
				_setup_static()

func _ready() -> void:
	super._ready()
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	if skill.is_revealed():
		(%NameLabel as Label).text = skill.get_effective_skill_name()
		interactive = interactive  # Trigger setter.
	else:
		(%NameLabel as Label).text = tr('???')
		(%RequirementUnfulfilledLabel as Control).visible = false
		(%InteractiveControls as Control).visible = false
		Utils.ensure(not interactive)
	(%NameLabel as Label).visible = true
	GlobalTooltipSystem.attach(%InsightsPanel as Control,
			func() -> String: return tr('<term:insight>s required to unlock this skill.'),
			[Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.ABOVE],
			[Tooltip.Alignment.CENTERED])

func _update_font_size() -> void:
	Utils._scale_font_size(%MarkedUpLabel as RichTextLabel, true, 16)

func _clear_extras() -> void:
	# No extras to setup, so skip parent's method.
	pass

func _ensure_extras_created() -> void:
	# No extras to setup, so skip parent's method.
	pass

func _place_extras(_direction: RelativeDirection) -> void:
	# No extras to setup, so skip parent's method.
	pass

func _get_link_mode() -> MarkedUpLabel.LinkMode:
	_in_detailed_mode = Input.is_key_pressed(KEY_CTRL)
	if _in_detailed_mode:
		return MarkedUpLabel.LinkMode.EXPAND
	elif interactive:
		return MarkedUpLabel.LinkMode.LINK
	else:
		return MarkedUpLabel.LinkMode.HINT

func _setup_interactive() -> void:
	Utils.ensure(skill.requirement != null)

	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED
	(%InteractiveControls as Control).visible = true

	# Make sure text uses links.
	(%MarkedUpLabel as MarkedUpLabel).set_markedup_text(_markedup_text, _get_link_mode())

	if GlobalSaveGame.has_unlocked_skill(skill):
		(%InsightsPanel as Control).visible = false
		(%UnlockButton as Control).visible = false
		(%RequirementUnfulfilledLabel as Control).visible = false
	else:
		var unlockable := true
		if not GlobalSaveGame.has_unlocked_skill(skill.requirement):
			unlockable = false
			(%RequirementUnfulfilledLabel as Label).text = tr('Requires %s to be unlocked.') % skill.requirement.get_effective_skill_name()
			(%RequirementUnfulfilledLabel as Label).visible = true
			(%InsightsPanel as Control).visible = false
			(%UnlockButton as Control).visible = false
		else:
			(%InsightsRequired as Label).text = '%d / %d' % [GlobalSaveGame.insights, skill.unlock_cost]
			(%RequirementUnfulfilledLabel as Control).visible = false
			if GlobalSaveGame.insights < skill.unlock_cost:
				unlockable = false
				(%InsightsPanel as Control).visible = true
				(%UnlockButton as Control).visible = true
				(%InsightsRequired as Label).add_theme_color_override('font_color', Color.DARK_RED)
		(%UnlockButton as Button).disabled = not unlockable

func _setup_static() -> void:
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	(%InteractiveControls as Control).visible = false

	if skill.requirement and not GlobalSaveGame.has_unlocked_skill(skill.requirement):
		Utils.ensure(not GlobalSaveGame.has_unlocked_skill(skill))
		(%RequirementUnfulfilledLabel as Label).text = tr('Requires %s to be unlocked.') % skill.requirement.get_effective_skill_name()
		(%RequirementUnfulfilledLabel as Label).visible = true
	else:
		(%RequirementUnfulfilledLabel as Label).visible = false

func _on_unlock_button_pressed() -> void:
	assert(not GlobalSaveGame.has_unlocked_skill(skill))
	assert(GlobalSaveGame.insights >= skill.unlock_cost)
	GlobalAudioSystem.play(AK.EVENTS.UI_GENERIC_SELECT_TAIKO_LOW)
	GlobalSaveGame.unlock_skill(skill)
	GlobalSaveGame.insights -= skill.unlock_cost
	GlobalSaveGame.save_game()
	close_requested.emit()

func _on_cancel_button_pressed() -> void:
	close_requested.emit()

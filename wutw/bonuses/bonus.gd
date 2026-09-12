@tool
class_name Bonus
extends Control

enum HighlightType { NONE, POSITIVE, NEGATIVE }

@export var bonus_type: BonusType:
	set(value):
		bonus_type = value
		if is_node_ready():
			_update()
@export var highlight_type: HighlightType = HighlightType.NONE:
	set(value):
		highlight_type = value
		if is_node_ready():
			_update()
@export var custom_tooltip_control: Control = null:
	set(value):
		if custom_tooltip_control != value:
			if custom_tooltip_control and GlobalTooltipSystem.has_attached_tooltip(custom_tooltip_control):
				GlobalTooltipSystem.detach(custom_tooltip_control)
			custom_tooltip_control = value
			if is_node_ready():
				_attach_tooltip()
@export var enable_animation: bool = false:
	set(value):
		enable_animation = value
		if is_node_ready():
			_update()

func _ready() -> void:
	var icon_material := ShaderMaterial.new()
	icon_material.shader = load('res://bonuses/bonus.gdshader')
	(%Texture as TextureRect).material = icon_material
	_update()
	_attach_tooltip()
	GlobalTooltipSystem.pre_tooltip_shown.connect(func(control: Control, tooltip: Tooltip) -> void:
		if control == custom_tooltip_control:
			tooltip.max_width = 1000
			tooltip.set_markedup_text(_make_tooltip_text(tooltip._in_detailed_mode))
			tooltip.avoid_top_bar = false
	)

func _get_minimum_size() -> Vector2:
	return Vector2(24, 24)

func _attach_tooltip() -> void:
	var control := custom_tooltip_control if custom_tooltip_control else self
	GlobalTooltipSystem.attach(control, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT, Tooltip.RelativeDirection.BELOW],
			[Tooltip.Alignment.BEGIN])

func _update() -> void:
	if not bonus_type:
		return
	var icon_material := (%Texture as TextureRect).material as ShaderMaterial
	icon_material.set_shader_parameter('base_tex', bonus_type.icon)
	icon_material.set_shader_parameter('glow_tex', bonus_type.glow_icon)
	icon_material.set_shader_parameter('enable_outline', highlight_type != HighlightType.NONE)
	icon_material.set_shader_parameter('is_negative', highlight_type == HighlightType.NEGATIVE)
	icon_material.set_shader_parameter('animation_speed', 2.5 if enable_animation else 0.0)

func _make_tooltip_text(expanded: bool = false) -> String:
	if Utils.is_in_editor():
		return ''
	var text := ('<related_term:bonus><header_font_size>[b]%s[/b][/font_size]' %
				 bonus_type.get_term_name(true))

	text += '\n' + tr(bonus_type.description)

	if not expanded:
		return text

	# Could check for the actual shop skill, but showing it anyway can point the player towards
	# the skill in the first place.
	if GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P200_STARTED_MAGIC:
		text += '\n\n' + tr(bonus_type.shop_hint)

	var run := Utils.get_active_run()
	if run:
		if bonus_type in run.get_unlocked_capital_bonuses():
			if run.get_current_season_index() > 0:
				text += tr('\n\nThis <term_lower:bonus> is currently provided by the <term:capital>.')
		elif Skill.get_skill_var(Skill.Var.CAPITAL_ACTIVATE_PROVISIONS):
			var required := ((1 + run.get_current_season_index()) * run.scaling.stages_per_season *
							 run.scaling.capital_bonus_req_per_settlement)
			text += '\n\n'
			if run.get_current_season_index() > 0:
				text += tr('This <term_lower:bonus> is NOT currently provided by the <term:capital>.')
				text += tr(' You will need [b]%d[/b] points to be able to provide it.') % required
			else:
				text += tr('You will need [b]%d[/b] points of this <term_lower:bonus> to be able to provide it at the <term:capital>.') % required

		if run.get_var(bonus_type.focus_var) > 0:
			text += tr('\n\n[b]%s is currently %s, so all gains of it are doubled.[/b]') % [
				bonus_type.get_term_tag(), tr('supported', 'YIELD_STATE') if Utils.is_realistic_era() else tr('blessed', 'YIELD_STATE')]
		elif run.get_var(bonus_type.focus_var) < 0:
			text += tr('\n\n[b]%s is currently %s, so all gains of it are halved.[/b]') % [
				bonus_type.get_term_tag(), tr('neglected', 'YIELD_STATE') if Utils.is_realistic_era() else tr('cursed', 'YIELD_STATE')]

		var loss_per_negative := maxi(0, run.get_var(RunVars.Var.INSPIRATION_LOST_PER_NEGATIVE_BONUS))
		if loss_per_negative > 0 and run.get_bonus_amounts().get_amount(bonus_type) < 0:
			text += tr('\n\n[b]The shard currently has a global shortage of %s, which will result in the loss of %d <term:inspiration> per <term_lower:foray>.[/b]') % [
				bonus_type.get_term_tag(), loss_per_negative]

	text += '\n\n' + tr('“%s”') % tr(bonus_type.flavor)

	return text

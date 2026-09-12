@tool
class_name SkillManagement
extends Node2D

signal closed

static var SKILL_TOOLTIP_SCENE := AsyncLoadedResource.new('res://hub/skill_management/skill_tooltip.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

var _closing := false
var _hovered_node: SkillNode
var _pinned := false
var _tooltip: SkillTooltip

@export_group('Debug')
@export_range(100, 510, 5, 'prefer_slider')
var debug_main_quest_state: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.P510_FINISHED_OUTRO_CUTSCENE:
	set(value):
		if not Utils.is_in_editor():
			return
		debug_main_quest_state = value
		if is_node_ready():
			for tree in %TreesList.get_children():
				for child in tree.get_children():
					if child is SkillNode:
						(child as SkillNode).debug_main_quest_state = debug_main_quest_state

func _ready() -> void:
	if Utils.is_in_editor():
		return

	for tree in %TreesList.get_children():
		for child in tree.get_children():
			if child is SkillNode:
				var skill_node := child as SkillNode
				if not skill_node.skill:
					continue
				skill_node.hovered.connect(_on_skill_hovered.bind(skill_node))
				skill_node.unhovered.connect(_on_skill_unhovered.bind(skill_node))
				if skill_node.skill.is_revealed():
					skill_node.clicked.connect(_on_skill_clicked.bind(skill_node))
					if not GlobalSaveGame.has_seen_skill(skill_node.skill):
						skill_node.is_new = true
						GlobalSaveGame.mark_skill_seen(skill_node.skill)

	(%ScrollPanel as ScrollPanel).animate_unroll()

func _handle_esc() -> bool:
	_close()
	return true

func _on_skill_hovered(skill_node: SkillNode) -> void:
	if _pinned:
		return
	assert(not _tooltip)
	assert(skill_node.skill)
	GlobalAudioSystem.play(AK.EVENTS.UI_MENU_HUB_SKILL_HOVER)
	_hovered_node = skill_node
	_tooltip = SkillTooltip.create(
			skill_node, '',
			[Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.LEFT],
			[Tooltip.Alignment.CENTERED],
			null, SKILL_TOOLTIP_SCENE.get_loaded_scene())
	_tooltip.z_index = Utils.get_absolute_z_index(self) + UI.LAYER_SPACING
	_tooltip.skill = skill_node.skill
	_tooltip.margin = 5
	_tooltip.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	if skill_node.skill.is_revealed():
		_tooltip._markedup_text = skill_node.skill.get_effective_description()
		if skill_node.is_new:
			_tooltip._markedup_text += '\n\n' + tr('This is a newly revealed skill!')
	elif skill_node.skill.revealed_manually:
		_tooltip._markedup_text = tr('This skill can be revealed by sending the Explorer to a shard with a specific culture.')
	else:
		_tooltip._markedup_text = tr('This skill will be revealed as the story continues.')
	_tooltip.show_tooltip()

func _on_skill_unhovered(skill_node: SkillNode) -> void:
	if _tooltip and not _pinned:
		Utils.ensure(_hovered_node == skill_node)
		var removed_tooltip := _tooltip
		_tooltip = null
		await removed_tooltip.hide_tooltip()
		removed_tooltip.destroy()

func _on_skill_clicked(skill_node: SkillNode) -> void:
	assert(_tooltip)

	if not skill_node.skill.requirement:
		return

	if _hovered_node != skill_node:
		Utils.ensure(_pinned)
		_pinned = false
		_hovered_node.is_selected = false
		_on_skill_unhovered(_hovered_node)
		_on_skill_hovered(skill_node)
	_pinned = true
	skill_node.is_selected = true
	_tooltip.interactive = true
	_tooltip.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
	_tooltip.close_requested.connect(func() -> void:
		_pinned = false
		skill_node.is_selected = false
		if _tooltip:
			_tooltip.hide_tooltip()
			_tooltip = null
	)

func _on_return_button_pressed() -> void:
	_close()

func _close() -> void:
	if not _closing:
		_closing = true
		if _tooltip:
			_tooltip.hide_tooltip()
			_tooltip = null
		Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		closed.emit()
		queue_free()

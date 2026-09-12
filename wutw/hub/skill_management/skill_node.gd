@tool
class_name SkillNode
extends Control

signal clicked
signal hovered
signal unhovered

enum State { UNKNOWN, UNAVAILABLE, AVAILABLE, UNLOCKED, EMPTY }

@export var up: bool:
	set(value):
		up = value
		_update()
@export var down: bool:
	set(value):
		down = value
		_update()
@export var left: bool:
	set(value):
		left = value
		_update()
@export var right: bool:
	set(value):
		right = value
		_update()
@export var up_left: bool:
	set(value):
		up_left = value
		_update()
@export var up_right: bool:
	set(value):
		up_right = value
		_update()
@export var down_left: bool:
	set(value):
		down_left = value
		_update()
@export var down_right: bool:
	set(value):
		down_right = value
		_update()

@export var skill: Skill:
	set(value):
		skill = value
		_update()
@export var is_new := false:
	set(value):
		is_new = value
		_update()
@export var is_selected := false:
	set(value):
		is_selected = value
		_update_shader()

@export_group('Config')
@export var unknown_texture: Texture2D
@export var placeholder_texture: Texture2D

@export_group('Debug')
@export_range(100, 510, 5, 'prefer_slider')
var debug_main_quest_state: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.P510_FINISHED_OUTRO_CUTSCENE:
	set(value):
		if not Utils.is_in_editor():
			return
		debug_main_quest_state = value
		_update()

var _state := State.UNKNOWN
var _is_hovered := false

func _ready() -> void:
	_update()

func _update() -> void:
	if not is_node_ready():
		return

	(%Label as Control).visible = skill != null

	_state = State.EMPTY
	if skill:
		_state = State.AVAILABLE
		if not Utils.is_in_editor() and not GlobalSaveGame.changed.is_connected(_update):
			GlobalSaveGame.changed.connect(_update)
		if _is_revealed():
			if _is_unlocked(skill):
				_state = State.UNLOCKED
			else:
				if skill.requirement and not _is_unlocked(skill.requirement):
					_state = State.UNAVAILABLE
				elif not _is_unlockable():
					_state = State.UNAVAILABLE
				else:
					_state = State.AVAILABLE
		else:
			_state = State.UNKNOWN

		if _state == State.UNKNOWN:
			(%Icon as TextureRect).texture = unknown_texture
		elif skill.icon:
			(%Icon as TextureRect).texture = skill.icon
		else:
			(%Icon as TextureRect).texture = placeholder_texture

		if skill.unlock_cost and _state in [State.AVAILABLE, State.UNAVAILABLE]:
			(%Label as Label).text = str(skill.unlock_cost)
		else:
			(%Label as Label).text = ''

	_update_shader()

func _is_revealed() -> bool:
	if Utils.is_in_editor():
		if skill.revealed_manually:
			return debug_main_quest_state >= SaveGame.MainQuestProgress.P510_FINISHED_OUTRO_CUTSCENE
		else:
			return debug_main_quest_state >= skill.min_main_quest_progress
	else:
		if skill.revealed_manually:
			return GlobalSaveGame.has_revealed_skill(skill)
		else:
			return GlobalSaveGame.get_main_quest_progress() >= skill.min_main_quest_progress

func _is_unlocked(in_skill: Skill) -> bool:
	if Utils.is_in_editor():
		return in_skill != skill
	else:
		return GlobalSaveGame.has_unlocked_skill(in_skill)

func _is_unlockable() -> bool:
	if Utils.is_in_editor():
		return true
	else:
		if skill.requirement and not _is_unlocked(skill.requirement):
			return false
		elif GlobalSaveGame.insights < skill.unlock_cost:
			return false
		else:
			return true

func _on_icon_mouse_entered() -> void:
	_is_hovered = true
	_update_shader()
	hovered.emit()

func _on_icon_mouse_exited() -> void:
	_is_hovered = false
	_update_shader()
	unhovered.emit()

func _on_icon_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if not mouse_event:
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		clicked.emit()

func _update_shader() -> void:
	var is_root := not skill or skill.requirement == null

	# HACK: To support old hardware that has limited space for instance uniform buffers,
	#       we pass the data through self_modulate that ends up in COLOR in the vertex shader.
	var packed_state := 0
	packed_state |= _state & 7
	packed_state |= int(_is_hovered or is_selected) << 3
	packed_state |= int(is_root) << 4
	packed_state |= int(is_new) << 5
	packed_state |= int(left) << 6
	packed_state |= int(right) << 7
	packed_state |= int(up) << 8
	packed_state |= int(down) << 9
	packed_state |= int(up_left) << 10
	packed_state |= int(down_left) << 11
	packed_state |= int(up_right) << 12
	packed_state |= int(down_right) << 13

	var chunk1: int = packed_state & 0xFF
	var chunk2: int = (packed_state >> 8) & 0xFF
	(%Icon as TextureRect).self_modulate = Color(chunk1 / 255.0, chunk2 / 255.0, 1.0, 1.0)

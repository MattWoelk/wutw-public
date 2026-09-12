@tool
extends EditorPlugin

var _dock: Node

func _enter_tree():
	_dock = load('res://addons/wutw_editor/editor_game_startup.tscn').instantiate()
	_dock.name = 'WutW Start'
	add_control_to_dock(DOCK_SLOT_LEFT_UR, _dock)

func _exit_tree():
	remove_control_from_docks(_dock)
	_dock.free()

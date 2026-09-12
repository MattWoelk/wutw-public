@tool
extends EditorScript

const IGNORE_DIRS = ['.godot', 'addons', '_art_experiment', '_dev_tools', '_generated', 'bin', 'Wwise']
const PARSE_EXTENSIONS = ['tscn', 'scn', 'gd', 'tres', 'res']

var files_found: PackedStringArray = []

func _run() -> void:
	files_found.clear()
	_scan_dir()

	var setting_name := 'internationalization/locale/translations_pot_files'
	ProjectSettings.set_setting(setting_name, files_found)
	ProjectSettings.save()

	prints('Successfully added', files_found.size(), 'files to pot.')

func _scan_dir(path: String = 'res://') -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name:
		if dir.current_is_dir():
			if not file_name.begins_with('.') and not file_name in IGNORE_DIRS:
				_scan_dir(path.path_join(file_name))
		else:
			if file_name.get_extension() in PARSE_EXTENSIONS:
				files_found.append(path.path_join(file_name))

		file_name = dir.get_next()

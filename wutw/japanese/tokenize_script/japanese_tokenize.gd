class_name JapaneseTokenize
extends Node

static func parse_sentence(sentence: String) -> Array:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	var temp_output_path := ProjectSettings.globalize_path('user://wutw_sentence_parse.json')
	var script_path := ProjectSettings.globalize_path('res://japanese/tokenize_script/tokenize_sentence.bat')
	OS.execute('CMD.exe', ['/c', script_path, sentence, temp_output_path])
	var f := FileAccess.open(temp_output_path, FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(f.get_as_text())
	assert(parse_result == OK)
	return json.data

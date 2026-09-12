@tool
extends EditorPlugin

var parser: EditorTranslationParserPlugin

func _enter_tree() -> void:
	parser = preload('res://addons/wutw_i18n_export/resource_parser.gd').new()
	add_translation_parser_plugin(parser)

func _exit_tree() -> void:
	if parser:
		remove_translation_parser_plugin(parser)
		parser = null

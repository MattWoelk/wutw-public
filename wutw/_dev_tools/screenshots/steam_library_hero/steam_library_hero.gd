@tool
extends Node2D

@export_tool_button('Render') @warning_ignore('unused_private_class_variable')
var _render_tree_tool := _render_tree

func _render_tree():
	%SubViewport.get_texture().get_image().save_png('c://users/max99/library_hero.png')

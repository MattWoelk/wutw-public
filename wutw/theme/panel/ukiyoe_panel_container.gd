@tool
class_name UkiyoePanelContainer
extends PanelContainer

@export var material_customized: bool = false

func _ready() -> void:
	if not material_customized:
		add_theme_stylebox_override('panel', load('res://theme/panel/ukiyoe_panel_container_stylebox.tres') as StyleBox)
	if not material or not material_customized:
		material = load('res://theme/panel/ukiyoe_panel_container_material.tres')

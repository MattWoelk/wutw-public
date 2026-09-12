extends Node2D

func _ready() -> void:
	seed(100)
	GlobalSaveGame.init_new_game(2)
	GlobalSaveGame.unlock_skill(load('res://skills/craft/skill_craft_1_common.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/craft/skill_craft_2_uncommon.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/craft/skill_craft_3_rare.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/craft/skill_craft_4_epic.tres') as Skill)
	for stroke in Stroke.get_all_strokes():
		GlobalSaveGame.add_stroke(stroke, randi_range(2, 8))

	var crafting := load('res://hub/crafting/crafting.tscn').instantiate() as Crafting
	crafting.z_index = 1000
	add_child(crafting)

	await get_tree().create_timer(1.5).timeout

	(crafting.get_node('%ScrollPanel') as ScrollPanel).animate_unroll(0.01)
	crafting.get_node('%CardsList').get_children()[3].get_node('%List').get_children()[-9].is_selected = true

	var scroller := crafting.get_node('%ScrollContainer') as ScrollContainer
	scroller.scroll_vertical = 6315

	Input.warp_mouse(Vector2(250, 300))

	await get_tree().create_timer(1).timeout

	Utils.take_screenshot(self, 'C:/users/max99/wutw/screenshots/crafting.png')

	await get_tree().process_frame

	get_tree().quit()

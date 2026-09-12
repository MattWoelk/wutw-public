extends Node2D

func _enter_tree() -> void:
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
	crafting.get_node('%CardsList').get_children()[2].get_node('%List').get_children()[10].is_selected = true

	var scroller := crafting.get_node('%ScrollContainer') as ScrollContainer
	scroller.scroll_vertical = 3500
	var scroll_tween := create_tween()
	scroll_tween.tween_property(scroller, 'scroll_vertical', 5000, 7.5)
	scroll_tween.play()
	await scroll_tween.finished

	get_tree().quit()

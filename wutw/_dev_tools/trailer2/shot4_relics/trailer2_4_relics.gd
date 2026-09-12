extends Node2D

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GlobalGameSettings.Interface.animation_speed.set_value(1.25)
	GameSettings.Interface.tooltip_speed.set_value(.001)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P510_FINISHED_OUTRO_CUTSCENE)
	for relic in Relic.get_all_relics():
		GlobalSaveGame.mark_relic_seen(relic)

	MuseumBrowser.open_museum_entry(load('res://relics/common/spring_rune/relic_spring_rune.tres'), UI.Layer.GAME)
	await get_tree().create_timer(1).timeout
	var scroller := MuseumBrowser.get_active_instance().get_node('%ScrollContainer') as ScrollContainer
	scroller.scroll_vertical += 250

	await get_tree().create_timer(1).timeout

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(scroller, 'scroll_vertical', scroller.scroll_vertical + 2000, 4.5)
	tween.play()

	await get_tree().create_timer(0.5).timeout
	MuseumBrowser.open_museum_entry(load('res://relics/common/sweet_honeycomb/relic_sweet_honeycomb.tres'), UI.Layer.GAME)

	await get_tree().create_timer(1).timeout
	MuseumBrowser.open_museum_entry(load('res://relics/common/weavers_comb/relic_weavers_comb.tres'), UI.Layer.GAME)

	await get_tree().create_timer(1).timeout
	MuseumBrowser.open_museum_entry(load('res://relics/season_reward/tiny_abacus/relic_tiny_abacus.tres'), UI.Layer.GAME)

	await get_tree().create_timer(1.2).timeout
	MuseumBrowser.open_museum_entry(load('res://relics/uncommon/glowing_ember/relic_glowing_ember.tres'), UI.Layer.GAME)

	await get_tree().create_timer(3).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

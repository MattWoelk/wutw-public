class_name EventOutcomeWidget_ChooseRelic
extends EventOutcomeWidget

static var RELIC_SELECTOR_SCENE := AsyncLoadedResource.new('res://relics/selector/relic_selector.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

var relic_choice_pool: Array[Relic]
var ui_layer: UI.Layer = UI.Layer.GAME_MENU_SUBMENU

func _ready() -> void:
	(%Label as Label).visible = false
	(%RelicChoice as RelicChoice).visible = false
	var tween := create_tween()
	modulate.a = 0
	tween.tween_property(self, 'modulate:a', 1.0, Utils.anim_duration(0.5))
	tween.play()
	await tween.finished

func _on_button_pressed() -> void:
	var relic_selector := RELIC_SELECTOR_SCENE.instantiate_loaded_scene() as RelicSelector
	relic_selector.relic_reward_pool = relic_choice_pool
	relic_selector.manual_select = false
	relic_selector.selected.connect(func(relic: Relic) -> void:
		(%Button as Button).visible = false
		(%Label as Label).visible = true
		(%RelicChoice as RelicChoice).visible = true
		(%RelicChoice as RelicChoice).relic = relic
		# HACK: Survey UI is not as wide.
		if Utils.get_active_run().get_state() == RunData.State.SURVEY:
			(%RelicChoice as RelicChoice).min_text_width = 250
			(%RelicChoice as RelicChoice).max_text_width = 250
		finished.emit()
	)
	relic_selector.canceled.connect(func() -> void:
		(%Button as Button).visible = false
		(%Label as Label).visible = true
		(%Label as Label).text = tr('Chose not to keep any relics.')
		finished.emit()
	)
	GlobalUI.add_layer_content(relic_selector, ui_layer)

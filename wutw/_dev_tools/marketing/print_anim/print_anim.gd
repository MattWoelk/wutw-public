extends Node2D

@export var event: Event
@export var anim_material: ShaderMaterial

var _run: Run

func _ready() -> void:
	GlobalSaveGame.init_new_game(13)
	event.mark_all_choices_seen()

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = GlobalSaveGame.get_run_starting_deck()
	_run.run_config.run_seed = 40
	add_child(_run)
	await get_tree().process_frame

	# Start stage.
	_run.debug_create_settlement(Vector2i(200, 110))
	_run.set_state(RunData.State.STAGE)
	add_bonus('harmony', 25)
	add_bonus('food', 65)
	add_bonus('safety', 110)
	add_bonus('productivity', 40)
	add_bonus('adventure', 30)
	add_bonus('knowledge', 10)
	add_bonus('beauty', 80)

	await get_tree().create_timer(2.0).timeout

	_run.queue_event(event)
	await get_tree().process_frame

	var step_scene := _run.get_current_event_scene().get_current_step_scene()
	step_scene._on_skip_button_pressed()
	(step_scene.get_node('%BG') as TextureRect).material = anim_material
	var content_block := step_scene.get_child(0).get_child(-1)
	(content_block as Control).modulate.a = 0.0

	await get_tree().create_timer(1.5).timeout

	var tween := create_tween()
	tween.set_ease(Tween.EaseType.EASE_IN)
	tween.tween_method(func(x: float) -> void:
		anim_material.set_shader_parameter('progress', x),
		0.0, 1.0, 4.0)
	tween.tween_interval(0.5)
	tween.tween_property(content_block, 'modulate:a', 1.0, 1.0)
	tween.play()
	await tween.finished

	await get_tree().create_timer(3).timeout

	get_tree().quit()

# Preamble Utilities

func add_bonus(bonus_id: String, amount: int) -> void:
	_run.gain_bonus(BonusGain.new(BonusType.get_bonus_type_by_id(bonus_id), amount, GlobalConsoleCommands))

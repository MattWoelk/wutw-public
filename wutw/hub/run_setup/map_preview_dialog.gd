class_name MapPreviewDialog
extends Control

signal map_seed_confirmed(new_map_seed: int)

@export var map_seed: int
@export var map_generation_config: MapGenerationConfig

var _closing := false

func _ready() -> void:
	_apply_map_overrides()
	_regenerate_map()

	if Skill.get_skill_var(Skill.Var.REROLL_MAP):
		(%CancelButton as Button).visible = true
		(%RegenerateButton as Button).visible = true
		(%ConfirmButton as Button).size_flags_horizontal &= ~Control.SIZE_EXPAND
	else:
		(%CancelButton as Button).visible = false
		(%RegenerateButton as Button).visible = false
		(%ConfirmButton as Button).size_flags_horizontal |= Control.SIZE_EXPAND

	(%ScrollPanel as ScrollPanel).animate_unroll()

func _handle_esc() -> bool:
	if (%CancelButton as Button).disabled:
		return true  # WARNING: Dangerous to leave a thread not cleaned up!
	close()
	return true

func close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled(self, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		queue_free()

func _on_regenerate_button_pressed() -> void:
	map_seed = randi_range(1, 10000)
	_regenerate_map()

func _regenerate_map() -> void:
	(%CancelButton as Button).disabled = true
	(%RegenerateButton as Button).disabled = true
	(%ConfirmButton as Button).disabled = true
	await (%MapPreview as MapPreview).regenerate(RandomState.new(map_seed))
	(%CancelButton as Button).disabled = false
	(%RegenerateButton as Button).disabled = false
	(%ConfirmButton as Button).disabled = false

func _on_cancel_button_pressed() -> void:
	close()

func _on_confirm_button_pressed() -> void:
	map_seed_confirmed.emit(map_seed)
	close()

func _apply_map_overrides() -> void:
	var config: MapGenerationConfig = map_generation_config

	# WARNING: Must be kept in sync with RunData.create() and Run._apply_map_overrides().
	if GlobalSaveGame.get_pinned_shard_type():
		config = GlobalSaveGame.get_pinned_shard_type().apply_map_generation_override(config)

	for quest_instance in GlobalSaveGame.get_all_quest_instances():
		if quest_instance.is_active():
			config = quest_instance.get_quest().apply_map_generation_override(config)

	(%MapPreview as MapPreview).generation_config = config

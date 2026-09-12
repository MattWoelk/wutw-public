@tool
class_name Relic_RopewayBasket
extends Relic

@export var hand_size_increase: int = 1

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.survey_started.connect(_on_survey_started)
	_run.signals.survey_finished.connect(_on_survey_finished)

func on_removed() -> void:
	_run.signals.survey_started.disconnect(_on_survey_started)
	_run.signals.survey_finished.disconnect(_on_survey_finished)
	super.on_removed()

func _on_survey_started() -> void:
	var survey := _run.get_current_stage().get_survey()
	assert(survey)
	var radius := _run.scaling.survey_scan_radius
	if MapBiomes.Biome.MOUNTAIN in _run.get_map().get_biomes_in_radius(survey.map_location, radius):
		_state = State.ACTIVE
		triggered.emit()
		_run.get_vars().add_modifier(RunVars.Var.HAND_SIZE, hand_size_increase, _get_modifier_tag())

func _on_survey_finished() -> void:
	_run.get_vars().remove_modifier(_get_modifier_tag())
	_state = State.PASSIVE

func get_description() -> String:
	return tr(default_description) % hand_size_increase

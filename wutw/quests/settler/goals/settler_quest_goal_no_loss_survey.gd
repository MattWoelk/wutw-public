class_name SettlerQuestGoal_NoLossSurvey
extends SettlerQuestGoal

var _any_losses := false
var _cur_invalidation_message: String

func start_listening(run: Run) -> void:
	run.signals.survey_started.connect(_on_survey_started)
	run.signals.survey_finished.connect(_on_survey_finished)

func stop_listening(run: Run) -> void:
	run.signals.survey_started.disconnect(_on_survey_started)
	run.signals.survey_finished.disconnect(_on_survey_finished)

func _on_survey_started() -> void:
	_any_losses = false
	_cur_invalidation_message = ''
	var run := Utils.get_active_run()
	run.signals.inspiration_lost.connect(_on_inspiration_lost)
	run.signals.bonus_lost.connect(_on_bonus_lost)
	var survey := run.get_current_stage().get_survey()
	survey.finished_all_episodes.connect(_on_finished_all_episodes)

func _on_survey_finished() -> void:
	_any_losses = false
	_cur_invalidation_message = ''
	var run := Utils.get_active_run()
	run.signals.inspiration_lost.disconnect(_on_inspiration_lost)
	run.signals.bonus_lost.disconnect(_on_bonus_lost)

func _on_finished_all_episodes() -> void:
	if not _any_losses:
		achieved.emit()

func _on_inspiration_lost(amount: int, _reason: Run.InspirationChangeReason) -> void:
	if not _any_losses:
		_any_losses = true
		_cur_invalidation_message = '%d <term:inspiration>' % amount

func _on_bonus_lost(bonus_type: BonusType, amount: int, _reason: BonusGain.Reason) -> void:
	if not _any_losses:
		var run := Utils.get_active_run()
		var survey := run.get_current_stage().get_survey()
		if survey.is_preparing():
			return

		_any_losses = true
		_cur_invalidation_message = '%d %s' % [amount, bonus_type.get_term_tag()]

func describe() -> String:
	var result := tr('Finish all <term_lower:encounter>s in a <term_lower:survey> without ever losing any <term_lower:bonus>s or <term:inspiration>.')
	if _cur_invalidation_message:
		result += tr(' [color=#444]The current survey is ineligible because %s was lost.[/color]') % _cur_invalidation_message
	return result

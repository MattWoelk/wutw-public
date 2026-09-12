class_name EventOutcomeWidget_Bonus
extends EventOutcomeWidget

var bonus_type: BonusType
var amount: int
var extra_per_season: int = 0
var event: Event

func _ready() -> void:
	if not (Utils.ensure(bonus_type != null) and Utils.ensure(amount != 0)):
		visible = false
		finished.emit()
		return

	var run := Utils.get_active_run()
	var effective_amount := amount + extra_per_season * run.get_current_season_index()
	var gain_source := event if event else (run.get_current_stage().get_survey() as Object)
	var gain := BonusGain.new(bonus_type, effective_amount, gain_source)
	run.gain_bonus(gain)  # May modify gain.amount.

	var amount_sign: String
	if gain.amount == 0:
		amount_sign = '-' if effective_amount < 0 else '+'
	else:
		amount_sign = '-' if gain.amount < 0 else '+'
	(%Label as Label).text = '%s%d' % [amount_sign, abs(gain.amount)]
	if effective_amount < 0:
		(%Label as Label).add_theme_color_override('font_color', Color(0.85, 0.213, 0.223))
	else:
		(%Label as Label).add_theme_color_override('font_color', Color(0.173, 0.702, 0.106))
	(%Bonus as Bonus).bonus_type = bonus_type

	var tween := create_tween()
	modulate.a = 0
	tween.tween_property(self, 'modulate:a', 1.0, Utils.anim_duration(0.4))
	tween.play()
	await tween.finished

	finished.emit()

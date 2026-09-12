@tool
class_name Relic_SweetHoneycomb
extends Relic

@export var harmony: BonusType
@export var knowledge: BonusType
@export var min_required: int = 20

# I think we don't need to persist this, since the effects only matter until the card reward.
# TODO: But I might be wrong?
var gained_harmony := 0
var gained_knowledge := 0
var mod_added := false

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.bonus_gained.connect(_on_bonus_gained)
	_run.signals.foray_started.connect(_on_foray_started)

func on_removed() -> void:
	_run.signals.bonus_gained.disconnect(_on_bonus_gained)
	_run.signals.foray_started.disconnect(_on_foray_started)
	super.on_removed()

func _on_bonus_gained(bonus_type: BonusType, amount: int, _reason: BonusGain.Reason) -> void:
	if mod_added:
		return
	if bonus_type == harmony:
		gained_harmony += amount
	elif bonus_type == knowledge:
		gained_knowledge += amount
	if gained_harmony >= min_required and gained_knowledge >= min_required:
		triggered.emit()
		mod_added = true
		_state = State.ACTIVE
		_run.get_vars().add_modifier(RunVars.Var.CARD_REWARDS_PER_STAGE, 1, _get_modifier_tag())

func _on_foray_started() -> void:
	gained_harmony = 0
	gained_knowledge = 0
	mod_added = false
	_state = State.PASSIVE
	_run.get_vars().remove_modifier(_get_modifier_tag())

func get_description() -> String:
	return tr(default_description) % [min_required, harmony.get_term_tag(), min_required, knowledge.get_term_tag()]

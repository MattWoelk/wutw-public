@tool
class_name ShopGetRelics
extends ShopBase

static var RELIC_SELECTOR_SCENE := AsyncLoadedResource.new('res://relics/selector/relic_selector.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var RELIC_POOL_OUTCOME := AsyncLoadedResource.new('res://events/landmark/endless_ruin/endless_ruin_relics.tres', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

var _relic_selector: RelicSelector

func _handle_esc() -> bool:
	if not _relic_selector:
		_close()
		return true
	else:
		return false

func _on_action_pressed() -> void:
	_relic_selector = RELIC_SELECTOR_SCENE.instantiate_loaded_scene() as RelicSelector
	_relic_selector.relic_reward_pool = (RELIC_POOL_OUTCOME.get_loaded() as EventOutcome_ChooseRelic).relic_choice_pool
	_relic_selector.manual_select = false
	_relic_selector.finished.connect(_on_relic_selected)
	add_child(_relic_selector)

func _on_relic_selected() -> void:
	_pay_cost()
	_update_action_availability()
	_relic_selector = null

func _get_action_button_tooltip() -> String:
	return tr('Retrieve a <term:relic> from the ruins.')

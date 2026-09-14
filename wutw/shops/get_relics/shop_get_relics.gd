@tool
class_name ShopGetRelics
extends ShopBase

static var RELIC_SELECTOR_SCENE := AsyncLoadedResource.new('res://relics/selector/relic_selector.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var RELIC_POOL_OUTCOME := AsyncLoadedResource.new('res://events/landmark/endless_ruin/endless_ruin_relics.tres', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

var _relic_selector: RelicSelector

func _ready() -> void:
	super._ready()
	GlobalTooltipSystem.attach(%RemoveButton as Button, _make_remove_button_tooltip,
			[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.CENTERED])

func _handle_esc() -> bool:
	if not _relic_selector:
		_close()
		return true
	else:
		return false

func _update() -> void:
	super._update()
	(%RemovalContainer as Control).visible = Skill.get_skill_var(Skill.Var.REMOVE_RELIC) > 0

func _update_action_availability() -> void:
	super._update_action_availability()
	var run := Utils.get_active_run()
	(%RemoveButton as Button).disabled = (
		Utils.get_active_run().has_shop_been_used_this_round(shop_type)
		or run.get_current_relics().is_empty())

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

func _make_remove_button_tooltip() -> String:
	var result := tr('Leave a <term:relic> at the ruins.')
	var run := Utils.get_active_run()
	if run.has_shop_been_used_this_round(shop_type):
		result += '\n\n'
		result += tr('[b]Only one transaction in each <term_lower:shop> can be performed per <term_lower:stage>.[/b]')
	return result

func _on_remove_button_pressed() -> void:
	var run := Utils.get_active_run()
	_relic_selector = RELIC_SELECTOR_SCENE.instantiate_loaded_scene() as RelicSelector
	_relic_selector.relic_reward_pool = run.get_current_relics()
	_relic_selector.manual_select = true
	_relic_selector.add_selected = false
	_relic_selector.selected.connect(func(relic: Relic) -> void:
		run.remove_relic(relic)
		_on_relic_selected()
	)
	GlobalUI.add_layer_content(_relic_selector, UI.Layer.GAME_MENU_SUBMENU)

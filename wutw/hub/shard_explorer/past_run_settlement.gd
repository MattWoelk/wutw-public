@tool
class_name PastRunSettlement
extends UkiyoePanelContainer

static var DISCOVERY_UPGRADE_SCENE := AsyncLoadedResource.new('res://run/run_end/discovery_upgrade.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var DISCOVERY_EVENT_SCENE := AsyncLoadedResource.new('res://run/run_end/discovery_event.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

var settlement_state: SettlementState
var events: Array[Event]

func _ready() -> void:
	super._ready()

	if not settlement_state:
		return

	(%NameLabel as Label).text = settlement_state.settlement_name.get_display_name()
	if settlement_state.settlement_name.name_jp:  # Save compatibility
		GlobalTooltipSystem.attach(%NameLabel as Label, _make_name_tooltip_text,
				[Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.BELOW],
				[Tooltip.Alignment.CENTERED])

	var provided_bonus := settlement_state.get_sorted_bonus_types()[0]
	for child in %BonusesList.get_children():
		if child is BonusCounter:
			var counter := child as BonusCounter
			counter.current_value = settlement_state.bonus_amounts.get_amount(counter.bonus_type)
			if counter.bonus_type == provided_bonus:
				counter.highlight_type =  Bonus.HighlightType.POSITIVE
				(counter.get_node('%Bonus') as Bonus).highlight_type =  Bonus.HighlightType.POSITIVE
	(%ShopIcon as Control).visible = not settlement_state.shop_types.is_empty()
	(%ConnectedIcon as Control).visible = settlement_state.is_settlement_connected

	Utils.clear_node(%UpgradesList)
	for upgrades in settlement_state.activated_upgrades:
		if upgrades:
			var discovery := DISCOVERY_UPGRADE_SCENE.instantiate_loaded_scene() as Discovery_Upgdrade
			discovery.spot_upgrade = upgrades[-1]
			%UpgradesList.add_child(discovery)

	Utils.clear_node(%EventsList)
	for event in events:
		if event.steps:
			var discovery := DISCOVERY_EVENT_SCENE.instantiate_loaded_scene() as Discovery_Event
			discovery.event = event
			%EventsList.add_child(discovery)

func _make_name_tooltip_text() -> String:
	return settlement_state.settlement_name.get_markedup_name_explanation().replace('\n', ' ')

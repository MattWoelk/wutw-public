@tool
class_name EventOutcome_UnlockShop
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/unlock_shop/event_outcome_widget_unlock_shop.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var shop_type: ShopType

func apply(_event: Event) -> EventOutcomeWidget:
	assert(shop_type)
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_UnlockShop
	widget.shop_type = shop_type
	return widget

func describe(_run: Run) -> String:
	return tr('Unlock Landmark: %s') % shop_type.get_term_tag()

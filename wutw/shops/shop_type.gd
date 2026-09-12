@tool
class_name ShopType
extends Term

@export var shop_id: String
@export var title: String
@export_multiline var intro: String
@export_multiline var action_description: String
@export var action_button_label: String
@export_multiline var tooltip: String
@export var base_cost: int = 50
@export var cost_type: BonusType
@export var background_texture: Texture
@export var background_credit: ArtPiece
@export var scene: PackedScene

static var _shop_group_loader := AsyncLoadedGroup.new('res://shops/resourcegroup_shop_types.tres')
static var _all_shop_types: Array[ShopType] = []

static func get_all_shop_types() -> Array[ShopType]:
	if not _all_shop_types:
		if Utils.is_dev():
			for shop_type in _all_shop_types:
				assert(shop_type.shop_id)
				if not shop_type.background_credit:
					push_warning('Stop missing art credit: ', shop_type.shop_id)
		_shop_group_loader.fetch_loaded(_all_shop_types)
	return _all_shop_types

static func get_shop_type_by_id(target_shop_id: String) -> ShopType:
	for shop_type in get_all_shop_types():
		if shop_type.shop_id == target_shop_id:
			return shop_type
	return null

func get_scaled_cost(run: Run) -> int:
	var cost: float = base_cost * pow(3, run.get_times_used_shop(self))
	cost = cost / 100.0 * run.get_var(RunVars.Var.SHOP_PRICE_PERCENTAGE)
	return floori(cost)

func get_term_id() -> String:
	return 'shop.' + shop_id

func get_term_name(long: bool) -> String:
	return (tr('Landmark: ') + tr(title)) if long else tr(title)

func get_markedup_description() -> String:
	return '<related_term:shop>' + tr(tooltip)

func get_term_priority() -> int:
	return 10  # Very specific, so probably important.

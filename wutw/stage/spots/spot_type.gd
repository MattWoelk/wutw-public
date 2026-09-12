@tool
class_name SpotType
extends Resource

static var _group_loader := AsyncLoadedGroup.new('res://stage/spots/resourcegroup_spot_types.tres')

@export var spot_type_id: String
@export var name: String
@export_multiline var description: String
@export var granted_capital_bonus: BonusType
@export var panel_material: ShaderMaterial
@export var preview_image: Texture2D
@export var sort_order: int

var upgrades: Array[SpotUpgrade]:
	get():
		get_all_spot_types()  # Ensure initialized.
		return _upgrades

static var _all_spot_types: Array[SpotType] = []
static var _spot_to_all_upgrades: Dictionary[SpotType, Array] = {}  # Array[SpotUpgrade]

var _upgrades: Array[SpotUpgrade]

static func get_all_spot_types() -> Array[SpotType]:
	if not _all_spot_types:
		_group_loader.fetch_loaded(_all_spot_types)
		for spot in _all_spot_types:
			_spot_to_all_upgrades[spot] = []
		for upgrade in SpotUpgrade.get_all_spot_upgrades():
			_spot_to_all_upgrades[upgrade.spot].append(upgrade)
			if not upgrade.parent_upgrade:
				upgrade.spot._upgrades.append(upgrade)

	return _all_spot_types

static func get_spot_type_by_id(target_spot_type_id: String) -> SpotType:
	for spot_type in get_all_spot_types():
		if spot_type.spot_type_id == target_spot_type_id:
			return spot_type
	return null

static func get_spot_type_by_upgrade(spot_upgrade: SpotUpgrade) -> SpotType:
	return spot_upgrade.spot

func contains_upgrade(upgrade: SpotUpgrade) -> bool:
	return _contains_upgrade(upgrade, upgrades)

func get_all_upgrades() -> Array[SpotUpgrade]:
	get_all_spot_types()  # Ensure initialized.
	var result: Array[SpotUpgrade]
	result.assign(_spot_to_all_upgrades[self])
	return result

func _contains_upgrade(needle: SpotUpgrade, haystack: Array[SpotUpgrade]) -> bool:
	for bale in haystack:
		if needle == bale:
			return true
		if _contains_upgrade(needle, bale.child_upgrades):
			return true
	return false

func _colect_upgrades(root: SpotUpgrade, output: Array[SpotUpgrade]) -> void:
	output.append(root)
	for upgrade in root.child_upgrades:
		_colect_upgrades(upgrade, output)

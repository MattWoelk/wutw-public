class_name SettlementState
extends RefCounted

signal bonuses_changed

const FULLY_FILLED_SLOTS: Array[int] = [0, 1]

var settlement_name: SettlementNameOption
var map_location: Vector2 = Vector2(-1, -1)
var radius: int = 0
var spot_types: Array[SpotType]
var goal: StageGoal
var bonus_amounts: BonusAmounts:
	set(value):
		bonus_amounts = value
		bonuses_changed.emit()
var activated_upgrades: Array[Array]  # Array[SpotUpgrade]; same order as spot_types
var lack1_slots_filled: Array[int] = []  # indices, always sorted
var lack2_slots_filled: Array[int] = []  # indices, always sorted
var is_settlement_connected: bool = false
var shop_types: Array[ShopType]
var roof_color: Color = Color.TRANSPARENT

func get_sorted_bonus_types() -> Array[BonusType]:
	var sorted: Array[Array] = []   # of [BonusType, float]
	var tie_breakers: Dictionary[BonusType, int]
	for spot_type in spot_types:
		var run := Utils.get_active_run()
		var sorted_available_bonuses := StageSatisfiability.get_sorted_spot_bonuses(run, spot_type, true, [], true)
		for i in sorted_available_bonuses.size():
			var bonus_type: = sorted_available_bonuses[i]
			tie_breakers[bonus_type] = tie_breakers.get(bonus_type, 0) + (sorted_available_bonuses.size() - i)
	for bonus_type in BonusType.get_all_types():
		var sort_index: int = 0
		if bonus_amounts:  # May be called before this settlement's foray is finished.
			sort_index += bonus_amounts.get_amount(bonus_type) * 10000
		sort_index += tie_breakers.get(bonus_type, 0) * 100
		sort_index += bonus_type.sort_order  # consistent tie breaker
		sorted.append([bonus_type, sort_index])
	sorted.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	var result: Array[BonusType] = []
	for pair in sorted:
		result.append(pair[0])
	return result

func has_upgrade(upgrade: SpotUpgrade) -> bool:
	for upgrades in activated_upgrades:
		if upgrade in upgrades:
			return true
	return false

func encode() -> Dictionary:
	var encoded: Dictionary = {}
	if settlement_name:
		encoded['name'] = {
			'name': settlement_name.name,
			'name_jp': settlement_name.name_jp,
			'translation': settlement_name.translation,
		}
		if settlement_name.related_spot:
			encoded['name']['spot'] = settlement_name.related_spot.spot_type_id
		if settlement_name.related_spot_upgrade:
			encoded['name']['spot_upgrade'] = settlement_name.related_spot_upgrade.spot_upgrade_id
	if map_location[0] >= 0:
		encoded['map_location'] = [map_location.x, map_location.y]
	if radius:
		encoded['radius'] = radius

	var encoded_spot_types: Array[String] = []
	for spot_type in spot_types:
		encoded_spot_types.append(spot_type.resource_path)
	encoded['spot_types'] = encoded_spot_types

	encoded['goal'] = goal.encode()
	if bonus_amounts:
		encoded['bonus_amounts'] = bonus_amounts.encode()
	var encoded_upgrades_lists: Array[Array] = []
	for upgrades_list in activated_upgrades:
		var encoded_upgrades_list: Array[String] = []
		for upgrade: SpotUpgrade in upgrades_list:
			encoded_upgrades_list.append(upgrade.resource_path)
		encoded_upgrades_lists.append(encoded_upgrades_list)
	encoded['activated_upgrades'] = encoded_upgrades_lists

	encoded['lack1_slots_filled'] = lack1_slots_filled
	encoded['lack2_slots_filled'] = lack2_slots_filled
	encoded['is_settlement_connected'] = is_settlement_connected
	var shop_type_ids: Array[String] = []
	for shop_type in shop_types:
		shop_type_ids.append(shop_type.shop_id)
	encoded['shop_types'] = shop_type_ids

	encoded['roof_color'] = [roof_color.r, roof_color.g, roof_color.b, roof_color.a]

	return encoded

func decode(encoded_data: Dictionary) -> void:
	var encoded_name: Variant = encoded_data.get('name', null)
	if encoded_name is Dictionary:
		var encoded_name_dict := encoded_name as Dictionary
		settlement_name = SettlementNameOption.new()
		settlement_name.name = encoded_name_dict['name']
		settlement_name.name_jp = encoded_name_dict['name_jp']
		settlement_name.translation = encoded_name_dict['translation']
		if encoded_name_dict.get('spot', ''):
			settlement_name.related_spot = SpotType.get_spot_type_by_id(
				encoded_name_dict.get('spot', '') as String)
		if encoded_name_dict.get('spot_upgrade', ''):
			settlement_name.related_spot_upgrade = SpotUpgrade.get_spot_upgrade_by_id(
				encoded_name_dict.get('spot_upgrade', '') as String)
	elif encoded_name is String:
		# Backward compatibility
		settlement_name = SettlementNameOption.new()
		settlement_name.name = encoded_name
	else:
		settlement_name = null
	var encoded_location := encoded_data.get('map_location', [-1, -1]) as Array
	map_location = Vector2(encoded_location[0] as float, encoded_location[1] as float)
	radius = encoded_data.get('radius', 0)

	for spot_type_path: String in encoded_data.get('spot_types', []):
		spot_types.append(load(spot_type_path) as SpotType)

	goal = StageGoal.new()
	goal.decode(encoded_data['goal'] as Dictionary)

	if encoded_data.has('bonus_amounts'):
		bonus_amounts = BonusAmounts.new()
		bonus_amounts.decode(encoded_data['bonus_amounts'] as Dictionary)
	else:
		bonus_amounts = null

	activated_upgrades = []
	for encoded_list: Array in encoded_data.get('activated_upgrades', []):
		var decoded_list := []
		for upgrade_path: String in encoded_list:
			decoded_list.append(load(upgrade_path) as SpotUpgrade)
		activated_upgrades.append(decoded_list)

	lack1_slots_filled.assign(encoded_data.get('lack1_slots_filled', []) as Array)
	lack2_slots_filled.assign(encoded_data.get('lack2_slots_filled', []) as Array)
	# Backward-compatibility.
	if encoded_data.get('lack1_satisfied', false):
		lack1_slots_filled = FULLY_FILLED_SLOTS.duplicate()
	if encoded_data.get('lack2_satisfied', false):
		lack2_slots_filled = FULLY_FILLED_SLOTS.duplicate()

	is_settlement_connected = encoded_data.get('is_settlement_connected', false)

	var shop_type_ids: Array = encoded_data.get('shop_types', [])
	shop_types.clear()
	for shop_type_id: String in shop_type_ids:
		shop_types.append(ShopType.get_shop_type_by_id(shop_type_id))

	var encoded_roof_color: Array = encoded_data.get('roof_color', [0, 0, 0, 0])
	roof_color = Color(encoded_roof_color[0] as float,
					   encoded_roof_color[1] as float,
					   encoded_roof_color[2] as float,
					   encoded_roof_color[3] as float)

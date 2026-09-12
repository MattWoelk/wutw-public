@tool
class_name ShardType_Archaeology
extends ShardType

@export var min_wasteland_settlements: int = 5
@export var wasteland: SpotType
@export var knowledge_bonus: BonusType
@export var min_knowledge: int = 100
@export var ruins_shop: ShopType

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0:
			var wasteland_settlements := 0
			for settlement_state in run_data.settlement_states:
				if wasteland in settlement_state.spot_types:
					wasteland_settlements += 1
			return wasteland_settlements / float(min_wasteland_settlements)
		1:
			for settlement_state in run_data.settlement_states:
				if ruins_shop in settlement_state.shop_types:
					return 1
			return 0
		2: return min(run_data.bonus_amounts.get_amount(knowledge_bonus) / float(min_knowledge), 1.0)
		_: return -1

func describe_requirements() -> Array[String]:
	return [tr('At least %d <spot:%s> settlements.') % [min_wasteland_settlements, wasteland.spot_type_id],
			tr('An <shop:%s> <term_lower:shop>.') % ruins_shop.shop_id,
			tr('At least %d %s.') % [min_knowledge, knowledge_bonus.get_term_tag()]]

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	# More wasteland.
	config = config.duplicate()
	config.biome_config = config.biome_config.duplicate()
	config.biome_config.max_moisture_for_dry_biome = 0.55
	config.biome_config.min_temperature_for_desert = 0.55
	return config

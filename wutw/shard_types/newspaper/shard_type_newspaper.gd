@tool
class_name ShardType_Newspaper
extends ShardType

@export var printer: SpotUpgrade
@export var notice_board: SpotUpgrade
@export var min_notice_boards: int = 2
@export var paper_studio: SpotUpgrade
@export var min_paper_studios: int = 2
@export var knowledge: BonusType
@export var min_knowledge: int = 300

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0: return run_data.bonus_amounts.get_amount(knowledge) / float(min_knowledge)
		1:
			var num_notice_boards := 0
			for settlement_state in run_data.settlement_states:
				for upgrades in settlement_state.activated_upgrades:
					if notice_board in upgrades:
						num_notice_boards += 1
			return float(num_notice_boards) / min_notice_boards
		2:
			var num_paper_studios := 0
			for settlement_state in run_data.settlement_states:
				for upgrades in settlement_state.activated_upgrades:
					if paper_studio in upgrades:
						num_paper_studios += 1
			return float(num_paper_studios) / min_paper_studios
		3:
			for settlement_state in run_data.settlement_states:
				for upgrades in settlement_state.activated_upgrades:
					if printer in upgrades:
						return 1
			return 0
		_: return -1

func describe_requirements() -> Array[String]:
	return [
		tr('At least %d %s.') % [min_knowledge, knowledge.get_term_tag()],
		tr('At least %d <spot_upgrade:%s> <term_lower:spot_upgrade>s.') % [min_notice_boards, notice_board.spot_upgrade_id],
		tr('At least %d <spot_upgrade:%s> <term_lower:spot_upgrade>s.') % [min_paper_studios, paper_studio.spot_upgrade_id],
		tr('A <spot_upgrade:%s> <term_lower:spot_upgrade>.') % printer.spot_upgrade_id,
	]

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	config = config.duplicate(true)

	# More town squares.
	for stamp in config.stamp_configs:
		if stamp.comment == 'city':
			stamp.stamp_count_range.x = 2
			stamp.stamp_count_range.y += 1

	# More brushland.
	config.biome_config.max_moisture_for_brushland = 0.5
	config.biome_config.max_temperature_for_brushland = 0.7

	return config

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return [printer, notice_board, paper_studio]

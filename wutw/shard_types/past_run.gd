class_name PastRun
extends Resource

var uid: int
var run_data: RunData
var shard_name: String
var shard_name_jp: String
var shard_name_meaning: String
var shard_type: ShardType
var screenshot: Image
var date_settled: int = 0

func validate() -> void:
	assert(uid)
	assert(run_data)
	assert(shard_name)
	assert(screenshot)

func get_town_name(index: int) -> SettlementNameOption:
	return run_data.settlement_states[index].settlement_name

func get_random_town_name(index: int) -> SettlementNameOption:
	var settlements := run_data.settlement_states.duplicate()
	RandomState.new(uid).shuffle(settlements)
	if Utils.ensure(index < settlements.size()):
		return settlements[index].settlement_name
	else:
		var fallback := SettlementNameOption.new()
		fallback.name = tr('another town')
		fallback.name_jp = fallback.name
		fallback.translation = fallback.name
		return fallback

func get_shard_display_name() -> String:
	match GameSettings.Japanese.shard_names.value():
		GameSettings.ShardNameDisplayType.ROMAJI:
			return tr(shard_name)
		GameSettings.ShardNameDisplayType.KANJI:
			return shard_name_jp if shard_name_jp else tr(shard_name)  # Backward-compatibility for old saves.
		GameSettings.ShardNameDisplayType.HIRAGANA:
			return JapaneseUtils.romaji_to_hiragana(shard_name)
		GameSettings.ShardNameDisplayType.MEANING:
			return tr(shard_name_meaning) if shard_name_meaning else tr(shard_name)  # Backward-compatibility for old saves.
	assert(false)
	return shard_name

func get_native_shard_display_name() -> String:
	if GameSettings.Japanese.embed_jp.value():
		return get_shard_display_name()
	else:
		if GameSettings.Japanese.shard_names.value() == GameSettings.ShardNameDisplayType.MEANING:
			return tr(shard_name_meaning) if shard_name_meaning else tr(shard_name)  # Backward-compatibility for old saves.
		else:
			return tr(shard_name)

func get_population(current_date: int) -> int:
	const MAX_SEASONS := 50

	var seasons_since_settled := current_date - date_settled
	var total := 0

	# Randomize start.
	total += RandomState.new(uid).rand_int(0, 500)

	# Small towns: 300 to 10,000
	var num_small_towns := mini(run_data.current_stage_index, 6)
	total += num_small_towns * lerp(100, 6_000, clampf(seasons_since_settled / float(MAX_SEASONS), 0, 1))

	# Large cities: 500 to 30,000
	var num_large_cities := maxi(0, run_data.current_stage_index - 6)
	total += num_large_cities * lerp(300, 10_000, clampf(seasons_since_settled / float(MAX_SEASONS), 0, 1))

	# Capital
	if run_data.capital_location.x >= 0:
		total += lerp(400, 50_000, clampf(seasons_since_settled / float(MAX_SEASONS), 0, 1))

	# Passive decaying increase forever.
	if seasons_since_settled > MAX_SEASONS:
		total += ceili(3_251 / pow(1.1, seasons_since_settled - MAX_SEASONS))

	# Remove noise.
	if total > 50_000:
		total -= total % 1000
	else:
		total -= total % 100

	return total

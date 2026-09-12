@tool
class_name Vocab
extends Resource

@export var japanese: String
@export var readings: Array[String]
@export var meanings: Array[String]
@export var jlpt_level: int = -1

@export var _difficulty: int = -1  # Stored as an int to stop the editor from resaving them with non-deterministic precision.
@export_storage var _used_kanji: Array[String]

func get_difficulty() -> float:
	if _difficulty < 0:
		_difficulty = _estimate_difficulty()
	return _difficulty / 1000.0

func get_used_kanji() -> Array[String]:
	if not _used_kanji:
		for c in japanese:
			if c not in _used_kanji:
				var kanji_details := JapaneseUtils.get_kanji_detail(c)
				if kanji_details:
					_used_kanji.append(c)
	return _used_kanji

func pick_meaning(random: RandomState) -> String:
	if meanings.size() == 1:
		return meanings[0]
	var meaning_weights: Dictionary[String, float]
	var cur_meaning_weight := 1.0
	for meaning in meanings:
		meaning_weights[meaning] = cur_meaning_weight
		cur_meaning_weight /= 3.0
	return random.pick_weighted_dict(meaning_weights)[0] as String

func _estimate_difficulty() -> int:
	if jlpt_level != -1:
		return 30 * (5 - jlpt_level) + len(japanese)
	var frequency_rank := JapaneseUtils.dev_get_word_frequency_rank(japanese)
	if frequency_rank < 1000:
		return roundi(50 + 800 * (frequency_rank / 2000.0))
	else:
		return roundi(1000 * (0.5 + clampf((frequency_rank - 1000) / 30_000.0, 0, 0.5)))

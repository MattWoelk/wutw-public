@tool
class_name ExampleSentence
extends Resource

@export var japanese: String
@export var native: String
@export var parsed: Array[JapaneseToken]

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

func _estimate_difficulty() -> int:
	var kanji_count := 0
	var kanji_grade_sum := 0
	var kanji_grade_max := 0
	for c in japanese:
		var kanji_details := JapaneseUtils.get_kanji_detail(c)
		if kanji_details:
			kanji_count += 1
			var grade := kanji_details.grade if kanji_details.grade != -1 else 11
			kanji_grade_sum += grade
			kanji_grade_max = maxi(grade, kanji_grade_max)
	var avg_grade := float(kanji_grade_sum) / kanji_count
	var length := japanese.length()

	var length_score := clampf(remap(length, 5, 25, 0, 1), 0, 1)
	var kanji_boost := 0.2 if kanji_count >= 5 else kanji_count * 0.025
	var grade_score := clampf(kanji_grade_max / 24.0 + avg_grade / 24.0 + kanji_boost, 0, 1)
	return roundi(1000 * (length_score + 2 * grade_score) / 3)

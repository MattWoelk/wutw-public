class_name Stroke
extends Resource

static var _group_loader := AsyncLoadedGroup.new('res://japanese/strokes/resourcegroup_strokes.tres')
static var _all_strokes: Dictionary[String, Stroke] = {}
static var _kanji_to_strokes: Dictionary[String, Array] = {}  # Array[Stroke]

@export var character: String
@export var name: String
@export var image: Texture2D

static func get_stroke(stroke_character: String) -> Stroke:
	_ensure_init()
	return _all_strokes[stroke_character]

static func get_all_strokes() -> Array[Stroke]:
	_ensure_init()
	return _all_strokes.values()

static func get_strokes_for_kanji(kanji: String) -> Dictionary[Stroke, int]:
	_ensure_init()
	Utils.ensure(kanji.length() == 1)
	if not Utils.ensure(kanji in _kanji_to_strokes):
		return {}
	var result: Dictionary[Stroke, int]
	for stroke: Stroke in _kanji_to_strokes[kanji]:
		result[stroke] = result.get(stroke, 0) + 1
	return result

static func _ensure_init() -> void:
	if not _all_strokes:
		for stroke: Stroke in _group_loader.get_loaded():
			Utils.ensure(stroke.character.length() == 1)
			Utils.ensure(stroke.character not in _all_strokes)
			_all_strokes[stroke.character] = stroke

	if not _kanji_to_strokes:
		var f := FileAccess.open('res://japanese/databases/kanji_to_strokes.csv', FileAccess.READ)
		while not f.eof_reached():
			var line := f.get_csv_line()
			if line.size() == 1 and not line[0]:
				continue  # Empty line
			assert(line.size() == 2)
			var strokes := []
			for stroke_str in line[1]:
				strokes.append(_all_strokes[stroke_str])
			_kanji_to_strokes[line[0]] = strokes

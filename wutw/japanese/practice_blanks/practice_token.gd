class_name PracticeToken
extends Control

signal slot_filled

static var BLANKS_KANJI_SCENE := AsyncLoadedResource.new('res://japanese/practice_blanks/blanks_kanji.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var KANJI_SLOT_SCENE := AsyncLoadedResource.new('res://japanese/practice_blanks/kanji_slot.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var label_settings: LabelSettings
@export var japanese: String:
	set(value):
		japanese = value
		if is_node_ready():
			_update()
@export var reading: String:  # hiragana
	set(value):
		reading = value
		if is_node_ready():
			_update()
@export var vocab: Vocab:
	set(value):
		vocab = value
		if is_node_ready():
			_update()
@export var kanji_blanks: Array[String]:
	set(value):
		kanji_blanks = value
		if is_node_ready():
			_update()
@export var universal_probability: float = 0.1:
	set(value):
		universal_probability = value
		if is_node_ready():
			_update()

var _kanji_slots: Array[KanjiSlot]
var _kanji_labels: Array[BlanksKanji]
var _solved := false

func _ready() -> void:
	_update()
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Until solved.
	if vocab:
		GlobalTooltipSystem.attach(self, _make_tooltip_text,
				[Tooltip.RelativeDirection.ABOVE], [Tooltip.Alignment.CENTERED],
				%MainBox as Control)

func mark_solved() -> void:
	_solved = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	for kanji_label in _kanji_labels:
		kanji_label.mark_solved()
	_update_furigana()

func _update_furigana() -> void:
	match GameSettings.Japanese.kanji_practice_furigana_mode.value():
		GameSettings.FuriganaMode.ALWAYS:
			(%FuriganaLabel as Label).modulate.a = 1
		GameSettings.FuriganaMode.WHEL_SOLVED:
			(%FuriganaLabel as Label).modulate.a = 1 if _solved else 0
		GameSettings.FuriganaMode.OFF:
			(%FuriganaLabel as Label).modulate.a = 0

func _update() -> void:
	var core_part := japanese
	var furigana_part := reading

	# Prefix
	var prefix := ''
	while core_part and not JapaneseUtils.get_kanji_detail(core_part[0]) and Utils.ensure(core_part[0] == furigana_part[0]):
		prefix += core_part[0]
		core_part = core_part.substr(1)
		furigana_part = furigana_part.substr(1)
	if prefix:
		var label := Label.new()
		label.text = prefix
		label.label_settings = label_settings
		label.size_flags_vertical = Control.SIZE_SHRINK_END
		%MainBox.add_child(label)
		%MainBox.move_child(label, 0)

	# Suffix
	var suffix := ''
	while core_part and not JapaneseUtils.get_kanji_detail(core_part[-1]) and Utils.ensure(core_part[-1] == furigana_part[-1]):
		suffix = core_part[-1] + suffix
		core_part = core_part.left(-1)
		furigana_part = furigana_part.left(-1)
	if suffix:
		var label := Label.new()
		label.text = suffix
		label.label_settings = label_settings
		label.size_flags_vertical = Control.SIZE_SHRINK_END
		%MainBox.add_child(label)

	# Core
	if core_part:
		Utils.clear_node(%KanjiBox)
		var remaining_kanji_blanks := kanji_blanks.duplicate()
		for c in core_part:
			if c in remaining_kanji_blanks:
				remaining_kanji_blanks.erase(c)
				var kanji_slot := KANJI_SLOT_SCENE.instantiate_loaded_scene() as KanjiSlot
				kanji_slot.kanji = c
				kanji_slot.universal_probability = universal_probability
				kanji_slot.get_aspect_slot().filled.connect(_on_slot_filled)
				_kanji_slots.append(kanji_slot)
				%KanjiBox.add_child(kanji_slot)
			else:
				var kanji_label := BLANKS_KANJI_SCENE.instantiate_loaded_scene() as BlanksKanji
				kanji_label.kanji = c
				_kanji_labels.append(kanji_label)
				%KanjiBox.add_child(kanji_label)
		if GameSettings.Japanese.romaji_furigana.value():
			(%FuriganaLabel as Label).text = JapaneseUtils.hiragana_to_romaji(furigana_part)
			(%FuriganaLabel as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			(%FuriganaLabel as Label).text = furigana_part
			(%FuriganaLabel as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if furigana_part.length() == 1 else HORIZONTAL_ALIGNMENT_FILL
		(%KanjiGroup as Control).visible = true
	else:
		(%KanjiGroup as Control).visible = false

	_update_furigana()

func _on_slot_filled() -> void:
	slot_filled.emit()

func get_aspect_slots() -> Array[AspectSlot]:
	var result: Array[AspectSlot]
	for kanji_slot in _kanji_slots:
		result.append(kanji_slot.get_aspect_slot())
	return result

func get_kanji_slots() -> Array[KanjiSlot]:
	return _kanji_slots.duplicate()

func _make_tooltip_text() -> String:
	return (tr('[center]<header_font_size>Vocabulary: [/font_size]<jp_font_size>%s[/font_size][/center]\n\n') % vocab.japanese
		+ tr('[b]Reading:[/b] %s') % ', '.join(vocab.readings)
		+ tr('\n[b]Meaning:[/b] %s') % ', '.join(vocab.meanings.slice(0,20).map(tr)))

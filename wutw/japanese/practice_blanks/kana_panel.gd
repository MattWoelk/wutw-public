@tool
class_name KanaPanel
extends UkiyoePanelContainer

const KANA_BASICS := '''
あ,い,う,え,お
か,き,く,け,こ
さ,し,す,せ,そ
た,ち,つ,て,と
な,に,ぬ,ね,の
は,ひ,ふ,へ,ほ
ま,み,む,め,も
や,,ゆ,,よ
ら,り,る,れ,ろ
わ,,,,を
,ん,,っ,
'''
const KANA_VOICED := '''
,,,,
が,ぎ,ぐ,げ,ご
ざ,じ,ず,ぜ,ぞ
だ,ぢ,づ,で,ど
,,,,
ば,び,ぶ,べ,ぼ
ぱ,ぴ,ぷ,ぺ,ぽ
,,,,
,,,,
,,,,
,,,,
'''
const KANA_COMBOS := '''
きゃ,,きゅ,,きょ
ぎゃ,,ぎゅ,,ぎょ
しゃ,,しゅ,,しょ
じゃ,,じゅ,,じょ
ちゃ,,ちゅ,,ちょ
にゃ,,にゅ,,にょ
ひゃ,,ひゅ,,ひょ
みゃ,,みゅ,,みょ
りゃ,,りゅ,,りょ
びゃ,,びゅ,,びょ
ぴゃ,,ぴゅ,,ぴょ
'''

const MINIMIZED_SIZE := 85

@export var title: String
@export var tooltip: String
@export var is_katakana := false

var _minimized := true

func _ready() -> void:
	super._ready()
	(%TitleLabel as Label).text = title
	GlobalTooltipSystem.attach(self, func() -> String: return tooltip,
		[Tooltip.RelativeDirection.ABOVE, Tooltip.RelativeDirection.RIGHT],
		[Tooltip.Alignment.CENTERED])
	_fill_grid(KANA_BASICS, %Grid_Basics as Container)
	_fill_grid(KANA_VOICED, %Grid_Voiced as Container)
	_fill_grid(KANA_COMBOS, %Grid_Combos as Container)
	(%TabBar as Control).visible = false
	(%Panel_Contents as Control).visible = false
	custom_maximum_size.y = MINIMIZED_SIZE

func _fill_grid(content: String, grid: Container) -> void:
	Utils.clear_node(grid)
	for line in content.strip_edges().split('\n'):
		for hiragana in line.split(','):
			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
			label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN | Control.SIZE_EXPAND
			label.add_theme_constant_override('line_spacing', -6)
			if hiragana:
				var kana := JapaneseUtils.hiragana_to_katakana(hiragana) if is_katakana else hiragana
				var romaji := tr('double') if hiragana == 'っ' else JapaneseUtils.hiragana_to_romaji(hiragana)
				label.text = kana + '\n' + romaji
			else:
				label.text = 'あ\na'  # To force matching size.
				label.modulate.a = 0
			grid.add_child(label)

func _on_tab_button_basic_pressed() -> void:
	(%Grid_Basics as Control).visible = true
	(%Grid_Voiced as Control).visible = false
	(%Grid_Combos as Control).visible = false

func _on_tab_button_voiced_pressed() -> void:
	(%Grid_Basics as Control).visible = false
	(%Grid_Voiced as Control).visible = true
	(%Grid_Combos as Control).visible = false

func _on_tab_button_combo_pressed() -> void:
	(%Grid_Basics as Control).visible = false
	(%Grid_Voiced as Control).visible = false
	(%Grid_Combos as Control).visible = true

func animate_show() -> void:
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 1.0, 0.5)
	tween.play()

func animate_hide() -> void:
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0.0, 0.5)
	tween.play()

func _on_minimize_button_pressed() -> void:
	var tween := create_tween()
	if _minimized:
		tween.tween_property(self, 'custom_maximum_size:y', 150, 0.2)
		tween.tween_callback(func() -> void:
			(%TabBar as Control).visible = true
			(%Panel_Contents as Control).visible = true
			(%MinimizeButton as Button).icon = load(
				'res://events/system/scenes/minimize_arrow_up.png')
		)
		tween.tween_property(self, 'custom_maximum_size:y', 900, 0.8)
	else:
		tween.tween_property(self, 'custom_maximum_size:y', 150, 0.8)
		tween.tween_callback(func() -> void:
			(%TabBar as Control).visible = false
			(%Panel_Contents as Control).visible = false
			(%MinimizeButton as Button).icon = load(
				'res://events/system/scenes/minimize_arrow_down.png')
		)
		tween.tween_property(self, 'custom_maximum_size:y', MINIMIZED_SIZE, 0.2)
	tween.set_speed_scale(Utils.anim_speed())
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	tween.play()
	await tween.finished
	_minimized = not _minimized
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED

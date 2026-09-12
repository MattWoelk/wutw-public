@tool
class_name MuseumDetail_Dialogue
extends Control

@export var dialogue: Dialogue:
	set(value):
		if dialogue == value:
			return
		dialogue = value
		if is_node_ready():
			_recreate()

var _pages: Array[Dialogue.Page]
var _current_page: int = 0

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_recreate()

func _update_font_size() -> void:
	Utils._scale_font_size(%RichText as RichTextLabel, false, 18)

func _recreate() -> void:
	if not dialogue:
		return
	(%TitleLabel as Label).text = tr(dialogue.record_title)
	_pages = dialogue.get_pages()
	_current_page = 0
	_update_page()

func _on_button_prev_pressed() -> void:
	_current_page = clamp(_current_page - 1, 0, _pages.size() - 1)
	_update_page()

func _on_button_next_pressed() -> void:
	_current_page = clamp(_current_page + 1, 0, _pages.size() - 1)
	_update_page()

func _update_page() -> void:
	_show_page(_pages[_current_page])
	(%PageLabel as Label).text = tr('Page %d of %d') % [_current_page + 1, _pages.size()]
	(%PageLabel as Label).visible = _pages.size() > 1
	(%Button_Prev as Button).visible = _current_page > 0
	(%Button_Next as Button).visible = _current_page < _pages.size() - 1
	(%ScrollContainer as FadedScrollContainer).scroll_vertical = 0

func _show_page(page: Dialogue.Page) -> void:
	var portrait1 := %PortraitDisplay1 as DialoguePortraitDisplay
	var portrait2 := %PortraitDisplay2 as DialoguePortraitDisplay
	portrait1.modulate.a = 0
	portrait2.modulate.a = 0
	if page.characters.size() > 0:
		portrait1.modulate.a = 1
		portrait1.character = page.characters[0]
		if page.characters.size() > 1:
			portrait2.modulate.a = 1
			portrait2.character = page.characters[1]
			# Ignore additional characters.

	var page_text: String = ''
	var current_character: Character = null
	for line in page.lines:
		if line.character != current_character:
			page_text += '[b][font_size=%d]%s[/font_size][/b]\n' % [
				roundi(22 * GameSettings.Interface.paragraph_font_scale.value()),
				tr(line.character.character_name)]
		page_text += line.text
		page_text += '\n\n'
		current_character = line.character
	(%RichText as RichTextLabel).text = page_text.strip_edges()

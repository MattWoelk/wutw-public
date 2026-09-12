class_name Dialogue
extends Resource

static var _group_loader := AsyncLoadedGroup.new('res://dialogue/resourcegroup_dialogues.tres')
static var _all_dialogues: Dictionary[String, Dialogue]

@export var dialogue_id: String
@export var record_title: String
@export_multiline var text: String

static func get_all_dialogues() -> Dictionary[String, Dialogue]:
	if not _all_dialogues:
		for dialogue: Dialogue in _group_loader.get_loaded():
			assert(dialogue.dialogue_id)
			if dialogue.dialogue_id in _all_dialogues:
				push_error('Duplicate dialogue ID "%s":\n- %s\n- %s' %
						[dialogue.dialogue_id, dialogue.resource_path, _all_dialogues[dialogue.dialogue_id].resource_path])
			_all_dialogues[dialogue.dialogue_id] = dialogue
	return _all_dialogues

static func get_dialogue_by_id(id: String) -> Dialogue:
	return get_all_dialogues().get(id)

func get_pages() -> Array[Page]:
	var pages: Array[Page]
	var current_page: Page = null
	for raw_line in tr(text).split('\n'):
		raw_line = raw_line.strip_edges()
		if not raw_line:
			continue
		if raw_line.begins_with('PAGE:'):
			if current_page:
				if not Utils.ensure(not current_page.lines.is_empty()):
					continue
				pages.append(current_page)
			current_page = Page.new()
			if not Utils.ensure(current_page.characters.is_empty()):
				continue
			for raw_character_spec in raw_line.right(-5).strip_edges().split(','):
				var character_id: String = ''
				var socket_id: String = ''
				if '(' in raw_character_spec:
					character_id = raw_character_spec.split('(')[0].strip_edges()
					socket_id = raw_character_spec.split('(')[1].strip_edges().left(-1)
				else:
					character_id = raw_character_spec.strip_edges()
					if character_id == 'AUDIENCE':
						current_page.show_audience = true
						continue
					push_warning('No character socket specified in dialogue: ' + dialogue_id)
				var character := Character.get_character_by_id(character_id)
				if Utils.ensure(character != null):
					current_page.characters.append(character)
				if socket_id and socket_id != 'NONE':  # None for non-hub dialogues.
					if Utils.ensure(socket_id in HubCharacterSpec.Socket):
						current_page.character_sockets[character] = HubCharacterSpec.Socket[socket_id]
		else:
			Utils.ensure(not current_page.characters.is_empty())
			var parts := raw_line.split(':', false, 1)
			var character_id := parts[0].strip_edges()
			var character := Character.get_character_by_id(character_id)
			Utils.ensure(character != null)
			var line := Line.new()
			line.character = character
			line.text = parts[1].strip_edges()
			current_page.lines.append(line)
	if current_page:
		if Utils.ensure(not current_page.lines.is_empty()):
			pages.append(current_page)
	Utils.ensure(not pages.is_empty())
	return pages

class Page extends RefCounted:
	var characters: Array[Character]
	var lines: Array[Line]
	var character_sockets: Dictionary[Character, HubCharacterSpec.Socket]
	var show_audience: bool = false

class Line extends RefCounted:
	var character: Character
	var text: String  # Already translated.

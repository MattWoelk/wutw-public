class_name SettlerQuestDescription
extends VBoxContainer

var hub_character: HubCharacter:
	set(value):
		hub_character = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_update()

func _update_font_size() -> void:
	Utils._scale_font_size(%SpeechLabel as RichTextLabel, false, 16)
	Utils._scale_font_size(%ReportLabel as RichTextLabel, false, 16)
	Utils._scale_font_size(%NoteLabel as RichTextLabel, false, 16)

func _update() -> void:
	if not hub_character:
		return
	var quest := hub_character.offered_quest
	if not Utils.ensure(quest != null):
		return

	(%TitleLabel as Label).text = tr('Settler Quest: ') + tr(quest.name)

	var job_name := tr(hub_character.job.job_name)
	if hub_character.character.gender == HubCharacterSpec.Gender.FEMALE and hub_character.job.female_job_name_override:
		job_name = tr(hub_character.job.female_job_name_override)
	(%NameLabel as Label).text = tr(hub_character.first_name) + tr(', ') + tr(job_name)
	(%SpeechLabel as MarkedUpLabel).set_markedup_text(
		tr(quest.intro_text), MarkedUpLabel.LinkMode.NONE)

	(%CharacterImage as TextureRect).texture = hub_character.get_character_sprite()
	(%CharacterImage as TextureRect).flip_h = hub_character.character.facing_direction in [
		HubCharacterSpec.Direction.WEST, HubCharacterSpec.Direction.NORTH]

	var pieces: Array[String]
	if quest.challenges.size() == 1:
		pieces.append(tr('[b]Difficulty Modifier[/b]: ') + quest.challenges[0].describe())
	else:
		pieces.append(tr('[b]Difficulty Modifier[/b]:[ul]'))
		for challenge in quest.challenges:
			pieces.append(challenge.describe())
		pieces.append('[/ul]')
	#pieces.append('')

	var goals := quest.get_decorated_goals()
	if goals.size() == 1:
		pieces.append(tr('[b]Task[/b]: ') + goals[0])
	else:
		pieces.append(tr('[b]Tasks[/b]:[ul]'))
		pieces.append_array(goals)
		pieces.append('[/ul]')
	#pieces.append('')

	if quest.rewards.size() == 1:
		pieces.append(tr('[b]Reward[/b]: ') + quest.rewards[0].describe())
	else:
		pieces.append(tr('[b]Rewards[/b]:[ul]'))
		for reward in quest.rewards:
			pieces.append(reward.describe())
		pieces.append('[/ul]')
	(%ReportLabel as MarkedUpLabel).set_markedup_text('\n'.join(pieces), MarkedUpLabel.LinkMode.LINK)

	var note_text := tr('[i]Settler quests last for one <term_lower:run> and increase total <term_lower:insight> rewards by %d%% per quest.[/i]') % Quest_Settler.INSIGHT_BONUS_PERCENT
	note_text += '\n'
	note_text += tr('[i]Difficulty modifiers last for the whole <term_lower:run>.[/i]')
	var num_currently_accepted := _get_num_currently_accepted()
	var currently_accepted := str(num_currently_accepted) if num_currently_accepted else tr('none', 'NO_QUESTS')
	note_text += '\n'
	note_text += tr('[i]You can accept up to %d settler quests at a time. You have currently accepted %s.[/i]') % [_get_max_quests(), currently_accepted]
	(%NoteLabel as MarkedUpLabel).set_markedup_text(note_text, MarkedUpLabel.LinkMode.LINK)

func can_accept_more_quests() -> bool:
	return _get_num_currently_accepted() < _get_max_quests()

func _get_max_quests() -> int:
	return Quest_Settler.BASE_MAX_QUESTS + Skill.get_skill_var(Skill.Var.MAX_SETTLER_QUESTS)

func _get_num_currently_accepted() -> int:
	var num_currently_accepted := 0
	for quest_instance in GlobalSaveGame.get_all_quest_instances():
		if quest_instance.is_active() and quest_instance.get_quest() is Quest_Settler:
			num_currently_accepted += 1
	return num_currently_accepted

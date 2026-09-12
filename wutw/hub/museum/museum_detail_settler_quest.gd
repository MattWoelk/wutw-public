@tool
class_name MuseumDetail_SettlerQuest
extends Control

@export var quest: Quest_Settler:
	set(value):
		if quest == value:
			return
		quest = value
		if is_node_ready():
			_recreate()

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_recreate()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainText as RichTextLabel, false, 18)

func _recreate() -> void:
	if not quest:
		return

	if Utils.is_in_editor() or GlobalSaveGame.has_seen_settler_quest(quest):
		(%TitleLabel as Label).text = tr(quest.name)
		(%MainText as MarkedUpLabel).set_markedup_text(_get_full_description(), MarkedUpLabel.LinkMode.LINK)
	else:
		(%TitleLabel as Label).text = tr('???')
		(%MainText as MarkedUpLabel).set_markedup_text(
			tr('Look for settlers in the <term:hub> who might offer this quest!'), MarkedUpLabel.LinkMode.LINK)

func _get_full_description() -> String:
	var pieces: Array[String]
	pieces.append(tr(quest.intro_text))
	pieces.append('')

	if quest.challenges.size() == 1:
		pieces.append(tr('[b]Difficulty Modifier[/b]: ') + quest.challenges[0].describe())
	else:
		pieces.append(tr('[b]Difficulty Modifiers[/b]:[ul]'))
		for challenge in quest.challenges:
			pieces.append(challenge.describe())
		pieces.append('[/ul]')

	var goals := quest.get_decorated_goals()
	if goals.size() == 1:
		pieces.append(tr('[b]Task[/b]: ') + goals[0])
	else:
		pieces.append(tr('[b]Tasks[/b]:[ul]'))
		pieces.append_array(goals)
		pieces.append('[/ul]')

	if quest.rewards.size() == 1:
		pieces.append(tr('[b]Reward[/b]: ') + quest.rewards[0].describe())
	else:
		pieces.append(tr('[b]Rewards[/b]:[ul]'))
		for reward in quest.rewards:
			pieces.append(reward.describe())
		pieces.append('[/ul]')
	pieces.append('')

	pieces.append(tr('[i]Difficulty modifiers persist until the end of the <term_lower:run>.[/i]'))
	pieces.append(tr('[i]Settler quests last for one <term_lower:run> and increase total <term_lower:insight> rewards by %d%% per quest.[/i]') % Quest_Settler.INSIGHT_BONUS_PERCENT)
	pieces.append('')

	if GlobalSaveGame.has_completed_settler_quest(quest):
		pieces.append(tr('You have already completed this quest at least once.'))
	else:
		pieces.append(tr('[b]You have never completed this quest before.[/b]'))

	return '\n'.join(pieces)

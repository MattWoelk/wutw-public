class_name SettlerChallengesList
extends PanelContainer

func _ready() -> void:
	var challenges: Array[String]
	for instance in GlobalSaveGame.get_all_quest_instances():
		var quest := instance.get_quest()
		if quest is Quest_Settler:
			for challenge in (quest as Quest_Settler).challenges:
				challenges.append(challenge.describe())
	if challenges:
		(%MarkedUpLabel as MarkedUpLabel).set_markedup_text('\n'.join(challenges))
		await get_tree().process_frame
		(%ScrollContainer as ScrollContainer).custom_minimum_size.y = minf(
			(%ScrollContainer as ScrollContainer).custom_minimum_size.y,
			(%MarkedUpLabel as MarkedUpLabel).size.y + 5)
		visible = true
	else:
		visible = false

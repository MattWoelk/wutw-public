class_name HubShrine
extends HubFacility

func _ready() -> void:
	super._ready()

	_update_new_badge()
	GlobalSaveGame.changed.connect(_update_new_badge)
	clicked.connect(func() -> void:
		(%NewSkillsLabel as Label).visible = false
	)

func _update_new_badge() -> void:
	var any_new_skills := false
	for skill: Skill in Skill.get_all_skills().values():
		if skill.is_revealed() and not GlobalSaveGame.has_seen_skill(skill):
			any_new_skills = true
			break
	(%NewSkillsLabel as Label).visible = any_new_skills

func _make_tooltip_text() -> String:
	var result := tr(tooltip_text)
	if (%NewSkillsLabel as Label).visible:
		result += '\n\n' + tr('[b]New skills are currently available![/b]')
	return result

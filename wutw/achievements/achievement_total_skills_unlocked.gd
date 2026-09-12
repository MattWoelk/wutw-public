class_name Achievement_TotalSkillsUnlocked
extends Achievement

func start_listening() -> void:
	GlobalSaveGame.skill_unlocked.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.skill_unlocked.disconnect(check)

func check() -> void:
	var num_unlocked := 0
	for skill in GlobalSaveGame.get_unlocked_skills():
		if skill.requirement:  # Not a fake root skill.
			num_unlocked += 1
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(num_unlocked)
	# Achievement unlocked automatically based on stat range.

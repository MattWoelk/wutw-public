@tool
class_name EventRequirement_MainQuestProgress
extends EventRequirement

@export var min_progress: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.P000_INTRO
@export var max_progress: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.NEVER_REACHED

func is_satisfied(_run: Run, _event: Event) -> bool:
	var progress := GlobalSaveGame.get_main_quest_progress()
	if min_progress >= 0 and progress < min_progress:
		return false
	if max_progress >= 0 and progress > max_progress:
		return false
	return true

func to_expression() -> String:
	var result := 'main_quest('
	result += str(min_progress)
	result += ', '
	result += str(max_progress)
	result += ')'
	return result

func describe(_run: Run, _detailed: bool) -> String:
	return ''

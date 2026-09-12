@tool
class_name EditorGameStartup
extends Control

const CONFIG_PATH := 'res://addons/wutw_editor/editor_game_startup_config.tres'

var _states: Array[Main.State] = []
var _main_quest_states: Array[SaveGame.MainQuestProgress] = []
var _companions: Array[Companion] = []
var _quests: Array[Quest] = []
@export var _templates: Array[EditorGameStartupConfig] = []

func _ready() -> void:
	(%DropDown_State as OptionButton).clear()
	_states.clear()
	for state_name in Main.State:
		(%DropDown_State as OptionButton).add_item(state_name, Main.State[state_name])
		_states.append(Main.State[state_name])

	(%DropDown_MainQuest as OptionButton).clear()
	_main_quest_states.clear()
	for state_name in SaveGame.MainQuestProgress:
		(%DropDown_MainQuest as OptionButton).add_item(state_name, SaveGame.MainQuestProgress[state_name])
		_main_quest_states.append(SaveGame.MainQuestProgress[state_name])

	(%DropDown_Companion as OptionButton).clear()
	_companions.clear()
	for companion in Companion.get_all_companions():
		(%DropDown_Companion as OptionButton).add_item(companion.companion_name)
		_companions.append(companion)

	Utils.clear_node(%VBox_Skills)
	for skill_id in Skill.get_all_skills():
		var skill_checkbox := CheckBox.new()
		skill_checkbox.text = skill_id
		skill_checkbox.pressed.connect(_on_ui_changed)
		%VBox_Skills.add_child(skill_checkbox)

	(%DropDown_StartingQuest as OptionButton).clear()
	(%DropDown_StartingQuest as OptionButton).add_item('-----')
	_quests.clear()
	_quests.append(null)
	for quest: Quest in Quest.get_all_quests().values():
		(%DropDown_StartingQuest as OptionButton).add_item(quest.quest_id)
		_quests.append(quest)

	%DropDown_LoadTemplate.clear()
	%DropDown_LoadTemplate.add_item('Load template...')
	for template: EditorGameStartupConfig in _templates:
		%DropDown_LoadTemplate.add_item(
			template.resource_path.split('editor_game_startup_template_')[1].replace('.tres', '').capitalize())

	if FileAccess.file_exists(CONFIG_PATH):
		var config := load(CONFIG_PATH) as EditorGameStartupConfig
		_apply_from_file(config)
	else:
		_on_button_reset_pressed()
	_update_ui()

func _apply_from_file(config: EditorGameStartupConfig) -> void:
	(%CheckBox_Load as CheckBox).button_pressed = config.load_savegame
	(%DropDown_State as OptionButton).selected = _states.find(config.start_state)
	(%CheckBox_TempSave as CheckBox).button_pressed = config.use_temporary_savegame
	(%CheckBox_MainQuest as CheckBox).button_pressed = config.main_quest_state >= 0
	if config.main_quest_state >= 0:
		(%DropDown_MainQuest as OptionButton).selected = _main_quest_states.find(config.main_quest_state)
	(%CheckBox_StagesPerSeason as CheckBox).button_pressed = config.stages_per_season >= 0
	if config.stages_per_season >= 0:
		(%Slider_StagesPerSeason as HSlider).value = config.stages_per_season
	(%CheckBox_StagesBeforeSurvey as CheckBox).button_pressed = config.stages_before_survey >= 0
	if config.stages_before_survey >= 0:
		(%Slider_StagesBeforeSurvey as HSlider).value = config.stages_before_survey
	(%CheckBox_HauntingChance as CheckBox).button_pressed = config.haunting_probability >= 0
	if config.haunting_probability >= 0:
		(%Slider_HauntingChance as HSlider).value = config.haunting_probability
	(%CheckBox_Companion as CheckBox).button_pressed = config.companion != null
	if config.companion:
		(%DropDown_Companion as OptionButton).selected = _companions.find(config.companion)
	(%CheckBox_RunSeed as CheckBox).button_pressed = config.run_seed >= 0
	if config.run_seed >= 0:
		(%SpinBox_RunSeed as SpinBox).value = config.run_seed
	(%CheckBox_MapSeed as CheckBox).button_pressed = config.map_seed >= 0
	if config.map_seed >= 0:
		(%SpinBox_MapSeed as SpinBox).value = config.map_seed
	(%CheckBox_Skills as CheckBox).button_pressed = config.custom_skills
	for checkbox: CheckBox in %VBox_Skills.get_children():
		checkbox.button_pressed = Skill.get_skill_by_id(checkbox.text) in config.skills
	(%CheckBox_StartingQuest as CheckBox).button_pressed = config.starting_quest != null
	(%DropDown_StartingQuest as OptionButton).selected = _quests.find(config.starting_quest)
	(%CheckBox_StartingQuestActive as CheckBox).button_pressed = config.starting_quest_active
	(%CheckBox_MuseumUnlocks as CheckBox).button_pressed = config.full_museum_unlocks

func _save_to_file() -> void:
	await get_tree().process_frame  # Debounce.
	var config := EditorGameStartupConfig.new()

	config.load_savegame = (%CheckBox_Load as CheckBox).button_pressed
	config.use_temporary_savegame = (%CheckBox_TempSave as CheckBox).button_pressed
	config.start_state = _states[(%DropDown_State as OptionButton).selected]

	if (%CheckBox_MainQuest as CheckBox).button_pressed:
		config.main_quest_state = _main_quest_states[(%DropDown_MainQuest as OptionButton).selected]
	else:
		config.main_quest_state = -1

	if (%CheckBox_StagesPerSeason as CheckBox).button_pressed:
		config.stages_per_season = (%Slider_StagesPerSeason as HSlider).value
	else:
		config.stages_per_season = -1

	if (%CheckBox_StagesBeforeSurvey as CheckBox).button_pressed:
		config.stages_before_survey = (%Slider_StagesBeforeSurvey as HSlider).value
	else:
		config.stages_before_survey = -1

	if (%CheckBox_HauntingChance as CheckBox).button_pressed:
		config.haunting_probability = (%Slider_HauntingChance as HSlider).value
	else:
		config.haunting_probability = -1

	if (%CheckBox_Companion as CheckBox).button_pressed:
		config.companion = _companions[(%DropDown_Companion as OptionButton).selected]
	else:
		config.companion = null

	if (%CheckBox_RunSeed as CheckBox).button_pressed:
		config.run_seed = (%SpinBox_RunSeed as SpinBox).value
	else:
		config.run_seed = -1

	if (%CheckBox_MapSeed as CheckBox).button_pressed:
		config.map_seed = (%SpinBox_MapSeed as SpinBox).value
	else:
		config.map_seed = -1

	config.custom_skills = (%CheckBox_Skills as CheckBox).button_pressed
	config.skills = []
	for checkbox: CheckBox in %VBox_Skills.get_children():
		if checkbox.button_pressed:
			config.skills.append(Skill.get_skill_by_id(checkbox.text))

	if (%CheckBox_StartingQuest as CheckBox).button_pressed:
		config.starting_quest = _quests[(%DropDown_StartingQuest as OptionButton).selected]
		config.starting_quest_active = (%CheckBox_StartingQuestActive as CheckBox).button_pressed
	else:
		config.starting_quest = null

	config.full_museum_unlocks = (%CheckBox_MuseumUnlocks as CheckBox).button_pressed

	if ResourceSaver.save(config, CONFIG_PATH) != OK:
		push_warning('Failed to save WutW startup config.')

func _update_ui() -> void:
	(%DropDown_MainQuest as OptionButton).disabled = not (%CheckBox_MainQuest as CheckBox).button_pressed
	(%Slider_StagesPerSeason as HSlider).editable = (%CheckBox_StagesPerSeason as CheckBox).button_pressed
	(%Slider_StagesBeforeSurvey as HSlider).editable = (%CheckBox_StagesBeforeSurvey as CheckBox).button_pressed
	(%Slider_HauntingChance as HSlider).editable = (%CheckBox_HauntingChance as CheckBox).button_pressed
	(%DropDown_Companion as OptionButton).disabled = not (%CheckBox_Companion as CheckBox).button_pressed
	(%SpinBox_RunSeed as SpinBox).editable = (%CheckBox_RunSeed as CheckBox).button_pressed
	(%SpinBox_MapSeed as SpinBox).editable = (%CheckBox_MapSeed as CheckBox).button_pressed
	(%DropDown_StartingQuest as OptionButton).disabled = not (%CheckBox_StartingQuest as CheckBox).button_pressed
	(%CheckBox_StartingQuestActive as CheckBox).disabled = not (%CheckBox_StartingQuest as CheckBox).button_pressed
	for checkbox: CheckBox in %VBox_Skills.get_children():
		checkbox.disabled = not (%CheckBox_Skills as CheckBox).button_pressed

	for child in get_children():
		child.visible = true
	if %CheckBox_Load.button_pressed:
		for i in range(6, get_child_count()):
			get_child(i).visible = false
	else:
		for i in range(8, get_child_count()):
			get_child(i).visible = _states[(%DropDown_State as OptionButton).selected] != Main.State.MAIN_MENU
		if _states[(%DropDown_State as OptionButton).selected] != Main.State.RUN:
			%Label_StagesPerSeason.visible = false
			%HBox_StagesPerSeason.visible = false
			%Label_StagesBeforeSurvey.visible = false
			%HBox_StagesBeforeSurvey.visible = false
			%Label_HauntingChance.visible = false
			%HBox_HauntingChance.visible = false
			%Label_Companion.visible = false
			%HBox_Companion.visible = false
			%Label_RunSeed.visible = false
			%HBox_RunSeed.visible = false
			%Label_MapSeed.visible = false
			%HBox_MapSeed.visible = false

func _on_ui_changed() -> void:
	_update_ui()
	_save_to_file()

func _on_item_selected(_index: int) -> void:
	_on_ui_changed()

func _on_value_changed(_value: float) -> void:
	_on_ui_changed()

func _on_button_reset_pressed() -> void:
	var config := EditorGameStartupConfig.new()
	config.load_savegame = false
	config.use_temporary_savegame = false
	config.start_state = Main.State.MAIN_MENU
	config.main_quest_state = -1
	config.stages_per_season = -1
	config.haunting_probability = -1
	config.companion = null
	config.run_seed = -1
	config.map_seed = 8962
	config.custom_skills = false
	config.skills.clear()
	config.starting_quest = null
	config.starting_quest_active = false
	config.full_museum_unlocks = false
	_update_ui()
	_apply_from_file(config)
	_save_to_file()

func _on_drop_down_load_template_item_selected(index: int) -> void:
	if index == 0:
		return
	_apply_from_file(_templates[index - 1])
	_update_ui()
	_save_to_file()
	%DropDown_LoadTemplate.selected = 0

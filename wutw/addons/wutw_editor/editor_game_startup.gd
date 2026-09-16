@tool
class_name EditorGameStartup
extends Control

const CONFIG_PATH := 'res://addons/wutw_editor/editor_game_startup_config.tres'

var _states: Array[Main.State] = []
var _main_quest_states: Array[SaveGame.MainQuestProgress] = []
var _companions: Array[Companion] = []
var _quests: Array[Quest] = []
@export var _templates: Array[EditorGameStartupConfig] = []

@onready var drop_down_main_quest: OptionButton = %DropDown_MainQuest
@onready var drop_down_state: OptionButton = %DropDown_State
@onready var drop_down_companion: OptionButton = %DropDown_Companion
@onready var drop_down_starting_quest: OptionButton = %DropDown_StartingQuest
@onready var drop_down_load_template: OptionButton = %DropDown_LoadTemplate

@onready var check_box_run_seed: CheckBox = %CheckBox_RunSeed
@onready var slider_stages_per_season: HSlider = %Slider_StagesPerSeason
@onready var check_box_stages_per_season: CheckBox = %CheckBox_StagesPerSeason
@onready var check_box_temp_save: CheckBox = %CheckBox_TempSave
@onready var check_box_load: CheckBox = %CheckBox_Load

func _ready() -> void:
	drop_down_state.clear()
	_states.clear()
	for state_name in Main.State:
		drop_down_state.add_item(state_name, Main.State[state_name])
		_states.append(Main.State[state_name])

	drop_down_main_quest.clear()
	_main_quest_states.clear()
	for state_name in SaveGame.MainQuestProgress:
		drop_down_main_quest.add_item(state_name, SaveGame.MainQuestProgress[state_name])
		_main_quest_states.append(SaveGame.MainQuestProgress[state_name])

	drop_down_companion.clear()
	_companions.clear()
	for companion in Companion.get_all_companions():
		drop_down_companion.add_item(companion.companion_name)
		_companions.append(companion)

	Utils.clear_node(%VBox_Skills)
	for skill_id in Skill.get_all_skills():
		var skill_checkbox := CheckBox.new()
		skill_checkbox.text = skill_id
		skill_checkbox.pressed.connect(_on_ui_changed)
		%VBox_Skills.add_child(skill_checkbox)

	drop_down_starting_quest.clear()
	drop_down_starting_quest.add_item('-----')
	_quests.clear()
	_quests.append(null)
	for quest: Quest in Quest.get_all_quests().values():
		drop_down_starting_quest.add_item(quest.quest_id)
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
	check_box_load.button_pressed = config.load_savegame
	drop_down_state.selected = _states.find(config.start_state)
	check_box_temp_save.button_pressed = config.use_temporary_savegame
	(%CheckBox_MainQuest as CheckBox).button_pressed = config.main_quest_state >= 0
	if config.main_quest_state >= 0:
		drop_down_main_quest.selected = _main_quest_states.find(config.main_quest_state)
	check_box_stages_per_season.button_pressed = config.stages_per_season >= 0
	if config.stages_per_season >= 0:
		slider_stages_per_season.value = config.stages_per_season
	(%CheckBox_StagesBeforeSurvey as CheckBox).button_pressed = config.stages_before_survey >= 0
	if config.stages_before_survey >= 0:
		(%Slider_StagesBeforeSurvey as HSlider).value = config.stages_before_survey
	(%CheckBox_HauntingChance as CheckBox).button_pressed = config.haunting_probability >= 0
	if config.haunting_probability >= 0:
		(%Slider_HauntingChance as HSlider).value = config.haunting_probability
	(%CheckBox_Companion as CheckBox).button_pressed = config.companion != null
	if config.companion:
		drop_down_companion.selected = _companions.find(config.companion)
	check_box_run_seed.button_pressed = config.run_seed >= 0
	if config.run_seed >= 0:
		(%SpinBox_RunSeed as SpinBox).value = config.run_seed
	(%CheckBox_MapSeed as CheckBox).button_pressed = config.map_seed >= 0
	if config.map_seed >= 0:
		(%SpinBox_MapSeed as SpinBox).value = config.map_seed
	(%CheckBox_Skills as CheckBox).button_pressed = config.custom_skills
	for checkbox: CheckBox in %VBox_Skills.get_children():
		checkbox.button_pressed = Skill.get_skill_by_id(checkbox.text) in config.skills
	(%CheckBox_StartingQuest as CheckBox).button_pressed = config.starting_quest != null
	drop_down_starting_quest.selected = _quests.find(config.starting_quest)
	(%CheckBox_StartingQuestActive as CheckBox).button_pressed = config.starting_quest_active
	(%CheckBox_MuseumUnlocks as CheckBox).button_pressed = config.full_museum_unlocks

func _save_to_file() -> void:
	await get_tree().process_frame  # Debounce.
	var config := EditorGameStartupConfig.new()

	config.load_savegame = check_box_load.button_pressed
	config.use_temporary_savegame = check_box_temp_save.button_pressed
	config.start_state = _states[drop_down_state.selected]

	if (%CheckBox_MainQuest as CheckBox).button_pressed:
		config.main_quest_state = _main_quest_states[drop_down_main_quest.selected]
	else:
		config.main_quest_state = -1

	if check_box_stages_per_season.button_pressed:
		config.stages_per_season = slider_stages_per_season.value
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
		config.companion = _companions[drop_down_companion.selected]
	else:
		config.companion = null

	if check_box_run_seed.button_pressed:
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
		config.starting_quest = _quests[drop_down_starting_quest.selected]
		config.starting_quest_active = (%CheckBox_StartingQuestActive as CheckBox).button_pressed
	else:
		config.starting_quest = null

	config.full_museum_unlocks = (%CheckBox_MuseumUnlocks as CheckBox).button_pressed

	if ResourceSaver.save(config, CONFIG_PATH) != OK:
		push_warning('Failed to save WutW startup config.')

func _update_ui() -> void:
	drop_down_main_quest.disabled = not (%CheckBox_MainQuest as CheckBox).button_pressed
	slider_stages_per_season.editable = check_box_stages_per_season.button_pressed
	(%Slider_StagesBeforeSurvey as HSlider).editable = (%CheckBox_StagesBeforeSurvey as CheckBox).button_pressed
	(%Slider_HauntingChance as HSlider).editable = (%CheckBox_HauntingChance as CheckBox).button_pressed
	drop_down_companion.disabled = not (%CheckBox_Companion as CheckBox).button_pressed
	(%SpinBox_RunSeed as SpinBox).editable = check_box_run_seed.button_pressed
	(%SpinBox_MapSeed as SpinBox).editable = (%CheckBox_MapSeed as CheckBox).button_pressed
	drop_down_starting_quest.disabled = not (%CheckBox_StartingQuest as CheckBox).button_pressed
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
			get_child(i).visible = _states[drop_down_state.selected] != Main.State.MAIN_MENU
		if _states[drop_down_state.selected] != Main.State.RUN:
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

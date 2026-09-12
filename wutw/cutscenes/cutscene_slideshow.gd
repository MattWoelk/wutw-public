class_name Cutscene_Slideshow
extends Node2D

signal finished

const CLICK_TO_ADVANCE_TUTORIAL_ID := 'click_to_advance_cutscene'

@export_multiline var texts: Array[String]
@export var voice_lines: Array[AudioStream]
@export var roll_sound: WwiseEvent
@export var roll_end_sound: WwiseEvent
@export var music_switch: WwiseSwitch
@export var initial_wait := 1.0
@export var main_quest_progress: SaveGame.MainQuestProgress
@export var started_quest: Quest

var preview_mode := false

@onready var _anim_player := %AnimationPlayer as AnimationPlayer
@onready var _audio_player := %AudioStreamPlayer as AudioStreamPlayer
var _cur_slide := 0
var _sfx_playing_id: int = 0
var _started := false
var _finished := false

func _ready() -> void:
	for child: Control in %Mask.get_children():
		child.visible = false
	(%Main as Control).visible = false
	(%Label as Label).text = ''

	await get_tree().create_timer(1.5).timeout  # Wait for fade in animation.

	# Setup initial state.
	_anim_player.play('roll')
	_anim_player.seek(0, true)
	_anim_player.stop(true)
	(%Main as Control).visible = true
	_audio_player.volume_linear = min(1.0, 2.0 * GlobalAudioSystem.get_master_volume() * GlobalAudioSystem.get_voice_volume())

	if Utils.ensure(music_switch != null):
		GlobalAudioSystem.switch_music(music_switch.id)
	else:
		GlobalAudioSystem.switch_music(AK.SWITCHES.MUSIC.SWITCH.INTRO)
	_show_next_slide(0)
	_started = true

	get_tree().create_timer(5).timeout.connect(func() -> void:
		if not GameSettings.SkipTutorials.is_skipped(CLICK_TO_ADVANCE_TUTORIAL_ID):
			var hint := get_node_or_null('%ClickHint_SteamDeck' if Utils.is_steam_deck() else '%ClickHintLabel') as Control
			if hint:
				hint.visible = true
	)

	# Allow Space/Enter to advanced slides.
	(%NextButton as Button).grab_focus.call_deferred(true)

func skip_cutscene() -> void:
	if not _finished:
		_cur_slide = texts.size() - 1
		await _show_next_slide(_cur_slide)
		_on_skip_button_pressed()

func _show_next_slide(index: int) -> void:
	_anim_player.speed_scale = 1

	_start_sfx()

	if index > 0:
		_audio_player.stop()
		(%Mask.get_child(index - 1) as Control).visible = true

		_anim_player.play('roll')
		await _anim_player.animation_finished
		_play_end_sfx()

	(%Mask.get_child(index) as Control).visible = true
	(%Label as Label).text = tr(texts[index])

	_anim_player.play_backwards('roll')
	await get_tree().create_timer(_anim_player.current_animation_length * 0.7).timeout

	_stop_sfx()

	_audio_player.stream = voice_lines[index]
	_audio_player.play()

	if OS.has_feature('movie'):
		if _audio_player.is_playing():
			await _audio_player.finished
		await get_tree().create_timer(1.0).timeout
		_on_skip_button_pressed()

func _start_sfx() -> void:
	if not Utils.is_in_editor():
		_stop_sfx()
		_sfx_playing_id = GlobalAudioSystem.start_loop(roll_sound.id)

func _stop_sfx() -> void:
	if _sfx_playing_id:
		GlobalAudioSystem.stop_loop(_sfx_playing_id)
		_sfx_playing_id = 0

func _play_end_sfx() -> void:
	GlobalAudioSystem.play(roll_end_sound.id)

func _on_skip_button_pressed() -> void:
	if not _anim_player.is_playing():
		_cur_slide += 1
		if _cur_slide < texts.size():
			_show_next_slide(_cur_slide)
		elif not _finished:
			_finished = true
			if preview_mode:
				finished.emit()
			elif OS.has_feature('movie'):
				_anim_player.play('roll')
				await _anim_player.animation_finished
				get_tree().quit()
			else:
				GlobalSaveGame.set_main_quest_progress(main_quest_progress)
				if started_quest:
					var quest_instance := started_quest.instantiate(QuestInstance.STATE_INACTIVE)
					GlobalSaveGame.add_quest_instance(quest_instance)
				GlobalSaveGame.save_game()
				finished.emit()

		GameSettings.SkipTutorials.set_skipped(CLICK_TO_ADVANCE_TUTORIAL_ID, true, true)
		var hint := get_node_or_null('%ClickHint_SteamDeck' if Utils.is_steam_deck() else '%ClickHintLabel') as Control
		if hint:
			hint.visible = false

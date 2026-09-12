@tool
class_name DevBarkImporter
extends Node2D

const BARKDB_FILE_PATH := 'res://dialogue/barks/bark_db.tres'
const JOB_FILE_PATH_TEMPLATE := 'res://characters/jobs/job_%s.tres'

@export_global_file var csv_file_path: String
@warning_ignore('unused_private_class_variable')
@export_tool_button('Import CSV')
var _import_csv_tool := _import_csv

enum Column {
	TEXT,
	CHARACTER,
	MIN_MAIN_QUEST,
	MAX_MAIN_QUEST,
	LIMIT_TO_ORIGINS,
	LIMIT_TO_JOBS,
	LIMIT_TO_SHARD_TYPE,
	LIMIT_TO_AGES,
	LIMIT_TO_SOCKETS,
	CUSTOM_REQUIREMENT,
	STATUS,
}

func _import_csv() -> void:
	var file := FileAccess.open(csv_file_path, FileAccess.READ)
	file.get_csv_line()  # Skip header.
	var barks: Array[Bark]
	while !file.eof_reached():
		var csv_row := file.get_csv_line()
		if not csv_row or not csv_row[Column.TEXT] or csv_row[Column.STATUS].to_upper() != 'CONFIRMED':
			continue
		var bark := Bark.new()

		bark.text = csv_row[Column.TEXT]

		var character_id := csv_row[Column.CHARACTER]
		if character_id != 'GENERIC':
			bark.specific_character = Character.get_character_by_id(character_id.to_lower())
			assert(bark.specific_character)

		bark.min_main_quest = SaveGame.MainQuestProgress[csv_row[Column.MIN_MAIN_QUEST]]
		bark.max_main_quest = SaveGame.MainQuestProgress[csv_row[Column.MAX_MAIN_QUEST]]

		var origin_limits := _split(csv_row, Column.LIMIT_TO_ORIGINS)
		if origin_limits:
			for origin_limit in origin_limits:
				bark.limit_to_origins |= 1 << HubCharacter.Origin[origin_limit]

		var job_limits := _split(csv_row, Column.LIMIT_TO_JOBS)
		if job_limits:
			for job_limit in job_limits:
				var job := load(JOB_FILE_PATH_TEMPLATE % job_limit) as Job
				assert(job)
				bark.limit_to_jobs.append(job)

		var shard_type_id := csv_row[Column.LIMIT_TO_SHARD_TYPE]
		if shard_type_id not in ['', '-']:
			bark.limit_to_shard_type = ShardType.get_shard_type_by_id(shard_type_id)
			assert(bark.limit_to_shard_type)

		var age_limits := _split(csv_row, Column.LIMIT_TO_AGES)
		bark.limit_to_ages = 0
		if age_limits:
			for age_limit in age_limits:
				bark.limit_to_ages |= 1 << HubCharacterSpec.Age[age_limit]

		var socket_limits := _split(csv_row, Column.LIMIT_TO_SOCKETS)
		if socket_limits:
			for socket_limit in socket_limits:
				bark.limit_to_sockets |= 1 << HubCharacterSpec.Socket[socket_limit]

		var custom_requirement := csv_row[Column.CUSTOM_REQUIREMENT]
		if custom_requirement:
			bark.custom_requirement = EventRequirementParser.parse(custom_requirement)
			assert(bark.custom_requirement)

		barks.append(bark)
	file.close()

	var barkdb := load(BARKDB_FILE_PATH) as BarkDB
	barkdb.barks = barks
	var save_result := ResourceSaver.save(barkdb, BARKDB_FILE_PATH)
	if save_result == OK:
		print('Imported %d barks.' % barks.size())
	else:
		push_error('Failed to save Bark DB')

func _split(csv_row: Array[String], column: Column) -> Array[String]:
	var result: Array[String]
	for s in csv_row[column].split(',', false):
		result.append(s.strip_edges())
	return result

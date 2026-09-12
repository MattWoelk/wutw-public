class_name BugReporter
extends Control

const REPORT_URL := 'http://worldsuponthewind.com/bugreport.php'
const MAX_LOG_LENGTH := 200_000

var _boundary: String
var _closing := false

func _ready() -> void:
	_boundary = '----GodotFormBoundary' + str(Time.get_ticks_msec())
	(%ScrollPanel as ScrollPanel).animate_unroll()

func _enter_tree() -> void:
	UI.register_zoomable(%ScrollPanel as ScrollPanel, 0.5, 0.6)

func _handle_esc() -> bool:
	if not _closing:
		_on_cancel_button_pressed()
	return true

func _close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled((%ScrollPanel as ScrollPanel), false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		queue_free()

func _on_cancel_button_pressed() -> void:
	_close()

func _on_confirm_button_pressed() -> void:
	(%ConfirmButton as Button).text = tr('Sending...')
	(%ConfirmButton as Button).disabled = true
	send_bug_report()

func send_bug_report() -> void:
	var body := PackedByteArray()

	var text_fields: Dictionary[String, String]
	text_fields['os'] = OS.get_name()
	text_fields['language'] = OS.get_locale_language()
	text_fields['is_demo'] = 'yes' if Utils.is_demo() else 'no'
	if Utils.is_dev():
		text_fields['build_tag'] = 'editor'
	else:
		var build_metadata := load(BuildMetadata.EXPORT_PATH) as BuildMetadata
		if build_metadata and build_metadata.git_commit_hash:
			text_fields['build_tag'] = build_metadata.git_tag
			text_fields['build_commit'] = build_metadata.git_commit_hash
		else:
			text_fields['build_tag'] = 'UNKNOWN'
	text_fields['description'] = (%TextEdit_Description as TextEdit).text
	text_fields['email'] = (%LineEdit_Email as LineEdit).text

	for key in text_fields:
		_append_string(body, '--' + _boundary + '\r\n')
		_append_string(body, 'Content-Disposition: form-data; name="%s"\r\n\r\n' % key)
		_append_string(body, text_fields[key] + '\r\n')

	_append_file(body, 'godot.log', _get_log_contents().to_utf8_buffer(), 'text/plain')
	_append_file(body, 'game_settings.ini', _get_settings_contents().to_utf8_buffer(), 'text/plain')

	if (%Button_Savegame as Button).button_pressed:
		_append_file(body, 'live_save.json', GlobalSaveGame.get_encoded_save_data().to_utf8_buffer(), 'text/json')
		_append_file(body, 'written_save.json', GlobalSaveGame.get_written_save_data().to_utf8_buffer(), 'text/json')

	if (%Button_Screenshot as Button).button_pressed:
		modulate.a = 0
		GlobalUI.get_layer(UI.Layer.PAUSE_MENU).modulate.a = 0
		await RenderingServer.frame_post_draw
		var screenshot := get_viewport().get_texture().get_image()
		var screenshot_data := screenshot.save_jpg_to_buffer()
		modulate.a = 1
		GlobalUI.get_layer(UI.Layer.PAUSE_MENU).modulate.a = 1
		_append_file(body, 'screenshot.jpg', screenshot_data, 'image/jpeg')

	_append_string(body, '--' + _boundary + '--\r\n')

	var headers := ['Content-Type: multipart/form-data; boundary=' + _boundary]
	var error := (%HTTPRequest as HTTPRequest).request_raw(REPORT_URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_warning('Failed to send bug report: %d' % error)

func _append_string(array: PackedByteArray, text: String) -> void:
	array.append_array(text.to_utf8_buffer())

func _append_file(array: PackedByteArray, file_name: String, data: PackedByteArray, mime_type: String) -> void:
	_append_string(array, '--' + _boundary + '\r\n')
	_append_string(array, 'Content-Disposition: form-data; name="%s"; filename="%s"\r\n' % [file_name, file_name])
	_append_string(array, 'Content-Type: %s\r\n\r\n' % mime_type)
	array.append_array(data)
	_append_string(array, '\r\n')

func _on_http_request_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != HTTPClient.RESPONSE_OK:
		push_warning('Server failed to receive bug report(%d): %s)' % [response_code, body.get_string_from_utf8()])
	_close()

func _on_button_screenshot_pressed() -> void:
	(%Button_Screenshot as Button).text = 'YES' if (%Button_Screenshot as Button).button_pressed else 'NO'

func _on_button_savegame_pressed() -> void:
	(%Button_Savegame as Button).text = 'YES' if (%Button_Savegame as Button).button_pressed else 'NO'

func _get_log_contents() -> String:
	var log_path: String = ProjectSettings.get_setting('debug/file_logging/log_path', 'user://logs/godot.log')
	if not FileAccess.file_exists(log_path):
		push_warning('Bug Reporter: Log file not found at %s' % log_path)
		return 'Log file not available.'
	var file := FileAccess.open(log_path, FileAccess.READ)
	if file:
		var log_content := file.get_as_text()
		if log_content.length() > MAX_LOG_LENGTH:
			log_content = log_content.left(MAX_LOG_LENGTH) + '...[TRUNCATED]...\n' + log_content.right(MAX_LOG_LENGTH)
		return log_content
	else:
		push_error('Bug Reporter: Failed to open log file. Error code: %s' % FileAccess.get_open_error())
		return 'Failed to read log data.'

func _get_settings_contents() -> String:
	var file := FileAccess.open('user://game_settings.ini', FileAccess.READ)
	if file:
		return file.get_as_text()
	else:
		push_error('Bug Reporter: Failed to open settings file. Error code: %s' % FileAccess.get_open_error())
		return 'Failed to read settings data.'

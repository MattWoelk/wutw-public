class_name DiscordButton
extends Button

const DISCORD_INVITE_URL := 'https://discord.gg/TEkakx6xDB'

func _ready() -> void:
	(%Label as Label).modulate.a = 0

func _pressed() -> void:
	OS.shell_open(DISCORD_INVITE_URL)

func _on_mouse_entered() -> void:
	(%Label as Label).modulate.a = 1
	modulate = Color(1.2, 1.2, 1.2, 1)

func _on_mouse_exited() -> void:
	(%Label as Label).modulate.a = 0
	modulate = Color(1.0, 1.0, 1.0, 1)

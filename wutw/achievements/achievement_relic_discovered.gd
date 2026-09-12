class_name Achievement_RelicDiscovered
extends Achievement

@export var relics: Array[Relic]

func start_listening() -> void:
	GlobalSaveGame.relic_discovered.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.relic_discovered.disconnect(check)

func check() -> void:
	if not relics:
		achieved.emit()
	else:
		for relic in relics:
			if GlobalSaveGame.has_seen_relic(relic):
				achieved.emit()
				break

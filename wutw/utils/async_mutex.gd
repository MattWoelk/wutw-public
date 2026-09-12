class_name AsyncMutex
extends RefCounted

signal unlocked

var _is_locked: bool = false

func lock() -> void:
	while _is_locked:
		await unlocked
	_is_locked = true

func unlock() -> void:
	if not _is_locked:
		push_warning('Attempted to unlock a mutex that is not locked.')
		return
	_is_locked = false
	unlocked.emit()

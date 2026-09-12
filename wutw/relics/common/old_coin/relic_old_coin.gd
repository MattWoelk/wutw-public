@tool
class_name Relic_OldCoin
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.shop_transacted.connect(_on_shop_transacted)

func on_removed() -> void:
	_run.signals.shop_transacted.disconnect(_on_shop_transacted)
	super.on_removed()

func _on_shop_transacted() -> void:
	# The actual effect is handled through var modifiers, but we should still emit a notification.
	triggered.emit()

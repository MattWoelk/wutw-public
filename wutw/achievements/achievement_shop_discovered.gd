class_name Achievement_ShopDiscovered
extends Achievement

@export var shop_type: ShopType

func start_listening() -> void:
	GlobalSaveGame.shop_discovered.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.shop_discovered.disconnect(check)

func check() -> void:
	if GlobalSaveGame.has_seen_shop(shop_type):
		achieved.emit()

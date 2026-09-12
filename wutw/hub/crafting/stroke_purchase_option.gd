@tool
class_name StrokePurchaseOption
extends VBoxContainer

@export var stroke: Stroke:
	set(value):
		stroke = value
		if is_node_ready():
			_update()
@export var cost: int = 10:
	set(value):
		cost = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update()
	GlobalSaveGame.changed.connect(_update)

func _update() -> void:
	(%StrokeDisplay as StrokeDisplay).stroke = stroke
	(%StrokeDisplay as StrokeDisplay).count = GlobalSaveGame.get_stroke_count(stroke)
	(%BuyButton as Button).text = str(cost)
	(%BuyButton as Button).disabled = GlobalSaveGame.insights < cost

func _on_buy_button_pressed() -> void:
	GlobalSaveGame.add_stroke(stroke, 1)
	GlobalSaveGame.insights -= cost
	GlobalSaveGame.save_game()

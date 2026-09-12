@tool
class_name Discovery_Shop
extends Control

@export var shop_type: ShopType:
	set(value):
		shop_type = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.ABOVE, Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.LEFT],
			[Tooltip.Alignment.CENTERED])

func _gui_input(input_event: InputEvent) -> void:
	var mouse_event := input_event as InputEventMouseButton
	if not mouse_event:
		return
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if Utils.is_museum_unlocked():
			MuseumBrowser.open_museum_entry(shop_type, UI.Layer.STATE_MENU_SUBMENU)

func _update() -> void:
	if not shop_type:
		return
	(%TitleLabel as Label).text = tr(shop_type.title)
	(%BG as TextureRect).texture = shop_type.background_texture

func _make_tooltip_text() -> String:
	var text := '[b]%s[/b]\n\n%s' % [tr(shop_type.title), shop_type.get_markedup_description()]
	if Utils.is_museum_unlocked():
		text += '\n\n'
		text += tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)
	return text

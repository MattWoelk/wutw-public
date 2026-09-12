class_name InputPrompts
extends Object

enum InputType {
	LEFT_CLICK,
	RIGHT_CLICK,
	MIDDLE_CLICK,
	CTRL,
	PAN,
	ZOOM,
	END_TURN,
	DRAW_STACK,
	DISCARD_STACK,
	QUESTS,
	MINIMIZE,
	SCROLL_SITES,
	ESCAPE,
}

const DECK_LABELS := {
	InputType.LEFT_CLICK: '[img width=1.5em height=1.5em]res://utils/input_icons/sd_rtrackpad_click_md.png[/img]',
	InputType.RIGHT_CLICK: '[img width=1.5em height=1.5em]res://utils/input_icons/sd_l2_md.png[/img]',
	InputType.MIDDLE_CLICK: '[img width=1.5em height=1.5em]res://utils/input_icons/sd_l4_md.png[/img]',
	InputType.CTRL: '[img width=1.5em height=1.5em]res://utils/input_icons/sd_r1_md.png[/img]',
	InputType.PAN: '[img width=1.5em height=1.5em]res://utils/input_icons/shared_lstick_md.png[/img]',
	InputType.ZOOM: '[img width=1.5em height=1.5em]res://utils/input_icons/sd_ltrackpad_md.png[/img]',
	InputType.END_TURN: '[img width=1.5em height=1.5em]res://utils/input_icons/shared_button_y_md.png[/img]',
	InputType.DRAW_STACK: '[img width=1.5em height=1.5em]res://utils/input_icons/shared_button_x_md.png[/img]',
	InputType.DISCARD_STACK: '[img width=1.5em height=1.5em]res://utils/input_icons/sd_r1_md.png[/img]+[img width=1.5em height=1.5em]res://utils/input_icons/shared_button_x_md.png[/img]',
	InputType.QUESTS: '[img width=1.5em height=1.5em]res://utils/input_icons/sd_r4_md.png[/img]',
	InputType.MINIMIZE: '[img width=1.5em height=1.5em]res://utils/input_icons/shared_button_x_md.png[/img]',
	InputType.SCROLL_SITES: '[img width=1.5em height=1.5em]res://utils/input_icons/shared_lstick_left_md.png[/img][img width=1.5em height=1.5em]res://utils/input_icons/shared_lstick_right_md.png[/img]',
	InputType.ESCAPE: '[img width=1.5em height=1.5em]res://utils/input_icons/shared_button_b_md.png[/img]',
}

static func get_input_markup(input_type: InputType) -> String:
	if Utils.is_steam_deck():
		return DECK_LABELS[input_type]
	else:
		if Utils.is_mac_os() and _get_mac_override(input_type):
			return '[b]' + _get_mac_override(input_type) + '[/b]'
		return '[b]' + _get_default_label(input_type) + '[/b]'

static func _get_default_label(type: InputType) -> String:
	match type:
		InputType.LEFT_CLICK: return Utils.TRANSLATION_DUMMY.tr('Click')
		InputType.RIGHT_CLICK: return Utils.TRANSLATION_DUMMY.tr('Right click')
		InputType.MIDDLE_CLICK: return Utils.TRANSLATION_DUMMY.tr('Middle click')
		InputType.CTRL: return Utils.TRANSLATION_DUMMY.tr('Ctrl')
		InputType.PAN: return Utils.TRANSLATION_DUMMY.tr('WASD or the right mouse button')
		InputType.ZOOM: return Utils.TRANSLATION_DUMMY.tr('mouse wheel')
		InputType.END_TURN: return Utils.TRANSLATION_DUMMY.tr('E')
		InputType.DRAW_STACK: return Utils.TRANSLATION_DUMMY.tr('Tab')
		InputType.DISCARD_STACK: return Utils.TRANSLATION_DUMMY.tr('Ctrl+Tab')
		InputType.QUESTS: return Utils.TRANSLATION_DUMMY.tr('Q')
		InputType.MINIMIZE: return Utils.TRANSLATION_DUMMY.tr('Tab')
		InputType.SCROLL_SITES: return Utils.TRANSLATION_DUMMY.tr('mouse wheel or A and D keys')
		InputType.ESCAPE: return Utils.TRANSLATION_DUMMY.tr('Escape')
		_:
			Utils.ensure(false)
			return ''

static func _get_mac_override(type: InputType) -> String:
	match type:
		InputType.MIDDLE_CLICK: return Utils.TRANSLATION_DUMMY.tr('Option-click')
		_:
			return ''

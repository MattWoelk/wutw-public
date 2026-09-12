extends Node2D

const STROKES := [
	[
		Vector2(106.0, 41.0),
		Vector2(103.889, 42.38624),
		Vector2(101.8667, 44.21587),
		Vector2(99.16001, 46.16476),
		Vector2(96.94801, 47.44943),
		Vector2(94.1844, 48.53483),
		Vector2(91.25532, 50.26045),
		Vector2(88.2766, 52.17813),
		Vector2(84.58298, 54.15344),
		Vector2(81.37489, 56.14603),
		Vector2(78.31247, 57.44381),
		Vector2(75.99374, 58.53314),
		Vector2(72.49812, 60.25994),
		Vector2(70.04944, 62.17798),
		Vector2(67.91483, 63.4534),
		Vector2(65.87445, 65.23602),
		Vector2(63.16233, 66.4708),
		Vector2(60.9487, 67.54124),
		Vector2(57.48461, 69.96237),
		Vector2(54.34538, 72.08871),
		Vector2(52.00362, 73.42661),
		Vector2(49.90108, 74.52798),
		Vector2(47.87033, 74.8584),
	],
	[
		Vector2(28.0, 116.0),
		Vector2(32.87431, 115.5486),
		Vector2(35.06229, 115.8646),
		Vector2(37.11869, 115.9594),
		Vector2(39.83561, 115.9878),
		Vector2(42.05068, 115.9963),
		Vector2(44.1152, 115.9989),
		Vector2(47.53456, 115.9997),
		Vector2(50.66037, 115.9999),
		Vector2(52.99811, 116.0),
		Vector2(56.49944, 116.7),
		Vector2(58.94983, 116.91),
		Vector2(62.48495, 116.973),
		Vector2(67.04549, 116.9919),
		Vector2(70.51365, 116.9976),
		Vector2(73.6541, 116.9993),
		Vector2(76.69623, 116.9998),
		Vector2(79.70887, 116.9999),
		Vector2(82.01266, 117.0),
		Vector2(84.8038, 117.0),
		Vector2(87.04114, 117.0),
		Vector2(89.81234, 117.0),
		Vector2(92.0437, 117.0),
		Vector2(94.11311, 117.0),
		Vector2(98.23393, 117.0),
		Vector2(101.5702, 117.0),
		Vector2(105.3711, 117.0),
		Vector2(109.3113, 116.3),
		Vector2(112.5934, 116.09),
		Vector2(114.978, 116.027),
		Vector2(117.7934, 116.0081),
		Vector2(120.038, 116.0024),
	],
	[
		Vector2(85.6367, 64.0),
		Vector2(85.6367, 64.74863),
		Vector2(85.59101, 65.62459),
		Vector2(86.27731, 67.98737),
		Vector2(86.78319, 70.09621),
		Vector2(86.93496, 72.12886),
		Vector2(86.98048, 74.13866),
		Vector2(86.99415, 76.14159),
		Vector2(86.99825, 78.84248),
		Vector2(86.99947, 81.75275),
		Vector2(86.99984, 84.02583),
		Vector2(86.99995, 87.50775),
		Vector2(86.99998, 89.95232),
		Vector2(86.99999, 92.7857),
		Vector2(87.0, 95.73571),
		Vector2(87.0, 100.1207),
		Vector2(87.0, 104.2362),
		Vector2(87.0, 108.9709),
		Vector2(87.0, 114.5913),
		Vector2(87.7, 118.3774),
		Vector2(87.91, 122.3132),
		Vector2(87.973, 125.594),
		Vector2(87.9919, 130.0782),
		Vector2(87.99757, 136.3235),
		Vector2(87.99927, 141.697),
		Vector2(87.99978, 146.1091),
		Vector2(87.99993, 148.8327),
		Vector2(87.99998, 151.7498),
		Vector2(87.99999, 154.7249),
		Vector2(88.0, 159.8175),
		Vector2(88.0, 164.8452),
		Vector2(89.4, 170.5536),
		Vector2(89.82, 175.0661),
		Vector2(89.946, 179.2198),
		Vector2(89.9838, 181.866),
		Vector2(89.99514, 184.0598),
		Vector2(89.99854, 186.8179),
		Vector2(89.99957, 189.7454),
		Vector2(89.99987, 194.1236),
		Vector2(89.99996, 197.5371),
		Vector2(89.99998, 202.0611),
		Vector2(89.99999, 206.9183),
		Vector2(90.0, 210.4755),
		Vector2(90.0, 215.0426),
		Vector2(90.0, 219.9128),
		Vector2(90.0, 222.7738),
		Vector2(90.0, 225.0322),
		Vector2(90.0, 227.1096),
		Vector2(90.0, 231.9329),
		Vector2(90.0, 235.4799),
		Vector2(89.3, 239.344),
		Vector2(89.09, 241.9032),
		Vector2(89.027, 244.071),
		Vector2(89.0081, 247.5213),
		Vector2(89.00243, 251.3564),
		Vector2(89.00073, 253.9069),
		Vector2(88.30022, 256.7721),
		Vector2(88.09007, 259.0316),
		Vector2(88.02702, 261.8095),
		Vector2(87.30811, 266.1429),
	],
		[
		Vector2(81.0, 116.0),
		Vector2(80.91927, 116.8413),
		Vector2(80.27578, 119.0524),
		Vector2(79.38274, 121.1157),
		Vector2(78.41482, 123.8347),
		Vector2(77.42445, 126.7504),
		Vector2(76.42734, 129.0251),
		Vector2(74.7282, 131.8075),
		Vector2(73.51846, 134.0423),
		Vector2(72.45554, 136.1127),
		Vector2(70.73666, 138.1338),
		Vector2(69.521, 140.1401),
		Vector2(67.7563, 143.542),
		Vector2(65.82689, 145.9626),
		Vector2(63.84807, 149.4888),
		Vector2(62.55442, 151.9466),
		Vector2(61.46633, 154.784),
		Vector2(60.4399, 157.0352),
		Vector2(58.73197, 158.4106),
		Vector2(57.51959, 160.2232),
		Vector2(56.45588, 162.1669),
		Vector2(55.43676, 164.1501),
		Vector2(53.73103, 167.545),
		Vector2(51.81931, 169.9635),
		Vector2(50.54579, 172.0891),
		Vector2(48.06374, 176.9267),
		Vector2(45.91912, 179.778),
		Vector2(43.87574, 182.7334),
		Vector2(41.86272, 185.02),
		Vector2(40.55882, 187.106),
		Vector2(39.46764, 189.1318),
		Vector2(37.74029, 191.1395),
		Vector2(35.12209, 194.5419),
		Vector2(32.93663, 196.9626),
		Vector2(30.88099, 199.7888),
		Vector2(28.1643, 202.7366),
		Vector2(25.94929, 204.321),
	],
	[
		Vector2(91.0, 130.0),
		Vector2(92.4734, 129.3945),
		Vector2(93.54202, 130.5184),
		Vector2(94.56261, 132.2555),
		Vector2(96.26878, 133.4767),
		Vector2(97.48064, 135.243),
		Vector2(99.94419, 137.8729),
		Vector2(102.0833, 140.7619),
		Vector2(104.825, 143.7286),
		Vector2(107.0475, 146.7186),
		Vector2(109.8142, 150.4156),
		Vector2(111.3443, 152.9247),
		Vector2(113.9033, 155.0774),
		Vector2(114.671, 157.1232),
		Vector2(116.3013, 159.837),
		Vector2(118.1904, 162.7511),
		Vector2(118.7571, 165.0253),
		Vector2(119.6271, 167.1076),
	],
	[
		Vector2(220.0, 36.0),
		Vector2(218.7541, 38.54587),
		Vector2(215.4262, 40.96376),
		Vector2(213.0279, 43.08913),
		Vector2(210.2084, 45.12674),
		Vector2(207.9625, 45.73802),
		Vector2(205.8887, 46.62141),
		Vector2(203.1666, 48.28642),
		Vector2(200.95, 49.48593),
		Vector2(198.185, 50.54578),
		Vector2(195.9555, 52.26373),
		Vector2(193.8867, 52.77912),
		Vector2(191.166, 54.33374),
		Vector2(188.2498, 56.20012),
		Vector2(185.9749, 56.76004),
		Vector2(183.1925, 58.32801),
		Vector2(180.9577, 59.4984),
		Vector2(178.1873, 61.24952),
		Vector2(175.2562, 62.47486),
		Vector2(172.2769, 63.54246),
		Vector2(169.9831, 63.86274),
		Vector2(167.8949, 64.65882),
		Vector2(164.4685, 66.29765),
		Vector2(161.3405, 67.4893),
		Vector2(159.0022, 68.54679),
		Vector2(156.9007, 68.86404),
		Vector2(154.8702, 69.65921),
		Vector2(152.8611, 69.89777),
		Vector2(150.1583, 69.96933),
		Vector2(147.2475, 70.6908),
		Vector2(144.9742, 71.60724),
		Vector2(142.1923, 71.88217),
	],
	[
		Vector2(128.0, 92.0),
		Vector2(129.3284, 92.25871),
		Vector2(131.1985, 92.07761),
		Vector2(133.8596, 92.72328),
		Vector2(136.0579, 92.91698),
		Vector2(139.5174, 92.9751),
		Vector2(143.3552, 93.69253),
		Vector2(145.9066, 93.90776),
		Vector2(148.072, 94.67233),
		Vector2(150.8216, 94.9017),
		Vector2(155.1465, 95.67051),
		Vector2(159.2439, 95.90115),
		Vector2(163.2732, 95.97034),
		Vector2(167.282, 95.9911),
		Vector2(172.6846, 96.69733),
		Vector2(177.1054, 96.9092),
		Vector2(181.9316, 96.97276),
		Vector2(184.7795, 96.99183),
		Vector2(187.0338, 96.99755),
		Vector2(189.1102, 97.69926),
		Vector2(193.233, 97.90978),
		Vector2(198.6699, 97.97293),
		Vector2(205.201, 97.99188),
		Vector2(212.0603, 97.99757),
		Vector2(216.2181, 97.99927),
		Vector2(220.2654, 97.99978),
		Vector2(224.9796, 98.69994),
		Vector2(230.5939, 99.60998),
		Vector2(235.7782, 99.883),
		Vector2(239.4335, 99.9649),
		Vector2(241.93, 99.98947),
		Vector2(245.479, 99.99684),
		Vector2(250.0437, 99.99905),
		Vector2(253.5131, 99.99972),
		Vector2(256.6539, 99.99992),
		Vector2(258.9962, 99.99998),
		Vector2(261.0988, 100.0),
		Vector2(264.5297, 100.0),
		Vector2(266.9589, 100.0),
	],
]

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GlobalGameSettings.Japanese.kanji_drawing_enabled.set_value(true)
	GlobalGameSettings.Interface.animation_speed.set_value(1.4)
	GlobalSaveGame.init_new_game(13)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P500_STARTED)
	GlobalSaveGame.unlock_skill(load('res://skills/craft/skill_craft_1_common.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/craft/skill_craft_2_uncommon.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/craft/skill_craft_3_rare.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/craft/skill_craft_4_epic.tres') as Skill)
	for stroke in Stroke.get_all_strokes():
		GlobalSaveGame.add_stroke(stroke, randi_range(20, 40))
	for card in CardType.get_all_card_types():
		GlobalSaveGame.mark_card_seen(card)

	var crafting := (load('res://hub/crafting/crafting.tscn') as PackedScene).instantiate() as Crafting
	GlobalUI.add_layer_content(crafting, UI.Layer.GAME_MENU)

	await get_tree().create_timer(2).timeout

	var card_tier_list := crafting.get_node('%CardsList').get_children()[2] as CardTierList
	var selected_card := card_tier_list.get_node('%List').get_children()[10] as Card
	selected_card.is_selected = true

	var scroller := crafting.get_node('%ScrollContainer') as ScrollContainer
	scroller.ensure_control_visible(selected_card)
	scroller.scroll_vertical += 200

	await get_tree().create_timer(4).timeout

	crafting._on_craft_button_pressed()

	await get_tree().create_timer(1.0/1.4).timeout

	var challenge := GlobalUI.get_layer(UI.Layer.GAME_MENU_SUBMENU).get_child(0) as KanjiDrawingChallenge
	var canvas := challenge.get_node('%DrawingCanvas') as KanjiDrawingCanvas

	for stroke: Array in STROKES:
		canvas._try_start_drawing(stroke[0] as Vector2)
		for point: Vector2 in stroke.slice(1):
			canvas._active_line.add_point(point)
			await get_tree().create_timer(0.015).timeout
		canvas._end_drawing()
		await get_tree().create_timer(.1).timeout

	await get_tree().create_timer(1).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

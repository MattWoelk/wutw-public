class_name SettlementNameOption
extends Resource

@export var name: String
@export var name_jp: String
@export var translation: String
@export var related_spot: SpotType
@export var related_spot_upgrade: SpotUpgrade
@export var probability_weight: int = 0  # Was batch-calculated based on related_spot_upgrade.

func get_markedup_name_explanation() -> String:
	var name_and_translation := get_display_name()
	match GameSettings.Japanese.town_names.value():
		GameSettings.TownNameDisplayType.MEANING:
			name_and_translation = '[b]%s[/b]' % name_and_translation
		GameSettings.TownNameDisplayType.ROMAJI:
			name_and_translation += ' ([b]%s[/b])' % tr(translation)
		GameSettings.TownNameDisplayType.KANJI:
			name_and_translation += ' (%s, [b]%s[/b])' % [JapaneseUtils.romaji_to_hiragana(name), tr(translation)]
		GameSettings.TownNameDisplayType.HIRAGANA:
			name_and_translation += ' (%s, [b]%s[/b])' % [name_jp if name_jp else tr(name), tr(translation)]
	var result := tr('The settlement is named')
	result += '\n'
	result += name_and_translation
	if related_spot or related_spot_upgrade:
		var name_origin: String
		if related_spot_upgrade:
			name_origin = '<spot_upgrade:%s>' % related_spot_upgrade.spot_upgrade_id
		else:
			name_origin = '<spot:%s>' % related_spot.spot_type_id
		result += '\n'
		result += tr('after its %s') % name_origin
	return result

func get_display_name() -> String:
	match GameSettings.Japanese.town_names.value():
		GameSettings.TownNameDisplayType.ROMAJI:
			return tr(name)
		GameSettings.TownNameDisplayType.KANJI:
			return name_jp if name_jp else tr(name)  # Backward-compatibility for old saves.
		GameSettings.TownNameDisplayType.HIRAGANA:
			return JapaneseUtils.romaji_to_hiragana(name)
		GameSettings.TownNameDisplayType.MEANING:
			return tr(translation) if translation else tr(name)  # Backward-compatibility for old saves.
	Utils.ensure(false)
	return tr(name)

func get_native_display_name() -> String:
	if GameSettings.Japanese.embed_jp.value():
		return get_display_name()
	else:
		if GameSettings.Japanese.town_names.value() == GameSettings.TownNameDisplayType.MEANING:
			return tr(translation) if translation else tr(name)  # Backward-compatibility for old saves.
		else:
			return tr(name)

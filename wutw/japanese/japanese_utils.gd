@tool
class_name JapaneseUtils
extends Node

## Most of this is not used at runtime, so the code is very inefficient.
## It's also full of hacks that are specific to the quirks of the datasets.

const ROMAJI_TO_HIRAGANA := {
	# Vowels
	'a': 'あ', 'i': 'い', 'u': 'う', 'e': 'え', 'o': 'お',
	# K
	'ka': 'か', 'ki': 'き', 'ku': 'く', 'ke': 'け', 'ko': 'こ',
	'kya': 'きゃ', 'kyu': 'きゅ', 'kyo': 'きょ',
	# S
	'sa': 'さ', 'shi': 'し', 'si': 'し', 'su': 'す', 'se': 'せ', 'so': 'そ',
	'sha': 'しゃ', 'shu': 'しゅ', 'sho': 'しょ',
	# T
	'ta': 'た', 'chi': 'ち', 'ti': 'ち', 'tsu': 'つ', 'tu': 'つ', 'te': 'て', 'to': 'と',
	'cha': 'ちゃ', 'chu': 'ちゅ', 'cho': 'ちょ',
	# N
	'na': 'な', 'ni': 'に', 'nu': 'ぬ', 'ne': 'ね', 'no': 'の',
	'nya': 'にゃ', 'nyu': 'にゅ', 'nyo': 'にょ',
	# H
	'ha': 'は', 'hi': 'ひ', 'fu': 'ふ', 'hu': 'ふ', 'he': 'へ', 'ho': 'ほ',
	'hya': 'ひゃ', 'hyu': 'ひゅ', 'hyo': 'ひょ',
	# M
	'ma': 'ま', 'mi': 'み', 'mu': 'む', 'me': 'め', 'mo': 'も',
	'mya': 'みゃ', 'myu': 'みゅ', 'myo': 'みょ',
	# Y
	'ya': 'や', 'yu': 'ゆ', 'yo': 'よ',
	# R
	'ra': 'ら', 'ri': 'り', 'ru': 'る', 're': 'れ', 'ro': 'ろ',
	'rya': 'りゃ', 'ryu': 'りゅ', 'ryo': 'りょ',
	# W
	'wa': 'わ', 'wo': 'を',
	# G
	'ga': 'が', 'gi': 'ぎ', 'gu': 'ぐ', 'ge': 'げ', 'go': 'ご',
	'gya': 'ぎゃ', 'gyu': 'ぎゅ', 'gyo': 'ぎょ',
	# Z
	'za': 'ざ', 'ji': 'じ', 'zi': 'じ', 'zu': 'ず', 'ze': 'ぜ', 'zo': 'ぞ',
	'ja': 'じゃ', 'ju': 'じゅ', 'jo': 'じょ',
	# D
	'da': 'だ', 'di': 'ぢ', 'du': 'づ', 'dzu': 'づ', 'de': 'で', 'do': 'ど',
	# B
	'ba': 'ば', 'bi': 'び', 'bu': 'ぶ', 'be': 'べ', 'bo': 'ぼ',
	'bya': 'びゃ', 'byu': 'びゅ', 'byo': 'びょ',
	# P
	'pa': 'ぱ', 'pi': 'ぴ', 'pu': 'ぷ', 'pe': 'ぺ', 'po': 'ぽ',
	'pya': 'ぴゃ', 'pyu': 'ぴゅ', 'pyo': 'ぴょ',
	# N
	'n': 'ん',
}
const HIRAGANA_TO_ROMAJI := {
	# Vowels
	'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
	# K
	'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
	'きゃ': 'kya', 'きゅ': 'kyu', 'きょ': 'kyo',
	# S
	'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
	'しゃ': 'sha', 'しゅ': 'shu', 'しょ': 'sho',
	# T
	'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
	'ちゃ': 'cha', 'ちゅ': 'chu', 'ちょ': 'cho',
	# N
	'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
	'にゃ': 'nya', 'にゅ': 'nyu', 'にょ': 'nyo',
	# H
	'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
	'ひゃ': 'hya', 'ひゅ': 'hyu', 'ひょ': 'hyo',
	# M
	'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'も': 'mo',
	'みゃ': 'mya', 'みゅ': 'myu', 'みょ': 'myo',
	# Y
	'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
	# R
	'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
	'りゃ': 'rya', 'りゅ': 'ryu', 'りょ': 'ryo',
	# W
	'わ': 'wa', 'を': 'wo',
	# G
	'が': 'ga', 'ぎ': 'gi', 'ぐ': 'gu', 'げ': 'ge', 'ご': 'go',
	'ぎゃ': 'gya', 'ぎゅ': 'gyu', 'ぎょ': 'gyo',
	# Z
	'ざ': 'za', 'じ': 'ji', 'ず': 'zu', 'ぜ': 'ze', 'ぞ': 'zo',
	'じゃ': 'ja', 'じゅ': 'ju', 'じょ': 'jo',
	# D
	'だ': 'da', 'ぢ': 'ji', 'づ': 'dzu', 'で': 'de', 'ど': 'do',
	# B
	'ば': 'ba', 'び': 'bi', 'ぶ': 'bu', 'べ': 'be', 'ぼ': 'bo',
	'びゃ': 'bya', 'びゅ': 'byu', 'びょ': 'byo',
	# P
	'ぱ': 'pa', 'ぴ': 'pi', 'ぷ': 'pu', 'ぺ': 'pe', 'ぽ': 'po',
	'ぴゃ': 'pya', 'ぴゅ': 'pyu', 'ぴょ': 'pyo',
	# N
	'ん': 'n',
}
const KATAKANA_TO_ROMAJI := {
	# Vowels
	'ア': 'a', 'イ': 'i', 'ウ': 'u', 'エ': 'e', 'オ': 'o',
	# K
	'カ': 'ka', 'キ': 'ki', 'ク': 'ku', 'ケ': 'ke', 'コ': 'ko',
	'キャ': 'kya', 'キュ': 'kyu', 'キョ': 'kyo',
	# S
	'サ': 'sa', 'シ': 'shi', 'ス': 'su', 'セ': 'se', 'ソ': 'so',
	'シャ': 'sha', 'シュ': 'shu', 'ショ': 'sho',
	# T
	'タ': 'ta', 'チ': 'chi', 'ツ': 'tsu', 'テ': 'te', 'ト': 'to',
	'チャ': 'cha', 'チュ': 'chu', 'チョ': 'cho',
	# N
	'ナ': 'na', 'ニ': 'ni', 'ヌ': 'nu', 'ネ': 'ne', 'ノ': 'no',
	'ニャ': 'nya', 'ニュ': 'nyu', 'ニョ': 'nyo',
	# H
	'ハ': 'ha', 'ヒ': 'hi', 'フ': 'fu', 'ヘ': 'he', 'ホ': 'ho',
	'ヒャ': 'hya', 'ヒュ': 'hyu', 'ヒョ': 'hyo',
	# M
	'マ': 'ma', 'ミ': 'mi', 'ム': 'mu', 'メ': 'me', 'モ': 'mo',
	'ミャ': 'mya', 'ミュ': 'myu', 'ミョ': 'myo',
	# Y
	'ヤ': 'ya', 'ユ': 'yu', 'ヨ': 'yo',
	# R
	'ラ': 'ra', 'リ': 'ri', 'ル': 'ru', 'レ': 're', 'ロ': 'ro',
	'リャ': 'rya', 'リュ': 'ryu', 'リョ': 'ryo',
	# W
	'ワ': 'wa', 'ヲ': 'wo',
	# G
	'ガ': 'ga', 'ギ': 'gi', 'グ': 'gu', 'ゲ': 'ge', 'ゴ': 'go',
	'ギャ': 'gya', 'ギュ': 'gyu', 'ギョ': 'gyo',
	# Z
	'ザ': 'za', 'ジ': 'ji', 'ズ': 'zu', 'ゼ': 'ze', 'ゾ': 'zo',
	'ジャ': 'ja', 'ジュ': 'ju', 'ジョ': 'jo',
	# D
	'ダ': 'da', 'ヂ': 'ji', 'ヅ': 'dzu', 'デ': 'de', 'ド': 'do',
	# B
	'バ': 'ba', 'ビ': 'bi', 'ブ': 'bu', 'ベ': 'be', 'ボ': 'bo',
	'ビャ': 'bya', 'ビュ': 'byu', 'ビョ': 'byo',
	# P
	'パ': 'pa', 'ピ': 'pi', 'プ': 'pu', 'ペ': 'pe', 'ポ': 'po',
	'ピャ': 'pya', 'ピュ': 'pyu', 'ピョ': 'pyo',
	# N
	'ン': 'n',
}
const DOUBLEABLE := ['a', 'i', 'u', 'e', 'o', 'n']
const PREFERRED_VERB_ENDS := ['る', 'く', 'う', 'す', 'む', 'つ', 'ぶ', 'ぐ', 'ぬ']
const ALL_HIRAGANA := {
	'あ': true,
	'い': true,
	'う': true,
	'え': true,
	'お': true,
	'か': true,
	'が': true,
	'き': true,
	'ぎ': true,
	'く': true,
	'ぐ': true,
	'け': true,
	'げ': true,
	'こ': true,
	'ご': true,
	'さ': true,
	'ざ': true,
	'し': true,
	'じ': true,
	'す': true,
	'ず': true,
	'せ': true,
	'ぜ': true,
	'そ': true,
	'ぞ': true,
	'た': true,
	'だ': true,
	'ち': true,
	'ぢ': true,
	'つ': true,
	'づ': true,
	'て': true,
	'で': true,
	'と': true,
	'ど': true,
	'な': true,
	'に': true,
	'ぬ': true,
	'ね': true,
	'の': true,
	'は': true,
	'ば': true,
	'ぱ': true,
	'ひ': true,
	'び': true,
	'ぴ': true,
	'ふ': true,
	'ぶ': true,
	'ぷ': true,
	'へ': true,
	'べ': true,
	'ぺ': true,
	'ほ': true,
	'ぼ': true,
	'ぽ': true,
	'ま': true,
	'み': true,
	'む': true,
	'め': true,
	'も': true,
	'ゃ': true,
	'や': true,
	'ゅ': true,
	'ゆ': true,
	'ょ': true,
	'よ': true,
	'ら': true,
	'り': true,
	'る': true,
	'れ': true,
	'ろ': true,
	'わ': true,
	'を': true,
	'ん': true,
	'っ': true,
	'ー': true
}
const PUNCTUATION := '.,!\'"&()[]-:;?~　、。「」『』〜！？（）・'
const DISALLOWED_JMDICT_TAGS := {
  'ship': 'ship name',
  'bra': 'Brazilian',
  'quote': 'quotation',
  'pref': 'prefix',
  'rK': 'rarely used kanji form',
  'derog': 'derogatory',
  'abbr': 'abbreviation',
  'sK': 'search-only kanji form',
  'rk': 'rarely used kana form',
  'vulg': 'vulgar expression or word',
  'X': 'rude or X-rated term (not displayed in educational software)',
  'sk': 'search-only kana form',
  'sl': 'slang',
  'tv': 'television',
  'euph': 'euphemistic',
  'rare': 'rare term',
  'hanaf': 'hanafuda',
  'given': 'given name or forename, gender not specified',
  'grmyth': 'Greek mythology',
  'adj-kari': 'kari adjective (archaic)',
  'internet': 'Internet',
  'noh': 'noh',
  'rommyth': 'Roman mythology',
  'ateji': 'ateji (phonetic) reading',
  'Christn': 'Christianity',
  'obs': 'obsolete term',
  'work': 'work of art, literature, music, etc. name',
  'adj-t': 'taru adjective',
  'surname': 'family or surname',
  'place': 'place name',
  'adj-ku': 'ku adjective (archaic)',
  'telec': 'telecommunications',
  'organization': 'organization name',
  'm-sl': 'manga slang',
  'manga': 'manga',
  'sens': 'sensitive',
  'mahj': 'mahjong',
  'rail': 'railway',
  'sumo': 'sumo',
  'v2d-k': 'Nidan verb (upper class) with dzu ending (archaic)',
  'ok': 'out-dated or obsolete kana usage',
  'tradem': 'trademark',
  'net-sl': 'Internet slang',
  'n-pr': 'proper noun',
  'gikun': 'gikun (meaning as reading) or jukujikun (special kanji reading)'
}

static var _all_kanji_details: Dictionary[String, KanjiDetail]

# Dev-only, not runtime
static var _vocab_by_kanji: Dictionary[String, Array]  # Array[Vocab]
static var _all_vocab_common: Dictionary[String, Array]  # Array[Vocab]
static var _all_vocab: Dictionary[String, Array]  # Array[Vocab]
static var _all_example_sentences: Dictionary[String, Array]  # Array[ExampleSentence]
static var _word_frequency_ranking: Dictionary[String, int]
static var _word_jlpt_levels: Dictionary[String, int]
static var _kanji_stroke_shapes: Dictionary[String, KanjiShape]

static func romaji_to_hiragana(romaji: String) -> String:
	var input_str := romaji.to_lower().replace('ō', 'ou').replace('ū', 'uu')
	var result := ''

	var i := 0
	while i < input_str.length():
		# Pass through spaces.
		if input_str[i] == ' ':
			result += ' '
			i += 1
			continue

		# Doubled consonants (sokuon).
		if i + 1 < input_str.length() and input_str[i] == input_str[i + 1]:
			if input_str[i] not in DOUBLEABLE:
				result += 'っ'
				i += 1
				continue
		# 'tch' edge case (e.g. 'matcha').
		if i + 2 < input_str.length() and input_str.substr(i, 3) == 'tch':
			result += 'っ'
			i += 1  # Skip the 't'; next iteration will handle 'ch'
			continue

		# Check in chunks.
		var match_found := false
		for step: int in [3, 2, 1]:
			if i + step <= input_str.length():
				var chunk := input_str.substr(i, step)
				if ROMAJI_TO_HIRAGANA.has(chunk):
					result += ROMAJI_TO_HIRAGANA[chunk]
					i += step
					match_found = true
					break

		if not match_found:
			if input_str[i] not in PUNCTUATION:
				push_warning('Kana conversion failed for "%s" at index %d' % [input_str, i])
			result += input_str[i]
			i += 1

	return result

static func hiragana_to_romaji(hiragana: String, suppress_warning: bool = false) -> String:
	var input_str := hiragana
	var result := ''
	var double_next_consonant := false

	var i := 0
	while i < input_str.length():
		# Pass through spaces.
		if input_str[i] == ' ':
			result += ' '
			i += 1
			continue

		# Doubled consonants (sokuon).
		if input_str[i] == 'っ':
			double_next_consonant = true
			i += 1
			continue

		var match_found := false

		# Check in chunks.
		for step: int in [2, 1]:
			if i + step <= input_str.length():
				var chunk := input_str.substr(i, step)
				if HIRAGANA_TO_ROMAJI.has(chunk):
					var romaji: String = HIRAGANA_TO_ROMAJI[chunk]

					if double_next_consonant:
						# 'tch' edge case (e.g. 'matcha').
						if romaji.begins_with('ch'):
							result += 't' + romaji
						else:
							result += romaji[0] + romaji
						double_next_consonant = false
					else:
						result += romaji

					i += step
					match_found = true
					break

		if not match_found:
			if double_next_consonant:
				push_warning('Dangling sokuon (っ) before "%s" at index %d' % [input_str[i], i])
				result += 'tsu' # Output it raw so it isn't completely lost
				double_next_consonant = false

			if not suppress_warning and input_str[i] not in PUNCTUATION:
				push_warning('Romaji conversion failed for "%s" at index %d' % [input_str, i])
			result += input_str[i]
			i += 1

	return result.replace('ou', 'ō').replace('uu', 'ū')

static func katakana_to_romaji(katakana: String) -> String:
	var input_str := katakana
	var result := ''
	var double_next_consonant := false

	var i := 0
	while i < input_str.length():
		# Pass through spaces.
		if input_str[i] == ' ':
			result += ' '
			i += 1
			continue

		# Chōonpu (long vowel mark).
		if input_str[i] == 'ー':
			if result.length() > 0:
				var last_char := result[result.length() - 1]
				var macron_map := {'a': 'ā', 'i': 'ī', 'u': 'ū', 'e': 'ē', 'o': 'ō'}
				if macron_map.has(last_char):
					# Replace the preceding standard vowel with a macron vowel
					result = result.substr(0, result.length() - 1) + macron_map[last_char]
				else:
					result += '-' # Fallback if misused
			else:
				result += '-'
			i += 1
			continue

		# Doubled consonants (sokuon).
		if input_str[i] == 'ッ':
			double_next_consonant = true
			i += 1
			continue

		var match_found := false

		# Check in chunks.
		for step: int in [2, 1]:
			if i + step <= input_str.length():
				var chunk := input_str.substr(i, step)
				if KATAKANA_TO_ROMAJI.has(chunk):
					var romaji: String = KATAKANA_TO_ROMAJI[chunk]

					if double_next_consonant:
						# 'tch' edge case (e.g. 'matcha').
						if romaji.begins_with('ch'):
							result += 't' + romaji
						else:
							result += romaji[0] + romaji
						double_next_consonant = false
					else:
						result += romaji

					i += step
					match_found = true
					break

		if not match_found:
			if double_next_consonant:
				push_warning('Dangling sokuon (ッ) before "%s" at index %d' % [input_str[i], i])
				result += 'tsu' # Output it raw so it isn't completely lost
				double_next_consonant = false

			if input_str[i] not in PUNCTUATION:
				push_warning('Romaji conversion failed for "%s" at index %d' % [input_str, i])
			result += input_str[i]
			i += 1

	return result.replace('ou', 'ō').replace('uu', 'ū')

static func katakana_to_hiragana(katakana: String) -> String:
	var result := ''
	var i := 0
	while i < katakana.length():
		var code := katakana.unicode_at(i)
		# Katakana and Hiragana at 0x60 code points apart in unicode.
		if code >= 0x30A1 and code <= 0x30F6:  # Hiragana
			result += String.chr(code - 0x0060)
		else:
			# Passes through everything else.
			result += katakana[i]
		i += 1
	return result

static func hiragana_to_katakana(hiragana: String) -> String:
	var result := ''
	var i := 0
	while i < hiragana.length():
		var code := hiragana.unicode_at(i)
		# Katakana and Hiragana at 0x60 code points apart in unicode.
		if code >= 0x3041 and code <= 0x3096:  # Hiragana
			result += String.chr(code + 0x0060)
		else:
			# Passes through everything else.
			result += hiragana[i]
		i += 1
	return result

class KanjiDetail extends RefCounted:
	var kanji: String
	var onyomi: Array[String]
	var kunyomi: Array[String]
	var nanori: Array[String]
	var meanings: Array[String]
	var grade: int = -1
	var jlpt: int = -1

	func get_preferred_kunyomi() -> String:
		var best := ''
		var best_score := -INF
		for i in kunyomi.size():
			var kun := kunyomi[i]
			var score := JapaneseUtils._rate_kunyomi(kun) - float(i) / 100.0
			if score > best_score:
				best_score = score
				best = kun
		return best

	func get_preferred_onyomi() -> String:
		return onyomi[0] if onyomi else ''

	func get_dictionary_tooltip() -> String:
		var dictionary_mode := GameSettings.Japanese.dictionary_mode.value()
		var pieces: Array[String]
		pieces.append(tr('[b]Meaning:[/b] '))
		pieces.append(', '.join(meanings.map(tr)))
		if kunyomi:
			pieces.append(tr('\n[b]Kunyomi:[/b] '))
			var decorated_kunyomi := kunyomi.map(func(s: String) -> String:
				s = JapaneseUtils.decorate_kunyomi(s)
				if '・' in s:
					var kun_pieces := s.split('・', false, 1)
					s = kun_pieces[0] + '[color=#666]' + kun_pieces[1] + '[/color]'
				return s
			)
			if dictionary_mode == GameSettings.DictionaryMode.ROMAJI:
				decorated_kunyomi = decorated_kunyomi.map(JapaneseUtils.hiragana_to_romaji)
			elif dictionary_mode == GameSettings.DictionaryMode.KANA_AND_ROMAJI:
				decorated_kunyomi = decorated_kunyomi.map(func(s: String) -> String:
					return '%s (%s)' % [s, JapaneseUtils.hiragana_to_romaji(s, true)]
				)
			pieces.append(', '.join(decorated_kunyomi))
		if onyomi:
			pieces.append(tr('\n[b]Onyomi:[/b] '))
			var decorated_onyomi: Array = onyomi
			if dictionary_mode == GameSettings.DictionaryMode.ROMAJI:
				decorated_onyomi = decorated_onyomi.map(JapaneseUtils.katakana_to_romaji)
			elif dictionary_mode == GameSettings.DictionaryMode.KANA_AND_ROMAJI:
				decorated_onyomi = decorated_onyomi.map(func(s: String) -> String:
					return '%s (%s)' % [s, JapaneseUtils.katakana_to_romaji(s)]
				)
			pieces.append(', '.join(decorated_onyomi))
		if jlpt != -1 and grade != -1:
			pieces.append(tr('\nJLPT Level N%d, taught in grade %d.') % [jlpt, grade])
		elif jlpt != -1:
			pieces.append(tr('\nJLPT Level N%d.') % jlpt)
		elif grade != -1:
			pieces.append(tr('\nTaught in grade %d.') % grade)
		return ''.join(pieces)

static func _get_all_kanji_details() -> Dictionary[String, KanjiDetail]:
	if not _all_kanji_details:
		var f := FileAccess.open('res://japanese/databases/kanjidic2.json', FileAccess.READ)
		var json := JSON.new()
		var parse_result := json.parse(f.get_as_text())
		assert(parse_result == OK)
		var encoded_data := json.data as Dictionary
		for kanji: String in encoded_data:
			var encoded_detail := encoded_data[kanji] as Dictionary
			var detail := KanjiDetail.new()
			detail.kanji = kanji
			detail.onyomi.assign(encoded_detail.get('on', []) as Array)
			detail.kunyomi.assign(encoded_detail.get('kun', []) as Array)
			detail.nanori.assign(encoded_detail.get('nanori', []) as Array)
			detail.meanings.assign(encoded_detail.get('meanings', []) as Array)
			detail.grade = encoded_detail.get('grade', -1) as int
			detail.jlpt = encoded_detail.get('jlpt', -1) as int
			_all_kanji_details[kanji] = detail
		_all_kanji_details.make_read_only()
	return _all_kanji_details

static func _parse_sentence(sentence: String) -> Array[JapaneseToken]:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	# Must avoid shipping with the game.
	var tokenize_wrapper := load('res://japanese/tokenize_script/japanese_tokenize.gd')
	@warning_ignore('unsafe_method_access')
	var json_data: Array = tokenize_wrapper.parse_sentence(sentence)
	var tokens: Array[JapaneseToken]
	var index := 0
	for encoded_token: Dictionary in json_data as Array:
		var token := JapaneseToken.new()
		token.raw_text = encoded_token['original']
		token.reading = encoded_token['reading']
		var normalized := encoded_token['normalized'] as String
		if token.raw_text != token.reading:  # Can't trust kana.
			var vocabs := dev_lookup_vocab(normalized, '' if encoded_token['part_of_speech'] in ['形容詞', '動詞'] else token.reading)
			if not vocabs and normalized.ends_with('な') and encoded_token['part_of_speech'] == '形容詞':
				# Try stripping na from na adjectives.
				vocabs = dev_lookup_vocab(normalized.left(-1), token.reading.left(-1))
			if vocabs.size() >= 1:
				token.vocab = vocabs[0]
		index += token.raw_text.length()
		tokens.append(token)
	assert(index == sentence.length(), '%d vs %d; [%s]' % [index, sentence.length(), sentence])
	return tokens

static func get_kanji_detail(kanji: String) -> KanjiDetail:
	return _get_all_kanji_details().get(kanji, null)

static func decorate_kunyomi(kun: String) -> String:
	if '.x' in kun:
		assert(kun.count('.') == 1)
		var pieces := kun.split('.')
		return pieces[0] + '[' + pieces[1] + ']'
	else:
		return kun.replace('.', '・')

static func _rate_kunyomi(kun: String) -> int:
	assert(kun)
	var result := 0
	if '.' in kun:
		#if kun[-1] in PREFERRED_VERB_ENDS:
		#	result += 20
		#elif kun[-1] == 'い':
		#	result += 10
		result += 10
	if kun.begins_with('-'):
		result -= 1000
	if kun.ends_with('-'):
		result -= 500
	return result

static func _fetch_vocab_by_kanji() -> Dictionary[String, Array]:  # Array[Vocab]
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	var f := FileAccess.open('res://japanese/databases/jmdict-eng-common-3.6.2.json', FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(f.get_as_text())
	assert(parse_result == OK)
	var encoded_data := (json.data as Dictionary)['words'] as Array

	var result: Dictionary[String, Array]
	for word_data: Dictionary in encoded_data:
		# Extract the kanji+okurigana forms.
		var kanji_writings: Array[String]
		for kanji_data: Dictionary in word_data['kanji'] as Array:
			if kanji_data['common'] != true:
				continue
			var passes_tags := true
			for tag: String in kanji_data['tags'] as Array:
				if tag in DISALLOWED_JMDICT_TAGS:
					passes_tags = false
					break
			if not passes_tags:
				continue
			var kanji_text := kanji_data['text'] as String
			var characters_valid := true
			var any_kanji_used := false
			for c in kanji_text:
				if c in _get_all_kanji_details():
					any_kanji_used = true
				elif c not in ALL_HIRAGANA:
					characters_valid = false
					break
			if not any_kanji_used or not characters_valid:
				continue
			kanji_writings.append(kanji_text)
		if not kanji_writings:
			continue

		# Extract readings.
		var readings: Array[String]
		for kana_data: Dictionary in word_data['kana'] as Array:
			if kana_data['common'] != true:
				continue
			var applicability := kana_data.get('appliesToKanji', []) as Array
			if not (applicability.size() == 1 and applicability[0] == '*'):
				var passes_applicability := true
				for writing in kanji_writings:
					if writing not in applicability:
						passes_applicability = false
						break
				if not passes_applicability:
					continue
			var passes_tags := true
			for tag: String in kana_data['tags'] as Array:
				if tag in DISALLOWED_JMDICT_TAGS:
					passes_tags = false
					break
			if not passes_tags:
				continue
			var reading := kana_data['text'] as String
			var characters_valid := true
			for c in reading:
				if c not in ALL_HIRAGANA:
					characters_valid = false
					break
			if not characters_valid:
				continue
			readings.append(reading)
		if not readings:
			continue

		# Extract meanings.
		var meanings: Array[String]
		for sense_data: Dictionary in word_data['sense'] as Array:
			var applicability := sense_data.get('appliesToKanji', []) as Array
			if applicability.size() != 1 or applicability[0] != '*':
				continue
			var applicability2 := sense_data.get('appliesToKana', []) as Array
			if applicability2.size() != 1 or applicability2[0] != '*':
				continue
			if sense_data.get('dialect', []):
				continue
			var passes_tags := true
			var tags := (
				(sense_data.get('tags', []) as Array) +
				(sense_data.get('field', []) as Array) +
				(sense_data.get('misc', []) as Array)
			)
			for tag: String in tags:
				if tag in DISALLOWED_JMDICT_TAGS:
					passes_tags = false
					break
			if not passes_tags:
				continue
			for gloss: Dictionary in sense_data['gloss'] as Array:
				var meaning := gloss['text'] as String
				if meaning not in meanings:
					meanings.append(meaning)
		if not meanings:
			continue

		var vocabs: Array[Vocab]
		for kanji_writing in kanji_writings:
			var vocab := Vocab.new()
			vocab.japanese = kanji_writing
			vocab.readings = readings.duplicate()
			vocab.meanings = meanings.duplicate()
			vocab.jlpt_level = dev_get_word_jlpt_level(kanji_writing)
			vocabs.append(vocab)

		var used_kanjis: Dictionary[String, bool]
		for kanji_writing in kanji_writings:
			for c in kanji_writing:
				if c in _get_all_kanji_details():
					used_kanjis[c] = true
		assert(used_kanjis)
		for kanji in used_kanjis:
			if kanji not in result:
				result[kanji] = []
			for vocab in vocabs:
				if kanji in vocab.japanese:
					result[kanji].append(vocab)

	return result

static func dev_fetch_vocab(kanji: String, max_results: int) -> Array[Vocab]:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	if not _vocab_by_kanji:
		_vocab_by_kanji = _fetch_vocab_by_kanji()
		for vocabs: Array in _vocab_by_kanji.values():
			vocabs.sort_custom(func(a: Vocab, b: Vocab) -> bool:
				return a.get_difficulty() < b.get_difficulty()
			)
		_vocab_by_kanji.make_read_only()
	var result: Array[Vocab]
	for vocab: Vocab in _vocab_by_kanji.get(kanji, []):
		result.append(vocab)
		if result.size() >= max_results:
			break
	return result

static func _fetch_all_vocab(common: bool) -> Dictionary[String, Array]:  # Array[Vocab]
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	var f := FileAccess.open('res://japanese/databases/jmdict-eng-common-3.6.2.json' if common else 'res://japanese/databases/jmdict-eng-3.6.2.json', FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(f.get_as_text())
	assert(parse_result == OK)
	var encoded_data := (json.data as Dictionary)['words'] as Array

	var result: Dictionary[String, Array]
	for word_data: Dictionary in encoded_data:
		# Extract the kanji+okurigana forms.
		var kanji_writings: Array[String]
		for kanji_data: Dictionary in word_data['kanji'] as Array:
			var kanji_text := kanji_data['text'] as String
			var characters_valid := true
			for c in kanji_text:
				if c not in _get_all_kanji_details() and c not in ALL_HIRAGANA:
					characters_valid = false
					break
			if not characters_valid:
				continue
			kanji_writings.append(kanji_text)

		# Extract readings.
		var readings: Array[String]
		var kana_writings: Array[String]
		for kana_data: Dictionary in word_data['kana'] as Array:
			var reading := kana_data['text'] as String
			var characters_valid := true
			for c in reading:
				if c not in ALL_HIRAGANA:
					characters_valid = false
					break
			if not characters_valid:
				continue
			kana_writings.append(reading)
			readings.append(reading)
		if not readings:
			continue

		# Extract meanings.
		var meanings: Array[String]
		var kana_meanings: Array[String]
		for sense_data: Dictionary in word_data['sense'] as Array:
			var applicability := sense_data.get('appliesToKanji', []) as Array
			if applicability.size() == 1 and applicability[0] == '*':
				for gloss: Dictionary in sense_data['gloss'] as Array:
					var meaning := gloss['text'] as String
					if meaning not in meanings:
						meanings.append(meaning)
					if meaning not in kana_meanings:
						kana_meanings.append(meaning)
			else:
				for gloss: Dictionary in sense_data['gloss'] as Array:
					var meaning := gloss['text'] as String
					if meaning not in kana_meanings:
						kana_meanings.append(meaning)

		if meanings:
			for kanji_writing in kanji_writings:
				var vocab := Vocab.new()
				vocab.japanese = kanji_writing
				vocab.readings = readings.duplicate()
				vocab.meanings = meanings.duplicate()
				vocab.jlpt_level = dev_get_word_jlpt_level(kanji_writing)
				if kanji_writing not in result:
					result[kanji_writing] = []
				if vocab not in result[kanji_writing]:
					result[kanji_writing].append(vocab)
		if kana_meanings:
			for kana_term in kana_writings:
				var vocab := Vocab.new()
				vocab.japanese = kana_term
				vocab.readings = [kana_term]
				vocab.meanings = kana_meanings.duplicate()
				vocab.jlpt_level = dev_get_word_jlpt_level(kana_term)
				if kana_term not in result:
					result[kana_term] = []
				if vocab not in result[kana_term]:
					result[kana_term].append(vocab)

	return result

static func dev_lookup_vocab(word: String, reading: String = '') -> Array[Vocab]:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	if not _all_vocab:
		_all_vocab = _fetch_all_vocab(false)
	if not _all_vocab_common:
		_all_vocab_common = _fetch_all_vocab(true)
	var result: Array[Vocab]
	for v: Vocab in _all_vocab_common.get(word, []) as Array:
		var any_matched := false
		for r in v.readings:
			if r.begins_with(reading):
				any_matched = true
				break
		if any_matched:
			result.append(v)
	result.sort_custom(func(a: Vocab, b: Vocab) -> bool:
		return a.get_difficulty() < b.get_difficulty()
	)
	var tmp := (_all_vocab.get(word, []) as Array).duplicate()
	tmp.sort_custom(func(a: Vocab, b: Vocab) -> bool:
		return a.get_difficulty() < b.get_difficulty()
	)
	for v: Vocab in tmp:
		var any_matched := false
		for r in v.readings:
			if r.begins_with(reading):
				any_matched = true
				break
		if any_matched:
			result.append(v)
	return result

static func _fetch_example_sentences() -> Dictionary[String, Array]:  # Array[ExampleSentence]
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	# HACK: Really TSV, but Godot is stupid about extensions and export.
	var f := FileAccess.open('res://japanese/databases/tatoeba_pairs.csv', FileAccess.READ)
	var result: Dictionary[String, Array]
	while not f.eof_reached():
		var line := f.get_line().split('\t')
		if line.size() <= 1 and not line[0]:
			continue  # Empty line
		assert(line.size() == 4, ' |  '.join(line))
		var japanese := line[1]
		var native := line[3]
		var japanese_chars_valid := true
		for c in japanese:
			if c not in ALL_HIRAGANA and c not in _get_all_kanji_details() and c not in PUNCTUATION:
				japanese_chars_valid = false
				break
		if not japanese_chars_valid:
			continue

		var example := ExampleSentence.new()
		example.japanese = japanese
		example.native = native

		var used_kanjis: Dictionary[String, bool]
		for c in japanese:
			if c in _get_all_kanji_details():
				used_kanjis[c] = true
		for kanji in used_kanjis:
			if kanji not in result:
				result[kanji] = []
			result[kanji].append(example)

	for examples: Array in result.values():
		examples.sort_custom(func(a: ExampleSentence, b: ExampleSentence) -> bool:
			if a.native.ends_with('!') != b.native.ends_with('!'):
				return not a.native.ends_with('!')
			return a.get_difficulty() < b.get_difficulty()
		)

	return result

static func dev_fetch_example_sentences(kanji: String, offset: int, max_results: int) -> Array[ExampleSentence]:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	if not _all_example_sentences:
		_all_example_sentences = _fetch_example_sentences()
		_all_example_sentences.make_read_only()
	var result: Array[ExampleSentence]
	for example: ExampleSentence in (_all_example_sentences.get(kanji, []) as Array).slice(offset):
		if not example.parsed:
			example.parsed = _parse_sentence(example.japanese)
		result.append(example)
		if result.size() >= max_results:
			break
	return result

static func dev_get_word_frequency_rank(word: String) -> int:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	dev_fetch_vocab('一', 1)  # Force vocab fetch.
	if not _word_frequency_ranking:
		assert(_vocab_by_kanji)
		var seen_words: Dictionary[String, bool]
		for kanji in _vocab_by_kanji:
			for w: Vocab in _vocab_by_kanji[kanji]:
				seen_words[w.japanese] = true

		var f := FileAccess.open('res://japanese/databases/word_frequency.txt', FileAccess.READ)
		var i := 0
		while not f.eof_reached():
			var line := f.get_line().strip_edges()
			if line in seen_words:
				_word_frequency_ranking[line] = i
				i += 1
	return _word_frequency_ranking.get(word, 1_000_000)

static func dev_get_word_jlpt_level(word: String) -> int:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	if not _word_jlpt_levels:
		var f := FileAccess.open('res://japanese/databases/word_jlpt_levels.csv', FileAccess.READ)
		while not f.eof_reached():
			var pieces := f.get_csv_line()
			if not pieces or (pieces.size() == 1 and not pieces[0]):
				continue
			assert(pieces.size() == 2, str(pieces))
			_word_jlpt_levels[pieces[0]] = int(pieces[1])
	return _word_jlpt_levels.get(word, -1)

static func _fetch_stroke_shapes() -> Dictionary[String, KanjiShape]:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	var f := FileAccess.open('res://japanese/databases/kanji_stroke_shapes.json', FileAccess.READ)
	var json := JSON.new()
	var parse_result := json.parse(f.get_as_text())
	assert(parse_result == OK)
	var result: Dictionary[String, KanjiShape]
	for kanji: String in json.data:
		var shape := KanjiShape.new()
		for stroke_points: Array in json.data[kanji]:
			var stroke := StrokeShape.new()
			for point_data: Array in stroke_points:
				stroke.points.append(Vector2(point_data[0] as float, point_data[1] as float,))
			shape.stroke_shapes.append(stroke)
		result[kanji] = shape
	return result

static func dev_get_kanji_stroke_shape(kanji: String) -> KanjiShape:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	if not _kanji_stroke_shapes:
		_kanji_stroke_shapes = _fetch_stroke_shapes()
	return _kanji_stroke_shapes[kanji]

## ----- Test; unused at runtime.

@warning_ignore('unused_private_class_variable')
@export_tool_button('Refresh Cards')
var _refresh_cards_tool := _refresh_cards
func _refresh_cards() -> void:
	var total_cards := 0
	var total_vocab := 0
	var total_sentences := 0
	for card_type in CardType.get_all_card_types():
		for vocab in card_type.vocabulary:
			vocab.get_used_kanji()
			vocab.jlpt_level = dev_get_word_jlpt_level(vocab.japanese)
			vocab._difficulty = vocab._estimate_difficulty()
			total_vocab += 1
		card_type.vocabulary.sort_custom(func(a: Vocab, b: Vocab) -> bool:
			return a.get_difficulty() < b.get_difficulty()
		)

		for example in card_type.example_sentences:
			example.get_used_kanji()
			example._difficulty = example._estimate_difficulty()
			total_sentences += 1
		card_type.example_sentences.sort_custom(func(a: ExampleSentence, b: ExampleSentence) -> bool:
			return a.get_difficulty() < b.get_difficulty()
		)
		total_cards += 1

	print('Refreshed %d cards, %d vocab, %d sentences' % [total_cards, total_vocab, total_sentences])

@warning_ignore('unused_private_class_variable')
@export_tool_button('Test Romaji')
var _test_romaji_tool := _test_romaji
func _test_romaji() -> void:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	for option in (load('res://shard_types/shard_names.tres') as ShardNameSet).names:
		prints(option.name, '->', romaji_to_hiragana(option.name), '->', hiragana_to_romaji(romaji_to_hiragana(option.name)))
		assert(option.name.to_lower() == hiragana_to_romaji(romaji_to_hiragana(option.name)).to_lower())
	print('----')
	for option in (load('res://stage/settlement_names.tres') as SettlementNameSet).options:
		prints(option.name, '->', romaji_to_hiragana(option.name), '->', hiragana_to_romaji(romaji_to_hiragana(option.name)))
		assert(option.name.to_lower() == hiragana_to_romaji(romaji_to_hiragana(option.name)).to_lower())
	print('----')

	for card_type in CardType.get_all_card_types():
		var detail := get_kanji_detail(card_type.symbol)
		for on in detail.onyomi:
			print(on, ' -> ', katakana_to_romaji(on))

@warning_ignore('unused_private_class_variable')
@export_tool_button('Test Cards')
var _test_cards_tool := _test_cards
func _test_cards() -> void:
	_all_kanji_details = {}
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	for card_type in CardType.get_all_card_types():
		var detail := get_kanji_detail(card_type.symbol)
		print(detail.kanji, ' -> ', decorate_kunyomi(detail.get_preferred_kunyomi()))
		assert(detail.kunyomi or detail.onyomi)

@warning_ignore('unused_private_class_variable')
@export_tool_button('Test Vocab')
var _test_vocab_tool := _test_vocab
func _test_vocab() -> void:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	const KNOWN_MISSING := '鞴沃智'
	_vocab_by_kanji = {}
	_word_frequency_ranking = {}
	_word_jlpt_levels = {}
	for card_type in CardType.get_all_card_types():
		if card_type.symbol in KNOWN_MISSING:
			continue
		var vocabs := dev_fetch_vocab(card_type.symbol, 200)
		if not vocabs:
			push_warning('No vocab for ' + card_type.symbol)
			continue
		print(card_type.symbol, '->', vocabs[0].japanese)
		print('  ', ', '.join(vocabs[0].readings))
		print('  ', ', '.join(vocabs[0].meanings))

@warning_ignore('unused_private_class_variable')
@export_tool_button('Test Sentences')
var _test_sentences_tool := _test_sentences
func _test_sentences() -> void:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	const KNOWN_MISSING := '鞴'
	_all_example_sentences = {}
	for card_type in CardType.get_all_card_types():
		if card_type.symbol in KNOWN_MISSING:
			continue
		var sentences := dev_fetch_example_sentences(card_type.symbol, 0, 100)
		if not sentences:
			push_warning('No sentences for: ' + card_type.symbol)
			continue
		print(card_type.symbol, ' -> ', sentences.size())
		print(sentences[0].japanese)
		print(sentences[0].native)

@warning_ignore('unused_private_class_variable')
@export_tool_button('Test Stroke Shapes')
var _test_stroke_shapes_tool := _test_stroke_shapes
func _test_stroke_shapes() -> void:
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	_kanji_stroke_shapes = {}
	assert(Utils.is_in_editor() or Utils.is_running_in_single_scene_mode())
	for card_type in CardType.get_all_card_types():
		var kanji_shape := dev_get_kanji_stroke_shape(card_type.symbol)
		if not kanji_shape:
			push_warning('No stroke shapes for: ' + card_type.symbol)
			continue
		prints(card_type.symbol, '->', kanji_shape.stroke_shapes.size(), 'strokes')

@warning_ignore('unused_private_class_variable')
@export_tool_button('Test ALL')
var _test_all_tool := _test_all
func _test_all() -> void:
	_test_romaji()
	_test_cards()
	_test_vocab()
	_test_sentences()
	_test_stroke_shapes()

@warning_ignore('unused_private_class_variable')
@export_tool_button('Dump Furigana')
var _write_furigana_tool := _write_furigana
func _write_furigana() -> void:
	var output_file := FileAccess.open('user://furigana.txt', FileAccess.WRITE)

	for card_type in CardType.get_all_card_types():
		for example in card_type.example_sentences:
			output_file.store_line('%s[%d]' % [card_type.card_name.to_lower(), card_type.example_sentences.find(example)])
			output_file.store_line(example.japanese)
			var hiragana := ''
			for token in example.parsed:
				hiragana += token.reading
			output_file.store_line(hiragana)
			for token in example.parsed:
				output_file.store_line('  %s: %s' % [token.raw_text, token.reading])
			output_file.store_line('')

	output_file.close()

func _on_button_test_romaji_pressed() -> void:
	_test_romaji()

func _on_button_test_cards_pressed() -> void:
	_test_cards()

func _on_button_test_vocab_pressed() -> void:
	_test_vocab()

func _on_button_test_sentences_pressed() -> void:
	_test_sentences()

func _on_button_test_strokes_pressed() -> void:
	_test_stroke_shapes()

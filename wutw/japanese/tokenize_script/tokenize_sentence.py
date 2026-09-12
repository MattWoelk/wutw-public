import os
import re
import sys
import json
import pykakasi
import fugashi
import ipadic

KATAKANA_TO_HIRAGANA = str.maketrans(
    'ァアィイゥウェエォオカガキギクグケゲコゴサザシジスズセゼソゾタダチヂッツヅテデトドナニヌネノハバパヒビピフブプヘベペホボポマミムメモャヤュユョヨラリルレロヮワヰヱヲンヴヵヶ',
    'ぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽまみむめもゃやゅゆょよらりるれろゎわゐゑをんゔかげ'
)

def main():
    if len(sys.argv) < 2:
        print('Usage: python tokenize.py sentence')
        sys.exit(1)

    # -r for mecabrc, which we don't meed.
    tagger = fugashi.GenericTagger(f'-r "{os.devnull}" -d "{ipadic.DICDIR}"')
    kks = pykakasi.kakasi()

    input_text = sys.argv[1]
    input_text = re.sub(r'昨日本', '昨日 本', input_text)  # Known bad parse.

    words = list(tagger(input_text))
    output_data = []
    for i, word in enumerate(words):
        # (pos1, pos2, pos3, pos4, inflectionType, inflectionForm, baseForm, reading, pronunciation)
        features = word.feature
        
        pos = features[0] if len(features) > 0 else '未知語'
        
        if len(features) > 6 and features[6] != '*':
            normalized = features[6]
        else:
            normalized = word.surface

        if len(features) > 7 and features[7] != '*':
            reading_kata = features[7]
        else:
            reading_kata = word.surface
        reading_hira = reading_kata.translate(KATAKANA_TO_HIRAGANA)
        
        # Edge case: reading contains kanji.
        if re.search(r'[\u4E00-\u9FFF]', reading_hira):
            converted = kks.convert(word.surface)
            reading_hira = ''.join([item['hira'] for item in converted])

        # 御 prefix sometimes misparsed (お vs ご). Parse it together with the word.
        if i > 0 and pos == '名詞' and words[i-1].feature[0] == '接頭詞' and words[i-1].surface in ['お', 'ご', '御']:
            combined_text = words[i-1].surface + word.surface
            converted_combined = kks.convert(combined_text)
            full_hira = ''.join([item['hira'] for item in converted_combined])
            prefix_hira = ''.join([item['hira'] for item in kks.convert(words[i-1].surface)])
            if full_hira.startswith(prefix_hira):
                reading_hira = full_hira[len(prefix_hira):]

        output_data.append({
            'original': word.surface,
            'normalized': normalized,
            'reading': reading_hira,
            'part_of_speech': pos
        })
    print(json.dumps(output_data, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()

import polib
import re
import sys

def __main__():
    patterns = [
        r'\[img[^\]]*\][^\[]+\[/img\]',
        r'<[^>]+>',
        r'\[[^\]]+\]',
        r'\{[^\}]+\}',
        r'^PAGE: [^\n]*',
        r'^(?:historian|scribe|monk|explorer|avatar_child|avatar_adult):',
        r'%\+?.',
    ]
    combined_pattern = re.compile(f"({'|'.join(patterns)})", re.MULTILINE)
    charmap = str.maketrans(
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'àƃçďéƒğĥíĵķļɱñöþqŕšţúvŵẋýžÀƁÇĎÉƑĞĤÍĴĶĻⱮÑÖÞQŔŠŢÚVŴẊÝŽ'
    )

    def pseudolocalize(text):
        parts = combined_pattern.split(text)
        for i in range(len(parts)):
            if i % 2 == 0 and parts[i]: 
                parts[i] = parts[i].translate(charmap)
        return ''.join(parts)

    po = polib.pofile(sys.argv[1])
    for entry in po:
        if not entry.obsolete and entry.msgid:
            if entry.msgid_plural:
                entry.msgstr_plural[0] = pseudolocalize(entry.msgid)
                entry.msgstr_plural[1] = pseudolocalize(entry.msgid_plural)
            else:
                entry.msgstr = pseudolocalize(entry.msgid)

    po.save(sys.argv[2])

if len(sys.argv) < 3:
    print('Usage: %s <input.po> <output.po>' % sys.argv[0])
else:
    __main__()


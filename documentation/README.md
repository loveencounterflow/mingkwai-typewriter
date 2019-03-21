

# Terms

* writing system, language
* typing system, keyboard layout
* base typing system, typing system base; == keybase
* output / target typing system; == keytop

# Key Translation Methods (KTMs)

* **Direct Input (`1:1`) KTM**: each keystroke is mapped to one (possibly empty) output string. Unmapped
  keys produce whatever effect they have in the basic mode. This mode is suitable for cases where the
  keybase and output e.g. a Greek (`Grek`) or Cyrillic (`Cyrl`) keyboard on top of a Latin (Latn)-based
  keyboard; it results in mappings like `Grek/Latn` (Greek keytop on Latin keybase) or `Cyrl/Latn` (Cyrillic
  keytop on Latin keybase).

* **Transliteration (`n:m`) KTM**: This mode maps one ore more continuous strings of keystrokes to output
  strings. This KTM is useful when it would be inconvenient to assign each output (e.g. each (sequence of)
  Hiragana) a single keystroke.

In practice, both Direct Input (`1:1`) and Transliteration (`n:m`) are implemented with prefix-matching
dictionaries (trie maps, a.k.a. 'triodes') whose keys are keybase strings (user inputs, e.g. in Latin
letters) to keytop strings (target outputs, e.g. Japanese Kana); thus, we can establish mappings like

```coffee
latn_hrkt_map = {
  'pa':       'ぱ'
  'ra':       'ら'
  'sa':       'さ'
  'ta':       'た'
  'wa':       'わ'
  'ya':       'や'
  'za':       'ざ'
  'kyu':      'きゅ'
  'kyo':      'きょ'
  'n':        'ん'
  'nya':      'にゃ'
  'nyu':      'にゅ'
  'nyo':      'にょ'
  'sha':      'しゃ'
  'shi':      'し'
  'shu':      'しゅ'
  'sho':      'しょ'
  }
```


```

# Writing System Codes

Hang: Hangeul
Hani: Han (Hanzi, Kanji, Hanja); a.ka. Sinographs, CJK Ideographs
Hira: Hiragana
Hrkt: Hiragana and Katakana
Kana: Katakana [sic]


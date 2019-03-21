

# Terms

* writing system, language
* typing system, keyboard layout
* base typing system, typing system base; == keybase
* output / target typing system; == keytop

# Determininstic Key Translation Methods (dKTMs)

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
letters) to keytop strings (target outputs, e.g. Japanese Kana); this has the advantage that authors of new
KTMs do not have to decide whether to use the one or the other technique, and that `1:1` schemas are
seamlessly extendable to incorporate some `1:m`, `n:1` or `n:m` mappings as seen fit in the course of
actions.

## Inclusive Prefixes in Triode Terms

In determininstic KTMs (dKTMs), the end-of-term (EOT) points (i.e. the point in time when the collected user
input is replaced by the keytop (target output)) are reached *implicitly*, without there being a step where
the user is presented with a list of possible completions to choose from (although such choices can be
presented before then implicit EOT is reached). Thus, in a dKTM for Japanese Hiragan, we may establish a map
like the below which goes from a Hepburn-like transliteration (call it `Latn.Xhb`) to Hiragana (`Hira`):

```coffee
latn_xhb_to_hrkt = {
  'ka':       'か'
  'ke':       'け'
  'ki':       'き'
  'ko':       'こ'
  'ku':       'く'
  'kya':      'きゃ'
  'kyo':      'きょ'
  'kyu':      'きゅ'
  ...
  'pa':       'ぱ'
  'ra':       'ら'
  'ta':       'た'
  'wa':       'わ'
  'ya':       'や'
  'za':       'ざ'
  ...
  'n':        'ん'
  'nya':      'にゃ'
  'nyu':      'にゅ'
  'nyo':      'にょ'
  ...
  'sa':       'さ'
  'sha':      'しゃ'
  'shi':      'し'
  'shu':      'しゅ'
  'sho':      'しょ'
  ...
  }
```

When the `Latn.Xhb/Hira` map is active and the user presses the key marked `[k]`, a `〈k〉` is inserted into
the current input target. No translation has been made as yet as there are several possible completions
`〈か|け|き|こ|く|きゃ|きょ|きゅ〉` at this point. When the user then hits `[y]`, the selector is updated to `[k|y]`,
which matches `〈きゃ|きょ|きゅ〉`. It is only when one of `[a]`, `[o]`, `[u]` is hit that a unique match is arrived
at, for example, `[k|y|a]` -> `〈きゃ〉`; this will cause MingKwai to send three backspaces to the input target
to erase the three letters typed so far, and insert `きゃ`.



# Writing System Codes

* **`Hang`**: Hangeul
* **`Hani`**: Han (Hanzi, Kanji, Hanja); a.ka. Sinographs, CJK Ideographs
* **`Hira`**: Hiragana
* **`Hrkt`**: Hiragana and Katakana
* **`Kana`**: Katakana [sic]; *we use* **`Kata`** *to avoid confusion*

# Non-Determininstic Key Translation Methods (dKTMs)






# Terms

* writing system, language
* typing system, keyboard layout
* base typing system, typing system base; == keybase
* output / target typing system; == keytop

# Key Transcriptors (KTSs)

* **Direct Input (`1:1`)**: each keystroke is mapped to one (possibly empty) output string. Unmapped
  keys produce whatever effect they have in the basic mode. This mode is suitable for cases where the
  keybase and output e.g. a Greek (`Grek`) or Cyrillic (`Cyrl`) keyboard on top of a Latin (Latn)-based
  keyboard; it results in mappings like `Grek/Latn` (Greek keytop on Latin keybase) or `Cyrl/Latn` (Cyrillic
  keytop on Latin keybase).

* **Transliteration (`n:m`)**: This mode maps one ore more continuous strings of keystrokes to output
  strings. This KTM is useful when it would be inconvenient to assign each output (e.g. each (sequence of)
  Hiragana) a single keystroke.

In practice, both Direct Input (`1:1`) and Transliteration (`n:m`) are implemented with prefix-matching
dictionaries (trie maps, a.k.a. 'triodes') whose keys are keybase strings (user inputs, e.g. in Latin
letters) to keytop strings (target outputs, e.g. Japanese Kana); this has the advantage that authors of new
KTMs do not have to decide whether to use the one or the other technique, and that `1:1` schemas are
seamlessly extendable to incorporate some `1:m`, `n:1` or `n:m` mappings as seen fit in the course of
actions.

## Inclusive Prefixes in Triode Terms

In Key TranScriptors (KTSs), the end-of-term (EOT) points (i.e. the point in time when the collected user
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
at, for example, `[k|y|a]` ⇒ `〈きゃ〉`; this will cause MingKwai to send three backspaces to the input target
to erase the three letters typed so far, and insert `きゃ`.

* keys / input / keybase: `[k|y|a]`
* display: `〈kya〉`
* multiple target / output / keytop: `〈きゃ|きょ|きゅ〉`
* singular target / output / keytop: `〈きゃ〉`
* 〈〉《》「」『』【】〖〗〘〙〚〛
* `〈〉《》「」『』【】〖〗〘〙〚〛`

# Codes for Writing Systems

* **`Hang`**: Hangeul
* **`Hani`**: Han (Hanzi, Kanji, Hanja); a.ka. Sinographs, CJK Ideographs
* **`Hira`**: Hiragana
* **`Hrkt`**: Hiragana and Katakana
* **`Kana`**: Katakana [sic]; *we use* **`Kata`** *to avoid confusion*

# XXX TranScriptors with Candidate Lists XXX


# How to Write a TranScriptor Module (TSM)

* name your transcriptor module something like `display-name.ts.js`; the filename must end in the double
  extension `.ts.js`; the part before the extensions will (with hyphens replaced by spaces) become the
  display name as it appears in the MKTW GUI `Transcriptors` menu (but you can override that, see below).
  There must be exactly one transcriptor per `*.ts.js` file.

* Export an transcriptor object with methods and settings. In the below, that object will be symbolized with
  an `@` (at-sign). You can do so either by assigning to `module.exports`, as in `module.exports = {}`, or,
  in case you author your module in CoffeeScript, by attaching all methods and settings `m1`, `m2`, ... to
  the implicit `this`/`@` object, as in `@m1 = ( ... ) -> ...`. Since CoffeeScript is just JavaScript,
  the same can be done in plain JavaScript and TypeScript.

* You may define a member `@display_name = 'display-name'` on the exported object, which must be a string
  and will override the display name as derived from the filename.

* As part of the exported object, define a method called `on_input` that accepts a single argument, `input`:
  `@on_input = ( input ) -> ...`. `input.text` will contain the relevant text as input by the user at that
  point.

* In case `input.text` does not match any of your outputs, or does not constitute a complete match, you may

  * simply do nothing;

  * emit a `^XXXXXXXXXXXXXXX` event to signal no match was found;

  * emit a `^candidates` event to signal that zero or more matches have been found. MKTW will receive that
    event and display the candidates list as it sees fit, allowing the user to ignore it or choose one or
    more candidates.

* The return value of a transcriptor's `on_input()` method is discarded.


## How to Transcribe (i.e. Use a MingKwai TypeWriter Transcriptor)

The editor pane is implemented with [CodeMirror (CM)](https://codemirror.net/).

The editor pane always shows the contents of some text file; by default, this is `.cache/default.md`, but
one can load any text file.

The text in the editor can always be edited as in any text editor; by default, CodeMirror has key bindings
and functionalities that make it very similar to [Sublime Text 3](https://www.sublimetext.com/).

Between the user input and the text that is entered into the editor, there's always a 'transcriptor' (TS)
that acts as a 'proxy' ('man in the middle', or 'middleware') that may complement or replace user inputs
and/or produce a list of 'candidates', that is, possible outputs for the text the user has entered.

The default transcriptor is the 'zero transcriptor' (TS0), which currently does nothing. Transcriptors that
actually do some work are called 'positive (or non-zero) transcriptors'; most of the time, 'transcriptor'
just means 'any transcriptor except for TS0'.

TSs use text in the edited text file to decide what to do next (e.g. replace text or show candidates). If
one edits a file that already has some text in it—say, `irohanihoheto`—and turns on a (positive)
transcriptor—say, `hiragana`—one certainly does not expect that TS to turn that text into `いろはにほへと`, at
least not by default. On the other hand, to take some existing stretch of text and give it the TS treatment
can occasionally be helpful and exactly what one is looking for, so there should be a way to make that
happen.

The point that makes MingKwai TypeWriter really unique is its use of persistent 'transcription regions'
(TSRs) that allow users to mark text stretches intended for transcription. In a MKTW document, each
character is always situated in exactly one TSR. TSRs are color coded for the TranScriptor that is valid
when the cursor is moved inside of them, except for the default, TS0, which remains unmarked.





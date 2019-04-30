
# Caveat

Under development. So far this app will probably only work on Debian-esque Linuxes (inlcuding Ubuntu, Mint).
YMMV. Caveat emptor.

# The MingKwai TypeWriter 明快打字机

The MingKwai TypeWriter 明快打字机 (MKTW) is a Unicode Text Input App and Input Method (IME) built with
[electron](https://electronjs.org) that is especially suited for the input of Sinographs (i.e. Kanji,
Chinese Characters, CJK Ideographs as used in Chinese, Japanese and Korean), but also to use Latin-based
keyboards to input other alphabetic scripts, such as Hangeul, Greek, or Cyrillic.

## Installation

Assuming you have [Git](https://git-scm.com), [NodeJS](https://nodejs.org) (and, therefore,
[`npm`](https://www.npmjs.com/)) already installed:

### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

```bash
git clone https://github.com/loveencounterflow/mingkwai-typewriter
cd mingkwai-typewriter
npm install
```

At this point, a decent NodeJs application with a fully automated installation procedure would be ready for
launch, but we're not quite there yet.

### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

First of all, MingKwai TypeWriter uses
[`loveencounterflow/interflug`](https://github.com/loveencounterflow/interflug) to manipulate GUI windows
and listen to the keyboard, so `interflug` system-level dependencies must also be satisfied:

```bash
sudo apt install xautomation wmctrl xsel
```

### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

MKTW uses a custom build of [SQLite3](https://sqlite.org) which is currently maintained in the (horribly
named) [`sqlite-for-mingkwai-ime`](https://github.com/loveencounterflow/sqlite-for-mingkwai-ime) repo. The C
code in that repo has to be compiled twice, once for the SQLite command line utility (in case you want to
use it), and once as a module for [`better-sqlite3`](https://github.com/JoshuaWise/better-sqlite3), the DB
connector we're using. The `install-better-sqlite3` script will do all that:

```bash
./install-better-sqlite3
```

1) clone the `sqlite-for-mingkwai-ime` repo;
2) build `sqlite-for-mingkwai-ime`, move executable to `./bin`;
3) build `sqlite-for-mingkwai-ime` extensions;
4) clone `better-sqlite3`;
5) <strike>delete `sqlite3.tar.gz` (not needed);</strike>
6) build `better-sqlite3` with `sqlite-for-mingkwai-ime`;
7) <strike>optionally delete `sqlite-for-mingkwai-ime` but keep extensions;</strike>
8) link `better-sqlite3` entry point under `node_modules`.

The last step will create a symlink `node_modules/better-sqlite3` that points to `./better-sqlite3`. This is
somewhat yucky and unsatisfactory, and I'm looking for better ways to accomplish a custom build (preferrably
without having to fork the project). This linking step can be repeated by running:

```bash
./link-better-sqlite3
```

### Matching User Inputs (Deriving Transcriptions from Probes)

* **User Input** or **Probe**—In the narrow sense, the text the user has supplied when trying to obtain a
  specific transcription (the 'target'). In the general sense, user input plus all configurational details
  (like dictionaries considered, transcription mode and so on).

* **Progressive Prefix Matching (PPM)**—Given a user's Probe and a dictionary, all the entries that start
  with the probe (including exact matches) in the dictionary are called Progressive Prefix Matches (PPMs).
  For example, the user may search with `circ` in a dictionary of words occurring in Unicode code point
  names; turns out that as of Unicode v11, the only possible PPMs are `circle`, `circus`, `circled`,
  `circles`, `circuit`, `circling`, `circular`, `circumflex`, and `circulation`.

* **Regressive (or, Partial) Prefix Matching (RPMs)**—Given a user's Probe and a dictionary, all the entries
  that start with any prefix of the Probe are called Regressive Prefix Matches (RPMs). This mode becomes
  relevant when we are given a text and are asked to successively fill in transcriptions where possible,
  until the text is exhausted, which happens to be approximately how Japanese Kana-to-Kanji conversion
  typically works.

  For example, the user may have entered `chuugokunoseifu` (which has already been transcribed to
  `ちゅうごくのせいふ` by Romaji-to-Kana conversion) and hit the spacebar, then the qustion becomes what Kanji, if
  any and where appropriate, match *parts* of this input. In this case, `ちゅう` matches `籌`, `中`,  `宙`,  `忠`
  and a host of other characters, while `ちゅうごく` matches `中国`. Accepting the latter, we find that there are
  no partial matches for `のせいふ` except for `の`, which could be written as `乃`, `之`, `幅`, `布`, `箆`, `篦` (none
  of which seem likely in the context or appropriate for a modern text). If the user should choose to leave
  `の` as `の`, we can then look for partial matches of `せいふ`; and indeed, among the choices—`正負`, `声符`,
  `政府`—there's one that makes sense, so we end up with `中国の政府`, 'Government of China'.—This short example
  makes it abundantly clear that in order to successfully transcribe Japanese from one form into the other,
  much more that any kind of prefix matching has to be done; context, usage, frequencies, collocations and
  so on will have to be considered to narrow down choices.

* **Iterative Matching**—Also called 'next letters', the set of possible next (atomic) steps the user could
  take to arrive at a Match (given a possibly as yet incomplete probe). For example, when inputting Japanese
  Kana, a probe `k` matches all of `ka`, `ke`, `ki`, `kka`, `kke`, `kki`, `kko`, `kku`, `kkya`, `kkyo`,
  `kkyu`, `ko`, `ku`, `kya`, `kyo`, `kyu`; when whittled down to the choices there are among the very next
  letter, this set may be reduced to `ka-`, `ke-`, `ki-`, `kk-`, `ko-`, `ku-`, `ky-`; this entails that
  progressing with anything but `a`, `e`, `i`, `k`, `o`, `u`, `y` will—barring fuzzy matching—certainly
  *not* lead to a result. Likewise, having typed `circ` into a search against Unicode character names (see
  example above) means the next letter must be either `l` or `u`.

### Inspiration

* https://yudit.org/
* http://www.babelstone.co.uk/Software/BabelPad.html
* http://www.babelstone.co.uk/Software/BabelMap.html
* http://www.unipad.org/main/












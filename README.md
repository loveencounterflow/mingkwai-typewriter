
# Abandoned Branch

The `interflug` branch contains code for a (somewhat crude) Kana input method that works (or is intended to
work) directly in all applications. This is achieved by listening to key events in
`/dev/input/by-path/platform-i8042-serio-0-event-kbd` (or whatever the relevant file is called on the user's
machine). These keystrokes (e.g. `[k|y|a]`) are buffered and as soon as a match has been found (in this case
`〈きゃ〉`), that text is written to the clipboard. Finally, a suitable number of backspaces is sent to the
current window, followed by `[ctrl+v]` to cause the application to insert the clipboard contents. These
interactions are implemented via
[`loveencounterflow/interflug`](https://github.com/loveencounterflow/interflug) which does its magic using
`xte`.

While this process does work to an extent, it has a number of problems:

* It's not fast enough; it is too easy to hit keys so fast that translations are intermittently skipped.
  This is super irritating as users have to intentionally slow down themselves and closely proof-read all
  text. Therefore,

* it's not reliable enough.

* There's the unsolved problem how to detect non-keyboard interactions between user and application.

* It is hard to predict an applications exact behavior for all keystrokes, for example, some text editors
  will sometimes but not always insert a right bracket when a left bracket is typed. The input mechanism has
  to basically fly on autopilot through a fog and one can never be sure no strange side-effects happen.

One could ignore the last problem but not the first one. It does look like the root of the performance and
reliability problem does not so much lie with NodeJS or JavaScript, but rather the `xte` command that
`interflug` uses. `xte` has been known to require arbitrary timeouts of hundreds of milliseconds between
some commands to work properly.



# Caveat

Under development. So far this app will probably only work on Debian-esque Linuxes (inlcuding Ubuntu, Mint).
YMMV. Caveat emptor.

# The MingKwai TypeWriter 明快排字机

The MingKwai TypeWriter 明快排字机 (MKTW) is a Unicode Text Input App and Input Method (IME) built with
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













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

### Inspiration

* https://yudit.org/
* http://www.babelstone.co.uk/Software/BabelPad.html
* http://www.babelstone.co.uk/Software/BabelMap.html
* http://www.unipad.org/main/












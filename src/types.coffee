


'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/TYPES'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
jr                        = JSON.stringify
Intertype                 = ( require 'intertype' ).Intertype
intertype                 = new Intertype module.exports

#-----------------------------------------------------------------------------------------------------------
@declare 'position',
  tests:
    '? isa pod':                ( x ) -> @isa.object        x
    '? has_keys line, ch':      ( x ) -> @has_keys          x, 'line', 'ch'
    '?.line is a count':        ( x ) -> @isa.count         x.line
    '?.ch is a count':          ( x ) -> @isa.count         x.ch

#-----------------------------------------------------------------------------------------------------------
@declare 'range',
  tests:
    '? isa pod':                ( x ) -> @isa.object        x
    '? has_keys from, to':      ( x ) -> @has_keys          x, 'from', 'to'
    '?.from is a position':     ( x ) -> @isa.position      x.from
    '?.to is a position':       ( x ) -> @isa.position      x.to

#-----------------------------------------------------------------------------------------------------------
### TAINT should check for upper boundary ###
@declare 'tsnr',
  tests:
    '? is a count':             ( x ) -> @isa.count         x
    # 'transcriptor exists':      ( x ) -> S.transcriptors[ x ]?

#-----------------------------------------------------------------------------------------------------------
### TAINT this describes the *value* property of the event, but this will probably change to the event
itself in the upcoming PipeDreams version. ###
@declare 'replace_text_event',
  tests:
    '? has keys 1':                 ( x ) -> @has_keys          x, 'otext', 'ntext'
    '? has keys 2':                 ( x ) -> @has_keys          x, 'tsnr', 'sigil', 'origin', 'target', 'tsm'
    '?.otext is a nonempty text':   ( x ) -> @isa.nonempty_text x.otext
    '?.ntext is a nonempty text':   ( x ) -> @isa.nonempty_text x.ntext
    '?.sigil is a nonempty text':   ( x ) -> @isa.nonempty_text x.sigil
    '?.tsnr is a tsnr':             ( x ) -> @isa.tsnr          x.tsnr
    '?.target is a position':       ( x ) -> @isa.position      x.target
    '?.tsm is a range':             ( x ) -> @isa.range         x.tsm
    '?.origin is a range':          ( x ) -> @isa.range         x.origin
   # { otext: 'ka',
   #   tsnr: 2,
   #   sigil: 'ひ',
   #   target: { line: 0, ch: 6 },
   #   tsm: { from: { line: 0, ch: 6 }, to: { line: 0, ch: 11 } },
   #   origin: { from: { line: 0, ch: 9 }, to: { line: 0, ch: 11 } },
   #   ntext: 'か' } }

#-----------------------------------------------------------------------------------------------------------
@declare 'edict2u_plural_row',
  tests:
    "? is an object":                   ( x ) -> @isa.object x
    "? has key 'readings'":             ( x ) -> @has_key x, 'readings'
    "? has key 'candidates'":           ( x ) -> @has_key x, 'candidates'
    "? has key 'gloss'":                ( x ) -> @has_key x, 'gloss'
    "? has key 'line'":                 ( x ) -> @has_key x, 'line'
    "?.readings is a *list":            ( x ) -> ( not x.readings? ) or @isa.list x.readings
    "?.candidates is a list":           ( x ) -> @isa.list x.candidates
    "?.gloss is a nonempty text":       ( x ) -> @isa.nonempty_text x.gloss
    "?.line is a nonempty text":        ( x ) -> @isa.nonempty_text x.line

#-----------------------------------------------------------------------------------------------------------
@declare 'edict2u_singular_row',
  tests:
    "? is an object":                   ( x ) -> @isa.object x
    "? has key 'reading'":              ( x ) -> @has_key x, 'reading'
    "? has key 'candidate'":            ( x ) -> @has_key x, 'candidate'
    "? has key 'gloss'":                ( x ) -> @has_key x, 'gloss'
    "? has key 'line'":                 ( x ) -> @has_key x, 'line'
    "?.reading is a nonempty text":     ( x ) -> @isa.nonempty_text x.reading
    "?.candidate is a nonempty text":   ( x ) -> @isa.nonempty_text x.candidate
    "?.gloss is a nonempty text":       ( x ) -> @isa.nonempty_text x.gloss
    "?.line is a nonempty text":        ( x ) -> @isa.nonempty_text x.line

#-----------------------------------------------------------------------------------------------------------
regex_cid_ranges =
  hiragana:     '[\u3041-\u3096]'
  katakana:     '[\u30a1-\u30fa]'
  kana:         '[\u3041-\u3096\u30a1-\u30fa]'
  ideographic:  '[\u3006-\u3007\u3021-\u3029\u3038-\u303a\u3400-\u4db5\u4e00-\u9fef\uf900-\ufa6d\ufa70-\ufad9\u{17000}-\u{187f7}\u{18800}-\u{18af2}\u{1b170}-\u{1b2fb}\u{20000}-\u{2a6d6}\u{2a700}-\u{2b734}\u{2b740}-\u{2b81d}\u{2b820}-\u{2cea1}\u{2ceb0}-\u{2ebe0}\u{2f800}-\u{2fa1d}]'

#-----------------------------------------------------------------------------------------------------------
@declare 'text_with_hiragana',
  tests:
    '? is a text':              ( x ) -> @isa.text   x
    '? has hiragana':           ( x ) -> ( x.match ///#{regex_cid_ranges.hiragana}///u )?

#-----------------------------------------------------------------------------------------------------------
@declare 'text_with_katakana',
  tests:
    '? is a text':              ( x ) -> @isa.text   x
    '? has katakana':           ( x ) -> ( x.match ///#{regex_cid_ranges.katakana}///u )?

#-----------------------------------------------------------------------------------------------------------
@declare 'text_with_kana',
  tests:
    '? is a text':              ( x ) -> @isa.text   x
    '? has kana':               ( x ) -> ( x.match ///#{regex_cid_ranges.kana}///u )?

#-----------------------------------------------------------------------------------------------------------
@declare 'text_with_ideographic',
  tests:
    '? is a text':              ( x ) -> @isa.text   x
    '? has ideographic':        ( x ) -> ( x.match ///#{regex_cid_ranges.ideographic}///u )?

#-----------------------------------------------------------------------------------------------------------
@declare 'text_hiragana',
  tests:
    '? is a text':              ( x ) -> @isa.text   x
    '? is hiragana':            ( x ) -> ( x.match ///^#{regex_cid_ranges.hiragana}+$///u )?

#-----------------------------------------------------------------------------------------------------------
@declare 'text_katakana',
  tests:
    '? is a text':              ( x ) -> @isa.text   x
    '? is katakana':            ( x ) -> ( x.match ///^#{regex_cid_ranges.katakana}+$///u )?

#-----------------------------------------------------------------------------------------------------------
@declare 'text_kana',
  tests:
    '? is a text':              ( x ) -> @isa.text   x
    '? is kana':                ( x ) -> ( x.match ///^#{regex_cid_ranges.kana}+$///u )?

#-----------------------------------------------------------------------------------------------------------
@declare 'text_ideographic',
  tests:
    '? is a text':              ( x ) -> @isa.text   x
    '? is ideographic':         ( x ) -> ( x.match ///^#{regex_cid_ranges.ideographic}+$///u )?

#-----------------------------------------------------------------------------------------------------------
@declare 'blank_text',
  tests:
    '? is a text':              ( x ) -> @isa.text   x
    '? is blank':               ( x ) -> ( x.match ///^\s*$///u )?


############################################################################################################
unless module.parent?
  null



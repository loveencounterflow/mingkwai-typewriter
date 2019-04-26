


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

############################################################################################################
unless module.parent?
  null



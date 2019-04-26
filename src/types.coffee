


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
intertype                 = new Intertype
{ isa
  validate
  type_of
  types_of
  size_of
  declare
  has_keys
  all_keys_of           } = intertype.export_methods()

#-----------------------------------------------------------------------------------------------------------
declare 'position',
  tests:
    '? isa pod':                ( x ) -> @isa.object        x
    '? has_keys line, ch':      ( x ) -> @has_keys          x, 'line', 'ch'
    '?.line is a count':        ( x ) -> @isa.count         x.line
    '?.ch is a count':          ( x ) -> @isa.count         x.ch

#-----------------------------------------------------------------------------------------------------------
declare 'range',
  tests:
    '? isa pod':                ( x ) -> @isa.object        x
    '? has_keys from, to':      ( x ) -> @has_keys          x, 'from', 'to'
    '?.from is a position':     ( x ) -> @isa.position      x.from
    '?.to is a position':       ( x ) -> @isa.position      x.to


############################################################################################################
unless module.parent?
  null



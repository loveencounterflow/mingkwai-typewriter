

'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/KANJI-INPUT'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
alert                     = CND.get_logger 'alert',     badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
#...........................................................................................................
# parallel                  = require './parallel-promise'
DB                        = require './db'
#...........................................................................................................
# _format                   = require 'pg-format'
# I                         = ( value ) -> _format '%I', value
# L                         = ( value ) -> _format '%L', value
#...........................................................................................................
{ jr, }                   = CND
PD                        = require 'pipedreams'
# { remote, }               = require 'electron'
# XE                        = remote.require './xemitter'
XE                        = require './xemitter'
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
#...........................................................................................................
XXX_SETTINGS =
  max_search_results:         500
  search_with_lower_case:     true

#-----------------------------------------------------------------------------------------------------------
@load_keyboard = ->
  ### TAINT compare filedates, refresh cache ###
  t0  = Date.now()
  R   = require '../.cache/cedict_ts.u8.js'
  t1  = Date.now()
  debug 'µ33344', "took #{t1 - t0}ms to load dictionary"
  return R
kanji_triode = @load_keyboard()

#-----------------------------------------------------------------------------------------------------------
@kanji_from_pinyin = ( text ) ->
  text            = text.toLowerCase() if XXX_SETTINGS.search_with_lower_case
  results         = kanji_triode.find text
  R               = []
  for [ pinyin, lemmata, ] in results
    R.push lemma for lemma in lemmata
    if R.length > XXX_SETTINGS.max_search_results
      R.length = XXX_SETTINGS.max_search_results
      break
  return R

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '^input', @, ( d ) ->
  candidates = @kanji_from_pinyin d.value.text
  XE.emit PD.new_event '^candidates', { candidates, }
  return null





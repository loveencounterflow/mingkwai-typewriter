

'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/TRANSCRIPTORS/SIMPLE-HANZI'
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
PD                        = require 'pipedreams'
assign                    = Object.assign
#...........................................................................................................
XXX_SETTINGS =
  max_search_results:         500
  search_with_lower_case:     true

#-----------------------------------------------------------------------------------------------------------
@display_name = '簡單繁體漢字'
@sigil        = '繁'
kanji_triode  = require '../../.cache/cedict_ts.cdt.js'

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
@on_transcribe = ( d ) ->
  { otext, }  = d.value
  return XE.emit PD.new_event '^candidates', { candidates: [], } if otext.length is 0
  candidates = @kanji_from_pinyin otext
  XE.emit PD.new_event '^candidates', assign { candidates, }, d.value
  return null





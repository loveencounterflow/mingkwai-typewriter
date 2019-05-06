

'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/TRANSCRIPTORS/edict2かな漢字変換'
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
@display_name = 'edict2かな漢字変換'
@sigil        = 'か漢'

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
  return null unless otext.length > 0
  ntext       = "[#{otext}]"
  OPS.log PD.new_event '^replace-text', assign {}, d.value, { ntext, }
  XE.emit PD.new_event '^replace-text', assign {}, d.value, { ntext, }
  return null






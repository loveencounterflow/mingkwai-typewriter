

'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/TRANSCRIPTORS/edict2かな漢字変換'
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
#...........................................................................................................
{ assign
  relpath
  abspath }               = require '../helpers'
#...........................................................................................................
{ log
  db }                    = OPS
#...........................................................................................................
XXX_SETTINGS =
  max_search_results:         500
  search_with_lower_case:     true
#...........................................................................................................
@initialized              = false

#-----------------------------------------------------------------------------------------------------------
@display_name = 'edict2かな漢字変換'
@sigil        = 'か漢'
@table_name   = 'edict2u'

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
@initialize = ->
  @initialized = true
  return if ( db.$.type_of @table_name ) is 'table'
  t0      = Date.now()
  db[ "create_table_#{@table_name}" ]()
  path    = abspath '.cache/edict2u.sql'
  log "reading #{relpath path}"
  db.$.read path
  log "creating indexes for #{@table_name}"
  db.create_indexes_for_table_edict2u()
  dt      = Date.now() - t0
  log "created table #{@table_name} and indexes in #{dt}ms"

#-----------------------------------------------------------------------------------------------------------
@on_transcribe = ( d ) ->
  @initialize() unless @initialized
  { otext, }  = d.value
  return null unless otext.length > 0
  ntext       = "[#{otext}]"
  XE.emit PD.new_event '^replace-text', assign {}, d.value, { ntext, }
  return null






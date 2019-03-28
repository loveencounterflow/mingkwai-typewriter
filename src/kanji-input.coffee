

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
  max_search_results:         10
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
XE.contract '^raw-input', @, ( d ) ->
  #.........................................................................................................
  { S, change, }  = d.value
  { editor, }     = S.codemirror
  { doc, }        = editor
  cursor          = doc.getCursor()
  #.........................................................................................................
  ### TAINT kludge to collapse multiple selections into a single one ###
  CodeMirror.commands.singleSelection editor
  #.........................................................................................................
  line_idx        = cursor.line
  line_handle     = doc.getLineHandle line_idx
  line_info       = doc.lineInfo line_handle ### TAINT consider to use line_idx, forego line_handle ###
  { text, }       = line_info
  # #.........................................................................................................
  # ### TAINT put this event further up in the chain ###
  # ### make behavior on paste configurable ###
  # debug 'µ77733', change
  # if change.origin is 'paste'
  #   head  = Array.from text
  #   tail  = []
  #   while ( chr = head.shift() )
  #     tail.push chr
  #     text = tail.join ''
  #     XE.emit PD.new_event '^input', { S, change, editor, doc, line_idx, text, }
  # #.........................................................................................................
  # else
  XE.emit PD.new_event '^input', { S, change, editor, doc, line_idx, text, }
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
XE.contract '^input', @, ( d ) ->
  v       = d.value
  { S, }  = v
  #.........................................................................................................
  # whisper 'µ34343', xrpr change
  candidates      = @kanji_from_pinyin v.text
  debug 'µ44733', candidates
  text            = candidates.join ', '
  urge 'µ34343', ( xrpr v.text ) + ' -> ' + ( xrpr text )
  XE.emit PD.new_event '^candidates', { S, candidates, }
  ### TAINT replacing the text of the entire line is one way to insert new text, but it would conceivably
  more elegant and / or more correct if we just replaced in the editor what we're replacing in the text ###
  ### TAINT consider to build micro shim so we get rid of these (for our use case) bizarre API choices ###
  # CodeMirror.commands.goLineEnd   v.editor
  # CodeMirror.commands.delLineLeft v.editor
  # v.doc.replaceSelection text
  return null

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '<keyboard-level', ( d ) ->
  # urge 'µ55402', jr d

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '>keyboard-level', ( d ) ->
  # urge 'µ55403', jr d





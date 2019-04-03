

'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/TRANSCRIPTORS/SIMPLE-HIRAGANA.TRS'
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
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
PD                        = require 'pipedreams'

#-----------------------------------------------------------------------------------------------------------
@load_keyboard = ->
  ### TAINT compare filedates, refresh cache ###
  return require '../../.cache/jp_kana.hrgn.keyboard.wsv.js'
  # return require '../../.cache/gr_gr.keyboard.wsv.js'
key_replacer = @load_keyboard()

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '^input', ( d ) ->
  v = d.value
  #.........................................................................................................
  # whisper 'µ34343', xrpr change
  text            = key_replacer v.text
  OPS.log 'µ34343', ( xrpr v.text ) + ' -> ' + ( xrpr text ) if v.text isnt text
  ### TAINT replacing the text of the entire line is one way to insert new text, but it would conceivably
  more elegant and / or more correct if we just replaced in the editor what we're replacing in the text ###
  ### TAINT consider to build micro shim so we get rid of these (for our use case) bizarre API choices ###
  ### Announce to ignore next `+delete` event as it did not originate from user input: ###
  await XE.emit PD.new_event '^ignore-delete'
  CodeMirror.commands.goLineEnd   S.codemirror.editor
  CodeMirror.commands.delLineLeft S.codemirror.editor
  S.codemirror.editor.doc.replaceSelection text
  return null







'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/TRANSCRIPTORS/SIMPLE-HIRAGANA'
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
assign                    = Object.assign
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
PD                        = require 'pipedreams'

#-----------------------------------------------------------------------------------------------------------
@display_name     = '簡単なひらがな'
@sigil            = 'ひ'
@focus_candidates = false
@_transcribe      = null
@_hiragana_triode = null

#-----------------------------------------------------------------------------------------------------------
@init = ->
  ### TAINT compare filedates, refresh cache ###
  @_transcribe      = require '../../.cache/jp_kana.kbd.js'
  @_hiragana_triode = require '../../.cache/jp_kana.cdt.js'

#-----------------------------------------------------------------------------------------------------------
@transcribe = ( text ) ->
  R = ''
  R = ( @_transcribe R + chr ) for chr in Array.from text
  return R

#-----------------------------------------------------------------------------------------------------------
@on_transcribe = ( d ) ->
  @init() unless ( @_transcribe? and @_hiragana_triode? )
  #.........................................................................................................
  { otext, }        = d.value
  focus_candidates  = @focus_candidates
  #.........................................................................................................
  ### Candidates: ###
  if otext.length is 0
    XE.emit PD.new_event '^candidates', { candidates: [], focus_candidates, }
  else
    candidates        = (  { candidate: lemma, } for [ transcription, lemma, ] in @_hiragana_triode.find otext )
    XE.emit PD.new_event '^candidates', assign { candidates, focus_candidates, }, d.value
  #.........................................................................................................
  ### Keyboard: ###
  ntext       = @transcribe otext
  if otext isnt ntext
    OPS.log 'µ34343', ( rpr otext ) + ' -> ' + ( rpr ntext )
    XE.emit PD.new_event '^replace-text', assign {}, d.value, { ntext, }
  return null







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

#-----------------------------------------------------------------------------------------------------------
### TAINT compare filedates, refresh cache ###
@load_kbd = -> require '../../.cache/jp_kana.kbd.js'
@load_cdt = -> require '../../.cache/jp_kana.cdt.js'
  # return require '../../.cache/gr_gr.keyboard.wsv.js'
transcribe      = @load_kbd()
hiragana_triode = @load_cdt()

#-----------------------------------------------------------------------------------------------------------
@transcribe = ( text ) ->
  R = ''
  R = ( transcribe R + chr ) for chr in Array.from text
  return R

#-----------------------------------------------------------------------------------------------------------
@init = -> OPS.log "#{badge}/init()"

#-----------------------------------------------------------------------------------------------------------
@on_transcribe = ( d ) ->
  { otext, }        = d.value
  focus_candidates  = @focus_candidates
  #.........................................................................................................
  ### Candidates: ###
  if otext.length is 0
    XE.emit PD.new_event '^candidates', { candidates: [], focus_candidates, }
  else
    candidates        = ( lemma for [ transcription, lemma, ] in hiragana_triode.find otext )
    XE.emit PD.new_event '^candidates', assign { candidates, focus_candidates, }, d.value
  #.........................................................................................................
  ### Keyboard: ###
  ntext       = @transcribe otext
  if otext isnt ntext
    OPS.log 'µ34343', ( rpr otext ) + ' -> ' + ( rpr ntext )
    XE.emit PD.new_event '^replace-text', assign {}, d.value, { ntext, }
  return null





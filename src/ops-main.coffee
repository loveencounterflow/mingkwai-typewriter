
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/OPS-MAKESHIFT'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
KEYS                      = require '../lib/keys'
T                         = require '../lib/templates'
PATH                      = require 'path'
FS                        = require 'fs'
#...........................................................................................................
require                   '../lib/exception-handler'
# require                   '../lib/kana-input'
# require                   '../lib/kanji-input'
#...........................................................................................................
PD                        = require 'pipedreams'
{ jr, }                   = CND
{ after, }                = CND.suspend
defer                     = setImmediate
{ $
  $async }                = PD
# XE                        = null
XE                        = require '../lib/xemitter'
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@always_focus_editor = ->
  ### TAINT this method inhibits selecting, copying text from logger, candidates ###
  @always_focus_editor = -> ### do not add any more handlers with this method after first call ###
  ( jQuery 'div.CodeMirror-code' ).on 'blur', -> @focus()
  ( jQuery 'div.CodeMirror-code' ).focus()
  return null



#===========================================================================================================
# FOCUSFRAME
#-----------------------------------------------------------------------------------------------------------
@toggle_focusframe = ->
  # @log "S.focus_is_candidates: #{S.focus_is_candidates}"
  if S.focus_is_candidates  then  @focusframe_to_editor()
  else                            @focusframe_to_candidates()
  return null

#-----------------------------------------------------------------------------------------------------------
@focusframe_to_editor = ->
  @_focusframe_to 'leftbar'
  S.focus_is_candidates = false

#-----------------------------------------------------------------------------------------------------------
@focusframe_to_candidates = ->
  @_focusframe_to 'rightbar'
  S.focus_is_candidates = true

#-----------------------------------------------------------------------------------------------------------
@_focusframe_to = ( target ) ->
  # target      = jQuery( document.activeElement )
  target      = jQuery target if CND.isa_text target
  ff          = jQuery 'focusframe'
  return if target.length < 1
  # ff.offset     target.offset()
  # ff.width      target.width()
  # ff.height     target.height()
  tgto        = target.offset()
  return unless tgto?
  left    = tgto.left       - 1
  top     = tgto.top        - 1
  width   = target.width()  + 2
  height  = target.height() + 2
  ff.animate { left, top, width, height, }, 100
  return null

#===========================================================================================================
# WINDOW
#-----------------------------------------------------------------------------------------------------------
@get_window = -> ( require 'electron' ).remote.getCurrentWindow()



#===========================================================================================================
# APP INITIALIZATION
#-----------------------------------------------------------------------------------------------------------
@init = ->
  # { remote, }               = require 'electron'
  # XE                        = remote.require './xemitter'
  #.........................................................................................................
  S.candidates          =
    jq:           jQuery '#candidates'
    selected:
      id:         null
  S.focus_is_candidates = false
  #.........................................................................................................
  ### Initialize CodeMirror ###
  S.codemirror.editor = CodeMirror.fromTextArea ( jQuery '#codemirror' )[ 0 ], S.codemirror.settings
  S.codemirror.editor.setSize null, '100%'
  S.codemirror.editor.on 'inputRead', ( me, change ) -> XE.emit PD.new_event '^raw-input', { change, }
  XE.listen_to '^ignore-delete', -> S.ignore_delete += +1
  S.codemirror.editor.on 'change', ( me, change ) ->
    ### TAINT when inserting results, will there be a change event? ###
    return null unless change.origin is '+delete'
    ### ignore event if it has been generated: ###
    if S.ignore_delete > 0
      S.ignore_delete += -1
      return null
    XE.emit PD.new_event '^raw-input', { change, }
  @always_focus_editor()
  #.........................................................................................................
  # S.codemirror.editor.on 'beforeChange',    ( me, change      ) -> whisper 'µ66653', 'beforeChange',  jr change
  # S.codemirror.editor.on 'change',          ( me, change      ) -> whisper 'µ66653', 'change',        jr change
  # S.codemirror.editor.on 'changes',         ( me, changes     ) -> whisper 'µ66653', 'changes',       jr changes
  # S.codemirror.editor.on 'cursorActivity',  ( me              ) -> whisper 'µ66653', 'cursorActivity'
  # S.codemirror.editor.on 'keyHandled',      ( me, name, event ) -> whisper 'µ66653', 'keyHandled',    jr name
  # S.codemirror.editor.on 'inputRead',       ( me, change      ) -> whisper 'µ66653', 'inputRead',     jr change
  #.........................................................................................................
  ### Register key and mouse events ###
  KEYS.generate_keboard_events jQuery 'html'
  # KEYS.register 'axis', 'vertical',     ( uie )   => @on_vertical_navigation  uie
  # KEYS.register 'slot', 'Enter',        ( uie )   => @on_add_selection        uie
  @add_menu()
  @restore_documents()
  @focusframe_to_editor()
  @set_codemirror_keybindings()
  @set_app_keybindings()
  @set_event_bindings()
  @log 'µ49884', ( k for k of @ ).sort()
  #.........................................................................................................
  ### Detect resizing events: ###
  ### TAINT won't work when panes are shifted (probably) ###
  ( jQuery window ).on 'resize', =>
    debug "resize window"
    @index_candidates()
    return null
  return null





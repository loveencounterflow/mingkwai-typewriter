
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
#...........................................................................................................
require                   '../lib/exception-handler'
@db                       = ( require './db' ).new_db { clear: false, }


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
  if S.focus_is_candidates  then  @focusframe_to_editor()
  else                            @focusframe_to_candidates()
  return null

#-----------------------------------------------------------------------------------------------------------
@adjust_focusframe = ->
  if S.focus_is_candidates  then  @focusframe_to_candidates()
  else                            @focusframe_to_editor()
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
@get_window     = -> ( require 'electron' ).remote.getCurrentWindow()
@open_devtools  = -> @get_window().webContents.openDevTools()


#===========================================================================================================
# APP INITIALIZATION
#-----------------------------------------------------------------------------------------------------------
@init = ->
  #.........................................................................................................
  ### Initialize CodeMirror ###
  S.codemirror.editor = CodeMirror.fromTextArea ( jQuery '#codemirror' )[ 0 ], S.codemirror.settings
  S.codemirror.editor.setSize null, '100%'
  @always_focus_editor()
  KEYS.generate_keboard_events jQuery 'html'
  #.........................................................................................................
  await @load_transcriptors()
  await @add_menu()
  await @add_context_menu()
  #.........................................................................................................
  await @set_codemirror_keybindings()
  await @set_codemirror_event_bindings()
  await @set_app_keybindings()
  await @set_xe_event_bindings()
  await @set_dom_event_bindings()
  #.........................................................................................................
  await @focusframe_to_editor()
  await @dbg_set_debugging_globals()
  # await @dbg_list_all_css_classes_in_document()
  # await @cm_select_all()
  #.........................................................................................................
  await @restore_documents()
  await @focusframe_to_editor()
  #.........................................................................................................
  return null





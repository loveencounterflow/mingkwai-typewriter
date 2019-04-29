
'use strict'


############################################################################################################
# CND                       = require 'cnd'
# rpr                       = CND.rpr
# badge                     = '明快打字机/OPS-BINDINGS'
# debug                     = CND.get_logger 'debug',     badge
# alert                     = CND.get_logger 'alert',     badge
# whisper                   = CND.get_logger 'whisper',   badge
# warn                      = CND.get_logger 'warn',      badge
# help                      = CND.get_logger 'help',      badge
# urge                      = CND.get_logger 'urge',      badge
# info                      = CND.get_logger 'info',      badge
PD                        = require 'pipedreams'
KEYS                      = require './keys'
XE                        = require './xemitter'


#===========================================================================================================
# KEY BINDINGS
#-----------------------------------------------------------------------------------------------------------
@_cm_keymap_move = ( cm, editor_method_name, candidates_method ) ->
  try
    return CodeMirror.commands[ editor_method_name ] cm unless S.focus_is_candidates
    return candidates_method.apply @
  catch error
    alert "when trying to call `CodeMirror.commands.#{editor_method_name}`, an error was thrown"
    throw error
  return null

#-----------------------------------------------------------------------------------------------------------
### TAINT the defaults for cursor moves are taken from
* public/codemirror/src/edit/commands.js
* public/codemirror/keymap/sublime.js
it would be advantageous to derive them somehow from the source or the running instance
###
@move_right         = ( cm ) -> @_cm_keymap_move cm, 'goCharRight', => @_select_delta_candidate { lnr: +1, }
@move_left          = ( cm ) -> @_cm_keymap_move cm, 'goCharLeft',  => @_select_delta_candidate { lnr: -1, }
@move_nxtline_first = ( cm ) -> @_cm_keymap_move cm, 'defaultTab',  => @_select_delta_candidate { lcol: 'first', lrow: +1, }
@move_prvline_first = ( cm ) -> @_cm_keymap_move cm, 'indentLess',  => @_select_delta_candidate { lcol: 'first', lrow: -1, }
@move_up            = ( cm ) -> @_cm_keymap_move cm, 'goLineUp',    => @log '######### move_up'
@move_down          = ( cm ) -> @_cm_keymap_move cm, 'goLineDown',  => @log '######### move_down'
@move_to_home       = ( cm ) -> @_cm_keymap_move cm, 'goLineStartSmart', => @_select_delta_candidate { lrow: 0, lcol: 'first', }
@move_to_end        = ( cm ) -> @_cm_keymap_move cm, 'goLineEnd',  => @_select_delta_candidate { lrow: 0, lcol: 'last',  }

#-----------------------------------------------------------------------------------------------------------
@set_codemirror_keybindings = ->
  ### TAINT consider to map keys pressed in CM to PipeDreams events so we can handle all keyboard shortcuts
  in a unified way (and idependently from originating DOM element) ###
  mktw_keymap =
    'Left':         ( cm ) => @move_left                        cm
    'Right':        ( cm ) => @move_right                       cm
    'Up':           ( cm ) => @move_up                          cm
    'Down':         ( cm ) => @move_down                        cm
    'Tab':          ( cm ) => @move_nxtline_first               cm
    'Shift-Tab':    ( cm ) => @move_prvline_first               cm
    'Home':         ( cm ) => @move_to_home                     cm
    'End':          ( cm ) => @move_to_end                      cm
    'Space':        ( cm ) => @select_candidate_or_insert_space cm
    'Ctrl-M':       ( cm ) => @cm_jump_to_tsr_or_bracket()
    'Shift-Ctrl-M': ( cm ) => @cm_mark_tsr_or_bracket()
    'Ctrl-0':       ( cm ) => @insert_tsm 0
    'Ctrl-1':       ( cm ) => @insert_tsm 1
    'Ctrl-2':       ( cm ) => @insert_tsm 2
    'Ctrl-3':       ( cm ) => @insert_tsm 3
    'Ctrl-4':       ( cm ) => @insert_tsm 4
    'Ctrl-5':       ( cm ) => @insert_tsm 5
    'Ctrl-6':       ( cm ) => @insert_tsm 6
    'Ctrl-7':       ( cm ) => @insert_tsm 7
    'Ctrl-8':       ( cm ) => @insert_tsm 8
    'Ctrl-9':       ( cm ) => @insert_tsm 9
  #.........................................................................................................
  S.codemirror.editor.addKeyMap mktw_keymap
  return null

#-----------------------------------------------------------------------------------------------------------
@set_codemirror_event_bindings = ->
  S.codemirror.editor.on 'cursorActivity', ( cm ) => @emit_transcribe_event() unless @is_frozen()
  return null

#-----------------------------------------------------------------------------------------------------------
@set_app_keybindings = ->
  KEYS.bind 'alt',      @, @show_or_hide_menu_bar
  KEYS.bind 'shift',    @, @toggle_focusframe
  KEYS.bind 'ctrl+s',   @, @save_document
  return null

#-----------------------------------------------------------------------------------------------------------
@set_xe_event_bindings = ->
  XE.listen_to_all                      @, @log_almost_all_events
  XE.listen_to '^candidates',           @, @display_candidates
  XE.listen_to '^replace-text',         @, @on_replace_text
  XE.listen_to '^window-resize',        @, @index_candidates
  XE.listen_to '^window-resize',        @, @adjust_focusframe
  XE.listen_to '^transcribe',           @, @dispatch_transcribe_event
  XE.listen_to '^open-document',        @, @format_existing_tsms

#-----------------------------------------------------------------------------------------------------------
@set_dom_event_bindings = ->
  ### TAINT won't work when panes are shifted (probably) ###
  ( jQuery window ).on 'resize', => XE.emit PD.new_event '^window-resize'





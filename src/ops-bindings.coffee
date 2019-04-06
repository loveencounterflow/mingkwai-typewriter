
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
  mktw_keymap =
    'Left':       ( cm ) => @move_left                 cm
    'Right':      ( cm ) => @move_right                cm
    'Up':         ( cm ) => @move_up                   cm
    'Down':       ( cm ) => @move_down                 cm
    'Tab':        ( cm ) => @move_nxtline_first        cm
    'Shift-Tab':  ( cm ) => @move_prvline_first        cm
    'Home':       ( cm ) => @move_to_home              cm
    'End':        ( cm ) => @move_to_end               cm
    'Space':      ( cm ) => @insert_space_or_selection cm
    'Ctrl-M':     ( cm ) => @cm_mark_tsrs()
    'Ctrl-0':     ( cm ) => @cm_set_tsrs 0
    'Ctrl-1':     ( cm ) => @cm_set_tsrs 1
    'Ctrl-2':     ( cm ) => @cm_set_tsrs 2
    'Ctrl-3':     ( cm ) => @cm_set_tsrs 3
    'Ctrl-4':     ( cm ) => @cm_set_tsrs 4
  #.........................................................................................................
  S.codemirror.editor.addKeyMap mktw_keymap
  return null

#-----------------------------------------------------------------------------------------------------------
@set_codemirror_event_bindings = ->
  S.codemirror.editor.on 'cursorActivity', ( cm, change ) => @cm_find_transcriptor_and_tsr()
  #.........................................................................................................
  ### Emit the `change` object that comes from a CM `inputRead` event: ###
  S.codemirror.editor.on 'inputRead', ( cm, change ) =>
    XE.emit @input_event_from_change_object change
  #.........................................................................................................
  ### Emit the `change` object that results from a CM `chnage/+delete` event, except `ignore_delete` is
  active: ###
  S.codemirror.editor.on 'change', ( cm, change ) =>
    ### TAINT when inserting results, will there be a change event? ###
    return null unless change.origin is '+delete'
    ### ignore event if it has been generated: ###
    if S.ignore_delete > 0
      S.ignore_delete += -1
      return null
    XE.emit @input_event_from_change_object change
  #.........................................................................................................
  ### Adjust `ignore_delete` counter: ###
  XE.listen_to '^ignore-delete', =>
    S.ignore_delete += +1
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@set_app_keybindings = ->
  KEYS.bind 'alt',      @, @show_or_hide_menu_bar
  KEYS.bind 'shift',    @, @toggle_focusframe
  KEYS.bind 'ctrl+s',   @, @save_document
  # KEYS.bind 'ctrl+m',   @, @cm_mark_tsrs
  # KEYS.bind 'ctrl+0',   @, -> @cm_set_tsrs 0
  # KEYS.bind 'ctrl+1',   @, -> @cm_set_tsrs 1
  # KEYS.bind 'ctrl+2',   @, -> @cm_set_tsrs 2
  # KEYS.bind 'ctrl+3',   @, -> @cm_set_tsrs 3
  # KEYS.bind 'ctrl+4',   @, -> @cm_set_tsrs 4
  return null

#-----------------------------------------------------------------------------------------------------------
@set_xe_event_bindings = ->
  XE.listen_to_all                      @, @log_almost_all_events
  XE.listen_to '^candidates',           @, @display_candidates
  XE.listen_to '^window-resize',        @, @index_candidates
  XE.listen_to '^window-resize',        @, @adjust_focusframe
  XE.listen_to '^select-transcriptor',  @, @select_transcriptor

#-----------------------------------------------------------------------------------------------------------
@set_dom_event_bindings = ->
  ### TAINT won't work when panes are shifted (probably) ###
  ( jQuery window ).on 'resize', => XE.emit PD.new_event '^window-resize'





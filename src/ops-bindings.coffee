
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
    'Left':       ( cm  ) => @move_left                 cm
    'Right':      ( cm  ) => @move_right                cm
    'Up':         ( cm  ) => @move_up                   cm
    'Down':       ( cm  ) => @move_down                 cm
    'Tab':        ( cm  ) => @move_nxtline_first        cm
    'Shift-Tab':  ( cm  ) => @move_prvline_first        cm
    'Home':       ( cm  ) => @move_to_home              cm
    'End':        ( cm  ) => @move_to_end               cm
    'Space':      ( cm  ) => @insert_space_or_selection cm
  #.........................................................................................................
  S.codemirror.editor.addKeyMap mktw_keymap
  return null

#-----------------------------------------------------------------------------------------------------------
@set_app_keybindings = ->
  KEYS.bind 'alt',      @, @show_or_hide_menu_bar
  KEYS.bind 'shift',    @, @toggle_focusframe
  KEYS.bind 'ctrl+s',   @, @save_document
  return null

#-----------------------------------------------------------------------------------------------------------
@set_event_bindings = ->
  XE.listen_to_all @, @log_all_events



'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/OPS-CM'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
#...........................................................................................................
PD                        = require 'pipedreams'


#-----------------------------------------------------------------------------------------------------------
@_cm_as_pos = ( x ) -> { line: x.line, ch: x.ch, } ### Unify position-like objects ###

#-----------------------------------------------------------------------------------------------------------
@_cm_order_positions  = ( positions ) -> positions.sort ( a, b ) ->
  return -1 if a.line < b.line
  return +1 if a.line > b.line
  return -1 if a.ch   < b.ch
  return +1 if a.ch   > b.ch
  return  0

#-----------------------------------------------------------------------------------------------------------
@_cm_fromto_from_range = ( range ) ->
  ### Given a `range` with `anchor` and `head` properties (which must both be positions, i.e.
  `{ line, ch, }` objects), return a `{ from, to, }` object where `from` comes always before or coincides
  with `to` in the document. This is needed to convert an object returned e.g. as selection to an
  argument that can be used by `markText()`. ###
  [ p, q, ] = @_cm_order_positions [ ( @_cm_as_pos range.anchor ), ( @_cm_as_pos range.head ), ]
  debug 'µ77833', '_cm_order_positions', ( @_cm_as_pos range.anchor ), ( @_cm_as_pos range.head )
  debug 'µ77833', '_cm_fromto_from_range', p, q
  return { from: p, to: q, }


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@cm_select_only_first   = -> CodeMirror.commands.singleSelection S.codemirror.editor
@cm_get_selections      = -> S.codemirror.editor.doc.listSelections()
### TAINT actually gets one of the selections; maybe rewrite to obtain first in document order ###
@cm_get_first_selection_as_fromto = -> @_cm_fromto_from_range @cm_get_selections()[ 0 ]

#-----------------------------------------------------------------------------------------------------------
@cm_set_mark = ( fromto, clasz ) ->
  settings =
    className:      clasz
    inclusiveLeft:  false
    inclusiveRight: true
  return S.codemirror.editor.markText fromto.from, fromto.to, settings

#-----------------------------------------------------------------------------------------------------------
@cm_clear_translation_mark = ->
  return 0 unless S.translation_mark?
  S.translation_mark.clear()
  S.translation_mark = null
  return 1

#-----------------------------------------------------------------------------------------------------------
@cm_set_translation_mark = ->
  @cm_select_only_first()
  @cm_clear_translation_mark()
  S.translation_mark = @cm_set_mark @cm_get_first_selection_as_fromto(), 'translation_mark'
  return 1





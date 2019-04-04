
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
@_cm_pos = ( obj ) -> { line: obj.line, ch: obj.ch, } ### Unify position-like objects ###

#-----------------------------------------------------------------------------------------------------------
@_cm_order_pos  = ( p, q ) -> [ p, q, ].sort ( a, b ) ->
  return -1 if p.line > q.line
  return +1 if p.line < q.line
  return -1 if p.ch   > q.ch
  return +1 if p.ch   < q.ch
  return  0

#-----------------------------------------------------------------------------------------------------------
@_cm_ordered_from_to = ( range ) ->
  ### Unify ranges; result will be `{ from: { line, ch, }, to: { line, ch, }, }` where `to` is always on
  or after `from`. ###
  [ p, q, ] = @_cm_order_pos ( @_cm_pos range.anchor ), ( @_cm_pos range.head )
  return { from: p, to: q, }

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@cm_select_only_first   = -> CodeMirror.commands.singleSelection S.codemirror.editor
@cm_get_selections      = -> S.codemirror.editor.doc.listSelections()
### TAINT actually gets one of the selections; maybe rewrite to obtain first in document order ###
@cm_get_first_selection = -> @_cm_ordered_from_to @cm_get_selections()[ 0 ]





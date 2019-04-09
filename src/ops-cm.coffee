
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
  return { from: p, to: q, }


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@cm_select_all                    = -> CodeMirror.commands.selectAll        S.codemirror.editor
@cm_select_only_first             = -> CodeMirror.commands.singleSelection  S.codemirror.editor
@cm_get_selections                = -> S.codemirror.editor.doc.listSelections()
@cm_get_selection_texts           = -> S.codemirror.editor.doc.getSelections()
@cm_get_selections_as_fromtos     = -> ( @_cm_fromto_from_range s for s in @cm_get_selections() )
# #-----------------------------------------------------------------------------------------------------------
# @cm_select_only_in_single_line = ->

#-----------------------------------------------------------------------------------------------------------
@cm_set_mark = ( fromto, clasz ) ->
  @log 'µ52981', "@cm_set_mark #{rpr fromto}, #{rpr clasz}"
  settings =
    className:      clasz
    inclusiveLeft:  true
    inclusiveRight: true
  return S.codemirror.editor.markText fromto.from, fromto.to, settings

#-----------------------------------------------------------------------------------------------------------
# @cm_clear_translation_mark = ->
#   return 0 unless S.translation_mark?
#   S.translation_mark.clear()
#   S.translation_mark = null
#   return 1

#-----------------------------------------------------------------------------------------------------------
@cm_get_marks_in_range        = ( fromto    ) -> S.codemirror.editor.findMarks fromto.from, fromto.to
@cm_get_mark_fromtos_in_range = ( fromto    ) -> ( ( @_cm_as_pos t.find() ) for t in @cm_get_marks_in_position fromto )
@cm_get_marks_in_position     = ( position  ) -> S.codemirror.editor.findMarksAt position
@cm_get_cursor                =               -> @_cm_as_pos S.codemirror.editor.getCursor 'head'
@cm_set_cursor                = ( position  ) -> S.codemirror.editor.setCursor position ### TAINT might want to use options ###
@cm_get_text                  = ( fromto    ) -> S.codemirror.editor.getRange fromto.from, fromto.to
@cm_text_from_mark            = ( mark      ) -> @cm_get_text mark.find()
@cm_text_from_line_idx        = ( line_idx  ) -> S.codemirror.editor.getLine line_idx
@cm_replace_selection         = ( text      ) -> S.codemirror.editor.doc.replaceSelection text
@cm_range_is_point            = ( fromto    ) -> CND.equals fromto.from, fromto.to

#-----------------------------------------------------------------------------------------------------------
@cm_select = ( fromto ) ->
  @log 'µ53082', "cm_select: #{rpr fromto}"
  return S.codemirror.editor.setSelection fromto.from, fromto.to

#-----------------------------------------------------------------------------------------------------------
@position_and_clasz_from_mark = ( mark ) ->
  fromto = mark.find()
  return { from: ( @_cm_as_pos fromto.from ), to: ( @_cm_as_pos fromto.to ), clasz: ( mark.className ? '' ), }






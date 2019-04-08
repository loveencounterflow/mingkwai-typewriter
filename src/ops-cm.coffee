
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


#===========================================================================================================
# SET TSRs, TRANSCRIPTORS
#-----------------------------------------------------------------------------------------------------------
@cm_set_tsrs_NG = ( tsnr ) ->
  ### Bound to `ctrl+0` ... `ctrl+4` ###
  action  = if tsnr is 0 then 'clear' else 'set'
  if action is 'clear'
    @log 'µ48733-1', "clear TSR not implemented"
    return null
  delta   = if action is 'clear' then -1 else +1
  clasz   = "tsr tsr#{tsnr}"
  for fromto in @cm_get_selections_as_fromtos()
    unless @cm_range_is_point fromto
      @log 'µ48733-2', "non-point ranges not implemented"
      return null
    @log 'µ48733-4', rpr fromto
    ### TAINT use own API ###
    ### TAINT allow to configure appearance of TSR mark ###
    # tsr_mark_left = "[#{S.transcriptors[ tsnr ].display_name}:"
    tsr_mark_left = "🛸#{tsnr}:"
    clasz         = "tsrNG tsrNG#{tsnr}"
    fromto_right  = { line: fromto.from.line, ch: ( fromto.from.ch + tsr_mark_left.length ), }
    settings      =
      className:        clasz
      atomic:           true
      inclusiveLeft:    false
      inclusiveRight:   false
    S.codemirror.editor.replaceRange tsr_mark_left, fromto.from
    S.codemirror.editor.markText fromto.from, fromto_right, settings
  S.emit_transcribe_event_NG()
  return null

#-----------------------------------------------------------------------------------------------------------
@emit_transcribe_event_NG = ->
  text = @cm_text_from_line_idx @cm_get_cursor().line
  return null if text.length is 0
  return unless ( match = text.match /🛸(?<tsnr>[0-9]+):(?<text>[.*?])$/ )?
  @log 'µ76663', rpr match.groups
  return null

# #-----------------------------------------------------------------------------------------------------------
# @cm_set_tsrs = ( tsnr ) ->
#   ### Bound to `ctrl+0` ... `ctrl+4` ###
#   ### TAINT code duplication ###
#   # @cm_select_only_in_single_line()
#   # @cm_clear_translation_mark()
#   action  = if tsnr is 0 then 'clear' else 'set'
#   delta   = if action is 'clear' then -1 else +1
#   clasz   = "tsr tsr#{tsnr}"
#   count   = 0
#   for fromto in @cm_get_selections_as_fromtos()
#     range_is_point = @cm_range_is_point fromto
#     if range_is_point then  old_marks = @cm_get_marks_in_position  fromto.from
#     else                    old_marks = @cm_get_marks_in_range     fromto
#     for old_mark in old_marks
#       do ( old_mark ) =>
#         @log 'µ53183', "found old mark: #{rpr @position_and_clasz_from_mark old_mark}"
#         old_mark.clear()
#     if action is 'set'
#       if range_is_point
#         ### TAINT use own API ###
#         S.codemirror.editor.replaceRange '\ue044', fromto.from
#         fromto1 = { from: fromto.from, to: { line: fromto.from.line, ch: ( fromto.from.ch + 1 ), }, }
#         @cm_select fromto1
#         mark    = @cm_set_mark fromto1, clasz
#       else
#         ### TAINT trailing newlines, empty lines are probably a bad idea; if CodeMirror would only visibly
#         mark those, but it doesn't ###
#         if ( nl_count = ( ( @cm_get_text fromto ).match /(\n*)$/ )[ 1 ].length ) > 0
#           @log 'µ53284', "fromto #{rpr fromto} contains empty lines"
#         mark = @cm_set_mark fromto, clasz
#       ### TAINT this is doing too much work for this case: ###
#       @emit_transcribe_event()
#   return count

# #-----------------------------------------------------------------------------------------------------------
# @emit_transcribe_event = ->
#   ### Called on CM `CursorActivity`, reads text from current TSR if any, emits XE `^transcribe` ###
#   # @log 'µ53486', 'cm_find_ts', "cursor at #{rpr @cm_get_cursor()}"
#   marks = @cm_get_marks_in_position @cm_get_cursor()
#   #.........................................................................................................
#   if marks.length is 0
#     S.tsnr          = 0
#     S.tsr           = null
#     S.tsr_text      = null
#     S.transcriptor  = S.transcriptors[ 0 ]
#   #.........................................................................................................
#   else
#     S.transcriptor  = null
#     ### TAINT this call may crash the app when text marker has length zero ###
#     try
#       { clasz
#         from
#         to  }         = @position_and_clasz_from_mark marks[ 0 ]
#     catch error
#       @log 'µ44774', "failed when trying to get position, class from mark:", rpr error.message
#       return null
#     S.tsnr          = parseInt ( clasz.replace /^.*\btsr([0-9]+)\b.*$/, '$1' ), 10
#     S.tsnr          = 0 unless CND.isa_number S.tsnr
#     S.tsr_text      = @cm_text_from_mark marks[ 0 ]
#     S.transcriptor  = S.transcriptors[ S.tsnr ]
#     #.......................................................................................................
#     unless S.transcriptor?
#       S.tsnr          = 0
#       S.transcriptor  = S.transcriptors[ S.tsnr ]
#   #.........................................................................................................
#   unless S.tsnr is 0
#     @log 'µ53587', "TS##{rpr S.tsnr} (#{rpr S.transcriptor.display_name})"
#     XE.emit PD.new_event '^transcribe', { text: S.tsr_text, from, to, }
#   return null


#===========================================================================================================
# DIAGNOSTICS
#-----------------------------------------------------------------------------------------------------------
@cm_mark_tsrs = ->
  ### Currently only used for diagnostics, will toggle CSS class `hilite` on all TSRs the selection is
  touching when `ctrl+m` is hit ###
  ### TAINT code duplication ###
  for fromto in @cm_get_selections_as_fromtos()
    if CND.equals fromto.from, fromto.to then marks = @cm_get_marks_in_position  fromto.from
    else                                      marks = @cm_get_marks_in_range     fromto
    if marks.length is 0
      @log 'µ53688', "didn't find any marks at #{rpr fromto}"
    else
      for mark in marks
        @log 'µ53789', "found existing mark: #{rpr @position_and_clasz_from_mark mark}"
        { from, to, clasz, } = @position_and_clasz_from_mark mark
        mark.clear()
        clasz = if ( clasz.match /\bhilite\b/ )? then clasz.replace /\s*hilite\s*/g, ' ' else clasz + ' hilite'
        @cm_set_mark { from, to, }, clasz
  return null




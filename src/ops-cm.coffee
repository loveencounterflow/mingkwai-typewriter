
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
  @log 'µ34333', "set mark #{rpr clasz} at #{rpr fromto}"
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
@cm_get_text                  = ( fromto    ) -> S.codemirror.editor.getRange fromto.from, fromto.to
@cm_text_from_mark            = ( mark      ) -> @cm_get_text mark.find()

#-----------------------------------------------------------------------------------------------------------
@cm_select = ( fromto ) ->
  @log 'µ34484', "cm_select: #{rpr fromto}"
  return S.codemirror.editor.setSelection fromto.from, fromto.to

#-----------------------------------------------------------------------------------------------------------
@position_and_clasz_from_mark = ( mark ) ->
  fromto = mark.find()
  return { from: ( @_cm_as_pos fromto.from ), to: ( @_cm_as_pos fromto.to ), clasz: mark.className, }

#-----------------------------------------------------------------------------------------------------------
@cm_set_tsrs = ( tsnr ) ->
  ### TAINT code duplication ###
  # @cm_select_only_in_single_line()
  # @cm_clear_translation_mark()
  action  = if tsnr is 0 then 'clear' else 'set'
  delta   = if action is 'clear' then -1 else +1
  clasz   = "tsr tsr#{tsnr}"
  count   = 0
  for fromto in @cm_get_selections_as_fromtos()
    range_is_point = CND.equals fromto.from, fromto.to
    if range_is_point then  marks = @cm_get_marks_in_position  fromto.from
    else                    marks = @cm_get_marks_in_range     fromto
    for mark in marks
      do ( mark ) =>
        @log 'µ34464', "found existing mark: #{rpr @position_and_clasz_from_mark mark}"
        mark.clear()
    if action is 'set'
      if range_is_point
        S.codemirror.editor.replaceRange '\ue044', fromto.from
        fromto1 = { from: fromto.from, to: { line: fromto.from.line, ch: ( fromto.from.ch + 1 ), }, }
        @cm_select fromto1
        mark    = @cm_set_mark fromto1, clasz
        # S.codemirror.editor.setBookmark fromto.from, { widget: ( jQuery "<span class='widget'></span>" )[ 0 ], }
      else
        ### TAINT trailing newlines, empty lines are probably a bad idea; if CodeMirror would only visibly
        mark those ###
        if ( nl_count = ( ( @cm_get_text fromto ).match /(\n*)$/ )[ 1 ].length ) > 0
          @log 'µ32873', "fromto #{rpr fromto} contains empty lines"
        mark = @cm_set_mark fromto, clasz
      # mark.on 'beforeCursorEnter', => @log 'µ44333', "entered tsr #{rpr @position_and_clasz_from_mark mark}"
  return count

#-----------------------------------------------------------------------------------------------------------
@cm_mark_tsrs = ->
  ### TAINT code duplication ###
  for fromto in @cm_get_selections_as_fromtos()
    if CND.equals fromto.from, fromto.to then marks = @cm_get_marks_in_position  fromto.from
    else                                      marks = @cm_get_marks_in_range     fromto
    if marks.length is 0
      @log 'µ83733', "didn't find any marks at #{rpr fromto}"
    else
      for mark in marks
        @log 'µ34464', "found existing mark: #{rpr @position_and_clasz_from_mark mark}"
        { from, to, clasz, } = @position_and_clasz_from_mark mark
        mark.clear()
        clasz = if ( clasz.match /\bhilite\b/ )? then clasz.replace /\s*hilite\s*/g, ' ' else clasz + ' hilite'
        @cm_set_mark { from, to, }, clasz
  return null

#-----------------------------------------------------------------------------------------------------------
@cm_find_transcriptor_and_tsr = ->
  ### TAINT code duplication ###
  # @log 'µ36633', 'cm_find_ts', "cursor at #{rpr @cm_get_cursor()}"
  marks = @cm_get_marks_in_position @cm_get_cursor()
  #.........................................................................................................
  if marks.length is 0
    S.tsnr          = 0
    S.tsr           = null
    S.tsr_text      = null
    S.transcriptor  = S.transcriptors[ 0 ]
  #.........................................................................................................
  else
    { clasz
      from
      to  }         = @position_and_clasz_from_mark marks[ 0 ]
    S.tsnr          = parseInt ( clasz.replace /^.*\btsr([0-9]+)\b.*$/, '$1' ), 10
    S.tsnr          = 0 unless CND.isa_number S.tsnr
    S.tsr_text      = @cm_text_from_mark marks[ 0 ]
    S.transcriptor  = S.transcriptors[ S.tsnr ]
    #.......................................................................................................
    unless S.transcriptor?
      S.tsnr          = 0
      S.transcriptor  = S.transcriptors[ S.tsnr ]
  #.........................................................................................................
  @log 'µ34464', "TS##{rpr S.tsnr} (#{rpr S.transcriptor.display_name})"
  XE.emit PD.new_event '^transcribe', { text: S.tsr_text, from, to, } unless S.tsnr is 0
  return null




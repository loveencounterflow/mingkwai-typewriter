
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/OPS-TRANSCRIPTION'
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
PD                        = require 'pipedreams'
{ jr, }                   = CND
{ after, }                = CND.suspend
assign                    = Object.assign
defer                     = setImmediate
{ $
  $async }                = PD
# XE                        = null
XE                        = require '../lib/xemitter'
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }




#===========================================================================================================
# INPUT TRANSLATION
#-----------------------------------------------------------------------------------------------------------
@load_transcriptors = ->
  ### TAINT stopgap code ###
  ### TAINT should search home directory, node_modules as well ###
  ### TAINT use glob ###
  PATH                = require 'path'
  FS                  = require 'fs'
  ops                 = {}
  directory_path      = PATH.resolve PATH.join __dirname, './transcriptors'
  on_transcribe_types = [
    'function'
    'asyncfunction' ]
  S.transcriptors     = []
  #.........................................................................................................
  t                   = {}
  t.display_name      = "(no transcriptor)"
  t.path              = null
  t.module            = null
  S.transcriptors.push t
  #.........................................................................................................
  for filename in FS.readdirSync directory_path
    continue unless filename.endsWith '.ts.js'
    #.......................................................................................................
    t                     = {}
    t.path                = PATH.join directory_path, filename
    t.display_name        = filename
    t.display_name        = t.display_name.replace /\.ts\.js$/g, ''
    t.display_name        = t.display_name.replace /-/g, ' '
    #.......................................................................................................
    relative_path         = PATH.relative process.cwd(), t.path
    @log "µ44755 loading transcription #{relative_path}"
    t.module              = require t.path
    #.......................................................................................................
    if t.module.init?
      unless ( type = CND.type_of t.module.init ) in on_transcribe_types
        throw new Error "µ27622 expected a function for #{relative_path}.init, got a #{type}"
      await t.module.init()
    #.......................................................................................................
    if t.module.display_name?
      unless ( type = CND.type_of t.module.display_name ) is 'text'
        throw new Error "µ27622 expected a text for #{relative_path}.display_name, got a #{type}"
      t.display_name = t.module.display_name
    #.......................................................................................................
    unless ( type = CND.type_of t.module.on_transcribe ) in on_transcribe_types
      throw new Error "µ27622 expected a function for #{relative_path}.on_transcribe, got a #{type}"
    unless ( arity = t.module.on_transcribe.length ) is 1
      throw new Error "µ27622 arity #{arity} for #{relative_path}.on_transcribe not implemented"
    #.......................................................................................................
    S.transcriptors.push t
    t.tsnr = S.transcriptors.length
    @log "µ44755 #{filename} loaded as #{rpr t.display_name} (TRS# #{t.tsnr})"
  #.........................................................................................................
  # info 'µ33736', S.transcriptors
  return null

#===========================================================================================================
# SET TSRs, TRANSCRIPTORS
#-----------------------------------------------------------------------------------------------------------
@format_existing_tsr_marks = ( d ) ->
  ### TAINT precompute, store in S: ###
  ### TAINT code duplication ###
  tsrm_prefix   = S.transcriptor_region_markers?.prefix ? '\u{f11c}'
  tsrm_suffix   = S.transcriptor_region_markers?.suffix ? '\u{f005}'
  pattern       = /// #{tsrm_prefix} (?<tsnr>[0-9]+) #{tsrm_suffix} ///
  finds         = []
  cursor        = S.codemirror.editor.getSearchCursor pattern
  # @log 'µ11121', rpr ( key for key of cursor )
  #.........................................................................................................
  while cursor.findNext()
    from      = cursor.from()
    to        = cursor.to()
    fromto    = { from, to, }
    text      = @cm_get_text fromto
    { tsnr, } = ( text.match pattern ).groups
    tsnr      = parseInt tsnr, 10
    finds.push { fromto, tsnr, }
  #.........................................................................................................
  for { fromto, tsnr, } in finds
    @log "µ46674", "found TSR mark at #{rpr fromto}: #{rpr text} (TS ##{tsnr})"
    @cm_format_as_tsr_mark fromto, tsnr
  #.........................................................................................................
  return null
  # for line_idx in [ S.codemirror.editor.firstLine() .. S.codemirror.editor.lastLine() ]
  #   text =

#-----------------------------------------------------------------------------------------------------------
@cm_format_as_tsr_mark = ( fromto, tsnr ) ->
  ### TAINT use own API ###
  settings      =
    className:        "tsr tsr#{tsnr}"
    atomic:           true
    inclusiveLeft:    false
    inclusiveRight:   false
  S.codemirror.editor.markText fromto.from, fromto.to, settings
  return null

#-----------------------------------------------------------------------------------------------------------
@cm_insert_tsr_mark = ( fromto, tsnr ) ->
  ### TSRM: TranScription Region Marker. TSR extends from marker up to cursor. ###
  ### TAINT precompute, store in S.transcriptors: ###
  tsrm_prefix   = S.transcriptor_region_markers?.prefix ? '\u{f11c}'
  tsrm_suffix   = S.transcriptor_region_markers?.suffix ? '\u{f005}'
  ### TAINT use configured TS sigil instead of tsnr ###
  tsrm          = "#{tsrm_prefix}#{tsnr}#{tsrm_suffix}"
  clasz         = "tsr tsr#{tsnr}"
  fromto_right  = { line: fromto.from.line, ch: ( fromto.from.ch + tsrm.length ), }
  settings      =
    className:        clasz
    atomic:           true
    inclusiveLeft:    false
    inclusiveRight:   false
  ### TAINT use own API ###
  S.codemirror.editor.replaceRange tsrm, fromto.from
  S.codemirror.editor.markText fromto.from, fromto_right, settings
  return null

#-----------------------------------------------------------------------------------------------------------
@cm_set_tsrs = ( tsnr ) ->
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
    ### TAINT allow to configure appearance of TSR mark ###
    # tsrm = "[#{S.transcriptors[ tsnr ].display_name}:"
    @cm_insert_tsr_mark fromto, tsnr
  @emit_transcribe_event()
  return null


#===========================================================================================================
# MOVES
#-----------------------------------------------------------------------------------------------------------
@cm_jump_to_tsr_or_bracket = -> @log 'µ44455', "cm_jump_to_tsr_or_bracket not implemented"
@cm_mark_tsr_or_bracket    = -> @log 'µ44455', "cm_mark_tsr_or_bracket not implemented"


#===========================================================================================================
# INPUT TRANSLATION
#-----------------------------------------------------------------------------------------------------------
@emit_transcribe_event = ->
  position  = @cm_get_cursor()
  full_text = ( @cm_text_from_line_idx position.line )[ ... position.ch ]
  return null if full_text.length is 0 ### TAINT consider whether transcriptions with empty text might be useful ###
  ### TAINT precompute, store in S: ###
  ### TAINT code duplication, see `ops-cm/format_tsr_marks()` ###
  tsrm_prefix   = S.transcriptor_region_markers?.prefix ? '\u{f11c}'
  tsrm_suffix   = S.transcriptor_region_markers?.suffix ? '\u{f005}'
  pattern       = /// ^ .* (?<all> #{tsrm_prefix} (?<tsnr>[0-9]+) #{tsrm_suffix} (?<otext>.*?) ) $ ///
  return unless ( match = full_text.match pattern )?
  { tsnr
    otext
    all   } = match.groups
  tsnr      = parseInt tsnr, 10
  return null if tsnr is 0
  value     =
    otext:    otext
    tsnr:     tsnr
    target:   { line: position.line, ch: position.ch - all.length,    }
    origin:
      from:     { line: position.line, ch: position.ch - otext.length,  }
      to:       position
  XE.emit PD.new_event '^transcribe', value
  return null

#-----------------------------------------------------------------------------------------------------------
@dispatch_transcribe_event = ( d ) ->
  transcriptor = S.transcriptors[ d.value.tsnr ]
  #.......................................................................................................
  unless transcriptor?.module?.on_transcribe?
    tsnr          = 0
    transcriptor  = S.transcriptors[ tsnr ]
  #.......................................................................................................
  if transcriptor?.module?.on_transcribe?
    @log 'µ33111', "calling #{transcriptor.display_name}", rpr d
    transcriptor.module.on_transcribe d
  #.......................................................................................................
  else
    @log 'µ33111', 'no transcriptor'
  return null

#-----------------------------------------------------------------------------------------------------------
@freeze     = -> S.is_frozen = true
@is_frozen  = -> S.is_frozen
@thaw       = -> S.is_frozen = false

#-----------------------------------------------------------------------------------------------------------
@on_replace_text = ( d ) ->
  @log 'µ53486', 'on_replace_text', rpr d
  v = d.value
  @freeze()
  ### TAINT use own API ###
  S.codemirror.editor.replaceRange '', v.origin.from, v.origin.to
  S.codemirror.editor.replaceRange v.ntext, v.target
  @thaw()
  return null

#-----------------------------------------------------------------------------------------------------------
@display_candidates = ( d ) ->
  v = d.value
  ( jQuery '#candidates-flexgrid div' ).remove()
  #.........................................................................................................
  if v.candidates.length is 0
    @focusframe_to_editor if S.focus_is_candidates
    # @index_candidates()
    return null
  #.........................................................................................................
  @focusframe_to_candidates() unless S.focus_is_candidates
  rows    = ( ( T.get_flexgrid_html ( idx + 1 ), glyph ) for glyph, idx in v.candidates ).join '\n'
  ( jQuery '#candidates-flexgrid'     ).append rows
  #.........................................................................................................
  ### TAINT code duplication ###
  glyphboxes = jQuery '#candidates-flexgrid div.glyph'
  glyphboxes.on 'click', ( e ) =>
    me = jQuery e.target
    ### TAINT code duplication ###
    ### TAINT use API to move selection ###
    glyphboxes.removeClass  'cdtsel'
    me.addClass             'cdtsel'
    #.......................................................................................................
    # lnr   = me.attr 'lnr'
    # lcol  = me.attr 'lcol'
    # @log "µ33983 clicked on #{me.text()} #{jr lnr} / #{jr lcol}"
    d.value.ntext = me.text()
    XE.emit PD.new_event '^replace-text', d.value
  #.........................................................................................................
  @index_candidates()
  return null

#-----------------------------------------------------------------------------------------------------------
@select_candidate_or_insert_space = ->
  ### TAINT this implementation precludes any other functionality that the space bar might be associated
  with in CodeMirror ###
  cdtsel = jQuery '.cdtsel'
  ### TAINT honour multiple selection ###
  if cdtsel.length > 0
    cdtsel.click()
  else
    S.codemirror.editor.replaceSelection ' '
  @focusframe_to_editor()
  return null

#-----------------------------------------------------------------------------------------------------------
@index_candidates = ->
  ### Add or update each candidate `<div class=glyph> with attributes indicating its left- and right-based
  column and row numbers, starting from 1. Elements that match `jQuery '[lrow=1]'` are in the first row from
  the top, while those that match `jQuery '[rrow=1]'` are in the last row from top (first row from the
  bottom). Likewise, `lcol=1`, `rcol=1` match the leftmost and rightmost elements. These indexes have to be
  re-calculated after each container resize event, but simplify the code needed to select single and groups
  of elements. The beauty of the scheme is that we can select e.g. all leftmost elements or all elements
  in the first row (should the need ever arise). ###
  ### TAINT code duplication ###
  glyphboxes      = jQuery '#candidates-flexgrid div.glyph'
  lcol            = 0
  lrow            = 0
  prv_top         = null
  candidate_count = glyphboxes.length
  lnr             = 0
  rnr             = candidate_count + 1
  rows            = []
  row             = null
  #.........................................................................................................
  @log "index_candidates() (#{candidate_count})"
  #.........................................................................................................
  for idx in [ 0 ... candidate_count ]
    glyphbox = glyphboxes.eq idx
    #.......................................................................................................
    if ( nxt_top = glyphbox.offset().top ) isnt prv_top
      if row?
        rows.push row
        col_count = row.length
        for sub_glyphbox, col_idx in row
          sub_glyphbox.attr 'rcol', col_count - col_idx
      #.....................................................................................................
      row = []
      prv_top = nxt_top
      lcol    = 0
      lrow   += +1
    #.......................................................................................................
    row.push glyphbox
    lnr      += +1
    rnr      += -1
    lcol     += +1
    #.......................................................................................................
    glyphbox.attr 'lnr',  lnr
    glyphbox.attr 'rnr',  rnr
    glyphbox.attr 'lcol', lcol
    glyphbox.attr 'lrow', lrow
  #.........................................................................................................
  rows.push row if row?
  row_count = rows.length
  for row, row_idx in rows
    for glyphbox in row
      glyphbox.attr 'rrow', row_count - row_idx
  #.........................................................................................................
  rows.length = 0 ### not strictly needed, just to make de-allocation explicit ###
  return null

#-----------------------------------------------------------------------------------------------------------
@_select_delta_candidate = ( deltas ) ->
  ### Select next candidate(s) based on `deltas`, which should be an object with one or more of the
  following members:

  * **`lnr`**:     left-anchored  candidate         number
  * **`lcol`**:    left-anchored  column            number
  * **`lrow`**:    left-anchored  row (i.e. line)   number
  * **`rnr`**:     right-anchored candidate         number
  * **`rcol`**:    right-anchored column            number
  * **`rrow`**:    right-anchored row (i.e. line)   number

  Left-anchored values count from the usual (i.e. top or left) end of that dimension, richt-anchored ones
  from the opposite sides; for example, `lcol: 1` selects the first (leftmost), `rcol: 1` the last
  (rightmost) entry in each row; `lrow: 1` the first row, `rrow: 1` the last one; in a line with, say, five
  candidates, `lrow: 4` is equivalent to `rrow: 2`, and `lrow: 5` is the same as `rrow: 1`.

  Each entry may be either a positive or negative integer, or zero, or 'first', or 'last'. A non-zero number
  indicates the number of steps to go in the respective dimension while zero indicates 'keep this value'.
  For example, to move right irregardless of line breaks, use `{ lnr: +1, }`. To move to the first entry on
  the next line, use `{ lcol: 'first', lrow: +1, }`. To go to the last entry of the current row, use `{
  lrow: 0, lcol: 'last', }` or `{ lrow: 0, rcol: 'first', }`. The selected candidates are the intersection
  of all sub-selectors.

  This method will have no effect unless there is one or more selected entries to start with. ###
  #.........................................................................................................
  R                   = 0
  prv_cdtsel          = jQuery '.cdtsel'
  #.........................................................................................................
  if prv_cdtsel.length is 0
    @log "_select_delta_candidate: no candidate selected"
    return R
  #.........................................................................................................
  ### TAINT code duplication ###
  glyphboxes    = jQuery '#candidates-flexgrid div.glyph'
  nxt_selector  = []
  #.........................................................................................................
  for delta_key, delta_value of deltas
    switch type = CND.type_of delta_value
      when 'text'
        switch delta_value
          when 'first'
            nxt_selector.push "[#{delta_key}=1]"
          when 'last'
            delta_key = delta_key.replace /^[rl]/, ( $0 ) -> if $0 is 'l' then 'r' else 'l'
            nxt_selector.push "[#{delta_key}=1]"
          else throw new Error "µ37634 unknown move command #{rpr delta_value}"
      when 'number'
        prv_value = parseInt ( prv_cdtsel.attr delta_key ),  10
        nxt_value = prv_value + delta_value
        nxt_selector.push "[#{delta_key}=#{nxt_value}]"
      else throw new Error "µ37633 expected a text or a number, got a #{type}"
  nxt_selector = nxt_selector.join ''
  @log "_select_delta_candidate #{jr deltas} #{jr nxt_selector}"
  return R if ( R = ( nxt_cdtsel = glyphboxes.filter nxt_selector ).length ) is 0
  prv_cdtsel.removeClass  'cdtsel'
  nxt_cdtsel.addClass     'cdtsel'
  nxt_cdtsel[ 0 ].scrollIntoViewIfNeeded()
  return R

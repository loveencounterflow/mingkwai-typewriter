
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
types                     = require './types'
{ isa
  validate
  type_of }               = types



#===========================================================================================================
# INPUT TRANSLATION
#-----------------------------------------------------------------------------------------------------------
@load_transcriptors = ->
  ### Called once by OPS `init()` as part of initialization. ###
  ### TAINT stopgap code ###
  ### TAINT should search home directory, node_modules as well ###
  ### TAINT use glob ###
  PATH                = require 'path'
  FS                  = require 'fs'
  tsnr                = 0
  ops                 = {}
  directory_path      = PATH.resolve PATH.join __dirname, './transcriptors'
  on_transcribe_types = [
    'function'
    'asyncfunction' ]
  S.transcriptors     = []
  tsnr_by_sigils      = {}
  #.........................................................................................................
  ### insert TS0; consider to do this within the loop to avoid code duplication ###
  ts                  = {}
  ts.standard_name    = "(no transcriptor)"
  ts.display_name     = ts.standard_name
  ts.tsnr             = 0
  ts.sigil            = 'ts0'
  ts.path             = null
  ts.module           = null
  S.transcriptors.push ts
  #.........................................................................................................
  for filename in FS.readdirSync directory_path
    continue unless filename.endsWith '.ts.js'
    t0  = Date.now()
    #.......................................................................................................
    tsnr                 += +1
    ts                    = {}
    ts.tsnr               = tsnr
    ts.path               = PATH.join directory_path, filename
    ts.standard_name      = filename
    ts.standard_name      = ts.standard_name.replace /\.ts\.js$/g, ''
    ts.standard_name      = ts.standard_name.replace /-/g, ' '
    ts.display_name       = ts.standard_name
    ts.sigil              = "ts#{ts.tsnr}"
    #.......................................................................................................
    relative_path         = PATH.relative process.cwd(), ts.path
    @log "µ44755 loading transcription #{relative_path}"
    ts.module             = require ts.path
    ### NOTE not used ATTB and probably not needed; transcriptors should execute any initialization code
    on module `require`d and/or immediately prior to first use. ###
    # #.......................................................................................................
    # if ts.module.init?
    #   unless ( type = CND.type_of ts.module.init ) in on_transcribe_types
    #     throw new Error "µ27622 expected a function for #{relative_path}.init, got a #{type}"
    #   await ts.module.init()
    #.......................................................................................................
    if ts.module.display_name?
      unless ( type = CND.type_of ts.module.display_name ) is 'text'
        throw new Error "µ27622 expected a text for #{relative_path}.display_name, got a #{type}"
      ts.display_name = ts.module.display_name
    #.......................................................................................................
    if ts.module.sigil?
      unless ( type = CND.type_of ts.module.sigil ) is 'text'
        throw new Error "µ27622 expected a text for #{relative_path}.sigil, got a #{type}"
      ts.sigil = ts.module.sigil
    #.......................................................................................................
    unless ( type = CND.type_of ts.module.on_transcribe ) in on_transcribe_types
      throw new Error "µ27622 expected a function for #{relative_path}.on_transcribe, got a #{type}"
    unless ( arity = ts.module.on_transcribe.length ) is 1
      throw new Error "µ27622 arity #{arity} for #{relative_path}.on_transcribe not implemented"
    #.......................................................................................................
    S.tsnr_by_sigils[ ts.sigil ] = ts.tsnr
    S.transcriptors.push ts
    t1  = Date.now()
    dt  = t1 - t0
    @log "µ44755 #{filename} loaded as #{rpr ts.display_name} (TSNR #{ts.tsnr}; took #{dt} ms)"
  #.........................................................................................................
  # info 'µ33736', S.transcriptors
  return null

#===========================================================================================================
# SET TSRs, TRANSCRIPTORS
#-----------------------------------------------------------------------------------------------------------
@format_existing_tsms = ( d ) ->
  ### Listens to `^open-document`, iterates over document and calls `format_as_tsm_at_position()` for
  each transcription mark found. ###
  ### TAINT precompute, store in S: ###
  ### TAINT code duplication ###
  #.........................................................................................................
  tsm_prefix    = S.transcriptor_region_markers?.prefix ? '\u{f11c}'
  tsm_suffix    = S.transcriptor_region_markers?.suffix ? '\u{f005}'
  pattern       = /// #{tsm_prefix} (?<sigil>[^#{tsm_suffix}]+) #{tsm_suffix} ///
  finds         = []
  cursor        = S.codemirror.editor.getSearchCursor pattern
  # @log 'µ11121', rpr ( key for key of cursor )
  #.........................................................................................................
  while cursor.findNext()
    from          = cursor.from()
    to            = cursor.to()
    fromto        = { from, to, }
    text          = @cm_get_text fromto
    { sigil, }    = ( text.match pattern ).groups
    tsnr          = S.tsnr_by_sigils[ sigil ]
    ### TAINT must fall back to 'unknown TS' or similar when sigil not found ###
    finds.push { fromto, tsnr, sigil, }
  #.........................................................................................................
  for { fromto, tsnr, sigil, } in finds
    @log "µ46674", "found TSM at #{rpr fromto}: #{rpr text} (TS ##{tsnr})"
    @format_as_tsm_at_position fromto, tsnr, sigil
  #.........................................................................................................
  return null
  # for line_idx in [ S.codemirror.editor.firstLine() .. S.codemirror.editor.lastLine() ]
  #   text =

#-----------------------------------------------------------------------------------------------------------
@format_as_tsm_at_position = ( fromto, tsnr, sigil ) ->
  ### Called by `format_existing_tsms()`, `on_replace_text()` to insert an atomic CM textmarker at the
  position indicated. ###
  ### TAINT unify with `_toggle_tsm_at_position` ###
  validate.range  fromto
  validate.tsnr   tsnr
  clasz         = "tsr tsr#{tsnr}"
  settings      =
    attributes:       { tsnr, }
    replacedWith:     ( jQuery "<span class=#{jr clasz}>#{sigil}</span>" )[ 0 ]
    atomic:           true
    inclusiveLeft:    false
    inclusiveRight:   false
  ### TAINT use own API ###
  S.codemirror.editor.markText fromto.from, fromto.to, settings
  return null

#-----------------------------------------------------------------------------------------------------------
@_toggle_tsm_at_position = ( position, tsnr, sigil, settings ) ->
  ### Called by `insert_tsm()`. ###
  ### TSM: TranScription Marker. TSR (TranScription Region) extends from marker up to cursor. ###
  ### TAINT unify with `format_as_tsm_at_position` ###
  ### TAINT precompute, store in S.transcriptors: ###
  validate.position position
  validate.tsnr     tsnr
  old_textmarker  = ( S.codemirror.editor.findMarksAt position )[ 0 ] ? null
  old_tsnr        = old_textmarker?.attributes?.tsnr                  ? null
  #.........................................................................................................
  if ( tsnr isnt 0 ) and ( ( not old_textmarker? ) or ( old_tsnr isnt tsnr ) )
    tsm_prefix            = S.transcriptor_region_markers?.prefix ? '\u{f11c}'
    tsm_suffix            = S.transcriptor_region_markers?.suffix ? '\u{f005}'
    tsm                   = "#{tsm_prefix}#{sigil}#{tsm_suffix}"
    clasz                 = "tsr tsr#{tsnr}"
    rposition             = { line: position.line, ch: ( position.ch + tsm.length ), }
    settings_for_markText =
      attributes:       { tsnr, }
      replacedWith:     ( jQuery "<span class=#{jr clasz}>#{sigil}</span>" )[ 0 ]
      atomic:           true
      inclusiveLeft:    false
      inclusiveRight:   false
    ### TAINT use own API ###
    S.codemirror.editor.replaceRange tsm, position
    S.codemirror.editor.markText position, rposition, settings_for_markText
  #.........................................................................................................
  @cm_remove_textmarker old_textmarker if settings.toggle and old_textmarker?
  return null

#-----------------------------------------------------------------------------------------------------------
@insert_tsm = ( tsnr, settings ) ->
  ### Called upon keyboard shortcut, menu item selection. ###
  validate.tsnr   tsnr
  ### Bound to `ctrl+0` ... `ctrl+4` ###
  settings  = assign {}, { toggle: true, }, settings
  validate.settings_for_insert_tsm settings
  ts        = S.transcriptors[ tsnr ]
  ts       ?= S.transcriptors[ 0 ]
  position  = @cm_get_position()
  @_toggle_tsm_at_position position, tsnr, ts.sigil, settings
  # @emit_transcribe_event()
  return null

# #-----------------------------------------------------------------------------------------------------------
# @insert_bookmark = ( position = null ) ->
#   position ?= @cm_get_position()
#   validate.position position
#   @log 'µ44644', 'position', position
#   sigil = 'SIGIL'
#   settings =
#     widget:             ( jQuery "<span class=tsm-bookmark>#{sigil}</span>" )[ 0 ]
#     insertLeft:         false
#     shared:             false
#     handleMouseEvents:  false
#   return S.codemirror.editor.setBookmark position, settings

#===========================================================================================================
# MOVES
#-----------------------------------------------------------------------------------------------------------
@cm_jump_to_tsr_or_bracket = -> @log 'µ44455', "cm_jump_to_tsr_or_bracket not implemented"
@cm_mark_tsr_or_bracket    = -> @log 'µ44455', "cm_mark_tsr_or_bracket not implemented"


#===========================================================================================================
# INPUT TRANSLATION
#-----------------------------------------------------------------------------------------------------------
@emit_transcribe_event = ->
  ### Called on cursor move in CM and by `insert_tsm()`, `emit_transcribe_event()` parses the current line,
  looks for the relevant TSM (TranScription Mark), and formulates a transcription event based on the text
  found between the TSM and the cursor position. That event is then processed by
  `dispatch_transcribe_event()` (and possibly other listeners). ###
  ### TAINT consider to always use either TSNR or TS sigil in text marker, displayed text, and only use
  that piece of data to identify transcriptors in events ###
  position      = @cm_get_cursor()
  # @log 'µ36373', 'position', position
  full_text     = ( @cm_text_from_line_idx position.line )[ ... position.ch ]
  return null if full_text.length is 0 ### TAINT consider whether transcriptions with empty text might be useful ###
  ### TAINT precompute, store in S: ###
  ### TAINT code duplication, see `ops-cm/format_tsr_marks()` ###
  tsm_prefix    = S.transcriptor_region_markers?.prefix ? '\u{f11c}'
  tsm_suffix    = S.transcriptor_region_markers?.suffix ? '\u{f005}'
  pattern       = ///
    ^
    .*
    (?<all>
      (?<mark>
        #{tsm_prefix}
        (?<sigil> [^#{tsm_suffix}]+ )
        #{tsm_suffix}
        (?<otext> .*? )
        )
      )
      $ ///
  return unless ( match = full_text.match pattern )?
  { mark
    sigil
    otext
    all   }     = match.groups
  tsnr          = S.tsnr_by_sigils[ sigil ]
  tsnr         ?= 0
  #.........................................................................................................
  return null if tsnr is 0
  #.........................................................................................................
  ### where to put ntext: ###
  target =
    line:           position.line
    ch:             position.ch - all.length
  #.........................................................................................................
  origin =
    from:
      line:         position.line
      ch:           position.ch - otext.length
    to:
      line:         position.line
      ch:           position.ch
  #.........................................................................................................
  tsm =
    from:
      line:         target.line
      ch:           target.ch
    to:
      line:         target.line
      ch:           target.ch + mark.length
  #.........................................................................................................
  XE.emit PD.new_event '^transcribe', { otext, tsnr, sigil, target, tsm, origin, }
  return null

#-----------------------------------------------------------------------------------------------------------
@dispatch_transcribe_event = ( d ) ->
  ### Called on `^transcribe` events. If indicated transcription module exists, calls its `on_transcribe()`
  method (which in turn may cause events like `^replace-text`, `^candidates` to be emitted). ###
  transcriptor = S.transcriptors[ d.value.tsnr ]
  #.......................................................................................................
  unless transcriptor?.module?.on_transcribe?
    tsnr          = 0
    transcriptor  = S.transcriptors[ tsnr ]
  #.......................................................................................................
  if transcriptor?.module?.on_transcribe?
    # @log 'µ33111', "calling #{transcriptor.display_name}", rpr d
    transcriptor.module.on_transcribe d
  #.......................................................................................................
  else
    @log 'µ33111', 'no transcriptor'
  return null

#-----------------------------------------------------------------------------------------------------------
### When `is_frozen()` is `true`, `^transcribe` events as result of cursor activities will not be sent; this
is to prevent text replacements from causing `^trancribe` events themselves. This simple method *should* be
OK as JS is single-threaded and interface updates are not possible until `on_replace_text()` (or any
function) has terminated. ###
@freeze     = -> S.is_frozen = true
@is_frozen  = -> S.is_frozen
@thaw       = -> S.is_frozen = false

#-----------------------------------------------------------------------------------------------------------
@on_replace_text = ( d ) ->
  ### Called on `^replace-text` events (issued by transcriptors). ###
  # @log 'µ53486', 'on_replace_text', ( rpr d ), ( isa.replace_text_event d.value )
  validate.replace_text_event v = d.value
  @freeze()
  ### TAINT use own API ###
  if v.match?
    target = { line: v.origin.from.line, ch: ( v.origin.from.ch + v.match.length ), }
    S.codemirror.editor.replaceRange '', v.origin.from, target
  else
    S.codemirror.editor.replaceRange '', v.origin.from, v.origin.to ### delete original text ###
    # @_toggle_tsm_at_position v.origin, v.tsnr, v.sigil               ### insert new TSM (where called for) ###
  #.........................................................................................................
  S.codemirror.editor.replaceRange v.ntext, v.target              ### insert new text ###
    # S.codemirror.editor.replaceRange '', v.tsm.from, v.tsm.to       ### delete TSM ###
    # S.codemirror.editor.replaceRange v.ntext, v.target              ### insert new tsm ###
  #.........................................................................................................
  if v.match?
    @emit_transcribe_event()
  #.........................................................................................................
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
  @focusframe_to_candidates() if ( not S.focus_is_candidates ) and ( v.focus_candidates ? true )
  #.........................................................................................................
  rows = []
  for entry, idx in v.candidates
    rows.push T.get_flexgrid_html ( idx + 1 ), entry.candidate
  ( jQuery '#candidates-flexgrid' ).append rows.join '\n'
  #.........................................................................................................
  ### TAINT code duplication ###
  glyphboxes = jQuery '#candidates-flexgrid div.glyph'
  nv          = assign {}, v
  delete nv.candidates
  glyphboxes.on 'click', ( e ) =>
    me = jQuery e.target
    ### TAINT code duplication ###
    ### TAINT use API to move selection ###
    glyphboxes.removeClass  'cdtsel'
    me.addClass             'cdtsel'
    #.......................................................................................................
    lnr   = parseInt ( me.attr 'lnr' ), 10
    # lcol  = me.attr 'lcol'
    # @log "µ33983 clicked on #{me.text()} #{jr lnr} / #{jr lcol}"
    match = v.candidates[ lnr - 1 ]?.reading ? null
    XE.emit PD.new_event '^replace-text', assign nv, { ntext: me.text(), match, }
  #.........................................................................................................
  @index_candidates()
  return null

#-----------------------------------------------------------------------------------------------------------
@select_candidate_or_insert_space = ->
  ### TAINT this implementation precludes any other functionality that the space bar might be associated
  with in CodeMirror ###
  ### TAINT code duplication ###
  return S.codemirror.editor.replaceSelection ' ' unless S.focus_is_candidates
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


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
# require                   '../lib/kana-input'
# require                   '../lib/kanji-input'
#...........................................................................................................
PD                        = require 'pipedreams'
{ jr, }                   = CND
{ after, }                = CND.suspend
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
@set_translation_mark = ( position_from, position_to ) ->
  settings =
    className:      'txtmark_xxx'
    inclusiveLeft:  false
    inclusiveRight: true
  return S.codemirror.editor.markText position_from, position_to, settings

#-----------------------------------------------------------------------------------------------------------
@set_transcription = ( xxx ) ->

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '^raw-input', ( d ) ->
  ### Transform `^raw-input` to `^input` events ###
  #.........................................................................................................
  { change, }     = d.value
  { editor, }     = S.codemirror
  { doc, }        = editor
  cursor          = doc.getCursor()
  #.........................................................................................................
  ### TAINT kludge to collapse multiple selections into a single one ###
  CodeMirror.commands.singleSelection editor
  #.........................................................................................................
  line_idx        = cursor.line
  line_handle     = doc.getLineHandle line_idx
  line_info       = doc.lineInfo line_handle ### TAINT consider to use line_idx, forego line_handle ###
  { text, }       = line_info
  #.........................................................................................................
  XE.emit PD.new_event '^input', { change, line_idx, text, }
  return null


#-----------------------------------------------------------------------------------------------------------
XE.listen_to '^candidates', @, ( d ) ->
  @focusframe_to_candidates() unless S.focus_is_candidates
  v       = d.value
  rows    = ( ( T.get_flexgrid_html ( idx + 1 ), glyph ) for glyph, idx in v.candidates ).join '\n'
  ( jQuery '#candidates-flexgrid div' ).remove()
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
    @log "µ33983-1 #{me.text()} #{jr me.offset()}"
  #.........................................................................................................
  @index_candidates()
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
@insert_space_or_selection = ->
  ### TAINT this implementation precludes any other functionality that the space bar might be associated
  with in CodeMirror ###
  cdtsel = jQuery '.cdtsel'
  ### TAINT honour multiple selection ###
  text   = if cdtsel.length > 0 then cdtsel.text() else ' '
  S.codemirror.editor.replaceSelection text
  @focusframe_to_editor()
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

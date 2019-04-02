
### TAINTs

* separate:

  * `focus` (a mechanism used by the browser)

  * ?`select`, `choose`? for the action of selecting one particular candidate

  * ??? for what is called `focusframe` now

  these are three different things and should be called different names.

* accordingly, rename `focusframe` and those `*_focus*` methods that refer to it instead of to browser focus

* use module-global `S`: this code will only ever run a single input instance; where it does use modules
  that potentially serve several independent consumers, `S` will not be used as argument anyway

* refactor code into (local) modules

###



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/OPS'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
inspect                   = ( require 'util' ).inspect
# TRAP                      = require 'mousetrap'
KEYS                      = require '../lib/keys'
T                         = require '../lib/templates'
PATH                      = require 'path'
FS                        = require 'fs'
#...........................................................................................................
require                   '../lib/exception-handler'
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
#...........................................................................................................
S                         = require '../lib/settings' ### module-global configuration and editor state object ###
global.S                  = S

#-----------------------------------------------------------------------------------------------------------
XE.listen_to_all ( key, d ) ->
  # whisper 'µ99823', key #, jr d
  v       = d.value ? {}
  logger  = jQuery '#logger'
  ( logger.find ':first-child').remove() while logger.children().length > 10
  message = switch key
    when '^kblevel' then  ( k for k, toggle of S.kblevels when toggle ).join ', '
    else                  ( k for k         of d.value                ).join ', '
  #.........................................................................................................
  logger.append ( "<div>#{Date.now()}: #{rpr key}: #{message}</div>" )
  console.log 'µ33499', Date.now(), key, d
  # if ( kblevels = d.value?.S?.kblevels )
  #   logger.append ( "<div>#{Date.now()}: kblevels: #{rpr kblevels}</div>" )
  logger.scrollTop logger[ 0 ].scrollHeight
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@log = ( text ) ->
  ### TAINT code duplication ###
  logger = jQuery '#logger'
  ( logger.find ':first-child').remove() while logger.children().length > 10
  ### TAINT should escape text (or accept HTML?) ###
  logger.append ( "<div>#{Date.now()}: #{text}</div>" )
  console.log 'µ33499', Date.now(), text
  logger.scrollTop logger[ 0 ].scrollHeight
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

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '^load-documents', @, ( d ) ->
  ### Will be used to restore previous state, open new documents; for now, just opens the default file. ###
  ### TAINT auto-create file when not present ###
  file_path = PATH.resolve PATH.join __dirname, '../.cache/default.md'
  S.codemirror.editor.doc.setValue FS.readFileSync file_path, { encoding: 'utf-8', }
  return null

#-----------------------------------------------------------------------------------------------------------
### TAINT use proper keybinding API to define key bindings ###
XE.listen_to '^keyboard', @, ( d ) ->
  if d.value.name is 'ctrl+s'
    XE.emit PD.new_event '^save-document'
  return null

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '^save-document', @, ( d ) ->
  ### Will be used to save active document; currently just saves default file. ###
  file_path = PATH.resolve PATH.join __dirname, '../.cache/default.md'
  @log "saving document to #{rpr file_path}"
  FS.writeFileSync file_path, S.codemirror.editor.doc.getValue()
  return null

#-----------------------------------------------------------------------------------------------------------
@focusframe_to_editor = ->
  @_focusframe_to 'leftbar'
  ### TAINT use method, must be possible to remap ###
  S.focus_is_candidates = false
  # S.kblevels.shift      = false
@focusframe_to_candidates = ->
  @_focusframe_to 'rightbar'
  ### TAINT use method, must be possible to remap ###
  S.focus_is_candidates = true
  # S.kblevels.shift      = false
@focusframe_to_logger = ->
  @_focusframe_to '#logger'
  ### TAINT use method, must be possible to remap ###
  S.focus_is_candidates = false
  # S.kblevels.shift      = false

#-----------------------------------------------------------------------------------------------------------
@_focusframe_to = ( target ) ->
  # target      = jQuery( document.activeElement )
  target      = jQuery target if CND.isa_text target
  ff          = jQuery 'focusframe'
  return if target.length < 1
  # ff.offset     target.offset()
  # ff.width      target.width()
  # ff.height     target.height()
  tgto        = target.offset()
  return unless tgto?
  left    = tgto.left       - 1
  top     = tgto.top        - 1
  width   = target.width()  + 2
  height  = target.height() + 2
  ff.animate { left, top, width, height, }, 100
  return null

#-----------------------------------------------------------------------------------------------------------
@always_focus_editor = ->
  @always_focus_editor = -> ### do not add any more handlers with this method after first call ###
  ( jQuery 'div.CodeMirror-code' ).on 'blur', -> @focus()
  ( jQuery 'div.CodeMirror-code' ).focus()
  return null

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
@set_translation_mode = ( xxx ) ->

#-----------------------------------------------------------------------------------------------------------
### TAINT use proper keybinding API to define key bindings ###
XE.listen_to '^kblevel', @, ( d ) ->
  ### map kblevel 'shift' to manual editor/candidates focus selection ###
  v       = d.value
  # debug 'µ87444', S.kblevels.shift
  if ( S.focus_is_candidates = S.kblevels.shift ) then  @focusframe_to_candidates()
  else                                                  @focusframe_to_editor()
  ### TAINT consider to re-set focus after mouse clicks to elsewhere in GUI ###
  ### Make browser focus always stay on editor: ###
  return null

#-----------------------------------------------------------------------------------------------------------
@set_translation_mark = ( position_from, position_to ) ->
  settings =
    className:      'txtmark_xxx'
    inclusiveLeft:  false
    inclusiveRight: true
  return S.codemirror.editor.markText position_from, position_to, settings

#-----------------------------------------------------------------------------------------------------------
@init_cm_keymap = ->
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
  XE.emit PD.new_event '^input', { change, editor, doc, line_idx, text, }
  return null

#-----------------------------------------------------------------------------------------------------------
@init = ->
  # { remote, }               = require 'electron'
  # XE                        = remote.require './xemitter'
  #.........................................................................................................
  S.candidates          =
    jq:           jQuery '#candidates'
    selected:
      id:         null
  S.focus_is_candidates = false
  #.........................................................................................................
  ### Initialize CodeMirror ###
  S.codemirror.editor = CodeMirror.fromTextArea ( jQuery '#codemirror' )[ 0 ], S.codemirror.settings
  S.codemirror.editor.setSize null, '100%'
  S.codemirror.editor.on 'inputRead', ( me, change ) -> XE.emit PD.new_event '^raw-input', { change, }
  XE.listen_to '^ignore-delete', -> S.ignore_delete += +1
  S.codemirror.editor.on 'change', ( me, change ) ->
    ### TAINT when inserting results, will there be a change event? ###
    return null unless change.origin is '+delete'
    ### ignore event if it has been generated: ###
    if S.ignore_delete > 0
      S.ignore_delete += -1
      return null
    XE.emit PD.new_event '^raw-input', { change, }
  @always_focus_editor()
  #.........................................................................................................
  # S.codemirror.editor.on 'beforeChange',    ( me, change      ) -> whisper 'µ66653', 'beforeChange',  jr change
  # S.codemirror.editor.on 'change',          ( me, change      ) -> whisper 'µ66653', 'change',        jr change
  # S.codemirror.editor.on 'changes',         ( me, changes     ) -> whisper 'µ66653', 'changes',       jr changes
  # S.codemirror.editor.on 'cursorActivity',  ( me              ) -> whisper 'µ66653', 'cursorActivity'
  # S.codemirror.editor.on 'keyHandled',      ( me, name, event ) -> whisper 'µ66653', 'keyHandled',    jr name
  # S.codemirror.editor.on 'inputRead',       ( me, change      ) -> whisper 'µ66653', 'inputRead',     jr change
  #.........................................................................................................
  ### Register key and mouse events ###
  KEYS.generate_keboard_events jQuery 'html'
  # KEYS.register 'axis', 'vertical',     ( uie )   => @on_vertical_navigation  uie
  # KEYS.register 'slot', 'Enter',        ( uie )   => @on_add_selection        uie
  XE.emit PD.new_event '^load-documents'
  @focusframe_to_editor()
  @init_cm_keymap()
  #.........................................................................................................
  ### Detect resizing events: ###
  ### TAINT won't work when panes are shifted (probably) ###
  ( jQuery window ).on 'resize', =>
    debug "resize window"
    @index_candidates()
    return null
  return null

#-----------------------------------------------------------------------------------------------------------
jQuery init.bind @


###
cm.findPosH(start: {line, ch}, amount: integer, unit: string, visually: boolean) → {line, ch, ?hitSide: boolean}
cm.findPosV(start: {line, ch}, amount: integer, unit: string) → {line, ch, ?hitSide: boolean}
cm.findWordAt(pos: {line, ch}) → {anchor: {line, ch}, head: {line, ch}}
cm.hasFocus() → boolean

doc.addSelection        = (anchor: {line, ch}, ?head: {line, ch})
doc.changeGeneration    = (?closeEvent: boolean) → integer
doc.eachLine            = (f: (line: LineHandle))
doc.eachLine            = (start: integer, end: integer, f: (line: LineHandle))
doc.extendSelection     = (from: {line, ch}, ?to: {line, ch}, ?options: object)
doc.extendSelections    = (heads: array<{line, ch}>, ?options: object)
doc.extendSelectionsBy  = (f: function(range: {anchor, head}) → {line, ch}), ?options: object)
doc.firstLine           = () → integer
doc.getCursor           = (?start: string) → {line, ch}
doc.getExtending        = () → boolean
doc.getLine             = (n: integer) → string
doc.getLineHandle       = (num: integer) → LineHandle
doc.getLineNumber       = (handle: LineHandle) → integer
doc.getRange            = (from: {line, ch}, to: {line, ch}, ?separator: string) → string
doc.getSelection        = (?lineSep: string) → string
doc.getSelections       = (?lineSep: string) → array<string>
doc.getValue            = (?separator: string) → string
doc.isClean             = (?generation: integer) → boolean
doc.lastLine            = () → integer
doc.lineCount           = () → integer
doc.listSelections      = () → array<{anchor, head}>
doc.markClean           = ()
doc.replaceRange        = (replacement: string, from: {line, ch}, to: {line, ch}, ?origin: string)
doc.replaceSelection    = (replacement: string, ?select: string)
doc.replaceSelections   = (replacements: array<string>, ?select: string)
doc.setCursor           = (pos: {line, ch}|number, ?ch: number, ?options: object)
doc.setExtending        = (value: boolean)
doc.setSelection        = (anchor: {line, ch}, ?head: {line, ch}, ?options: object)
doc.setSelections       = (ranges: array<{anchor, head}>, ?primary: integer, ?options: object)
doc.setValue            = (content: string)
doc.somethingSelected   = () → boolean
###





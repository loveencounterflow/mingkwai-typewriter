
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
STATE                     = require '../lib/state'
T                         = require '../lib/templates'
PATH                      = require 'path'
FS                        = require 'fs'
#...........................................................................................................
require                   '../lib/exception-handler'
# require                   '../lib/kana-input'
require                   '../lib/kanji-input'
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
# `S` is the module-global configuration and editor state object; this will probably factored out into a
# separate local module to make it `require`able to other modules running in the renderer process:
S                         = null

#-----------------------------------------------------------------------------------------------------------
XE.listen_to_all ( key, d ) ->
  # whisper 'µ99823', key #, jr d
  v       = d.value
  { S, }  = v
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


# #-----------------------------------------------------------------------------------------------------------
# @on_add_selection = ( uie ) ->
#   { S, } = uie
#   debug '44545', 'selected row nr:', S.row_idx + 1
#   chr = S.rows?[ S.row_idx ]?.glyph
#   XE.emit 'IME/input/add', { S, row_idx: S.row_idx, chr, }
#   uie.event.preventDefault()
#   return null

# #-----------------------------------------------------------------------------------------------------------
# XE.listen_to 'IME/input/add', @, ( { S, row_idx, chr, } ) ->
#   debug "update output area"
#   debug "reset candidates area, input box"
#   ### TAINT remove buffer ###
#   S.buffer.push chr
#   # ( jQuery '#output-area .inbox' ).text S.buffer.join ''
#   S.codemirror.editor.replaceSelection chr
#   ( jQuery '#text-input' ).text ''
#   return null

#-----------------------------------------------------------------------------------------------------------
@on_scroll = ( S, event ) =>
  # if event.originalEvent.deltaY < 0 then  @navigate_vertically S, -1
  # else                                    @navigate_vertically S, +1
  if S.ignore_next_scroll_events >= 0
    S.ignore_next_scroll_events += -1
    # debug 'scroll', 'discard'
    return true
  S.ignore_next_scroll_events = 1
  delta_px                    = ( S.scroller.scrollTop() - S.scroller_last_top ) / S.candidates_tr_height
  S.scroller_last_top         = S.scroller.scrollTop()
  # debug 'scroll', delta_px
  # CND.dir event
  # return false if delta_px is 0
  if delta_px < 0 then  @navigate_vertically S, -1
  else                  @navigate_vertically S, +1
  return false;

#-----------------------------------------------------------------------------------------------------------
@on_wheel = ( S, event ) =>
  if event.originalEvent.deltaY < 0 then  @navigate_vertically S, -1
  else                                    @navigate_vertically S, +1
  return false;

#-----------------------------------------------------------------------------------------------------------
@on_vertical_navigation = ( uie ) ->
  switch uie.name
    when 'up'         then  delta = -1
    when 'down'       then  delta = +1
    when 'page-up'    then  delta = -10
    when 'page-down'  then  delta = +10
  @navigate_vertically uie.S, delta
  uie.event.preventDefault()
  return null

#-----------------------------------------------------------------------------------------------------------
@navigate_vertically = ( S, delta ) ->
  new_row_idx       = S.row_idx + delta
  corrected_row_idx = Math.max 0,                 new_row_idx
  corrected_row_idx = Math.min S.rows.length - 1, corrected_row_idx
  #.........................................................................................................
  XE.emit 'WINDOW/scroll/vertical', {
    S,
    from: S.row_idx         + 1,
    via:  new_row_idx       + 1,
    to:   corrected_row_idx + 1, }
  #.........................................................................................................
  S.row_idx         = corrected_row_idx
  element           = ( jQuery '#candidates tr' ).eq S.row_idx
  if element?.offset? and ( element_offset = element.offset() )?
    delta_px                      = element_offset.top - S.shade_offset_top
    S.scroller_last_top           = S.scroller.scrollTop() + delta_px
    S.ignore_next_scroll_events  += +1
    S.scroller.scrollTop S.scroller_last_top
    # ( ( jQuery element ).find '.glyph' ).css 'font-size', '125%'
  return null

# # #-----------------------------------------------------------------------------------------------------------
# # XE.listen_to 'WINDOW/scroll/vertical', @, ({ S, from, via, to, }) ->
# #   whisper "WINDOW/scroll/vertical #{from} -> #{via} -> #{to}"

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '^candidates', @, ( d ) ->
  @focusframe_to_candidates S unless S.focus_is_candidates
  v       = d.value
  { S, }  = v
  rows    = ( ( T.get_flexgrid_html ( idx + 1 ), glyph ) for glyph, idx in v.candidates ).join '\n'
  ( jQuery '#candidates-flexgrid div' ).remove()
  ( jQuery '#candidates-flexgrid'     ).append rows
  #.........................................................................................................
  ### TAINT code duplication ###
  S.glyphboxes = jQuery '#candidates-flexgrid div.glyph'
  S.glyphboxes.on 'click', ( e ) =>
    me = jQuery e.target
    ### TAINT code duplication ###
    ### TAINT use API to move selection ###
    S.glyphboxes.removeClass  'cdtsel'
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
  S.glyphboxes   ?= jQuery '#candidates-flexgrid div.glyph'
  lcol            = 0
  lrow            = 0
  prv_top         = null
  candidate_count = S.glyphboxes.length
  lnr             = 0
  rnr             = candidate_count + 1
  rows            = []
  row             = null
  #.........................................................................................................
  @log "index_candidates() (#{candidate_count})"
  #.........................................................................................................
  for idx in [ 0 ... candidate_count ]
    glyphbox = S.glyphboxes.eq idx
    #.......................................................................................................
    if ( nxt_top = glyphbox.offset().top ) isnt prv_top
      if row?
        rows.push row
        col_count = row.length
        for candidate, col_idx in row
          candidate.attr 'rcol', col_count - col_idx
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
    for candidate in row
      candidate.attr 'rrow', row_count - row_idx
  #.........................................................................................................
  rows.length = 0 ### not strictly needed, just to make de-allocation explicit ###
  return null

#-----------------------------------------------------------------------------------------------------------
@select_nxt_candidate     = -> @_select_delta_candidate          +1
@select_prv_candidate     = -> @_select_delta_candidate          -1
@select_nxtline_candidate = -> @_select_deltaline_candidate      +1
@select_prvline_candidate = -> @_select_prv_deltaline_candidate  -1

#-----------------------------------------------------------------------------------------------------------
@_select_delta_candidate = ( delta ) ->
  ### Select delta-next or -previous candidate; `+1` moves to immediately following candidate, `-1` to
  immediately preceding one; higher `delta` skips that many gaps. Returns number of candidates moved, so
  returns zero if there were no candidates, or was already on first (or last) when moving backwards (or
  forwards). ###
  R                   = 0
  return R if delta is 0
  prv_cdtsel          = jQuery '.cdtsel'
  #.........................................................................................................
  if prv_cdtsel.length is 0
    @log "_select_delta_candidate: no candidate selected"
    return R
  #.........................................................................................................
  glyphboxes          = jQuery '#candidates-flexgrid div.glyph'
  method_name         = if delta > 0 then 'next' else 'prev'
  delta               = Math.abs delta
  prv_cdtsel[ 0 ].scrollIntoViewIfNeeded()
  #.........................................................................................................
  while delta > 0
    nxt_cdtsel          = prv_cdtsel[ method_name ]()
    break if nxt_cdtsel.length is 0
    R                  += +1
    glyphboxes.removeClass  'cdtsel'
    nxt_cdtsel.addClass     'cdtsel'
    nxt_cdtsel[ 0 ].scrollIntoViewIfNeeded()
    delta              += -1
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@_select_prv_deltaline_candidate = ( delta ) ->
  await @_select_deltaline_candidate delta
  await @_select_first_candidate_in_line()

#-----------------------------------------------------------------------------------------------------------
@_select_first_candidate_in_line = ->

#-----------------------------------------------------------------------------------------------------------
@_select_deltaline_candidate = ( delta ) ->
  return new Promise ( resolve ) =>
    @log "µ77722 _select_deltaline_candidate #{delta}"
    return resolve() if S.selecting_candidate
    return resolve() if delta is 0
    S.selecting_candidate = true
    prv_cdtsel            = jQuery '.cdtsel'
    #.......................................................................................................
    if prv_cdtsel.length is 0
      S.selecting_candidate = false
      @log "µ33634 _select_deltaline_candidate: no candidate selected"
      return resolve()
    #.......................................................................................................
    sub_delta             = Math.sign delta
    delta                 = Math.abs  delta
    prv_top               = prv_cdtsel.offset().top
    dts                   = 0
    #.......................................................................................................
    try_next_candidate  = =>
      #.....................................................................................................
      if ( @_select_delta_candidate sub_delta ) is 0
        S.selecting_candidate = false
        return resolve()
      #.....................................................................................................
      nxt_cdtsel  = jQuery '.cdtsel'
      if nxt_cdtsel.length is 0 ### should never happen ###
        S.selecting_candidate = false
        @log "µ33679 _select_deltaline_candidate: no candidate selected"
        return resolve()
      #.....................................................................................................
      if ( Math.abs nxt_cdtsel.offset().top - prv_top ) < 2
        defer try_next_candidate
      else
        S.selecting_candidate = false
      return resolve()
    #.......................................................................................................
    defer try_next_candidate
    return resolve()

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '^load-documents', @, ( d ) ->
  ### Will be used to restore previous state, open new documents; for now, just opens the default file. ###
  ### TAINT auto-create file when not present ###
  file_path = PATH.resolve PATH.join __dirname, '../.cache/default.md'
  d.value.S.codemirror.editor.doc.setValue FS.readFileSync file_path, { encoding: 'utf-8', }
  return null

#-----------------------------------------------------------------------------------------------------------
### TAINT use proper keybinding API to define key bindings ###
XE.listen_to '^keyboard', @, ( d ) ->
  { key, S, } = d.value
  if ( key.name is 'ctrl+s' ) and ( key.move is 'up' )
    XE.emit PD.new_event '^save-document', { S, }
  return null

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '^save-document', @, ( d ) ->
  ### Will be used to save active document; currently just saves default file. ###
  file_path = PATH.resolve PATH.join __dirname, '../.cache/default.md'
  @log "saving document to #{rpr file_path}"
  FS.writeFileSync file_path, d.value.S.codemirror.editor.doc.getValue()
  return null

#-----------------------------------------------------------------------------------------------------------
@focusframe_to_editor = ( S ) ->
  @_focusframe_to S, 'leftbar'
  ### TAINT use method, must be possible to remap ###
  S.focus_is_candidates = false
  # S.kblevels.shift      = false
@focusframe_to_candidates = ( S ) ->
  @_focusframe_to S, 'rightbar'
  ### TAINT use method, must be possible to remap ###
  S.focus_is_candidates = true
  # S.kblevels.shift      = false
@focusframe_to_logger = ( S ) ->
  @_focusframe_to S, '#logger'
  ### TAINT use method, must be possible to remap ###
  S.focus_is_candidates = false
  # S.kblevels.shift      = false

#-----------------------------------------------------------------------------------------------------------
@_focusframe_to = ( S, target ) ->
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
### TAINT use proper keybinding API to define key bindings ###
XE.listen_to '^kblevel', @, ( d ) ->
  ### map kblevel 'shift' to manual editor/candidates focus selection ###
  v       = d.value
  { S, }  = v
  # debug 'µ87444', S.kblevels.shift
  if ( S.focus_is_candidates = S.kblevels.shift ) then  @focusframe_to_candidates S
  else                                                  @focusframe_to_editor     S
  ### TAINT consider to re-set focus after mouse clicks to elsewhere in GUI ###
  ### Make browser focus always stay on editor: ###
  return null

#-----------------------------------------------------------------------------------------------------------
@always_focus_editor = ->
  @always_focus_editor = -> ### do not add any more handlers with this method after first call ###
  ( jQuery 'div.CodeMirror-code' ).on 'blur', -> @focus()
  ( jQuery 'div.CodeMirror-code' ).focus()
  return null

# #-----------------------------------------------------------------------------------------------------------
# ### TAINT use proper keybinding API to define key bindings ###
# XE.listen_to '^keyboard', @, ( d ) ->
#   { key, S, } = d.value
#   return unless ( key.move is 'up' )
#   switch key.name
#     when 'left'     then  @focusframe_to_editor     S
#     when 'right'    then  @focusframe_to_candidates S
#     when 'up'       then  @focusframe_to_editor     S
#     when 'down'     then  @focusframe_to_logger     S
#   return null



###
#-----------------------------------------------------------------------------------------------------------
@_handle_cm_keymap_move = ( cm, editor_method, candidates_method ) ->
  if S.focus_is_candidates then candidates_method.apply @,                    cm
  else                          editor_method.apply     CodeMirror.commands,  cm
  return null
###

#-----------------------------------------------------------------------------------------------------------
@cm_keymap_move_left = ( cm ) ->
  ### TAINT is there a way not to name default command explicitly? ###
  if S.focus_is_candidates then @select_prv_candidate()
  else                          CodeMirror.commands.goCharLeft cm
  return null

#-----------------------------------------------------------------------------------------------------------
@cm_keymap_move_right = ( cm ) ->
  if S.focus_is_candidates then @select_nxt_candidate()
  else                          CodeMirror.commands.goCharRight cm
  return null

#-----------------------------------------------------------------------------------------------------------
@cm_keymap_move_up = ( cm ) ->
  if S.focus_is_candidates then debug 'µ77644-2', "cursor movement goes to candidates"
  else                          CodeMirror.commands.goLineUp cm
  return null

#-----------------------------------------------------------------------------------------------------------
@cm_keymap_move_down = ( cm ) ->
  if S.focus_is_candidates then debug 'µ77644-2', "cursor movement goes to candidates"
  else                          CodeMirror.commands.goLineDown cm
  return null

#-----------------------------------------------------------------------------------------------------------
@cm_keymap_move_tab = ( cm ) ->
  if S.focus_is_candidates then @select_nxtline_candidate()
  else                          CodeMirror.commands.defaultTab cm
  return null

#-----------------------------------------------------------------------------------------------------------
@cm_keymap_move_shifttab = ( cm ) ->
  if S.focus_is_candidates then @select_prvline_candidate()
  else                          CodeMirror.commands.indentLess cm
  return null


#-----------------------------------------------------------------------------------------------------------
@init_cm_keymap = ( S ) ->
  mktw_keymap =
    'Left':       ( cm  ) => @cm_keymap_move_left     cm
    'Right':      ( cm  ) => @cm_keymap_move_right    cm
    'Up':         ( cm  ) => @cm_keymap_move_up       cm
    'Down':       ( cm  ) => @cm_keymap_move_down     cm
    'Tab':        ( cm  ) => @cm_keymap_move_tab      cm
    'Shift-Tab':  ( cm  ) => @cm_keymap_move_shifttab cm
  #.........................................................................................................
  S.codemirror.editor.addKeyMap mktw_keymap
  return null

#-----------------------------------------------------------------------------------------------------------
@init = ->
  # { remote, }               = require 'electron'
  # XE                        = remote.require './xemitter'
  #.........................................................................................................
  ### Instantiate state, add important UI elements ###
  S                     = STATE.new()
  S.candidates          =
    jq:           jQuery '#candidates'
    selected:
      id:         null
  S.focus_is_candidates = false
  #.........................................................................................................
  # ### Register key and mouse events ###
  # S.scroller.on 'wheel',                ( event ) => @on_wheel                S, event
  # S.scroller.on 'scroll',               ( event ) => @on_scroll               S, event
  # S.input.on 'input',                   ( event ) => @on_input                S, event
  # ### use event for this? ###
  # S.scroller_last_top = S.scroller.scrollTop()
  #.........................................................................................................
  ### Initialize CodeMirror ###
  S.codemirror.editor = CodeMirror.fromTextArea ( jQuery '#codemirror' )[ 0 ], S.codemirror.settings
  S.codemirror.editor.setSize null, '100%'
  S.codemirror.editor.on 'inputRead', ( me, change ) -> XE.emit PD.new_event '^raw-input', { S, change, }
  S.codemirror.editor.on 'change', ( me, change ) ->
    ### TAINT when inserting results, will there be a change event? ###
    return null unless change.origin is '+delete'
    XE.emit PD.new_event '^raw-input', { S, change, }
  @always_focus_editor()
  #.........................................................................................................
  S.codemirror.editor.on 'beforeChange',    ( me, change      ) -> whisper 'µ66653', 'beforeChange',  jr change
  S.codemirror.editor.on 'change',          ( me, change      ) -> whisper 'µ66653', 'change',        jr change
  # S.codemirror.editor.on 'changes',         ( me, changes     ) -> whisper 'µ66653', 'changes',       jr changes
  # S.codemirror.editor.on 'cursorActivity',  ( me              ) -> whisper 'µ66653', 'cursorActivity'
  # S.codemirror.editor.on 'keyHandled',      ( me, name, event ) -> whisper 'µ66653', 'keyHandled',    jr name
  # S.codemirror.editor.on 'inputRead',       ( me, change      ) -> whisper 'µ66653', 'inputRead',     jr change
  #.........................................................................................................
  ### Register key and mouse events ###
  KEYS.syphon_key_and_mouse_events S, jQuery 'html'
  # KEYS.register 'axis', 'vertical',     ( uie )   => @on_vertical_navigation  uie
  # KEYS.register 'slot', 'Enter',        ( uie )   => @on_add_selection        uie
  XE.emit PD.new_event '^load-documents', { S, }
  @focusframe_to_editor S
  @init_cm_keymap S
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





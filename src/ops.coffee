

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
{ $
  $async }                = PD
# XE                        = null
XE                        = require '../lib/xemitter'
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }


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
  logger.append ( "<div>#{Date.now()}: #{rpr key}: #{message}</div>" )
  console.log 'µ33499', Date.now(), key, d
  # if ( kblevels = d.value?.S?.kblevels )
  #   logger.append ( "<div>#{Date.now()}: kblevels: #{rpr kblevels}</div>" )
  logger.scrollTop logger[ 0 ].scrollHeight
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
  v       = d.value
  { S, }  = v
  @focusframe_to_candidates S
  rows    = []
  columns = [ 'short_iclabel', 'glyph', 'value', ]
  for candidate, idx in v.candidates
    nr = idx + 1
    rows.push T.get_flexgrid_html candidate
    # rows.push T.get_row_html [ [ 'nr', nr, ], [ 'glyph', candidate, ] ]
    # rows.push T.get_row_html [ [ 'nr', nr, ], ( [ key, row[ key ], ] for key in columns )..., ]
  rows = rows.join '\n'
  if true
    ( jQuery '#candidates-flexgrid div' ).remove()
    ( jQuery '#candidates-flexgrid'     ).append rows
  else
    ( jQuery '#candidates tr'    ).remove()
    ( jQuery '#candidates tbody' ).append rows
    ( jQuery '#qdt'              ).text S.qdt
  return null

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
@focusframe_to_editor     = ( S ) -> @_focusframe_to S, 'leftbar'
@focusframe_to_candidates = ( S ) -> @_focusframe_to S, 'rightbar'
@focusframe_to_logger     = ( S ) -> @_focusframe_to S, '#logger'

#-----------------------------------------------------------------------------------------------------------
@_focusframe_to = ( S, target_selector ) ->
  # target      = jQuery( document.activeElement )
  target      = jQuery target_selector
  ff          = jQuery 'focusframe'
  # ff.offset     target.offset()
  # ff.width      target.width()
  # ff.height     target.height()
  tgto        = target.offset()
  ff.animate {
    left:     tgto.left
    top:      tgto.top
    width:    target.width()
    height:   target.height() }, 100
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

#-----------------------------------------------------------------------------------------------------------
@init_keymap = ( S ) ->
  ### TAINT don't define method inside of object ###
  mktw_keymap = {
    #.......................................................................................................
    'Left': ( cm ) ->
      if S.focus_is_candidates
        debug 'µ77644-1', "cursor movement goes to candidates"
      else
        CodeMirror.commands.goCharLeft cm
      return null
    #.......................................................................................................
    'Right': ( cm ) ->
      if S.focus_is_candidates
        debug 'µ77644-2', "cursor movement goes to candidates"
      else
        CodeMirror.commands.goCharRight cm
      return null
    #.......................................................................................................
    'Up': ( cm ) ->
      if S.focus_is_candidates
        debug 'µ77644-2', "cursor movement goes to candidates"
      else
        CodeMirror.commands.goLineUp cm
      return null
    #.......................................................................................................
    'Down': ( cm ) ->
      if S.focus_is_candidates
        debug 'µ77644-2', "cursor movement goes to candidates"
      else
        CodeMirror.commands.goLineDown cm
      return null
    #.......................................................................................................
    'Tab': ( cm ) ->
      if S.focus_is_candidates
        debug 'µ77644-2', "cursor movement goes to candidates"
      else
        CodeMirror.commands.defaultTab cm
      return null
    }
  #.........................................................................................................
  S.codemirror.editor.addKeyMap mktw_keymap
  # CodeMirror.normalizeKeyMap keyMap.mktw
  # S.codemirror.editor.setOption 'extraKeys', mktw_keymap
  # S.codemirror.commands.foobar = ( cm ) -> debug 'µ46644', 'foobar'
  return null

#-----------------------------------------------------------------------------------------------------------
@init = ->
  # { remote, }               = require 'electron'
  # XE                        = remote.require './xemitter'
  #.........................................................................................................
  ### Instantiate state, add important UI elements ###
  S                     = STATE.new()
  S.candidates          = jQuery '#candidates'
  # S.shade_offset_top    = ( jQuery 'shade.foreground' ).offset().top
  # S.scroller            = jQuery 'scroller'
  S.focus_is_candidates = false
  #.........................................................................................................
  # ### Make sure focus is on input element ###
  # ( jQuery '#text-input' ).focus()
  #.........................................................................................................
  ### TAINT temporary; will use KB event, icon, dedicated method for this ###
  ### Switch focus on click on editor ###
  # ( jQuery 'leftbar content' ).on 'click', ( event ) =>
  #   if S.codemirror.is_enlarged then  property = { 'height': ( jQuery 'leftbar content' ).css 'min-height' }
  #   else                              property = { 'height': ( jQuery 'leftbar content' ).css 'max-height' }
  #   S.codemirror.is_enlarged = not S.codemirror.is_enlarged
  #   ( jQuery 'leftbar content' ).animate property, 100
  # property = { 'height': ( jQuery 'leftbar content' ).css 'max-height' }
  # ( jQuery 'leftbar content' ).animate property, 100
  # #.........................................................................................................
  # ### Register key and mouse events ###
  # S.scroller.on 'wheel',                ( event ) => @on_wheel                S, event
  # S.scroller.on 'scroll',               ( event ) => @on_scroll               S, event
  # S.input.on 'input',                   ( event ) => @on_input                S, event
  # ### use event for this? ###
  # S.scroller_last_top = S.scroller.scrollTop()
  # #.........................................................................................................
  # ### Measure table row height, adjust shade ###
  # S.candidates_tr_height = ( jQuery '#candidates tr' ).height()
  # ( jQuery 'shade' ).height S.candidates_tr_height * 1.1
  #.........................................................................................................
  ### Initialize CodeMirror ###
  S.codemirror.editor = CodeMirror.fromTextArea ( jQuery '#codemirror' )[ 0 ], S.codemirror.settings
  S.codemirror.editor.setSize null, '100%'
  S.codemirror.editor.on 'inputRead', ( me, change ) -> XE.emit PD.new_event '^raw-input', { S, change, }
  #.........................................................................................................
  # S.codemirror.editor.on 'change',          ( me, change      ) -> whisper 'µ66653', 'change',        jr change
  # S.codemirror.editor.on 'changes',         ( me, changes     ) -> whisper 'µ66653', 'changes',       jr changes
  # S.codemirror.editor.on 'beforeChange',    ( me, change      ) -> whisper 'µ66653', 'beforeChange',  jr change
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
  @init_keymap S
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





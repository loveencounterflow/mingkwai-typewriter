

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
# log                       = ( P... ) -> process.stdout.write ( rpr P ) + '\n'
# TRAP                      = require 'mousetrap'
# { app, globalShortcut, }  = require 'electron'
# PTVR                      = require '../lib/lib/ptv-reader'
# IME                       = require '../lib/ime'
STATE                     = require '../lib/state'
T                         = require '../lib/templates'
### https://github.com/sindresorhus/electron-unhandled ###
#...........................................................................................................
require                   '../lib/exception-handler'
require                   '../lib/kana-input'
#...........................................................................................................
PD                        = require 'pipedreams'
{ jr, }                   = CND
{ $
  $async }                = PD
XE                        = null



# #-----------------------------------------------------------------------------------------------------------
# XE.listen_to 'KEYS/kblevels/change', @, ( { S, key, } ) ->
#   ### TAINT bind keys using configuration ###
#   { name, toggle, } = key
#   #.........................................................................................................
#   S.bind_left   = ( toggle is 'on' ) if name is 'alt'
#   S.bind_right  = ( toggle is 'on' ) if name is 'altgr'
#   #.........................................................................................................
#   if S.bind_left  then  ( jQuery 'lbbar' ).show() ### TAINT ###
#   else                  ( jQuery 'lbbar' ).hide() ### TAINT ###
#   if S.bind_right then  ( jQuery 'rbbar' ).show() ### TAINT ###
#   else                  ( jQuery 'rbbar' ).hide() ### TAINT ###
#   #.........................................................................................................
#   return null

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
  element           = $( '#candidates tr' ).eq S.row_idx
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
@on_input = ( S, event ) ->
  self    = jQuery @
  # await IME.fetch_rows S, S.input.text()
  rows    = []
  columns = [ 'short_iclabel', 'glyph', 'value', ]
  for row, idx in S.rows
    rows.push T.get_row_html [ [ 'nr', idx + 1, ], ( [ key, row[ key ], ] for key in columns )..., ]
  rows = rows.join '\n'
  ( jQuery '#candidates tr'    ).remove()
  ( jQuery '#candidates tbody' ).append rows
  ( jQuery '#qdt'              ).text S.qdt
  return null

#-----------------------------------------------------------------------------------------------------------
@init = ->
  { remote, }               = require 'electron'
  XE                        = remote.require './xemitter'
  #.........................................................................................................
  ### Instantiate state, add important UI elements ###
  S                     = STATE.new()
  S.candidates          = jQuery '#candidates'
  S.shade_offset_top    = ( jQuery 'shade.foreground' ).offset().top
  S.input               = jQuery '#text-input'
  S.scroller            = jQuery 'scroller'
  #.........................................................................................................
  ### Make sure focus is on input element ###
  ( jQuery '#text-input' ).focus()
  #.........................................................................................................
  ### TAINT temporary; will use KB event, icon, dedicated method for this ###
  ### Switch focus on click on editor ###
  ( jQuery 'topbar content' ).on 'click', ( event ) =>
    if S.codemirror.is_enlarged then  property = { 'height': ( jQuery 'topbar content' ).css 'min-height' }
    else                              property = { 'height': ( jQuery 'topbar content' ).css 'max-height' }
    S.codemirror.is_enlarged = not S.codemirror.is_enlarged
    ( jQuery 'topbar content' ).animate property, 100
  #.........................................................................................................
  ### Register key and mouse events ###
  S.scroller.on 'wheel',                ( event ) => @on_wheel                S, event
  S.scroller.on 'scroll',               ( event ) => @on_scroll               S, event
  S.input.on 'input',                   ( event ) => @on_input                S, event
  ### use event for this? ###
  S.scroller_last_top = S.scroller.scrollTop()
  #.........................................................................................................
  ### Measure table row height, adjust shade ###
  S.candidates_tr_height = ( jQuery '#candidates tr' ).height()
  ( jQuery 'shade' ).height S.candidates_tr_height * 1.1
  #.........................................................................................................
  ### Initialize CodeMirror ###
  S.codemirror.editor = CodeMirror.fromTextArea ( jQuery '#codemirror' )[ 0 ], S.codemirror.settings
  # S.codemirror.editor.replaceSelection 'this is the editor'
  S.codemirror.editor.setSize null, '100%'
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
jQuery init.bind @

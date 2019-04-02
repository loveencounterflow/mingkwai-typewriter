

'use strict'
### TAINT consider using e.g. https://www.npmjs.com/package/combokeys ###


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = '明快打字机/KEYS'
log                       = CND.get_logger 'plain',   badge
info                      = CND.get_logger 'info',    badge
alert                     = CND.get_logger 'alert',   badge
debug                     = CND.get_logger 'debug',   badge
warn                      = CND.get_logger 'warn',    badge
urge                      = CND.get_logger 'urge',    badge
whisper                   = CND.get_logger 'whisper', badge
help                      = CND.get_logger 'help',    badge
echo                      = CND.echo.bind CND
#...........................................................................................................
jr                        = JSON.stringify
assign                    = Object.assign
#...........................................................................................................
PD                        = require 'pipedreams'
XE                        = require './xemitter'
S                         = require './settings' ### module-global configuration and editor state object ###

#-----------------------------------------------------------------------------------------------------------
@keycodes = require './blaidddrwg-keycodes'

#-----------------------------------------------------------------------------------------------------------
@_preprocess_key_up_or_down_event = ( event ) =>
  # code      = event.keyCode ? event.which
  code    = event.which
  name    = []
  #.........................................................................................................
  name.push 'alt'       if code is  18  or event.altKey
  name.push 'altgr'     if code is 225  or event.originalEvent.getModifierState "AltGraph"
  name.push 'ctrl'      if code is  17  or event.ctrlKey
  name.push 'capslock'  if code is  20
  name.push 'shift'     if code is  16  or event.shiftKey
  label = @keycodes.get code
  unless label in [ 'alt', 'altgr', 'ctrl', 'capslock', 'shift', ]
    name.push label ? code
  name  = name.join '+'
  return { name, code, }

#-----------------------------------------------------------------------------------------------------------
@$on_key_down = -> ( event ) =>
  d = @_preprocess_key_up_or_down_event event
  if d.name in [ 'alt', 'altgr', 'ctrl', 'shift', 'capslock', ] then  S.kblevels.prv_down = d.name
  else                                                                S.kblevels.prv_down = null
  return null

#-----------------------------------------------------------------------------------------------------------
@$on_key_up = -> ( event ) =>
  key                 = @_preprocess_key_up_or_down_event event
  prv_down            = S.kblevels.prv_down
  S.kblevels.prv_down = null
  #.........................................................................................................
  if key.name in [ 'alt', 'altgr', 'ctrl', 'shift', 'capslock', ]
    return unless key.name is prv_down
  #.........................................................................................................
  XE.emit PD.new_event '^keyboard', key
  return true

#-----------------------------------------------------------------------------------------------------------
@generate_keboard_events = ( jquery_element ) ->
  jquery_element.on 'keydown',            @$on_key_down()
  jquery_element.on 'keyup',              @$on_key_up()

#-----------------------------------------------------------------------------------------------------------
@bind = ( P... ) ->
  [ keyname, self, listener, ] = XE._get_ksl arguments...
  XE.listen_to '^keyboard', ( d ) ->
    return null unless d.value.name is keyname
    return listener.apply self




###
document.onkeypress = (e) ->
  console.log 'µ22982', e
  debug 'µ22982', e.keyIdentifier, e.getModifierState
  # cid = parseInt ( e[ 'keyIdentifier' ].replace /^U\+/, '' ), 16
  # cid = 0x3013 if ( CND.type_of cid ) isnt 'number'
  # debug '©sz3Ku', 'keyIdentifier',    e[ 'keyIdentifier'    ], rpr String.fromCodePoint cid
  # debug '©hRgmv', 'getModifierState "Alt"       ', e.getModifierState "Alt"
  # debug '©hRgmv', 'getModifierState "AltGraph"  ', e.getModifierState "AltGraph"
  # debug '©hRgmv', 'getModifierState "CapsLock"  ', e.getModifierState "CapsLock"
  # debug '©hRgmv', 'getModifierState "Control"   ', e.getModifierState "Control"
  # debug '©hRgmv', 'getModifierState "Fn"        ', e.getModifierState "Fn"
  # debug '©hRgmv', 'getModifierState "FnLock"    ', e.getModifierState "FnLock"
  # debug '©hRgmv', 'getModifierState "Hyper"     ', e.getModifierState "Hyper"
  # debug '©hRgmv', 'getModifierState "Meta"      ', e.getModifierState "Meta"
  # debug '©hRgmv', 'getModifierState "NumLock"   ', e.getModifierState "NumLock"
  # debug '©hRgmv', 'getModifierState "OS"        ', e.getModifierState "OS"
  # debug '©hRgmv', 'getModifierState "ScrollLock"', e.getModifierState "ScrollLock"
  # debug '©hRgmv', 'getModifierState "Shift"     ', e.getModifierState "Shift"
  # debug '©hRgmv', 'getModifierState "Super"     ', e.getModifierState "Super"
  # debug '©hRgmv', 'getModifierState "Symbol"    ', e.getModifierState "Symbol"
  # debug '©hRgmv', 'getModifierState "SymbolLock"', e.getModifierState "SymbolLock"
  # return null
###




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
@keycodes = require './BLAIDDDRWG-keycodes'

#-----------------------------------------------------------------------------------------------------------
@_preprocess_key_up_or_down_event = ( event ) =>
  # code      = event.keyCode ? event.which
  code    = event.which
  name    = []
  #.........................................................................................................
  name.push 'alt'       if code is  18  or event.altKey
  name.push 'altgr'     if code is 225  or event.originalEvent.getModifierState "AltGraph"
  name.push 'ctrl'      if code is  17  or event.ctrlKey
  name.push 'shift'     if code is  16  or event.shiftKey
  # name.push 'capslock'  if code is   0
  label = @keycodes.get code
  unless label in [ 'alt', 'altgr', 'ctrl', 'shift', ]
    name.push label ? code
  name  = name.join '+'
  #.........................................................................................................
  move = switch event.type
    when 'keyup'    then 'up'
    when 'keydown'  then 'down'
    else null
  #.........................................................................................................
  return { name, code, move, }


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@$on_key_down = -> ( event ) =>
  # debug 'µ56545', event
  ### thx to https://stackoverflow.com/a/22029109/7568091 ###
  oe        = event.originalEvent
  chr       = oe.key
  slot      = oe.code
  #.........................................................................................................
  location  = switch oe.location
    when KeyboardEvent.DOM_KEY_LOCATION_STANDARD        then 'standard'
    when KeyboardEvent.DOM_KEY_LOCATION_LEFT            then 'left'
    when KeyboardEvent.DOM_KEY_LOCATION_RIGHT           then 'right'
    when KeyboardEvent.DOM_KEY_LOCATION_NUMPAD          then 'numpad'
    else null
  #.........................................................................................................
  kind = switch slot
    when 'ArrowUp', 'ArrowDown', 'PageUp', 'PageDown', 'ArrowLeft', 'ArrowRight', 'Home', 'End' then 'navigation'
    when 'Space', 'Tab', 'Return', 'Enter' then 'spacing'
    else null
  #.........................................................................................................
  axis = switch slot
    when 'ArrowUp', 'ArrowDown', 'PageUp', 'PageDown'   then 'vertical'
    when 'ArrowLeft', 'ArrowRight'                      then 'horizontal'
    when 'Home', 'End'                                  then 'either'
    else null
  #.........................................................................................................
  direction = switch slot
    when 'ArrowLeft'                                    then 'left'
    when 'ArrowRight'                                   then 'right'
    when 'ArrowUp', 'PageUp'                            then 'up'
    when 'ArrowDown', 'PageDown'                        then 'down'
    else null
  #.........................................................................................................
  ### UIE: User Interaction Event ###
  uie           = { chr, slot, location, kind, axis, direction, }
  uie           = assign uie, { event, }, ( @_preprocess_key_up_or_down_event event )
  #.........................................................................................................
  if uie.name in [ 'alt', 'altgr', 'ctrl', 'shift', 'capslock', ] then  S.kblevels.prv_down = uie.name
  else                                                                  S.kblevels.prv_down = null
  #.........................................................................................................
  XE.emit PD.new_event '^uie', uie
  # return handler uie if ( handler = @_get_key_handler uie )?
  return null

###
'ArrowLeft':  [ 'navigation', 'horizontal', 'left' ]
'ArrowRight': [ 'navigation', 'horizontal', 'right' ]
'ArrowUp':    [ 'navigation', 'vertical', 'up' ]
'ArrowDown':  [ 'navigation', 'vertical', 'down' ]
'PageUp':     [ 'navigation', 'vertical', 'up' ]
'PageDown':   [ 'navigation', 'vertical', 'down' ]
'Home':       [ 'navigation', 'vertical', 'horizontal', 'home' ]
'End':        [ 'navigation', 'vertical', 'horizontal', 'end' ]
###

#-----------------------------------------------------------------------------------------------------------
@$on_key_up = -> ( event ) =>
  key = @_preprocess_key_up_or_down_event event
  #.........................................................................................................
  if key.name in [ 'alt', 'altgr', 'ctrl', 'shift', 'capslock', ] and S.kblevels.prv_down is key.name
    S.kblevels[ key.name ]  = toggle = not S.kblevels[ key.name ]
    key.toggle              = if toggle then 'on' else 'off'
    XE.emit PD.new_event '^kblevel', { key, }
  #.........................................................................................................
  S.kblevels.prv_down = null
  XE.emit PD.new_event '^keyboard', { key, }
  return true

#-----------------------------------------------------------------------------------------------------------
@$on_other = -> ( event ) =>
  # info '77363', event.type, event.originalEvent.data
  return true

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@syphon_key_and_mouse_events = ( jquery_element ) ->
  jquery_element.on 'keydown',            @$on_key_down()
  jquery_element.on 'keyup',              @$on_key_up()
  jquery_element.on 'beforeinput',        @$on_other()
  jquery_element.on 'input',              @$on_other()
  jquery_element.on 'compositionstart',   @$on_other()
  jquery_element.on 'compositionupdate',  @$on_other()
  jquery_element.on 'compositionend ',    @$on_other()

###
    document.onkeypress = (e) ->
      cid = parseInt ( e[ 'keyIdentifier' ].replace /^U\+/, '' ), 16
      cid = 0x3013 if ( CND.type_of cid ) isnt 'number'
      debug '©sz3Ku', 'keyIdentifier',    e[ 'keyIdentifier'    ], rpr String.fromCodePoint cid
      debug '©hRgmv', 'getModifierState "Alt"       ', e.getModifierState "Alt"
      debug '©hRgmv', 'getModifierState "AltGraph"  ', e.getModifierState "AltGraph"
      debug '©hRgmv', 'getModifierState "CapsLock"  ', e.getModifierState "CapsLock"
      debug '©hRgmv', 'getModifierState "Control"   ', e.getModifierState "Control"
      debug '©hRgmv', 'getModifierState "Fn"        ', e.getModifierState "Fn"
      debug '©hRgmv', 'getModifierState "FnLock"    ', e.getModifierState "FnLock"
      debug '©hRgmv', 'getModifierState "Hyper"     ', e.getModifierState "Hyper"
      debug '©hRgmv', 'getModifierState "Meta"      ', e.getModifierState "Meta"
      debug '©hRgmv', 'getModifierState "NumLock"   ', e.getModifierState "NumLock"
      debug '©hRgmv', 'getModifierState "OS"        ', e.getModifierState "OS"
      debug '©hRgmv', 'getModifierState "ScrollLock"', e.getModifierState "ScrollLock"
      debug '©hRgmv', 'getModifierState "Shift"     ', e.getModifierState "Shift"
      debug '©hRgmv', 'getModifierState "Super"     ', e.getModifierState "Super"
      debug '©hRgmv', 'getModifierState "Symbol"    ', e.getModifierState "Symbol"
      debug '©hRgmv', 'getModifierState "SymbolLock"', e.getModifierState "SymbolLock"

###


###

'key' events
  * move / flank / gesture
    * down / press
    * up / release
    * hold / repeat (single glyph and DNS only)
    * on  (toggles only)
    * off (toggles only)
  * kind
    * glyph (printable character)
      * single
      * partial (e.g. ´e -> é)
    * DNS (deletion, navigation, spacing)
      * deletion (backspace, delete)
      * navigation (left, right, up, down, page-down, home)
      * spacing (space, tab, return, enter)
      * IME (input method e.g. for East Asian languages)
      * insertion
      * correction
      * result
    * KBL (keyboard levels, a.k.a. modifiers)
      * chorded (alt, shift, ctrl)
      * toggles (capslock, numlock, scrolllock, insert)


* can we catch all DOM events?

* cursor styling in input field? -> caret-color
* text input, textarea or contenteditable? -> contenteditable allows styling, so this
* difference between jquery `.on`, `.on` methods? -> new vs. old
* does Chrome have a beforeinput event? -> OK with update to Electron 3
* why is the data attribute not used? -> OK with update to Electron 3

###



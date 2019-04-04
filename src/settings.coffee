

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/WINDOW'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
# inspect                   = ( require 'util' ).inspect
PATH                      = require 'path'

#-----------------------------------------------------------------------------------------------------------
module.exports = S =
  app:
    high_dpi_support:           1
    force_device_scale_factor:  1.25
    force_color_profile:        'sRGB'
  window:
    # show_devtools:    true
    maximize:         true
    electron: ### see https://electronjs.org/docs/api/browser-window ###
      x:                      700
      y:                      0
      # width:                  1500
      width:                  800
      height:                 600

      # width:                  1200
      # height:                 600
      # fullscreen:             true

      backgroundColor:        "#d6d8dc" # Set the default background color of the window to match the CSS background color of the page, this prevents any white flickering
      show:                   false     # Don't show the window until it's ready, this prevents any white flickering
      frame:                  true
      transparent:            true
      icon:                   PATH.join __dirname, '../public/mingkwai-icon.128.png'
      # icon:                   PATH.join __dirname, '../public/icon@2x.png'
      title:                  '明快打字机'
      textAreasAreResizable:  false
      # darkTheme:              true ### no effect on Mint ###
      webSecurity:                  true
      allowRunningInsecureContent:  false
      defaultEncoding:              'utf-8'
      nodeIntegration:              true ### required from electron v5.0.0 onwards ###
      setAutoHideMenuBar:           true
      setMenuBarVisibility:         true
      zoomFactor:                   1
  # selectors:      'abcdefghijklmnopqrstuvwxyz'
  #.......................................................................................................
  codemirror:
    #.....................................................................................................
    editor:                   null ### CodeMirror instance ###
    is_enlarged:              false
    #.....................................................................................................
    settings:
      # specialCharPlaceholder: function(char) → Element
      value:                        'console.log( "helo" );'
      autoCloseBrackets:            true
      direction:                    'ltr'
      electricChars:                true
      firstLineNumber:              1
      indentUnit:                   2
      indentWithTabs:               true
      inputStyle:                   'contenteditable'
      keyMap:                       'sublime'
      lineNumbers:                  true
      lineWrapping:                 false
      matchBrackets:                true
      # mode:                         'coffeescript'
      # mode:                         'javascript',
      mode:                         'markdown',
      rtlMoveVisually:              true
      showCursorWhenSelecting:      true
      smartIndent:                  true
      specialChars:                 /[\u0000-\u001f\u007f-\u009f\u00ad\u061c\u200b-\u200f\u2028\u2029\ufeff]/
      tabSize:                      2
      theme:                        'monokai'
      selectionsMayTouch:           true
      undoDepth:                    200
      autofocus:                    true
      cursorBlinkRate:              400
      cursorScrollMargin:           5
      cursorHeight:                 1
      resetSelectionOnContextMenu:  false
      viewportMargin:               10
      spellcheck:                   false
      autocorrect:                  false
      autocapitalize:               false
  #.......................................................................................................
  buffer:         []
  rows:           []
  kblevels:
    prv_down:       null
    alt:            true
    altgr:          false
    shift:          false
    capslock:       false
    ctrl:           false
  query:                      null
  row_idx:                    0
  page_idx:                   0
  page_height:                30
  bind_left:                  null
  bind_right:                 null
  qdt:                        null ### query time ###
  scroller_last_top:          null
  ignore_next_scroll_events:  0
  candidates:                 null
  input:                      null
  ignore_delete:              0 ### number of `+delete` events to ignore ###
  transcriptors:              null
  transcriptor:               null


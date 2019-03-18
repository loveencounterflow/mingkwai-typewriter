

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
@new = ->
  R =
    window:
      # show_devtools:    true
      # maximize:         true
      electron: ### see https://electronjs.org/docs/api/browser-window ###
        x:                      700
        y:                      0
        width:                  1500
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
        nodeIntegration:        true ### required from electron v5.0.0 onwards ###
    # selectors:      'abcdefghijklmnopqrstuvwxyz'
    #.......................................................................................................
    codemirror:
      #.....................................................................................................
      editor:                   null ### CodeMirror instance ###
      is_enlarged:              false
      #.....................................................................................................
      settings:
        # mode:                     'coffeescript'
        # mode:                     'javascript',
        keyMap:                   'sublime'
        theme:                    'monokai'
        # value:                    'console.log( "helo" );'
        lineNumbers:              true
        autoCloseBrackets:        true
        matchBrackets:            true
        showCursorWhenSelecting:  true
        tabSize:                  2
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
    qdt:                        null # query time
    scroller_last_top:          null
    ignore_next_scroll_events:  0
    candidates:                 null
    shade_offset_top:           null
    input:                      null
    scroller:                   null
  return R


# ############################################################################################################
# if ( remote = ( require 'electron' ).remote )?
#   global.S = remote.getGlobal 'S'
#   unless S?
#     throw new Error "unable to acquire state"
# else
#   global.S = @new()


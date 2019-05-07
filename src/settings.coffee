

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
    high_dpi_support:           0
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

      backgroundColor:              "#d6d8dc" # Set the default background color of the window to match the CSS background color of the page, this prevents any white flickering
      show:                         false     # Don't show the window until it's ready, this prevents any white flickering
      frame:                        true
      transparent:                  true
      icon:                         PATH.join __dirname, '../public/mingkwai-icon.128.png'
      # icon:                         PATH.join __dirname, '../public/icon@2x.png'
      title:                        '明快打字机'
      contextIsolation:             false
      defaultEncoding:              'utf-8'
      setAutoHideMenuBar:           true
      setMenuBarVisibility:         true
      webPreferences:
        allowRunningInsecureContent:  true
        backgroundThrottling:         true
        defaultEncoding:              'utf-8'
        defaultFontSize:              16
        defaultMonospaceFontSize:     13
        devTools:                     true
        enableBlinkFeatures:          'CSSVariables,KeyboardEventKey'
        enableRemoteModule:           true
        experimentalFeatures:         false
        images:                       true
        javascript:                   true
        minimumFontSize:              0
        navigateOnDragDrop:           false
        nodeIntegration:              true ### required from electron v5.0.0 onwards ###
        nodeIntegrationInWorker:      true
        offscreen:                    false
        plugins:                      false
        safeDialogs:                  false
        scrollBounce:                 false
        textAreasAreResizable:        false
        webaudio:                     true
        webgl:                        true
        webSecurity:                  false
        # zoomFactor:                   0.25
        # disableBlinkFeatures:         'CSSVariables,KeyboardEventKey'
        # preload:                      ### run with full rights before page load ###
        # defaultFontFamily Object (optional) - Sets the default font for the font-family.
        #   standard String (optional) - Defaults to Times New Roman.
        #   serif String (optional) - Defaults to Times New Roman.
        #   sansSerif String (optional) - Defaults to Arial.
        #   monospace String (optional) - Defaults to Courier New.
        #   cursive String (optional) - Defaults to Script.
        #   fantasy String (optional) - Defaults to Impact.
        # additionalArguments:          String - A list of strings that will be appended to process.argv in the renderer process of this app. Useful for passing small bits of data down to renderer process preload scripts.
        # safeDialogsMessage:           String (optional) - The message to display when consecutive dialog protection is triggered. If not defined the default message would be used, note that currently the default message is in English and not localized.
        # autoplayPolicy:
        # darkTheme:              true ### no effect on Mint ###
  # selectors:      'abcdefghijklmnopqrstuvwxyz'
  #.........................................................................................................
  codemirror:
    #.......................................................................................................
    editor:                   null ### CodeMirror instance ###
    is_enlarged:              false
    #.......................................................................................................
    settings:
      # specialCharPlaceholder: function(char) → Element
      # inputStyle:                   'contenteditable'
      # mode:                         'coffeescript'
      # mode:                         'javascript',
      # mode:                         'markdown',
      # specialChars:                 /[\u0000-\u000b\u000d-\u001f\u007f-\u009f\u00ad\u061c\u200b-\u200f\u2028\u2029\ufeff]/
      # specialChars:                 /[\u0000-\u001f\u007f-\u009f\u00ad\u061c\u200b-\u200f\u2028\u2029\ufeff]/
      # theme:                        'cobalt'
      # theme:                        'duotone-dark'
      # theme:                        'duotone-light'
      # theme:                        'mdn-like'
      autocapitalize:               false
      autoCloseBrackets:            true
      autocorrect:                  false
      autofocus:                    true
      cursorBlinkRate:              200
      cursorHeight:                 1
      cursorScrollMargin:           5
      direction:                    'ltr'
      electricChars:                true
      firstLineNumber:              1
      indentUnit:                   2
      indentWithTabs:               true
      inputStyle:                   'textarea'
      keyMap:                       'sublime'
      lineNumbers:                  true
      lineWrapping:                 true
      matchBrackets:                true
      mode:                         'text'
      resetSelectionOnContextMenu:  false
      rtlMoveVisually:              true
      selectionsMayTouch:           true
      showCursorWhenSelecting:      true
      smartIndent:                  true
      specialChars:                 /[\u0001-\u001f\u007f-\u009f\u00ad\u061c\u200b-\u200f\u2028\u2029\ufeff]/
      spellcheck:                   false
      tabSize:                      2
      theme:                        'monokai'
      undoDepth:                    200
      value:                        'console.log( "helo" );'
      viewportMargin:               10
  #.........................................................................................................
  kblevels:
    prv_down:         null
    alt:              true
    altgr:            false
    shift:            false
    capslock:         false
    ctrl:             false
  #.........................................................................................................
  is_frozen:        false
  transcriptors:    null
  tsnr_by_sigils:   {}
  transcriptor_region_markers:
    prefix:         '\u{f002}'
    suffix:         '\u{f003}'



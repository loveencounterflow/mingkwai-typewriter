
# cannot 'use strict'


############################################################################################################
njs_path                  = require 'path'
njs_fs                    = require 'fs'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = '明快打字机/TEMPLATES'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
#...........................................................................................................
# MKTS                      = require './main'
TEACUP                    = require 'coffeenode-teacup'
# CHR                       = require 'coffeenode-chr'
#...........................................................................................................
_STYLUS                   = require 'stylus'
# as_css                    = STYLUS.render.bind STYLUS
# style_route               = njs_path.join __dirname, '../src/mingkwai-typesetter.styl'
# css                       = as_css njs_fs.readFileSync style_route, encoding: 'utf-8'
#...........................................................................................................

#===========================================================================================================
# TEACUP NAMESPACE ACQUISITION
#-----------------------------------------------------------------------------------------------------------
Object.assign @, TEACUP

#-----------------------------------------------------------------------------------------------------------
@FULLHEIGHTFULLWIDTH  = @new_tag ( P... ) -> @TAG 'fullheightfullwidth', P...
@OUTERGRID            = @new_tag ( P... ) -> @TAG 'outergrid',           P...
@TOPBAR               = @new_tag ( P... ) -> @TAG 'topbar',              P...
@CONTENT              = @new_tag ( P... ) -> @TAG 'content',             P...
@MIDBAR               = @new_tag ( P... ) -> @TAG 'midbar',              P...
@SHADE                = @new_tag ( P... ) -> @TAG 'shade',               P...
@SCROLLER             = @new_tag ( P... ) -> @TAG 'scroller',            P...
@BOTTOMBAR            = @new_tag ( P... ) -> @TAG 'bottombar',           P...
@LBBAR                = @new_tag ( P... ) -> @TAG 'lbbar',               P...
@RBBAR                = @new_tag ( P... ) -> @TAG 'rbbar',               P...
#...........................................................................................................
@JS                   = @new_tag ( route ) -> @SCRIPT type: 'text/javascript',  src: route
@CSS                  = @new_tag ( route ) -> @LINK   rel:  'stylesheet',      href: route
@STYLUS               = ( source ) -> @STYLE {}, _STYLUS.render source


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@get_row_html = ( key_value_pairs ) ->
  return @render =>
    @TR '.candidate', =>
      for [ key, value, ] in key_value_pairs
        @TD ".#{key}", value.toString()


# #===========================================================================================================
# #
# #-----------------------------------------------------------------------------------------------------------
# @main = ->
#   #.........................................................................................................
#   return @render =>
#     @DOCTYPE 5
#     @HTML =>
#       @HEAD =>
#         @META charset: 'utf-8'
#         @TITLE '明快打字机'
#         # @LINK rel: 'shortcut icon', href: './favicon.icon'
#         ### -------------------------------------------------------------------------------------------- ###
#         ### The Tomkel-Harders device to make sure jQuery and other libraries are correctly              ###
#         ### loaded and made available even in Electron; see                                              ###
#         ###   https://github.com/electron/electron/issues/254#issuecomment-183483641                     ###
#         ###   https://stackoverflow.com/a/37480521/7568091                                               ###
#         ### -------------------------- THIS LINE MUST COME BEFORE ANY IMPORTS -------------------------- ###
#         @SCRIPT "if (typeof module === 'object') {window.module = module; module = undefined;}"
#         ### -------------------------------------------------------------------------------------------- ###
#         @JS     '../public/jquery-3.3.1.js'
#         @CSS    './styles.css'
#         ### -------------------------------------------------------------------------------------------- ###
#         ### CodeMirror                                                                                   ###
#         @CSS    '../public/codemirror-5.39.0/lib/codemirror.css'
#         @CSS    '../public/codemirror-5.39.0/addon/fold/foldgutter.css'
#         @CSS    '../public/codemirror-5.39.0/addon/dialog/dialog.css'
#         @CSS    '../public/codemirror-5.39.0/theme/monokai.css'
#         @JS     '../public/codemirror-5.39.0/lib/codemirror.js'
#         @JS     '../public/codemirror-5.39.0/mode/javascript/javascript.js'
#         @JS     '../public/codemirror-5.39.0/mode/coffeescript/coffeescript.js'
#         @JS     '../public/codemirror-5.39.0/addon/search/searchcursor.js'
#         @JS     '../public/codemirror-5.39.0/addon/search/search.js'
#         @JS     '../public/codemirror-5.39.0/addon/dialog/dialog.js'
#         @JS     '../public/codemirror-5.39.0/addon/edit/matchbrackets.js'
#         @JS     '../public/codemirror-5.39.0/addon/edit/closebrackets.js'
#         @JS     '../public/codemirror-5.39.0/addon/comment/comment.js'
#         @JS     '../public/codemirror-5.39.0/addon/wrap/hardwrap.js'
#         @JS     '../public/codemirror-5.39.0/addon/fold/foldcode.js'
#         @JS     '../public/codemirror-5.39.0/addon/fold/brace-fold.js'
#         @JS     '../public/codemirror-5.39.0/keymap/sublime.js'
#         ### -------------------------- THIS LINE MUST COME AFTER ANY IMPORTS --------------------------- ###
#         @SCRIPT "if (window.module) module = window.module;"
#         ### -------------------------------------------------------------------------------------------- ###
#       #=====================================================================================================
#       @COFFEESCRIPT =>
#         ( $ document ).ready ->
#       #=====================================================================================================
#       @BODY =>
#         #...................................................................................................
#         # @DIV '#qdt', '0'
#         @DIV '#outergrid.grid', =>
#           #.................................................................................................
#           @DIV '#toggle-area.area', =>
#             @DIV '#capslock.kblayers.toggle', => 'L'
#             @DIV '#shift.kblayers.toggle',    => 'S'
#             @DIV '#ctrl.kblayers.toggle',     => 'C'
#             @DIV '#alt.kblayers.toggle',      => 'A'
#             @DIV '#altgr.kblayers.toggle',    => '?'
#           #.................................................................................................
#           @DIV '#innergrid.grid.area', =>
#             @DIV '#upper-placeholder.area', => 'upper-placeholder'
#           #   @DIV '#output-area.area', =>
#           #     @TEXTAREA '#codemirror.inbox'
#             #...............................................................................................
#             @DIV '#candidates-area.area', =>
#               @DIV '.inbox', =>
#                 'candidates'
#               # @DIV '#selector-background'
#               # @DIV '.inbox', =>
#               #   # 'CANDIDATES'
#               #   @TABLE '#candidates', =>
#               #     @TBODY()
#               # @DIV '#selector-foreground'
#           #.................................................................................................
#           @DIV '#input-area.area', =>
#             @DIV '#text-input.inbox', contenteditable: 'true'
#           #.................................................................................................
#           @DIV '#status-area.area', => @DIV '.inbox', => 'STATUS'
#         #...................................................................................................
#         @JS     './window.js'

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@main_2 = ->
  #.........................................................................................................
  return @render =>
    @DOCTYPE 5
    @META charset: 'utf-8'
    # @META 'http-equiv': "Content-Security-Policy", content: "default-src 'self'"
    # @META 'http-equiv': "Content-Security-Policy", content: "script-src 'unsafe-inline'"
    @TITLE '明快打字机'
    # @LINK rel: 'shortcut icon', href: './favicon.icon'
    ### ------------------------------------------------------------------------------------------------ ###
    ### The Tomkel-Harders device to make sure jQuery and other libraries are correctly                  ###
    ### loaded and made available even in Electron; see                                                  ###
    ###   https://github.com/electron/electron/issues/254#issuecomment-183483641                         ###
    ###   https://stackoverflow.com/a/37480521/7568091                                                   ###
    ### -------------------------- THIS LINE MUST COME BEFORE ANY IMPORTS ------------------------------ ###
    @SCRIPT "if (typeof module === 'object') {window.module = module; module = undefined;}"
    ### ------------------------------------------------------------------------------------------------ ###
    @JS     '../public/jquery-3.3.1.js'
    @CSS    '../public/reset.css'
    @CSS    './styles-01.css'
    ### ------------------------------------------------------------------------------------------------ ###
    ### CodeMirror                                                                                       ###
    @CSS    '../public/codemirror-5.39.0/lib/codemirror.css'
    @CSS    '../public/codemirror-5.39.0/addon/fold/foldgutter.css'
    @CSS    '../public/codemirror-5.39.0/addon/dialog/dialog.css'
    @CSS    '../public/codemirror-5.39.0/theme/monokai.css'
    @JS     '../public/codemirror-5.39.0/lib/codemirror.js'
    @JS     '../public/codemirror-5.39.0/mode/javascript/javascript.js'
    @JS     '../public/codemirror-5.39.0/mode/coffeescript/coffeescript.js'
    @JS     '../public/codemirror-5.39.0/addon/search/searchcursor.js'
    @JS     '../public/codemirror-5.39.0/addon/search/search.js'
    @JS     '../public/codemirror-5.39.0/addon/dialog/dialog.js'
    @JS     '../public/codemirror-5.39.0/addon/edit/matchbrackets.js'
    @JS     '../public/codemirror-5.39.0/addon/edit/closebrackets.js'
    @JS     '../public/codemirror-5.39.0/addon/comment/comment.js'
    @JS     '../public/codemirror-5.39.0/addon/wrap/hardwrap.js'
    @JS     '../public/codemirror-5.39.0/addon/fold/foldcode.js'
    @JS     '../public/codemirror-5.39.0/addon/fold/brace-fold.js'
    @JS     '../public/codemirror-5.39.0/keymap/sublime.js'
    ### -------------------------- THIS LINE MUST COME AFTER ANY IMPORTS ------------------------------- ###
    @CSS    '../public/styles-99.css'
    @SCRIPT "if (window.module) module = window.module;"
    ### ------------------------------------------------------------------------------------------------ ###
    #=======================================================================================================
    @FULLHEIGHTFULLWIDTH =>
      @OUTERGRID =>
        @TOPBAR =>
          ### TAINT multiple wrapping needed? ###
          @CONTENT =>
            @TEXTAREA '#codemirror'
        @MIDBAR =>
          @SHADE '.background'
          @SCROLLER =>
            @TABLE '#candidates', =>
              @TBODY =>
                @TR =>
                  @TD '.value', "MingKwai"
                  @TD '.glyph', "明快打字机"
                  @TD '.value', "TypeWriter"
          @SHADE '.foreground'
        @LBBAR => 'L'
        @BOTTOMBAR =>
          @DIV '#text-input.inbox', contenteditable: 'true'
        @RBBAR => 'R'
    #=======================================================================================================
    @JS     './window.js'


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@font_test = ( app, md, settings, handler ) ->
  n           = 10
  triplets    = [
    [  0x0061,  0x007a,    'u-latn',        ]
    [  0x2e80,  0x2eff,    'u-cjk-rad2',    ]
    [  0x2f00,  0x2fdf,    'u-cjk-rad1',    ]
    [  0x3000,  0x303f,    'u-cjk-sym',     ]
    [  0x31c0,  0x31ef,    'u-cjk-strk',    ]
    [  0x3200,  0x32ff,    'u-cjk-enclett', ]
    [  0x3300,  0x33ff,    'u-cjk-cmp',     ]
    [  0x3400,  0x4dbf,    'u-cjk-xa',      ]
    [  0x4e00,  0x9fff,    'u-cjk',         ]
    [  0xe000,  0xf8ff,    'jzr',           ]
    [  0xf900,  0xfaff,    'u-cjk-cmpi1',   ]
    [  0xfe30,  0xfe4f,    'u-cjk-cmpf',    ]
    [ 0x20000, 0x2b81f,    'u-cjk-xb',      ]
    [ 0x2a700, 0x2b73f,    'u-cjk-xc',      ]
    [ 0x2b740, 0x2b81f,    'u-cjk-xd',      ]
    [ 0x2f800, 0x2fa1f,    'u-cjk-cmpi2',   ]
    ]
  #.........................................................................................................
  return render =>
    DOCTYPE 5
    HTML =>
      HEAD =>
        META charset: 'utf-8'
        # META name: 'viewport', content: 'width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;'
        TITLE 'mingkwai'
        # TITLE '明快打字机'
        LINK rel: 'shortcut icon', href: './favicon.icon'
        CSS './html5doctor-css-reset.css'
        # CSS './fonts/webfontkit-20150311-073132/stylesheet.css'
        JS  './jquery-2.1.3.js'
        CSS './jquery-ui-1.11.3.custom/jquery-ui.css'
        JS  './jquery-ui-1.11.3.custom/jquery-ui.js'
        JS  './jquery.event.drag-2.2/jquery.event.drag-2.2.js'
        JS  './outerHTML-2.1.0.js'
        JS  './blaidddrwg.js'
        # JS  './convertPointFromPageToNode.js'
        JS  './jquery-transit.js'
        JS  './browser.js'
        JS  './process-xcss-rules.js'
        CSS './materialize/css/materialize.css'
        JS  './materialize/js/materialize.min.js'
        CSS './mkts-main.rework.css'
      #=====================================================================================================
      BODY style: "transform:scale(2);transform-origin:top left;", =>
        H1 => """Ligatures"""
        P =>
          TEXT """Standard Ligatures* (feature liga): fluffy, shy, official; """
          EM """gg, nagy, gjuha, Qyteti."""
        #...................................................................................................
        H1 => """Unicode Ranges"""
        DIV =>
          for cids in [ [ 0x2a6d6 - 9 .. 0x2a6d6 ], [ 0x2a700 .. 0x2a70a ], ]
            for cid in cids
              TEXT CHR.as_uchr cid
        for [ cid, _, rsg, ] in triplets
          P =>
            # SPAN style: "font-family:'cjk','lastresort';", =>
            SPAN =>
              for i in [ 0 ... n ]
                SPAN style: "display:inline-block;", => CHR.as_uchr cid + i
            SPAN =>
              TEXT "(#{rsg})"
        #...................................................................................................
        H1 => """Other Stuff"""
        P style: "font-family:'spincycle-eot','lastresort';", =>
          SPAN => "一丁"
          SPAN => "abcdef (spincycle-eot)"
        P style: "font-family:'spincycle-embedded-opentype','lastresort';", =>
          SPAN => "一丁"
          SPAN => "abcdef (spincycle-embedded-opentype)"
        P style: "font-family:'spincycle-woff2','lastresort';", =>
          SPAN => "一丁"
          SPAN => "abcdef (spincycle-woff2)"
        P style: "font-family:'spincycle-woff','lastresort';", =>
          SPAN => "一丁"
          SPAN => "abcdef (spincycle-woff)"
        P style: "font-family:'spincycle-truetype','lastresort';", =>
          SPAN => "一丁"
          SPAN => "abcdef (spincycle-truetype)"
        P style: "font-family:'spincycle-svg','lastresort';", =>
          SPAN => "一丁"
          SPAN => "abcdef (spincycle-svg)"
        P style: "font-family:'lastresort';", =>
          SPAN => "一丁"
          SPAN => "abcdef (lastresort)"




#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@test_page = ->
  #.........................................................................................................
  return render =>
    DOCTYPE 5
    HTML =>
      HEAD =>
        META charset: 'utf-8'
        JS  './jquery-2.1.3.js'
        JS  './outerHTML-2.1.0.js'
        # JS  './blaidddrwg.js'
        JS  './browser.js'
        STYLE '', """
            html, body {
              margin:                 0;
              padding:                0;
            }
            .gauge {
              position:               absolute;
              outline:                1px solid red;
            }
          """
        #===================================================================================================
        COFFEESCRIPT ->
          ( $ 'document' ).ready ->
            log                   = console.log.bind console
            # #...............................................................................................
            # gauges                = $ '.gauge'
            # for gauge_idx in [ 0 ... gauges.length ]
            #   gauge               = gauges.eq gauge_idx
            #   height_npx          = parseInt ( gauge.css 'height' ), 10
            #   height_rpx_a        = gauge.height()
            #   height_rpx_b        = gauge[ 0 ].getBoundingClientRect()[ 'height' ]
            #   log gauge_idx + 1, height_npx, height_rpx_a, height_rpx_b
            #...............................................................................................
            gauge         = $ "<div id='meter-gauge' style='position:absolute;'></div>"
            ( $ 'body' ).append gauge
            for d_npx in [ 1 .. 1000 ]
              gauge.css 'height', "#{d_npx}px"
              d_rpx = gauge[ 0 ].getBoundingClientRect()[ 'height' ]
              log d_npx, d_rpx

      #=====================================================================================================
      BODY =>

#-----------------------------------------------------------------------------------------------------------
@splash_window = ->
  #.........................................................................................................
  return render =>
    DOCTYPE 5
    HTML =>
      STYLE '', """
        body, html {
          width:                    100%;
          height:                   100%;
          overflow:                 hidden;
        }
        body {
          width:                    100%;
          height:                   100%;
          background-color:         rgba( 255, 255, 255, 0.0 );
          background-image:         url(./mingkwai-logo-circled.png);
          background-size:          contain;
          background-repeat:        no-repeat;
          background-position:      50%;
        }
        """
          # position:                 fixed;
          # top:                      10mm;
          # left:                     10mm;
      BODY =>

#-----------------------------------------------------------------------------------------------------------
@NORMAL_layout = ->
  #.........................................................................................................
  return render =>
    DOCTYPE 5
    HTML =>
      HEAD =>
        META charset: 'utf-8'
        # META name: 'viewport', content: 'width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;'
        TITLE 'mingkwai (NORMAL_layout)'
        # TITLE '明快打字机'
        LINK rel: 'shortcut icon', href: './favicon.icon'
        CSS './html5doctor-css-reset.css'
        # # CSS './fonts/webfontkit-20150311-073132/stylesheet.css'
        JS  './jquery-2.1.3.js'
        CSS './jquery-ui-1.11.3.custom/jquery-ui.css'
        JS  './jquery-ui-1.11.3.custom/jquery-ui.js'
        JS  './jquery.event.drag-2.2/jquery.event.drag-2.2.js'
        JS  './outerHTML-2.1.0.js'
        JS  '../node_modules/jquery-replace-text/jquery-replace-text.js'
        JS  './blaidddrwg.js'
        # JS  './convertPointFromPageToNode.js'
        JS  './jquery-transit.js'
        JS  './browser.js'
        JS  './process-xcss-rules.js'
        CSS './materialize/css/materialize.css'
        JS  './materialize/js/materialize.min.js'
        CSS './mkts-main.rework.css'
        STYLE """
          body {
            font-size: 4mm;
          }
          """
      #=====================================================================================================
      COFFEESCRIPT =>
        ( $ document ).ready ->
          # #.................................................................................................
          # start_node  = ( $ 'page column p' ).contents().eq 0
          # start_dom   = start_node.get 0
          # # endNode = $('span.second').contents().get(0);
          # range = document.createRange()
          # idx   = 0
          # text  = start_node.text()
          # while idx < text.length
          #   range.setStart start_dom, idx
          #   idx += if ( text.codePointAt idx ) > 0xffff then +2 else +1
          #   range.setEnd start_dom, idx
          #   { bottom, height, left, right, top, width } = range.getBoundingClientRect()
          #   t = range.toString()
          #   console.log ( if t is '\u00ad' then '~' else t ), left, top
          # # range.setEnd   start_node, 0
          # # console.log range.toString()
          # # console.log range.getBoundingClientRect()
          # window.myrange = range
          #.................................................................................................
          # getBoundingClientRect
          window.zoomer = $ 'zoomer'
          # zoomer.draggable()
          scroll_x  = null
          scroll_y  = null
          page_x    = null
          page_y    = null
          dragging  = no
          shifted   = no
          ( $ document ).on 'keyup keydown', ( event ) -> shifted = event.shiftKey; return true
          ### DRAGGING / HAND TOOL SUPPORT ###
          # ( $ document ).on 'dragstart', ( event, data ) ->
          #   console.log 'dragstart', event
          #   scroll_x  = ( $ window ).scrollLeft()
          #   scroll_y  = ( $ window ).scrollTop()
          #   page_x    = event.pageX
          #   page_y    = event.pageY
          #   dragging  = yes
          #   ( $ 'body' ).addClass 'grabbing'
          # # ( $ document ).on 'drag', ( event, data ) ->
          # #   console.log 'drag', [ data.deltaX, data.deltaY, ]
          # #   ( $ window ).scrollLeft scroll_x - data.deltaX
          # #   ( $ window ).scrollTop  scroll_y - data.deltaY
          # ( $ document ).on 'mousemove', ( event ) ->
          #   return unless dragging
          #   factor = 1 # if shifted then 2 else 1
          #   ( $ window ).scrollLeft ( $ window ).scrollLeft() + ( page_x - event.pageX ) * factor
          #   ( $ window ).scrollTop  ( $ window ).scrollTop()  + ( page_y - event.pageY ) * factor
          # # ( $ document ).on 'draginit', ( event ) ->
          # #   console.log 'draginit', event
          # ( $ document ).on 'dragend', ( event ) ->
          #   # console.log 'dragend', event
          #   dragging  = no
          #   ( $ 'body' ).removeClass 'grabbing'

          # ( $ document ).on 'drag',        -> console.log 'drag'; return true
          # ( $ document ).on 'touchstart',  -> console.log 'touchstart'; return true
          # ( $ document ).on 'touchmove',   -> console.log 'touchmove'; return true
          # ( $ document ).on 'touchend',    -> console.log 'touchend'; return true
          # ( $ document ).on 'touchcancel', -> console.log 'touchcancel'; return true
          # ( $ document ).on 'scrollstart', -> console.log 'scrollstart'; return true
          # ( $ document ).on 'scrollstop',  -> console.log 'scrollstop'; return true
          # ( $ document ).on 'swipe',       -> console.log 'swipe'; return true
          # ( $ document ).on 'swipeleft',   -> console.log 'swipeleft'; return true
          # ( $ document ).on 'swiperight',  -> console.log 'swiperight'; return true
          # ( $ document ).on 'tap',         -> console.log 'tap'; return true
          # ( $ document ).on 'taphold',     -> console.log 'taphold'; return true
          # ( $ document ).on 'mousedown',   -> console.log 'mousedown'; return true
          # ( $ document ).on 'mouseup',     -> console.log 'mouseup'; return true
          # ( $ document ).on 'mousemove',   -> console.log 'mousemove'; return true
        # ( $ document ).on 'mousemove', ( event ) ->
        #   app                 = window[ 'app' ]
        #   [ page_x, page_y, ] = [ event.pageX, event.pageY, ]
        #   zmr                 = window.convertPointFromPageToNode ( app[ 'zoomer' ].get 0 ), page_x, page_y
        #   console.log '©YC6EG', [ page_x, page_y, ], zmr
        #   window[ 'app' ][ 'mouse-position' ] = [ page_x, page_y, ]
        #   ( $ '#tg' ).css 'left', "#{zmr[ 'x' ]}px"
        #   ( $ '#tg' ).css 'top',  "#{zmr[ 'y' ]}px"
        # ( $ document ).on 'mousemove', ( event ) ->
        #   # console.log '©YC6EG', [ event.pageX, event.pageY, ]
        #   window[ 'app' ][ 'mouse-position' ] = [ event.pageX, event.pageY, ]
      #=====================================================================================================
      BODY =>
        # A style: "display:block;position:absolute;top:0;z-index:1000;", href: './font-test.html', => "font-test"
        #...............................................................................................
        DIV '#mkts-top'
        ARTBOARD '.galley', =>
          ZOOMER =>
            GALLEY =>
              OVERLAY "Galley"
              CHASE =>
                TOPMARGIN =>
                HBOX =>
                  LEFTMARGIN =>
                  COLUMN =>
                  VGAP =>
                  COLUMN =>
                  VGAP =>
                  COLUMN =>
                  RIGHTMARGIN =>
                BOTTOMMARGIN =>
        ARTBOARD '.pages', =>
          ZOOMER =>
            for page_nr in [ 1 .. 5 ]
              PAGE =>
                OVERLAY page_nr
                RULER '.horizontal'
                RULER '.vertical'
                # CHASEWRAP =>
                CHASE =>
                  TOPMARGIN =>
                  HBOX =>
                    LEFTMARGIN =>
                    COLUMN =>
                    VGAP =>
                    COLUMN =>
                    VGAP =>
                    COLUMN =>
                    RIGHTMARGIN =>
                  BOTTOMMARGIN =>

        HRIBBON '.draggable', style: 'height:20mm;', =>
          I '.small.mkts-tool-hand',            action: 'tool-mode-hand'
          I '.small.mdi-editor-insert-chart',   action: 'editor-insert-chart'
          I '.small.mdi-action-3d-rotation',    action: 'action-3d-rotation'
          I '.small.mdi-action-assignment',     action: 'action-assignment'
          I '.small.mdi-image-blur-on',         action: 'image-blur-on'
          I '.small.mdi-action-print',          action: 'action-print'
          I '.small.mdi-action-cached',         action: 'action-cached'
          I '.small.mdi-content-content-cut',   action: 'content-content-cut'
          I '.small.mdi-content-content-copy',  action: 'content-content-copy'
        DIV '#mkts-bottom'



### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###

#-----------------------------------------------------------------------------------------------------------
### just for testing of CSS @font-face, unicode-range ###
@FONTTEST_layout = ->
  #.........................................................................................................
  return render =>
    DOCTYPE 5
    HTML =>
      HEAD =>
        META charset: 'utf-8'
        TITLE 'mingkwai'
        LINK rel: 'shortcut icon', href: './favicon.icon'
        CSS './html5doctor-css-reset.css'
        # # CSS './fonts/webfontkit-20150311-073132/stylesheet.css'
        JS  './jquery-2.1.3.js'
        CSS './jquery-ui-1.11.3.custom/jquery-ui.css'
        JS  './jquery-ui-1.11.3.custom/jquery-ui.js'
        JS  './jquery.event.drag-2.2/jquery.event.drag-2.2.js'
        JS  './outerHTML-2.1.0.js'
        JS  './blaidddrwg.js'
        # JS  './convertPointFromPageToNode.js'
        JS  './jquery-transit.js'
        JS  './browser.js'
        # JS  './process-xcss-rules.js'
        CSS './materialize/css/materialize.css'
        JS  './materialize/js/materialize.min.js'
        CSS './mkts-main.rework.css'
        STYLE """
          @font-face {
            font-family:    'ampersand';
            src:            local('Schwabacher');
            unicode-range:  U+0026;
          }

          @font-face {
            font-family:    'cjk';
            src:            local('Sun-ExtA');
            unicode-range:  U+4e00-9fff;
          }

          @font-face {
            font-family:    'cjk';
            src:            local('sunflower-u-cjk-xb');
            unicode-range:  U+20000-2b81f;
          }

          @font-face {
            font-family:    'cjk';
            src:            local('jizura3b');
            unicode-range:  U+e000-f8ff;
          }

          @font-face {
            font-family:    'ancientsymbols';
            src:            local('Geneva');
            unicode-range:  U+10190-1019B;
          }

          body, html {
            font-family:    'ampersand', 'cjk', 'ancientsymbols', 'Source Code Pro';
          }


          """
        # html {
        #   text-rendering:  geometricPrecision;
        #   }
      # -webkit-font-feature-settings:  "liga" 1, "dlig" 1;
      # // text-rendering:                 optimizeLegibility
      # // font-variant-ligatures:         common-ligatures
      # // font-kerning:                   normal
      #=====================================================================================================
      BODY =>
        RAW """
          <div>&amp;</div>
          <div>𐆓</div>
          <div>一丁丂七丄丅丆万丈三 u-cjk</div>
          <div>𠀀𠀁𠀂𠀃𠀄𠀅𠀆𠀇𠀈𠀉 u-cjk-xb</div>
          <div> jzr</div>
          """

### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###

#-----------------------------------------------------------------------------------------------------------
### for testing of possible rendering bug related to CSS `display: flex; height: ...;` ###
@FLEXHEIGHTTEST_layout = ->
  #.........................................................................................................
  return render =>
    DOCTYPE 5
    HTML =>
      HEAD =>
        META charset: 'utf-8'
        TITLE 'mingkwai'
        JS  './jquery-2.1.3.js'
        JS  './blaidddrwg.js'
        JS  './browser.js'
        STYLUS """

          html
            font-size:        3mm

          chase
          column
            outline:                1px dotted red
            outline-offset:         -1px

          chase
            position:               relative
            left:                   4.5mm
            top:                    8mm
            // width:                  201mm
            // /* ### TAINT ### */
            height:                 278.85mm
            display:                flex
            flex-direction:         column
            float:                  left

          column
            display:                block
            flex-shrink:            1
            flex-grow:              1

                    """
      #=====================================================================================================
      BODY =>
        CHASE =>
          COLUMN =>
            for idx in [ 0 ... 90 ]
              DIV "#{idx}"

      # DIV '.chase', =>
      #   DIV '.column', =>
      #     for idx in [ 0 ... 90 ]
      #       DIV "#{idx}"


#-----------------------------------------------------------------------------------------------------------
### rendering with float instead of flex ###
@FLOAT_layout = ->
  #.........................................................................................................
  return render =>
    DOCTYPE 5
    HTML =>
      HEAD =>
        META charset: 'utf-8'
        TITLE 'mingkwai'
        JS  './jquery-2.1.3.js'
        JS  './blaidddrwg.js'
        JS  './browser.js'
        STYLUS """


          /* ------------------------------------------------------------------------------------------------------ */
          /* Experimentally detected that `$paper-height = 297mm - 0.13mm` is not enough but
            `297mm - 0.15mm` is enough to avoid intervening blank pages in the PDF. */
          $paper-width                = 210mm
          $paper-height               = 297mm - 0.15mm
          // $paper-width                = 210mm
          // $paper-height               = 297mm
          /* ...................................................................................................... */
          // 'gutters' in typographic terms (non-printable areas) become 'paddings' in CSS:
          $gutter-left                = 4.5mm
          $gutter-right               = $gutter-left
          $gutter-top                 = 8mm
          $gutter-bottom              = 10mm
          /* ...................................................................................................... */
          // 'margins' in typographic terms (areas outside the main content) become 'paddings' in CSS:
          $margin-left                = 15mm
          $margin-right               = $margin-left
          $margin-top                 = 11mm
          $margin-bottom              = 5mm
          /* ...................................................................................................... */
          $gap-vertical-width         = 5mm
          /* ...................................................................................................... */
          // the chase represents the printable area; inside, flanked by the margins, is the main content area:
          $chase-width                = $paper-width  - $gutter-left  - $gutter-right
          $chase-height               = $paper-height - $gutter-top   - $gutter-bottom
          /* ...................................................................................................... */
          $galley-width               = $paper-width
          /* ...................................................................................................... */
          $epsilon                    = 1mm


          /* ------------------------------------------------------------------------------------------------------ */
          paper
          page
           width:                   $paper-width
           height:                  $paper-height
           display:                 block

          html
            font-size:              4mm

          overlay
            display:                block
            position:               absolute

          margin
            display:                block

          margin.left
          margin.right
            float:                  left
            height:                 100%

          margin.left
            min-width:              $margin-left
            max-width:              $margin-left

          margin.right
            min-width:              $margin-right
            max-width:              $margin-right

          margin.top
          margin.bottom
            width:                  100%

          margin.top
            min-height:             $margin-top
            max-height:             $margin-top

          margin.bottom
            min-height:             $margin-bottom
            max-height:             $margin-bottom

          chase
          column
          box
          margin
          gap
          page
            outline:                1px dotted red
            outline-offset:         -1px

          chase
            position:               relative
            left:                   $gutter-left
            top:                    $gutter-top
            width:                  $chase-width
            height:                 $chase-height
            display:                block

          box
            display:                block
            float:                  left
            width:                  $chase-width - $margin-left - $margin-right - $epsilon
            height:                 10mm
            background-color: #ddd

          gap
            display:                block
            width:                  $gap-vertical-width
            float:                  left
            height:                 100%

          column
            display:                block
            height:                 100%
            float:                  left

          .columns-3 column
            width:                  ( ( $chase-width - 2 * $gap-vertical-width ) / 3 )
                    """
      #=====================================================================================================
      BODY =>
        ARTBOARD '.pages', =>
          ZOOMER =>
            # for page_nr in [ 1 .. 5 ]
            PAGE =>
              # OVERLAY page_nr
              CHASE =>
                MARGIN '.top', =>
                MARGIN '.left', =>
                BOX '.horizontal.columns-3', =>
                  COLUMN =>
                    # if page_nr is 1
                      # for idx in [ 0 ... 70 ]
                      #   DIV '', "#{idx}"
                  # GAP '.vertical', =>
                  # COLUMN =>
                  # GAP '.vertical', =>
                  # COLUMN =>
                MARGIN '.right', =>
                MARGIN '.bottom', =>

#-----------------------------------------------------------------------------------------------------------
### rendering with float instead of flex ###
@TABLE_layout = ->
  #.........................................................................................................
  return render =>
    DOCTYPE 5
    HTML =>
      HEAD =>
        META charset: 'utf-8'
        TITLE 'mingkwai'
        JS  './jquery-2.1.3.js'
        JS  './blaidddrwg.js'
        JS  './browser.js'
        STYLUS """


          /* ------------------------------------------------------------------------------------------------------ */
          /* Experimentally detected that `$paper-height = 297mm - 0.13mm` is not enough but
            `297mm - 0.15mm` is enough to avoid intervening blank pages in the PDF. */
          $paper-width                = 210mm
          $paper-height               = 297mm - 0.15mm
          // $paper-width                = 210mm
          // $paper-height               = 297mm
          /* ...................................................................................................... */
          // 'gutters' in typographic terms (non-printable areas) become 'paddings' in CSS:
          $gutter-left                = 4.5mm
          $gutter-right               = $gutter-left
          $gutter-top                 = 8mm
          $gutter-bottom              = 10mm
          /* ...................................................................................................... */
          // 'margins' in typographic terms (areas outside the main content) become 'paddings' in CSS:
          $margin-left                = 15mm
          $margin-right               = $margin-left
          $margin-top                 = 11mm
          $margin-bottom              = 5mm
          /* ...................................................................................................... */
          $gap-vertical-width         = 5mm
          /* ...................................................................................................... */
          // the chase represents the printable area; inside, flanked by the margins, is the main content area:
          $chase-width                = $paper-width  - $gutter-left  - $gutter-right
          $chase-height               = $paper-height - $gutter-top   - $gutter-bottom
          /* ...................................................................................................... */
          $galley-width               = $paper-width


          /* ------------------------------------------------------------------------------------------------------ */
          paper
          page
           width:                   $paper-width
           height:                  $paper-height
           display:                 block

          html
            font-size:              4mm

          .chase
          column
          box
          margin
          gap
          page
            outline:                1px dotted red
            outline-offset:         -1px

          .chase
            border-collapse:        collapse
            margin:                 0
            padding:                0
            position:               relative
            left:                   $gutter-left
            top:                    $gutter-top
            width:                  $chase-width
            height:                 $chase-height

          .margin
            margin:                 0
            padding:                0

          .margin.margin-left
            height:                 $chase-height
            width:                  $margin-left

          .margin.margin-right
            height:                 $chase-height
            width:                  $margin-right

          .margin.margin-top
          .margin.margin-bottom
            width:                  $galley-width - $margin-left - $margin-right

          .margin.margin-top
            height:                 $margin-top

          .margin.margin-bottom
            height:                 $margin-bottom

          .gap
            margin:                 0
            padding:                0
            width:                  $gap-vertical-width
            min-width:              $gap-vertical-width
            max-width:              $gap-vertical-width

          .columnbox
          .column
            border-collapse:        collapse
            margin:                 0
            padding:                0
            height:                 100%

          .columnbox
            width:                  100%

          .column.columns-3
            width:                  ( ( $chase-width - 2 * $gap-vertical-width ) / 3 )
            min-width:              ( ( $chase-width - 2 * $gap-vertical-width ) / 3 )
            max-width:              ( ( $chase-width - 2 * $gap-vertical-width ) / 3 )

          td
            outline: 1px solid green
          """
      #=====================================================================================================
      CHASE = ( p... ) =>
        TABLE '.chase', =>
          TR =>
            TD '.margin.margin-left', rowspan: 3
            TD '.margin.margin-top'
            TD '.margin.margin-right', rowspan: 3
          TR =>
            TD '.main', p...
          TR =>
            TD '.margin.margin-bottom'
      #-----------------------------------------------------------------------------------------------------
      COLUMNBOX = ( column_count ) =>
        TABLE '.columnbox', =>
          TR =>
            for column_nr in [ 1 .. column_count ]
              unless column_nr is 1
                TD '.gap.vertical'
              TD ".column.columns-#{column_count}", =>
                if column_nr is 1
                  TEXT """xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
                    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
                    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
                    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
                    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
                    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
                    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
                    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
                    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
                    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
                    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
                    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
                    """
      #=====================================================================================================
      BODY =>
        ARTBOARD '.pages', =>
          ZOOMER =>
            PAGE =>
              CHASE {}, =>
                COLUMNBOX 3, =>
                #   MARGIN '.left', =>
                #   COLUMN =>
                #     for idx in [ 0 ... 70 ]
                #       DIV '', "#{idx}"
                #   GAP '.vertical', =>
                #   COLUMN =>
                #   GAP '.vertical', =>
                #   COLUMN =>
                #   MARGIN '.right', =>
                # MARGIN '.bottom', =>


#-----------------------------------------------------------------------------------------------------------
### rendering with float instead of flex ###
@INLINEBLOCK_layout = ->
  #.........................................................................................................
  return render =>
    DOCTYPE 5
    HTML =>
      HEAD =>
        META charset: 'utf-8'
        TITLE 'mingkwai'
        JS  './jquery-2.1.3.js'
        JS  './blaidddrwg.js'
        JS  './browser.js'
        STYLUS """


          /* ------------------------------------------------------------------------------------------------------ */
          /* Experimentally detected that `$paper-height = 297mm - 0.13mm` is not enough but
            `297mm - 0.15mm` is enough to avoid intervening blank pages in the PDF. */
          $paper-width                = 210mm
          $paper-height               = 297mm - 0.15mm
          // $paper-width                = 210mm
          // $paper-height               = 297mm
          /* ...................................................................................................... */
          // 'gutters' in typographic terms (non-printable areas) become 'paddings' in CSS:
          $gutter-left                = 4.5mm
          $gutter-right               = $gutter-left
          $gutter-top                 = 8mm
          $gutter-bottom              = 10mm
          /* ...................................................................................................... */
          // 'margins' in typographic terms (areas outside the main content) become 'paddings' in CSS:
          $margin-left                = 15mm
          $margin-right               = $margin-left
          $margin-top                 = 11mm
          $margin-bottom              = 5mm
          /* ...................................................................................................... */
          $gap-vertical-width         = 5mm
          /* ...................................................................................................... */
          // the chase represents the printable area; inside, flanked by the margins, is the main content area:
          $chase-width                = $paper-width  - $gutter-left  - $gutter-right
          $chase-height               = $paper-height - $gutter-top   - $gutter-bottom
          /* ...................................................................................................... */
          $galley-width               = $paper-width
          /* ...................................................................................................... */
          $epsilon                    = 1mm


          /* ------------------------------------------------------------------------------------------------------ */
          paper
          page
           width:                   $paper-width
           height:                  $paper-height
           display:                 block

          html
            font-size:              4mm

          overlay
            display:                block
            position:               absolute

          margin
            background-color:       #e994ae

          margin.left
          margin.right
            display:                inline-block
            height:                 100%

          margin.left
            min-width:              $margin-left
            max-width:              $margin-left

          margin.right
            min-width:              $margin-right
            max-width:              $margin-right

          margin.top
          margin.bottom
            display:                block
            width:                  $chase-width

          margin.top
            min-height:             $margin-top
            max-height:             $margin-top

          margin.bottom
            min-height:             $margin-bottom
            max-height:             $margin-bottom

          chase
          column
          box
          margin
          gap
          page
            outline:                1px dotted red
            outline-offset:         -1px

          chase
            position:               relative
            left:                   $gutter-left
            top:                    $gutter-top
            width:                  $chase-width
            height:                 $chase-height
            display:                block

          row
            display:                inline-block
            width:                  $chase-width
            white-space:            nowrap
            // !!!!!
            height:                 10mm

          gap
            display:                inline-block
            width:                  $gap-vertical-width
            height:                 100%
            background-color: #ddd

          column
            display:                inline-block
            white-space:            normal
            height:                 100%

          .columns-3 column
            width:                  ( ( $chase-width - 2 * $gap-vertical-width - $margin-left - $margin-right ) / 3 )
                    """
      #=====================================================================================================
      BODY =>
        ARTBOARD '.pages', =>
          ZOOMER =>
            # for page_nr in [ 1 .. 5 ]
            PAGE =>
              # OVERLAY page_nr
              CHASE =>
                MARGIN '.top', =>
                ROW '.horizontal.columns-3', =>
                  MARGIN '.left', =>
                  COLUMN =>
                    # if page_nr is 1
                      # for idx in [ 0 ... 70 ]
                      #   DIV '', "#{idx}"
                  GAP '.vertical', =>
                  COLUMN =>
                  GAP '.vertical', =>
                  COLUMN =>
                  MARGIN '.right', =>
                MARGIN '.bottom', =>

# #-----------------------------------------------------------------------------------------------------------
# @layout = @FONTTEST_layout
# @layout = @FLEXHEIGHTTEST_layout
# @layout = @TABLE_layout
# @layout = @FLOAT_layout
# @layout = @INLINEBLOCK_layout
# @layout = @NORMAL_layout



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
# _STYLUS                   = require 'stylus'
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
# @STYLUS               = ( source ) -> @STYLE {}, _STYLUS.render source


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@get_row_html = ( key_value_pairs ) ->
  return @render =>
    @TR '.candidate', =>
      for [ key, value, ] in key_value_pairs
        @TD ".#{key}", value.toString()


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
    @JS     './jquery-3.3.1.js'
    @CSS    './reset.css'
    @CSS    './styles-01.css'
    ### ------------------------------------------------------------------------------------------------ ###
    ### CodeMirror                                                                                       ###
    @CSS    './codemirror-5.39.0/lib/codemirror.css'
    @CSS    './codemirror-5.39.0/addon/fold/foldgutter.css'
    @CSS    './codemirror-5.39.0/addon/dialog/dialog.css'
    @CSS    './codemirror-5.39.0/theme/monokai.css'
    @JS     './codemirror-5.39.0/lib/codemirror.js'
    @JS     './codemirror-5.39.0/mode/javascript/javascript.js'
    @JS     './codemirror-5.39.0/mode/coffeescript/coffeescript.js'
    @JS     './codemirror-5.39.0/addon/search/searchcursor.js'
    @JS     './codemirror-5.39.0/addon/search/search.js'
    @JS     './codemirror-5.39.0/addon/dialog/dialog.js'
    @JS     './codemirror-5.39.0/addon/edit/matchbrackets.js'
    @JS     './codemirror-5.39.0/addon/edit/closebrackets.js'
    @JS     './codemirror-5.39.0/addon/comment/comment.js'
    @JS     './codemirror-5.39.0/addon/wrap/hardwrap.js'
    @JS     './codemirror-5.39.0/addon/fold/foldcode.js'
    @JS     './codemirror-5.39.0/addon/fold/brace-fold.js'
    @JS     './codemirror-5.39.0/keymap/sublime.js'
    ### -------------------------- THIS LINE MUST COME AFTER ANY IMPORTS ------------------------------- ###
    @CSS    './styles-99.css'
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
    @JS     './ops.js'
    return null

#-----------------------------------------------------------------------------------------------------------
@minimal = ->
  #.........................................................................................................
  return @render =>
    @DOCTYPE 5
    @META charset: 'utf-8'
    # @META 'http-equiv': "Content-Security-Policy", content: "default-src 'self'"
    # @META 'http-equiv': "Content-Security-Policy", content: "script-src 'unsafe-inline'"
    @JS     './jquery-3.3.1.js'
    @CSS    './reset.css'
    @CSS    './styles-01.css'
    @CSS    './styles-99.css'
    @TITLE '明快打字机'
    @DIV => "helo world"
    @JS     './ops.js'
    return null


# #-----------------------------------------------------------------------------------------------------------
# @layout = @FLOAT_layout




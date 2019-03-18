

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/APP'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
PATH                      = require 'path'
FS                        = require 'fs'
URL                       = require 'url'
inspect                   = ( require 'util' ).inspect
log                       = ( P... ) -> process.stdout.write ( rpr P ) + '\n'
# { app, globalShortcut, }  = require 'electron'
window                    = null
# log Object.keys require 'electron'
{ app, BrowserWindow }    = require 'electron'
TEMPLATES                 = require './templates'
PD                        = require 'pipedreams'
XE                        = require './xemitter'
IF                        = require 'interflug'
{ jr, }                   = CND
#...........................................................................................................
kb_listener_is_ready      = false
app_is_ready              = false
page_html_path            = PATH.resolve PATH.join __dirname, '../public/main.html'


#-----------------------------------------------------------------------------------------------------------
@write_page_source = ->
  ### Write out the HTML of the main page; this is strictly only needed when template has changed, which we
  maybe should detect in the future: ###
  page_source = TEMPLATES.main_2()
  # page_source = TEMPLATES.minimal()
  FS.writeFileSync page_html_path, page_source
  help "updated page source written to #{rpr PATH.relative process.cwd(), page_html_path}"

#-----------------------------------------------------------------------------------------------------------
@list_versions = ->
  ### Log the most important versions to the console: ###
  keys = [
    'v8'
    'node'
    'electron'
    'chrome'
    'icu'
    'unicode' ]
  whisper ( key.padEnd 20 ), process.versions[ key ] for key in keys
  whisper ( '明快打字机'.padEnd 15 ), ( require '../package.json' ).version
  return null

#-----------------------------------------------------------------------------------------------------------
@listen_to_keyboard = ->
  on_ready  = =>
    urge 'µ88782', "keybvoard event source ready"
    kb_listener_is_ready = true
    @launch() if app_is_ready and kb_listener_is_ready
  #.........................................................................................................
  pipeline  = []
  source    = IF.K.new_keyboard_event_source { on_ready, }
  pipeline.push source
  pipeline.push PD.$watch ( d ) -> XE.emit d
  pipeline.push PD.$drain()
  PD.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@on_app_ready = ->
  app_is_ready = true
  @launch() if app_is_ready and kb_listener_is_ready

#-----------------------------------------------------------------------------------------------------------
@launch = ->
  debug 'µ11233', 'launch'
  ### TAINT workaround: obtain configuration from a throw-away state instance ###
  state   = require './state'
  S       = state.new()
  window  = new BrowserWindow S.window.electron
  #.........................................................................................................
  window.loadURL URL.format { pathname: page_html_path, protocol: 'file:', slashes: true, }
  #.........................................................................................................
  ### TAINT consider to move all exception handlers to module `exception-handler` ###
  window.on 'unresponsive', ->
    alert "window unresponsive!"
  #.........................................................................................................
  process.on 'uncaughtException',  ( error ) ->
    alert "uncaught exception"
    alert rpr error
    process.exit 1
  #.........................................................................................................
  window.webContents.on 'crashed', ->
    alert "window crashed!"
    window.close()
    return null
  #.........................................................................................................
  window.once 'ready-to-show', ->
    # debug '77565-1', 'ready-to-show'
    window.show()
    window.maximize()                 if S.window.maximize      ? no
    window.webContents.openDevTools() if S.window.show_devtools ? no
    window.webContents.on 'error', ( error ) => warn 'µ76599', error.message
    ### thx to https://stackoverflow.com/a/44012967/7568091 ###
    pid                 = process.pid
    wid                 = await IF.wait_for_window_id_from_pid process.pid
    XE.emit PD.new_event '^window-id', wid
    return null


############################################################################################################
app.once 'ready', @on_app_ready.bind @
@write_page_source()
@list_versions()
@listen_to_keyboard()



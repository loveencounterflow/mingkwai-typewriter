

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
{ app
  BrowserWindow }         = require 'electron'
TEMPLATES                 = require './templates'
{ jr, }                   = CND
page_html_path            = PATH.resolve PATH.join __dirname, '../public/main.html'
#...........................................................................................................
### keep a module-global reference to main window to prevent GC from collecting it as per
https://youtu.be/iVdXOrtdHvA?t=713 ###
#...........................................................................................................
main_window               = null
### module-global configuration and editor state object ###
### OBS this instance of `S` is *not* shared with renderer process and can only be used to read presets ###
S                         = require './settings'
require                   '../lib/exception-handler'
#-----------------------------------------------------------------------------------------------------------
### TAINT investigate how to set these dynamically from the app ###
app.commandLine.appendSwitch 'high-dpi-support',          S.app?.high_dpi_support           ? 1
app.commandLine.appendSwitch 'force-device-scale-factor', S.app?.force_device_scale_factor  ? 1.25
app.commandLine.appendSwitch 'force-color-profile',       S.app?.force_color_profile        ? 'sRGB'
#-----------------------------------------------------------------------------------------------------------
### Enable live reloading in developement, see https://github.com/sindresorhus/electron-reloader: ###
do ->
  error = null
  try ( ( require 'electron-reloader' ) module ) catch error then null
  urge "µ32221 using electron-reloader" unless error


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
@launch = ->
  debug 'µ11233', 'launch'
  main_window = new BrowserWindow S.window.electron
  main_window.loadURL URL.format { pathname: page_html_path, protocol: 'file:', slashes: true, }
  #.........................................................................................................
  ### TAINT consider to move all exception handlers to module `exception-handler` ###
  main_window.on 'unresponsive', =>
    alert "main_window unresponsive!"
  #.........................................................................................................
  process.on 'uncaughtException',  ( error ) =>
    alert "uncaught exception"
    alert rpr error
    process.exit 1
  #.........................................................................................................
  main_window.webContents.on 'crashed', =>
    alert "main_window crashed!"
    main_window.close()
    return null
  #.........................................................................................................
  main_window.once 'ready-to-show', =>
    # debug '77565-1', 'ready-to-show'
    main_window.show()
    main_window.maximize()                 if S.window.maximize      ? no
    main_window.webContents.openDevTools() if S.window.show_devtools ? no
    main_window.webContents.on 'error', ( error ) => warn 'µ76599', error.message
    # ### thx to https://stackoverflow.com/a/44012967/7568091 ###
    # pid                 = process.pid
    # wid                 = await IF.wait_for_window_id_from_pid process.pid
    return null

#-----------------------------------------------------------------------------------------------------------
@open_homepage = ->
  ( require 'electron' ).shell.openExternal 'https://github.com/loveencounterflow/mingkwai-typewriter'


############################################################################################################
app.once 'ready', @launch.bind @
@write_page_source()
@list_versions()




'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/OPS-MENU'
# debug                     = CND.get_logger 'debug',     badge
# alert                     = CND.get_logger 'alert',     badge
# whisper                   = CND.get_logger 'whisper',   badge
# warn                      = CND.get_logger 'warn',      badge
# help                      = CND.get_logger 'help',      badge
# urge                      = CND.get_logger 'urge',      badge
# info                      = CND.get_logger 'info',      badge
PD                        = require 'pipedreams'

#-----------------------------------------------------------------------------------------------------------
@show_or_hide_menu_bar = ->
  w = @get_window()
  w.setMenuBarVisibility not w.isMenuBarVisible()
  return null

#-----------------------------------------------------------------------------------------------------------
@get_transcriptors_submenu = ->
  R = []
  for t, tsnr in S.transcriptors
    do ( t, tsnr ) =>
      if tsnr < 10 then   label = "&#{tsnr} #{t.display_name}"
      else                label =  "#{tsnr} #{t.display_name}"
      click = => @cm_set_tsrs tsnr
      R.push { label, click, }
  return R

#-----------------------------------------------------------------------------------------------------------
@add_menu = ->
  throw new Error "µ37763 internal error: load transcriptors before adding menu" unless S.transcriptors?
  transcriptors_submenu = @get_transcriptors_submenu()
  template              = []
  @log "µ39883 found #{S.transcriptors.length} entries in S.transcriptors"
  @log "µ39883 transcriptors_submenu: #{rpr transcriptors_submenu}"
  #.........................................................................................................
  template.push {
    label: '&File'
    submenu: [
      { label: '&imagine',  click: ( -> alert 'a message for you' ), }
      { label: '&Quit', role: 'close', accelerator: 'CmdOrCtrl+Q', } ] }
  #.........................................................................................................
  template.push {
    label: '&Edit'
    submenu: [
      { role: 'undo'                }
      { role: 'redo'                }
      { type: 'separator'           }
      { role: 'cut'                 }
      { role: 'copy'                }
      { role: 'paste'               }
      { role: 'pasteandmatchstyle'  }
      { role: 'delete'              }
      { role: 'selectall'           } ] }
  #.........................................................................................................
  template.push {
    label: '&View'
    submenu: [
      { role: 'reload'              }
      { role: 'forcereload'         }
      { role: 'toggledevtools'      }
      { type: 'separator'           }
      { role: 'resetzoom'           }
      { role: 'zoomin'              }
      { role: 'zoomout'             }
      { type: 'separator'           }
      { role: 'togglefullscreen'    } ] }
  #.........................................................................................................
  template.push {
    label:  '&Transcriptors'
    submenu: transcriptors_submenu }
  #.........................................................................................................
  template.push {
    label: '&Help'
    role: 'help',
    submenu: [
      { label: 'Learn More', click: ( => @open_homepage() ), } ] }
  #.........................................................................................................
  { Menu, } = ( require 'electron' ).remote
  menu      = Menu.buildFromTemplate template
  Menu.setApplicationMenu menu


'use strict'


############################################################################################################
# CND                       = require 'cnd'
# rpr                       = CND.rpr
# badge                     = '明快打字机/OPS-MENU'
# debug                     = CND.get_logger 'debug',     badge
# alert                     = CND.get_logger 'alert',     badge
# whisper                   = CND.get_logger 'whisper',   badge
# warn                      = CND.get_logger 'warn',      badge
# help                      = CND.get_logger 'help',      badge
# urge                      = CND.get_logger 'urge',      badge
# info                      = CND.get_logger 'info',      badge

#-----------------------------------------------------------------------------------------------------------
@show_or_hide_menu_bar = ->
  w = @get_window()
  w.setMenuBarVisibility not w.isMenuBarVisible()
  return null

#-----------------------------------------------------------------------------------------------------------
@add_menu = ->
  template = []
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
    label: '&Translators'
    submenu: [
      { label: '&1 Ja Kana'         }
      { label: '&2 Ja Kanji'        }
      { label: '&3 zhs Hanzi'       }
      { label: '&4 zht Hanzi'       }
      { label: '&5 el Greek'        }
      { label: '&6 ru Cyrillic'     } ] }
  #.........................................................................................................
  # template.push {
  #   label: '&Window'
  #   role: 'window',
  #   submenu: [
  #     { role: 'minimize'            },
  #     { role: 'close', accelerator: 'CmdOrCtrl+Q',               } ] }
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

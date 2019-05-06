
'use strict'

### TAINTs

* separate:

  * `focus` (a mechanism used by the browser)

  * ?`select`, `choose`? for the action of selecting one particular candidate

  * ??? for what is called `focusframe` now

  these are three different things and should be called different names.

* accordingly, rename `focusframe` and those `*_focus*` methods that refer to it instead of to browser focus

* use module-global `S`: this code will only ever run a single input instance; where it does use modules
  that potentially serve several independent consumers, `S` will not be used as argument anyway

* refactor code into (local) modules

###



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/OPS'
debug                     = CND.get_logger 'debug',     badge
# alert                     = CND.get_logger 'alert',     badge
# whisper                   = CND.get_logger 'whisper',   badge
# warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
# urge                      = CND.get_logger 'urge',      badge
# info                      = CND.get_logger 'info',      badge
# inspect                   = ( require 'util' ).inspect
# # TRAP                      = require 'mousetrap'
# KEYS                      = require '../lib/keys'
# T                         = require '../lib/templates'
PATH                      = require 'path'
FS                        = require 'fs'
#...........................................................................................................
require                   '../lib/exception-handler'
global.S                  = require '../lib/settings' ### global configuration and editor state object ###
global.OPS                = {}
global.XE                 = require '../lib//xemitter'


############################################################################################################
# Assemble On-Page Script from its modules:
path  = PATH.resolve PATH.join __dirname, '../lib/'
for module_name in FS.readdirSync path
  continue unless module_name.endsWith    '.js'
  continue unless module_name.startsWith  'ops-'
  help "µ44744 loading #{module_name}"
  for key, value of require PATH.join '../lib', module_name
    throw new Error "name collision in module #{module_name}: #{rpr key}" if OPS[ key ]?
    OPS[ key ] = value
# debug 'µ37333', ( k for k of OPS )
jQuery OPS.init.bind OPS


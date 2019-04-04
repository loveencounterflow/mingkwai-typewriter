

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/TESTS/main' # /OPS-CM'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
OS                        = require 'os'
test                      = require 'guy-test'
#...........................................................................................................
{ jr
  is_empty }              = CND
defer                     = setImmediate
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
OPSCM                     = require '../ops-cm'

#-----------------------------------------------------------------------------------------------------------
@[ "demo" ] = ( T, done ) ->
  probes_and_matchers = [
    [ [ { line: 1, ch: 1, }, { line: 1, ch: 1, }, ], [ { line: 1, ch: 1 }, { line: 1, ch: 1 } ], ]
    [ [ { line: 2, ch: 1, }, { line: 1, ch: 1, }, ], [ { line: 1, ch: 1 }, { line: 2, ch: 1 } ], ]
    [ [ { line: 1, ch: 1, }, { line: 2, ch: 1, }, ], [ { line: 1, ch: 1 }, { line: 2, ch: 1 } ], ]
    [ [ { line: 1, ch: 5, }, { line: 1, ch: 5, }, ], [ { line: 1, ch: 5 }, { line: 1, ch: 5 } ], ]
    [ [ { line: 1, ch: 5, }, { line: 1, ch: 6, }, ], [ { line: 1, ch: 5 }, { line: 1, ch: 6 } ], ]
    [ [ { line: 1, ch: 4, }, { line: 1, ch: 5, }, ], [ { line: 1, ch: 4 }, { line: 1, ch: 5 } ], ]
    [ [ { line: 2, ch: 5, }, { line: 1, ch: 5, }, ], [ { line: 1, ch: 5 }, { line: 2, ch: 5 } ], ]
    [ [ { line: 2, ch: 5, }, { line: 1, ch: 6, }, ], [ { line: 1, ch: 6 }, { line: 2, ch: 5 } ], ]
    [ [ { line: 2, ch: 4, }, { line: 1, ch: 5, }, ], [ { line: 1, ch: 5 }, { line: 2, ch: 4 } ], ]
    [ [ { line: 2, ch: 4, }, { line: 1, ch: 1, }, ], [ { line: 1, ch: 1 }, { line: 2, ch: 4 } ], ]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      result = OPSCM._cm_order_pos probe...
      # debug jr [ probe, result, null, ]
      resolve result
  #.........................................................................................................
  done()
  return null



############################################################################################################
unless module.parent?
  test @, { timeout: 5000, }
  # test @[ "wye with duplex pair"            ]



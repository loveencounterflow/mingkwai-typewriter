

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
@[ "order positions" ] = ( T, done ) ->
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
    [ [ { line: 3, ch: 0 }, { line: 3, ch: 5 }, ], [ { line: 3, ch: 0 }, { line: 3, ch: 5 } ], ]
    [ [ { line: 3, ch: 5 }, { line: 3, ch: 0 }, ], [ { line: 3, ch: 0 }, { line: 3, ch: 5 } ], ]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      result = OPSCM._cm_order_positions probe
      # debug jr [ probe, result, null, ]
      resolve result
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "fromto from range" ] = ( T, done ) ->
  probes_and_matchers = [
    [{"anchor":{"line":3,"ch":0,"sticky":null},"head":{"line":3,"ch":5,"sticky":null}},{"from":{"line":3,"ch":0},"to":{"line":3,"ch":5}},null]
    [{"anchor":{"line":3,"ch":5,"sticky":null},"head":{"line":3,"ch":0,"sticky":null}},{"from":{"line":3,"ch":0},"to":{"line":3,"ch":5}},null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      result = OPSCM._cm_fromto_from_range probe
      # debug jr [ probe, result, null, ]
      resolve result
  #.........................................................................................................
  done()
  return null



############################################################################################################
unless module.parent?
  test @, { timeout: 5000, }
  # test @[ "wye with duplex pair"            ]



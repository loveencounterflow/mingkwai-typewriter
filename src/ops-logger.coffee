
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/OPS-LOGGER'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
#...........................................................................................................
{ jr, }                   = CND
# { inspect, }              = require 'util'
# xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }

skip_events = new Set [
  '^input'
  '^ignore-delete'
  '^keyboard'
  ]

#-----------------------------------------------------------------------------------------------------------
@log_almost_all_events = ( key, d ) ->
  # whisper 'µ99823', key #, jr d
  return if skip_events.has key
  v       = d.value ? {}
  logger  = jQuery '#logger'
  ( logger.find ':first-child').remove() while logger.children().length > 10
  message = rpr v
  # message = ( k for k         of d.value                ).join ', '
  # message = switch key
  #   when '^kblevel' then  ( k for k, toggle of S.kblevels when toggle ).join ', '
  #   else                  ( k for k         of d.value                ).join ', '
  #.........................................................................................................
  logger.append ( "<div>#{Date.now()}: #{rpr key}: #{message}</div>" )
  console.log 'µ33499', Date.now(), key, d
  # if ( kblevels = d.value?.S?.kblevels )
  #   logger.append ( "<div>#{Date.now()}: kblevels: #{rpr kblevels}</div>" )
  logger.scrollTop logger[ 0 ].scrollHeight
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@log = ( P... ) ->
  ### TAINT code duplication ###
  text    = ( ( if CND.isa_text p then p else rpr p ) for p in P ).join ' '
  logger  = jQuery '#logger'
  ( logger.find ':first-child').remove() while logger.children().length > 10
  ### TAINT should escape text (or accept HTML?) ###
  logger.append ( "<div>#{Date.now()}: #{text}</div>" )
  console.log 'µ33499', Date.now(), text
  logger.scrollTop logger[ 0 ].scrollHeight
  return null

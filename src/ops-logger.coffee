
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
_lognr                    = 0
{ remote, }               = ( require 'electron' )
rprocess                  = remote.process
rprocess.stdout.write 'µ55398' + ( ( k for k of ( require 'electron' ).remote ).join ', ' ) + '\n'
# rprocess.stdout.write CND.orange "µ33389 #{remote.getGlobal().app_t0}\n"
{ assign
  abspath
  format_float }          = require './helpers'
#...........................................................................................................
app_t0                    = ( remote.require './snarf' ).app_t0
t_prv                     = app_t0
get_times                 = ->
  t           = Date.now()
  dt          = t - t_prv
  t_prv       = t
  app_t       = t - app_t0
  app_t       = format_float ( app_t ) / 1000
  dt          = format_float (    dt ) / 1000
  return { app_t, dt, }

#-----------------------------------------------------------------------------------------------------------
skip_events = new Set [
  # '^input'
  '^ignore-delete'
  '^keyboard'
  ]

#-----------------------------------------------------------------------------------------------------------
@log_almost_all_events = ( key, d ) ->
  # whisper 'µ99823', key #, jr d
  return if skip_events.has key
  _lognr         += +1
  lognr           = "#{_lognr}".padStart 5, '_'
  v               = d.value ? {}
  logger          = jQuery '#logger'
  ( logger.find ':first-child').remove() while logger.children().length > 1000
  { app_t, dt, }  = get_times()
  message     = rpr v
  # message = ( k for k         of d.value                ).join ', '
  # message = switch key
  #   when '^kblevel' then  ( k for k, toggle of S.kblevels when toggle ).join ', '
  #   else                  ( k for k         of d.value                ).join ', '
  #.........................................................................................................
  rprocess.stderr.write CND.blue "#{app_t} #{dt} #{lognr}: #{rpr key}: #{message}\n"
  logger.append ( "<div>#{app_t} #{dt} #{lognr}: #{rpr key}: #{message}</div>" )
  console.log lognr, key, d
  logger.scrollTop logger[ 0 ].scrollHeight
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@log = ( P... ) ->
  ### TAINT code duplication ###
  _lognr         += +1
  lognr           = "#{_lognr}".padStart 5, '_'
  text            = ( ( if CND.isa_text p then p else rpr p ) for p in P ).join ' '
  logger          = jQuery '#logger'
  ( logger.find ':first-child').remove() while logger.children().length > 1000
  { app_t, dt, }  = get_times()
  ### TAINT should escape text (or accept HTML?) ###
  # p.stdout.write CND.green "#{lognr}"
  # p.stderr.write CND.red "#{lognr}"
  console.log app_t, lognr, text
  rprocess.stderr.write CND.blue "#{app_t} #{dt} #{lognr}: #{text}\n"
  logger.append ( "<div>#{app_t} #{dt} #{lognr}: #{text}</div>" )
  logger.scrollTop logger[ 0 ].scrollHeight
  return null


############################################################################################################
@log 'logger started'




'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/KANA-INPUT'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
alert                     = CND.get_logger 'alert',     badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
#...........................................................................................................
# parallel                  = require './parallel-promise'
DB                        = require './db'
#...........................................................................................................
# _format                   = require 'pg-format'
# I                         = ( value ) -> _format '%I', value
# L                         = ( value ) -> _format '%L', value
#...........................................................................................................
{ jr, }                   = CND
PD                        = require 'pipedreams'
# { remote, }               = require 'electron'
# XE                        = remote.require './xemitter'
XE                        = require './xemitter'
#...........................................................................................................
TRIODE                    = require 'triode'
kana_keyboard 						= require '../db/kana.keyboard.json'
kana_triode 							= null
buffer 										= []

#-----------------------------------------------------------------------------------------------------------
@load_kana_triode = ->
	kana_triode = TRIODE.new()
	kana_triode[ source ] = target for [ source, target, ] in kana_keyboard
	return null

# #-----------------------------------------------------------------------------------------------------------
# XE.listen_to_all ( key, d ) -> whisper 'µ44532', jr d
urge __filename
#-----------------------------------------------------------------------------------------------------------
XE.contract '^input', ( d ) ->
	urge 'µ55401', jr d
	matches	= kana_triode[ d.value ]
	return null unless matches.length is 1
	return matches[ 0 ][ 1 ]

do ->
	debug 'µ98933', await XE.emit PD.new_event '^input', 'kyo'

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '<keyboard-level', ( d ) ->
	# urge 'µ55402', jr d

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '>keyboard-level', ( d ) ->
	# urge 'µ55403', jr d


############################################################################################################
@load_kana_triode()



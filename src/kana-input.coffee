

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
{ remote, }               = require 'electron'
IF                        = require 'interflug'
XE                        = remote.require './xemitter'
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

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '^keypress', ( d ) ->
	# urge 'µ55401', jr d
	v = d.value
	return unless v.move is 'down'
	#.........................................................................................................
	### TAINT need proper keyboard mapping ###
	if v.name.length is 1
		buffer.push v.name
	#.........................................................................................................
	else if v.name is 'backspace'
		buffer.pop() if buffer.length > 0
	#.........................................................................................................
	probe 	= buffer.join ''
	matches	= kana_triode[ probe ]
	if matches.length is 1
		hit 						= matches[ 0 ][ 1 ]
		backspace_count	= buffer.length
		buffer.length		= 0
		await IF.T.erase_and_insert backspace_count, hit
	# hits 		= ( match[ 1 ] for match in matches ).join ', '
	# debug 'µ87876', probe, '->', rpr hits
	debug 'µ87876', rpr buffer.join ''
	#.........................................................................................................
	return null

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '<keyboard-level', ( d ) ->
	# urge 'µ55402', jr d

#-----------------------------------------------------------------------------------------------------------
XE.listen_to '>keyboard-level', ( d ) ->
	# urge 'µ55403', jr d


############################################################################################################
@load_kana_triode()



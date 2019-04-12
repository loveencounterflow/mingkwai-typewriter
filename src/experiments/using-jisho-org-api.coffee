

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/EXPERIMENTS/USING-JISHO-ORG-API'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
FS                        = require 'fs'
PATH                      = require 'path'
PD                        = require 'pipedreams'
{ $
  $async
  select }                = PD
{ assign
  jr }                    = CND
request										= require 'request-promise-native'
require '../exception-handler'

url = 'https://jisho.org/api/v1/search/words?keyword=にほん'
url = 'https://jisho.org/api/v1/search/words?keyword=%E3%81%AB%E3%81%BB%E3%82%93'
url = 'https://jisho.org/api/v1/search/words?keyword=%E3%81%BE%E3%82%82%E3%82%8B'

# read_as_stream = ( url ) ->
# 	### API gives back one blob of JSON, so better off w/ promised-based interface ###
# 	source = PD.read_from_nodejs_stream request.get url
# 	pipeline = []
# 	pipeline.push source
# 	pipeline.push PD.$split()
# 	pipeline.push PD.$show()
# 	pipeline.push PD.$drain()
# 	PD.pull pipeline...
# read_as_stream 'https://jisho.org/api/v1/search/words?keyword=%E3%81%AB%E3%81%BB%E3%82%93'

lookup_in_jishodotorg = ( q ) ->
	base_url 	= 'https://jisho.org/api/v1/search/words'
	response 	= await request.get base_url, { qs: { keyword: q, }, json: true, }
	info 'µ66474', q
	for entry in response.data
		# continue unless entry.is_common
		continue unless entry.japanese?
		#.......................................................................................................
		# seen 		= new Set()
		english = new Set()
		if entry.senses?
			for sense in entry.senses
				continue unless sense.english_definitions?
				for definition in sense.english_definitions
					english.add definition
		english = [ english.keys()... ].join '; '
		#.......................................................................................................
		seen = new Set()
		for { word, reading, } in entry.japanese
			continue unless reading? and reading.startsWith q
			continue unless word?
			continue if seen.has word
			seen.add word
			urge word, '[' + reading + ']', ( CND.lime english )
	return null

do ->
	# await lookup_in_jishodotorg 'きょう'
	await lookup_in_jishodotorg 'かく'
	await lookup_in_jishodotorg 'しみず'
	await lookup_in_jishodotorg 'きよみず'
	await lookup_in_jishodotorg 'taiwan'
	await lookup_in_jishodotorg '父親'


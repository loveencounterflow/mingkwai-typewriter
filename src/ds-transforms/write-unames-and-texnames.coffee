
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'IME/EXPERIMENTS/KB'
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
Sqlite_db                 = require 'better-sqlite3'


#-----------------------------------------------------------------------------------------------------------
xray = ( text ) -> ( ( ( chr.codePointAt 0 ).toString 16 ) for chr in Array.from text )

#-----------------------------------------------------------------------------------------------------------
@$reshape = ->
  return $ ( d0, send ) ->
    d = {}
    names = [
      [ 'ucid',        'ID'                   ]
      [ 'uname',       'UNICODE DESCRIPTION'  ]
      [ 'texname',     'latex'                ]
      [ 'description', 'op dict'              ]
      ]
    d[ new_name ] = d0[ old_name ] for [ new_name, old_name, ] in names
    send d

#-----------------------------------------------------------------------------------------------------------
@$omit_empty = ->
  names = [ 'ucid', 'uname', 'texname', 'description', ]
  return $ ( d, send ) ->
    for name in names
      delete d[ name ] if ( d[ name ].match /^\s*$/ )?
    send d

#-----------------------------------------------------------------------------------------------------------
@$cleanup_texname = ->
  cleanup_texname = ( text ) ->
    R = text
    R = R.replace /\\/g,    ''
    R = R.replace /[{}]/g,  '-'
    R = R.replace /-+/g,    '-'
    R = R.replace /^-/g,    ''
    R = R.replace /-$/g,    ''
    R = R.replace /'/g,     'acute'
    return R
  return $ ( d, send ) ->
    d.texname = cleanup_texname d.texname if d.texname?
    send d

#-----------------------------------------------------------------------------------------------------------
@$cleanup_uname = ->
  cleanup_uname = ( text ) ->
    return null unless text?
    R = text
    R = R.toLowerCase()
    return R
  return $ ( d, send ) ->
    d.uname = cleanup_uname d.uname
    send d

#-----------------------------------------------------------------------------------------------------------
@$distinct_tokens_from_uname = ->
  split = ( text ) -> text.split /[\s-]+/
  seen  = new Set()
  return $ ( d, send ) ->
    for uname_token in split d.uname
      continue if seen.has uname_token
      seen.add uname_token
      send { uname_token, } unless uname_token.length is 0
    return null

#-----------------------------------------------------------------------------------------------------------
@$ranked_tokens_from_uname = ->
  split = ( text ) -> text.split /[\s-]+/
  ranks = {}
  last  = Symbol 'last'
  return $ { last, }, ( d, send ) ->
    if d is last
      for uname_token, rank of ranks
        send { uname_token, rank, }
    else
      for uname_token in split d.uname
        continue if uname_token.length is 0
        ranks[ uname_token ] = ( ranks[ uname_token ] ?= 0 ) + 1
    return null

#-----------------------------------------------------------------------------------------------------------
@$skip_extraneous = ->
  return PD.$filter ( d ) ->
    return true unless d.uname?
    return false if ( d.uname.match /^cjk compatibility ideograph/ )?
    return false if ( d.uname.match /^language tag/ )?
    return false if ( d.uname.match /^tag / )?
    return false if ( d.uname.match /^variation selector-/ )?
    return false if ( d.uname.match /^multiple character operator/ )?
    return true

#-----------------------------------------------------------------------------------------------------------
@$_XXX_skip_whitespace_etc = ->
  ### TAINT should implement symbolic whitespace representation ###
  return PD.$filter ( d ) ->
    return false unless d.glyph?
    return false if ( d.glyph.match /^\s+$/ )?
    return false if ( d.glyph.match /^[\x00-\x20]+$/ )?
    return true

#-----------------------------------------------------------------------------------------------------------
@$_XXX_skip_longer_texts = ->
  ### TAINT must implement target texts with more than a single glyph ###
  return PD.$filter ( d ) -> ( d.ucid.match /^U[0-9A-F]{5}$/ )?

#-----------------------------------------------------------------------------------------------------------
@$add_glyph = ->
  return $ ( d, send ) ->
    return send d unless d.ucid?
    cid       = parseInt ( d.ucid.replace /^U/, '' ), 16
    d.glyph   = String.fromCodePoint cid
    d.cid_hex = 'u/' + cid.toString 16
    delete d.ucid
    send d

#-----------------------------------------------------------------------------------------------------------
@$as_tsv = ( names ) -> PD.$map ( d ) -> ( ( d[ name ] for name in names ).join '\t' ) + '\n'

#-----------------------------------------------------------------------------------------------------------
csvesc    = ( text  ) -> text.replace /"/g, '""'

#-----------------------------------------------------------------------------------------------------------
@$as_csv = ( names ) ->
  first = Symbol 'first'
  return $ { first, }, ( d, send ) ->
    if d is first
      send ( ( "\"#{csvesc name}\"" for name in names ).join ',' ) + '\n'
    else
      send ( ( "\"#{csvesc d[ name ].toString()}\"" for name in names ).join ',' ) + '\n'
    return null

#-----------------------------------------------------------------------------------------------------------
@$filter_unames               = -> PD.$filter ( d ) -> d.uname?    and d.glyph?
@$filter_texnames             = -> PD.$filter ( d ) -> d.texname?  and d.glyph?
@$skip_tautological_texnames  = -> PD.$filter ( d ) -> d.texname isnt d.glyph
@$as_uname_tsv                = -> @$as_tsv [ 'cid_hex', 'glyph', 'uname',   ]
@$as_texname_tsv              = -> @$as_tsv [ 'cid_hex', 'glyph', 'texname', ]
@$as_uname_csv                = -> @$as_csv [ 'cid_hex', 'glyph', 'uname',   ]
@$as_texname_csv              = -> @$as_csv [ 'cid_hex', 'glyph', 'texname', ]
@$as_uname_token_csv          = -> @$as_csv [ 'uname_token', 'rank',         ]
# @$as_uname_token_csv          = -> @$as_csv [ 'uname_token',                 ]

#-----------------------------------------------------------------------------------------------------------
@write_unames_and_texnames = ( settings ) ->
  new_csv_parser  = require 'csv-parser'
  strip_bom       = require 'strip-bom-stream'
  njs_source      = FS.createReadStream settings.source_path
  njs_source      = njs_source.pipe strip_bom()
  njs_source      = njs_source.pipe new_csv_parser()
  source          = PD.read_from_nodejs_stream njs_source
  #.........................................................................................................
  get_unames_byline = =>
    pipeline        = []
    pipeline.push @$filter_unames()
    pipeline.push @$as_uname_csv()
    # pipeline.push PD.$watch ( d ) => info d
    pipeline.push PD.write_to_file settings.unames_target_path
    return PD.pull pipeline...
  #.........................................................................................................
  get_uname_tokens_byline = =>
    pipeline        = []
    pipeline.push @$filter_unames()
    # pipeline.push @$distinct_tokens_from_uname()
    pipeline.push @$ranked_tokens_from_uname()
    pipeline.push @$as_uname_token_csv()
    # pipeline.push PD.$watch ( d ) => info d
    pipeline.push PD.write_to_file settings.uname_tokens_target_path
    return PD.pull pipeline...
  #.........................................................................................................
  get_texnames_byline = =>
    pipeline        = []
    pipeline.push @$filter_texnames()
    pipeline.push @$skip_tautological_texnames()
    pipeline.push @$as_texname_csv()
    pipeline.push PD.write_to_file settings.texnames_target_path
    return PD.pull pipeline...
  #.........................................................................................................
  convert = =>
    pipeline        = []
    pipeline.push source
    # pipeline.push PD.$sample 1 / 2000
    pipeline.push @$reshape()
    pipeline.push @$omit_empty()
    pipeline.push PD.$watch ( d ) => urge jr d if d.ucid.endsWith '0002D'
    pipeline.push @$cleanup_texname()
    pipeline.push @$cleanup_uname()
    pipeline.push @$skip_extraneous()
    pipeline.push @$_XXX_skip_longer_texts()
    pipeline.push @$add_glyph()
    pipeline.push @$_XXX_skip_whitespace_etc()
    # pipeline.push PD.$show()
    pipeline.push PD.$tee get_unames_byline()
    pipeline.push PD.$tee get_uname_tokens_byline()
    pipeline.push PD.$tee get_texnames_byline()
    pipeline.push PD.$drain()
    PD.pull pipeline...
    return null
  #.........................................................................................................
  convert()
  return null

L = @
settings =
  source_path:              PATH.resolve PATH.join __dirname, '../../db/unicode-names-and-entities.csv'
  unames_target_path:       PATH.resolve PATH.join __dirname, '../../db/unames.csv'
  uname_tokens_target_path: PATH.resolve PATH.join __dirname, '../../db/uname-tokens.csv'
  texnames_target_path:     PATH.resolve PATH.join __dirname, '../../db/texnames.csv'

#   db_path:              PATH.resolve PATH.join __dirname, '../../db/data.db'
# settings.db = new Sqlite_db settings.db_path, { verbose: urge }

L.write_unames_and_texnames settings


















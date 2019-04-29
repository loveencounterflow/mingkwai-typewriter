

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/DS-TRANSFORMS/WRITE-CEDICT-PINYIN'
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
TRIODE                    = require 'triode'
@_drop_extension          = ( path ) -> path[ ... path.length - ( PATH.extname path ).length ]
types                     = require '../types'
{ isa
  validate
  size_of
  type_of }               = types
#...........................................................................................................
require                   '../exception-handler'

#-----------------------------------------------------------------------------------------------------------
last_of   = ( x ) -> x[ ( size_of x ) - 1 ]
@$as_line = => $ ( line, send ) => send line + '\n'

#-----------------------------------------------------------------------------------------------------------
as_sql = ( x ) ->
  validate.text x
  R = x
  R = R.replace /'/g, "''"
  return "'#{R}'"

#-----------------------------------------------------------------------------------------------------------
@$split_fields = ->
  # 臈たける;臈長ける;臈闌ける,[ろうたける],/(v1,vi)
  pattern = ///
    ^
    (?<candidates> \S+ )
    (
      \x20
      \[
        (?<readings> [^\]]+ )
        \]
      |
      )
    \x20 \/
    (?<glosses> .* )
    \/
    $
    ///
  return $ ( line, send ) =>
    unless ( match = line.match pattern )?
      warn "unexpected format: #{rpr line}"
      return null
    { candidates
      readings
      glosses   } = match.groups
    candidates    = candidates.trim().split ';'
    glosses       = glosses.trim().split '/'
    glosses.pop() if ( last_of glosses ).startsWith 'EntL'
    glosses       = glosses.join '; '
    if readings? then readings  = readings.trim().split ';'
    else              readings  = null
    send { candidates, readings, glosses, }

#-----------------------------------------------------------------------------------------------------------
@$as_sql = =>
  first = Symbol 'first'
  last  = Symbol 'last'
  return $ { first, last, }, ( record, send ) =>
    #.......................................................................................................
    if record is first
      send "insert into dictionary ( readings, candidates, glosses ) values"
    #.......................................................................................................
    else if record is last
      send ";"
    #.......................................................................................................
    else
      { candidates
        readings
        glosses   } = record
      return null unless readings?
      for reading in readings
        for candidate in candidates
          send "( #{as_sql reading}, #{as_sql candidate}, #{as_sql glosses} )"
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@$write_sql = ( target_path ) =>
  pipeline = []
  # pipeline.push @$distill_traditional()
  # pipeline.push @$feed_triode()
  # pipeline.push $ ( triode, send ) => send triode.as_js_module_text()
  pipeline.push @$as_sql()
  pipeline.push @$as_line()
  pipeline.push PD.$show()
  pipeline.push PD.write_to_file target_path
  return PD.$tee PD.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@write_dictionary = ( settings ) -> new Promise ( resolve, reject ) =>
  target_filename   = ( @_drop_extension PATH.basename settings.source_path ) + '.sql'
  target_path       = PATH.resolve PATH.join __dirname, '../../.cache', target_filename
  help "translating #{rpr PATH.relative process.cwd(), settings.source_path}"
  #.........................................................................................................
  convert = =>
    pipeline = []
    pipeline.push PD.read_from_file settings.source_path
    pipeline.push PD.$split()
    pipeline.push PD.$sample 20 / 183000 #, seed: 12
    pipeline.push @$split_fields()
    # pipeline.push $ ( line, send ) -> send line.replace /\s+$/, '\n' # prepare for line-splitting in WSV reader
    # pipeline.push PD.$split_wsv 3
    # pipeline.push @$split_pinyin_and_gloss()
    # pipeline.push @$cleanup_pinyin()
    pipeline.push @$write_sql target_path
    pipeline.push PD.$drain =>
      help "wrote output to #{rpr PATH.relative process.cwd(), target_path}"
      resolve()
    PD.pull pipeline...
    return null
  #.........................................................................................................
  convert()
  return null


############################################################################################################
unless module.parent?
  L = @
  do ->
    #.......................................................................................................
    settings =
      source_path:  PATH.resolve PATH.join __dirname, '../../db/edict2u'
      # postprocess: ( triode ) ->
      #   triode.disambiguate_subkey 'n', 'n.'
      #   triode.disambiguate_subkey 'v', 'v.'
      #   for subkey, superkeys of triode.get_all_superkeys()
      #     help "µ46474 resolving #{rpr subkey} -> #{rpr superkeys}"
      #     triode.apply_replacements_recursively subkey
      #   return null
    await L.write_dictionary settings
    help 'ok'



















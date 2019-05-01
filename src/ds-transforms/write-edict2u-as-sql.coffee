

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
JACONV                    = require 'jaconv'
@_drop_extension          = ( path ) -> path[ ... path.length - ( PATH.extname path ).length ]
types                     = require '../types'
{ isa
  validate
  declare
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
declare 'edict2u_plural_row',
  tests:
    '? is an object':           ( x ) -> @isa.object   x
    '? has keys':               ( x ) -> @has_keys x, 'readings', 'candidates', 'glosses'
    '?.readings is a *list':    ( x ) -> ( not x.readings? ) or @isa.list x.readings
    '?.candidates is a list':   ( x ) -> @isa.list x.candidates
    '?.glosses is a text':      ( x ) -> @isa.text x.glosses

#-----------------------------------------------------------------------------------------------------------
declare 'edict2u_singular_row',
  tests:
    '? is an object':           ( x ) -> @isa.object   x
    '? has keys':               ( x ) -> @has_keys x, 'reading', 'candidate', 'glosses'
    '?.reading is a text':      ( x ) -> @isa.text x.reading
    '?.candidate is a text':    ( x ) -> @isa.text x.candidate
    '?.glosses is a text':      ( x ) -> @isa.text x.glosses

#-----------------------------------------------------------------------------------------------------------
@$fan_out = =>
  return $ ( row, send ) =>
    return null unless row.readings?
    for reading in row.readings
      for candidate in row.candidates
        send { reading, candidate, glosses: row.glosses, }
    return null

#-----------------------------------------------------------------------------------------------------------
@$validate_plural_row   = PD.$watch ( row ) => validate.edict2u_plural_row   row
@$validate_singular_row = PD.$watch ( row ) => validate.edict2u_singular_row row

#-----------------------------------------------------------------------------------------------------------
@$normalize = =>
  return PD.$watch ( row ) =>
    row.reading   = JACONV.toHanAscii row.reading
    row.candidate = JACONV.toHanAscii row.candidate
    return null

#-----------------------------------------------------------------------------------------------------------
@$remove_annotations = =>
  pattern = /[-(\[,;.:#~+*\])]/
  return PD.$watch ( row ) =>
    row.reading   = row.reading.replace     /\(gikun|ateji|P|io|gikun|ok|\)/g,     ''
    row.candidate = row.candidate.replace   /\(gikun|ateji|P|io|gikun|ok|\)/g,     ''
    # help 'µ43993', 'reading:    ', row.reading   if ( row.reading.match    pattern )?
    # urge 'µ43993', 'candidate:  ', row.candidate if ( row.candidate.match  pattern )?
    return null

#-----------------------------------------------------------------------------------------------------------
@$remove_duplicates = =>
  seen  = new Set()
  count = 0
  last  = Symbol 'last'
  return $ ( row, send ) =>
    if row is last
      help "µ33392 skipped #{count} duplicates"
      return null
    key = "#{row.reading}\x00#{row.candidate}"
    if seen.has key
      count += +1
      # whisper "duplicate: #{rpr key}"
      return null
    seen.add key
    send row

#-----------------------------------------------------------------------------------------------------------
@$as_sql = =>
  first           = Symbol 'first'
  last            = Symbol 'last'
  is_first_record = true
  return $ { first, last, }, ( row, send ) =>
    #.......................................................................................................
    if row is first
      send "insert into edict2u ( reading, candidate, glosses ) values"
    #.......................................................................................................
    else if row is last
      send ";"
    #.......................................................................................................
    else
      if is_first_record
        is_first_record = false
        send "( #{as_sql row.reading}, #{as_sql row.candidate}, #{as_sql row.glosses} )"
      else
        send ",( #{as_sql row.reading}, #{as_sql row.candidate}, #{as_sql row.glosses} )"
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@$write_sql = ( target_path ) =>
  pipeline = []
  pipeline.push @$as_sql()
  pipeline.push @$as_line()
  pipeline.push PD.write_to_file target_path
  return PD.$tee PD.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@write_dictionary = ( settings ) -> new Promise ( resolve, reject ) =>
  ### TAINT normalize fullwidth characters ###
  ### TAINT remove annotations from readings (e.g. 'おひいさま(ok)') ###
  ### TAINT recognize, repair conflated entries like
    一昨年(P);おと年 [いっさくねん(一昨年)(P);おととし(P)] /(n-adv,n-t) year before last/(P)/EntL1576060X/
  ###
  target_filename   = ( @_drop_extension PATH.basename settings.source_path ) + '.sql'
  target_path       = PATH.resolve PATH.join __dirname, '../../.cache', target_filename
  help "translating #{rpr PATH.relative process.cwd(), settings.source_path}"
  #.........................................................................................................
  convert = =>
    pipeline = []
    pipeline.push PD.read_from_file settings.source_path
    pipeline.push PD.$split()
    # pipeline.push PD.$sample 20 / 183000 #, seed: 12
    pipeline.push @$split_fields()
    pipeline.push @$validate_plural_row()
    pipeline.push @$fan_out()
    pipeline.push @$validate_singular_row()
    pipeline.push @$normalize()
    pipeline.push @$remove_annotations()
    pipeline.push @$remove_duplicates()
    pipeline.push @$write_sql target_path
    # pipeline.push @$populate_db()
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



















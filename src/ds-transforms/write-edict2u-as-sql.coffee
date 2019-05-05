

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
PSPG                      = require 'pspg'
#...........................................................................................................
### TAINT needed for tabular output, to be moved to a package or submodule: ###
{ to_width, width_of, }   = require 'to-width'


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
    gloss         = glosses.join '; '
    if readings? then readings  = readings.trim().split ';'
    else              readings  = null
    send { line, candidates, readings, gloss, }

#-----------------------------------------------------------------------------------------------------------
@$skip_blank_lines_and_comments = => PD.$filter ( line ) =>
  return false if ( isa.blank_text line )
  return false if ( line.startsWith '#' )
  return false if ( line.startsWith '　？？？ ' ) # first line of edict2u as downloaded
  return true

#-----------------------------------------------------------------------------------------------------------
@$fan_out = =>
  return $ ( row, send ) =>
    return null unless row.readings?
    for reading in row.readings
      for candidate in row.candidates
        send { reading, candidate, gloss: row.gloss, line: row.line, }
    return null

#-----------------------------------------------------------------------------------------------------------
@$distribute_refined_readings = =>
  ### Takes care of `reading`s like `いっさくねん(一昨年)` that are only valid for a subset of candidates. ###
  refinements_pattern = /^(?<reading>[^(]+)\((?<refinements>[^)]+)\)$/
  return $ ( row, send ) =>
    { reading
      candidate
      gloss
      line }      = row
    return send row unless ( match = reading.match refinements_pattern )?
    { reading
      refinements }   = match.groups
    refinements       = refinements.split /,/
    # send { badge: 'µ33734', reading, refinements: ( jr refinements ), }
    for candidate in refinements
      send { reading, candidate, gloss, line, }

#-----------------------------------------------------------------------------------------------------------
@$validate_plural_row   = => PD.$watch ( row ) => validate.edict2u_plural_row   row
@$validate_singular_row = => PD.$watch ( row ) => validate.edict2u_singular_row row

#-----------------------------------------------------------------------------------------------------------
@$normalize = =>
  return PD.$watch ( row ) =>
    return null unless isa.edict2u_singular_row row
    row.reading   = JACONV.toHanAscii row.reading
    row.reading   = JACONV.toHiragana row.reading
    row.candidate = JACONV.toHanAscii row.candidate
    return null

#-----------------------------------------------------------------------------------------------------------
@$add_kana_candidates = =>
  return $ ( row, send ) =>
    return null unless isa.edict2u_singular_row row
    # send { row..., candidate: row.reading, }
    # send { row..., candidate: ( JACONV.toKatakana row.reading ), }
    send { row..., candidate: ( JACONV.toHiragana row.candidate ), }
    send { row..., candidate: ( JACONV.toKatakana row.candidate ), }
    send { row..., candidate: ( JACONV.toZenAscii row.candidate ), }
    send { row..., candidate: ( JACONV.toHanKana  row.candidate ), }
    send row
    return null

#-----------------------------------------------------------------------------------------------------------
@$remove_annotations = =>
  ### see http://www.edrdg.org/jmdictdb/cgi-bin/edhelp.py?svc=jmdict&sid=#kw_misc ###
  pattern = /\((?:ateji|gikun|iK|ik|io|oK|ok|P)\)/g
  return PD.$watch ( row ) =>
    return null unless isa.edict2u_singular_row row
    row.reading   = row.reading.replace     pattern, ''
    row.candidate = row.candidate.replace   pattern, ''
    return null

#-----------------------------------------------------------------------------------------------------------
@$collect_remarkables = =>
  # pattern = /\((?<annotation>[\x00-\xff]+)\)/
  pattern = /\((?<annotation>[^)]+)\)/
  seen = new Set()
  return PD.$watch ( row ) =>
    return null unless isa.edict2u_singular_row row
    for key in [ 'reading', 'candidate', ]
      text = row[ key ]
      continue if seen.has text
      seen.add text
      #.....................................................................................................
      continue unless ( match = text.match pattern )?
      #.....................................................................................................
      { annotation, } = match.groups
      continue if seen.has annotation
      seen.add annotation
      #.....................................................................................................
      # color = if key is 'reading' then CND.orange else CND.lime
      # debug 'µ33982', key, text
      debug 'µ33982', jr [ key, row, ]
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
    return unless isa.edict2u_singular_row row
    #.......................................................................................................
    if row is first
      send "insert into edict2u ( reading, candidate, gloss ) values"
    #.......................................................................................................
    else if row is last
      send ";"
    #.......................................................................................................
    else
      if is_first_record
        is_first_record = false
        send "( #{as_sql row.reading}, #{as_sql row.candidate}, #{as_sql row.gloss} )"
      else
        send ",( #{as_sql row.reading}, #{as_sql row.candidate}, #{as_sql row.gloss} )"
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@$tee_write_sql = ( target_path ) =>
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
    上枝;秀つ枝 [うわえだ(上枝);うわえ(上枝);ほつえ] /(n) (See 下枝) upper branches of a tree/EntL2579960/

    try to recognize entries where

    * one or more (stretches) kana from a term that has kana and kanji do not appear in a corresponding
      kana-only term. (This test is, strictly speaking, not sufficient.)
    * there are different kana-only (hg & kt) terms.

  ###
  ### TAINT some entries are loosing data:

  子猫(P);仔猫;子ネコ;小猫;子ねこ;仔ネコ [こねこ(子猫,仔猫,小猫,子ねこ)(P);こネコ(子ネコ,仔ネコ);コネコ] /(n) (1) kitten/(2) small cat/(P)/EntL1593380X/

  'reading',
  '子猫,仔猫,小猫,子ねこ',
  {
    reading: 'こねこ(子猫,仔猫,小猫,子ねこ)',
    candidate: '子ねこ',
    glosses: '(n) (1) kitten; (2) small cat; (P)'
  }

  `コネコ` is in source, but not in target.
  ###
  target_filename   = ( @_drop_extension PATH.basename settings.source_path ) + '.sql'
  target_path       = PATH.resolve PATH.join __dirname, '../../.cache', target_filename
  help "translating #{rpr PATH.relative process.cwd(), settings.source_path}"
  #.........................................................................................................
  return new Promise ( resolve ) =>
    pipeline = []
    pipeline.push PD.read_from_file settings.source_path
    pipeline.push PD.$split()
    pipeline.push @$skip_blank_lines_and_comments()
    pipeline.push @$split_fields()
    pipeline.push @$validate_plural_row()
    pipeline.push @$fan_out()
    # pipeline.push PD.$sample 100 / 200000
    pipeline.push @$validate_singular_row()
    pipeline.push @$normalize()
    pipeline.push @$remove_annotations()
    pipeline.push @$distribute_refined_readings()
    pipeline.push @$add_kana_candidates()
    pipeline.push @$collect_remarkables()
    pipeline.push @$remove_duplicates()
    pipeline.push PSPG.$tee_as_table -> resolve()
    pipeline.push @$tee_write_sql target_path
    pipeline.push PD.$drain =>
      help "wrote output to #{rpr PATH.relative process.cwd(), target_path}"
      resolve()
    PD.pull pipeline...
    #.......................................................................................................
    return null


############################################################################################################
unless module.parent?
  L = @
  do ->
    #.......................................................................................................
    settings =
      # source_path:  PATH.resolve PATH.join __dirname, '../../db/edict2u'
      source_path:  PATH.resolve PATH.join __dirname, '../../db/edict2u-test'
      # postprocess: ( triode ) ->
      #   triode.disambiguate_subkey 'n', 'n.'
      #   triode.disambiguate_subkey 'v', 'v.'
      #   for subkey, superkeys of triode.get_all_superkeys()
      #     help "µ46474 resolving #{rpr subkey} -> #{rpr superkeys}"
      #     triode.apply_replacements_recursively subkey
      #   return null
    await L.write_dictionary settings
    help 'ok'

    debug 'µ33441', JACONV.toHiragana 'カブ'
    debug 'µ33441', JACONV.toHiragana '仔ネコ'
    demo_jaconv_methods = ->
      probes = [
        'hyakupaasento'
        'ｈａｋｕｐａａｓｅｎｔｏ'
        '100ぱーせんと'
        '100パーセント'
        '100ﾊﾟｰｾﾝﾄ'
        'ひゃくぱーせんと'
        '１００パーセント' ]
      method_names = [
        'normalize'
        'toHan'
        # 'toHanAscii'
        # 'toHanKana'
        # 'toHebon'
        'toHiragana'
        'toKatakana'
        'toZen'
        # 'toZenAscii'
        # 'toZenKana'
        ]
      pipeline = []
      pipeline.push PD.new_value_source probes
      pipeline.push $ ( probe, send ) =>
        send null
        for method_name in method_names
          result = JACONV[ method_name ] probe
          send { probe, m: method_name, result, }
      pipeline.push PSPG.$tee_as_table()
      pipeline.push do =>
        first = Symbol 'first'
        last  = Symbol 'last'
        return PD.$watch { first, last }, ( d ) =>
          urge 'first' if d is first
          urge 'last'  if d is last
      pipeline.push PD.$show()
      pipeline.push PD.$drain()
      PD.pull pipeline...


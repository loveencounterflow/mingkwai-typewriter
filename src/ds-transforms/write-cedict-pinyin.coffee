
### TAINTs

* deal with mssing characters

* PY `ü` is written `u:`, use `ü`, `v` to replace

* consider to collapse words from prefixes:
  咖 ->
    咖哩
    咖啡 ->
      咖啡伴侶
      咖啡因
      咖啡館 ->
        咖啡館兒 ->

###


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

#-----------------------------------------------------------------------------------------------------------
xray = ( text ) -> ( ( ( chr.codePointAt 0 ).toString 16 ) for chr in Array.from text )

#-----------------------------------------------------------------------------------------------------------
@$as_line = -> $ ( d, send ) => send ( jr d ) + '\n'

#-----------------------------------------------------------------------------------------------------------
@$name_fields = ->
  return $ ( d, send ) =>
    [ transliteration, target, ] = d
    send { transliteration, target, }

#-----------------------------------------------------------------------------------------------------------
@$feed_triode = ->
  last    = Symbol 'last'
  triode  = TRIODE.new()
  return $ { last, }, ( d, send ) =>
    return send triode if d is last
    triode.set d.transliteration, ( target = [] ) unless ( target = triode.get d.transliteration )?
    target.push d.target unless d.target in target
    return null

#-----------------------------------------------------------------------------------------------------------
@$split_pinyin_and_gloss = ->
  pinyin_and_gloss_pattern = /// ^ \[ (?<pinyin> .+? ) \] \s+ \/ (?<gloss> .+? ) \/  $ ///
  return $ ( fields, send ) =>
    [ kt, ks, pinyin_and_gloss, ] = fields
    unless ( match = pinyin_and_gloss.match pinyin_and_gloss_pattern )?
      throw new Error "µ33833 illegal pinyin_and_gloss: #{rpr pinyin_and_gloss}"
    { pinyin
      gloss }                     = match.groups
    gloss                         = gloss.split '/'
    send { kt, ks, pinyin, gloss, }

#-----------------------------------------------------------------------------------------------------------
@$cleanup_pinyin = ->
  return $ ( fields, send ) =>
    fields.pinyin = fields.pinyin.replace /[,\s0-5]/g, ''
    fields.pinyin = fields.pinyin.toLowerCase()
    send fields

#-----------------------------------------------------------------------------------------------------------
@$distill_traditional = ->
  return $ ( fields, send ) =>
    { kt, pinyin, } = fields
    send { transliteration: pinyin, target: kt, }

#-----------------------------------------------------------------------------------------------------------
@$write_traditional_cdt = ( target_path ) =>
  pipeline = []
  pipeline.push @$distill_traditional()
  pipeline.push @$feed_triode()
  pipeline.push $ ( triode, send ) => send triode.as_js_module_text()
  pipeline.push PD.write_to_file target_path
  return PD.$tee PD.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@write_keyboard = ( settings ) -> new Promise ( resolve, reject ) =>
  cdt_target_filename  = ( @_drop_extension PATH.basename settings.source_path ) + '.cdt.js'
  cdt_target_path      = PATH.resolve PATH.join __dirname, '../../.cache', cdt_target_filename
  help "translating #{rpr PATH.relative process.cwd(), settings.source_path}"
  #.........................................................................................................
  convert = =>
    pipeline = []
    pipeline.push PD.read_from_file settings.source_path
    # pipeline.push PD.$split()
    # pipeline.push PD.$sample 1 / 5000 #, seed: 12
    # pipeline.push $ ( line, send ) -> send line.replace /\s+$/, '\n' # prepare for line-splitting in WSV reader
    pipeline.push PD.$split_wsv 3
    pipeline.push @$split_pinyin_and_gloss()
    pipeline.push @$cleanup_pinyin()
    # pipeline.push PD.$show()
    pipeline.push @$write_traditional_cdt cdt_target_path
    pipeline.push PD.$drain =>
      help "wrote output to #{rpr PATH.relative process.cwd(), cdt_target_path}"
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
      source_path:  PATH.resolve PATH.join __dirname, '../../db/cedict_ts.u8'
      # postprocess: ( triode ) ->
      #   triode.disambiguate_subkey 'n', 'n.'
      #   triode.disambiguate_subkey 'v', 'v.'
      #   for subkey, superkeys of triode.get_all_superkeys()
      #     help "µ46474 resolving #{rpr subkey} -> #{rpr superkeys}"
      #     triode.apply_replacements_recursively subkey
      #   return null
    await L.write_keyboard settings
    help 'ok'




















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
TRIODE                    = require 'triode'

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
@$translate_to_js = ->
  return $ ( triode, send ) =>
    # send triode.replacements_as_js_module_text()
    # send rpr triode
    # send triode.as_js_function_text()
    send triode.as_js_module_text()

#-----------------------------------------------------------------------------------------------------------
@write_keyboard = ( settings ) -> new Promise ( resolve, reject ) =>
  target_filename = ( PATH.basename settings.source_path ) + '.js'
  target_path     = PATH.resolve PATH.join __dirname, '../../.cache', target_filename
  help "translating #{rpr PATH.relative process.cwd(), settings.source_path}"
  #.........................................................................................................
  get_traditional_byline = =>
    pipeline        = []
    pipeline.push @$distill_traditional()
    # pipeline.push @$as_line()
    pipeline.push @$feed_triode()
    pipeline.push @$translate_to_js()
    pipeline.push PD.write_to_file target_path
    return PD.pull pipeline...
  #.........................................................................................................
  convert = =>
    pipeline        = []
    pipeline.push PD.read_from_file settings.source_path
    # pipeline.push PD.$split()
    # pipeline.push PD.$sample 1 / 5000 #, seed: 12
    # pipeline.push $ ( line, send ) -> send line.replace /\s+$/, '\n' # prepare for line-splitting in WSV reader
    pipeline.push PD.$split_wsv 3
    pipeline.push @$split_pinyin_and_gloss()
    pipeline.push @$cleanup_pinyin()
    # pipeline.push PD.$show()
    pipeline.push PD.$tee get_traditional_byline()
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




















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
    triode.set d.transliteration, d.target
    return null

#-----------------------------------------------------------------------------------------------------------
@$translate_to_js = ->
  return $ ( triode, send ) =>
    send triode.replacements_as_js_module_text()

#-----------------------------------------------------------------------------------------------------------
@write_keyboard = ( settings ) -> new Promise ( resolve, reject ) =>
  target_filename = ( PATH.basename settings.source_path ) + '.js'
  target_path     = PATH.resolve PATH.join __dirname, '../../.cache', target_filename
  help "translating #{rpr PATH.relative process.cwd(), settings.source_path}"
  #.........................................................................................................
  get_unames_byline = =>
    pipeline        = []
    # pipeline.push @$filter_unames()
    # pipeline.push @$as_line()
    pipeline.push PD.write_to_file target_path
    return PD.pull pipeline...
  #.........................................................................................................
  convert = =>
    pipeline        = []
    pipeline.push PD.read_from_file settings.source_path
    pipeline.push PD.$split_wsv 2
    pipeline.push @$name_fields()
    pipeline.push @$feed_triode()
    ( pipeline.push PD.$watch ( triode ) -> settings.postprocess triode ) if settings.postprocess?
    pipeline.push @$translate_to_js()
    # pipeline.push PD.$show()
    pipeline.push PD.$tee get_unames_byline()
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
      source_path:  PATH.resolve PATH.join __dirname, '../../db/jp_kana.hrgn.keyboard.wsv'
      postprocess: ( triode ) ->
        triode.disambiguate_subkey 'n', 'n.'
        triode.disambiguate_subkey 'v', 'v.'
        for subkey, superkeys of triode.get_all_superkeys()
          help "µ46474 resolving #{rpr subkey} -> #{rpr superkeys}"
          triode.apply_replacements_recursively subkey
        return null
    await L.write_keyboard settings
    #.......................................................................................................
    settings =
      source_path:  PATH.resolve PATH.join __dirname, '../../db/gr_gr.keyboard.wsv'
      postprocess: ( triode ) ->
        debug 'µ77622', triode.get_all_superkeys()
      #   triode.disambiguate_subkey 'n', 'n.'
      #   triode.disambiguate_subkey 'v', 'v.'
      #   for subkey, superkeys of triode.get_all_superkeys()
      #     help "µ46474 resolving #{rpr subkey} -> #{rpr superkeys}"
      #     triode.apply_replacements_recursively subkey
      #   return null
    await L.write_keyboard settings
    help 'ok'



















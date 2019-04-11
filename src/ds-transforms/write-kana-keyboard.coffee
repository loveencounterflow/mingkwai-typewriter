
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/DS-TRANSFORMS/WRITE-KANA-KEYBOARD'
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
JACONV                    = require 'jaconv'
require '../exception-handler'
#-----------------------------------------------------------------------------------------------------------
@_drop_extension          = ( path ) -> path[ ... path.length - ( PATH.extname path ).length ]
@_xray                    = ( text ) -> ( ( ( chr.codePointAt 0 ).toString 16 ) for chr in Array.from text )
@$as_line                 = -> $ ( d, send ) => send ( jr d ) + '\n'
@_resolve_dec_entities    = ( text ) -> text.replace /&#([0-9a-f]+);/ig,  ( $0, $1 ) -> String.fromCodePoint ( parseInt $1, 10 )
@_resolve_hex_entities    = ( text ) -> text.replace /&#x([0-9a-f]+);/ig, ( $0, $1 ) -> String.fromCodePoint ( parseInt $1, 16 )
@_resolve_entities        = ( text ) -> @_resolve_dec_entities @_resolve_hex_entities text


# debug rpr @_resolve_entities 'xxx&#x20;xxx'
# process.exit 1

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
@$remove_inline_comments = => PD.$watch ( d ) =>
  d.target = d.target.replace /\s+#\s+.*$/g, ''

#-----------------------------------------------------------------------------------------------------------
@$add_katakana = => $ ( d ) =>
  send d
  d = assign {}, d
  d.transliteration = d.transliteration.toUpperCase()
  d.target          = JACONV.toKatakana d.target
  return null

#-----------------------------------------------------------------------------------------------------------
@$write_kbd = ( target_path ) =>
  pipeline = []
  pipeline.push PD.$watch ( triode ) => debug 'µ7887-11', triode.get_all_superkeys()
  pipeline.push $ ( triode, send ) => send triode.replacements_as_js_module_text()
  pipeline.push PD.write_to_file target_path
  return PD.$tee PD.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@$write_cdt = ( target_path ) =>
  pipeline = []
  pipeline.push $ ( triode, send ) => send triode.as_js_module_text()
  pipeline.push PD.write_to_file target_path
  return PD.$tee PD.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@write_cache = ( settings ) -> new Promise ( resolve, reject ) =>
  kbd_target_filename  = ( @_drop_extension PATH.basename settings.source_path ) + '.kbd.js'
  cdt_target_filename  = ( @_drop_extension PATH.basename settings.source_path ) + '.cdt.js'
  kbd_target_path      = PATH.resolve PATH.join __dirname, '../../.cache', kbd_target_filename
  cdt_target_path      = PATH.resolve PATH.join __dirname, '../../.cache', cdt_target_filename
  help "translating #{rpr PATH.relative process.cwd(), settings.source_path}"
  #.........................................................................................................
  convert = =>
    pipeline = []
    pipeline.push PD.read_from_file settings.source_path
    pipeline.push PD.$split_wsv 2
    pipeline.push @$name_fields()
    pipeline.push @$remove_inline_comments()
    pipeline.push @$resolve_entities()
    pipeline.push @$add_katakana()
    pipeline.push @$feed_triode()
    ( pipeline.push PD.$watch ( triode ) -> settings.postprocess triode ) if settings.postprocess?
    # pipeline.push PD.$show()
    pipeline.push @$write_kbd kbd_target_path
    pipeline.push @$write_cdt cdt_target_path
    pipeline.push PD.$drain =>
      help "wrote output to #{rpr PATH.relative process.cwd(), kbd_target_path}"
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
      source_path:  PATH.resolve PATH.join __dirname, '../../db/jp_kana.wsv'
      postprocess: ( triode ) ->
        triode.disambiguate_subkey 'n', 'n.'
        triode.disambiguate_subkey 'v', 'v.'
        for subkey, superkeys of triode.get_all_superkeys()
          help "µ46474 resolving #{rpr subkey} -> #{rpr superkeys}"
          # triode.apply_replacements_recursively subkey
        return null
    await L.write_cache settings
    # #.......................................................................................................
    # settings =
    #   source_path:  PATH.resolve PATH.join __dirname, '../../db/gr_gr.keyboard.wsv'
    #   postprocess: ( triode ) ->
    #     debug 'µ77622', triode.get_all_superkeys()
    #   #   triode.disambiguate_subkey 'n', 'n.'
    #   #   triode.disambiguate_subkey 'v', 'v.'
    #   #   for subkey, superkeys of triode.get_all_superkeys()
    #   #     help "µ46474 resolving #{rpr subkey} -> #{rpr superkeys}"
    #   #     triode.apply_replacements_recursively subkey
    #   #   return null
    # await L.write_cache settings
    # help 'ok'




















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
length_of                 = ( x ) -> ( Object.keys x ).length
terminate                 = -> warn 'terminating'; process.exit 1
#-----------------------------------------------------------------------------------------------------------
@_drop_extension          = ( path ) -> path[ ... path.length - ( PATH.extname path ).length ]
@_xray                    = ( text ) -> ( ( ( chr.codePointAt 0 ).toString 16 ) for chr in Array.from text )
@$as_line                 = -> $ ( d, send ) => send ( jr d ) + '\n'
@_resolve_dec_entities    = ( text ) -> text.replace /&#([0-9a-f]+);/ig,  ( $0, $1 ) -> String.fromCodePoint ( parseInt $1, 10 )
@_resolve_hex_entities    = ( text ) -> text.replace /&#x([0-9a-f]+);/ig, ( $0, $1 ) -> String.fromCodePoint ( parseInt $1, 16 )
@_resolve_entities        = ( text ) -> @_resolve_dec_entities @_resolve_hex_entities text

# debug @_xray '𪜈゙  ドモ'; xxx

# debug rpr @_resolve_entities 'xxx&#x20;xxx'
# process.exit 1

#-----------------------------------------------------------------------------------------------------------
@$name_fields = ->
  return $ ( d, send ) =>
    [ source, target, ] = d
    send { source, target, }

#-----------------------------------------------------------------------------------------------------------
@$add_sections = ->
  section = null
  return $ ( d, send ) =>
    if d.source is 'SECTION'
      section = ( d.target.split /\s+/ )[ 0 ].toLowerCase()
    else
      d.section = section if section?
      send d
    return null

#-----------------------------------------------------------------------------------------------------------
@$feed_triode = ->
  last        = Symbol 'last'
  triode      = TRIODE.new()
  duplicates  = {}
  #.........................................................................................................
  return $ { last, }, ( d, send ) =>
    if d is last
      if ( count = length_of duplicates ) > 0
        for source, targets of duplicates
          warn "duplicate: #{source} -> #{targets.join ', '}"
        warn "µ44874 detected #{count} duplicates (see listing above)"
        terminate()
        # throw new Error "µ44874 detected #{count} duplicates (see listing above)"
      return send triode
    #.......................................................................................................
    if triode.has d.source
      unless ( targets = duplicates[ d.source ] )?
        targets = duplicates[ d.source ] = [ triode.get d.source ]
      return targets.push d.target
    #.......................................................................................................
    triode.set d.source, d.target
    return null

#-----------------------------------------------------------------------------------------------------------
@$resolve_entities = => PD.$watch ( d ) =>
  d.source = @_resolve_entities d.source
  d.target = @_resolve_entities d.target

#-----------------------------------------------------------------------------------------------------------
@$remove_inline_comments = => PD.$watch ( d ) =>
  d.target = d.target.replace /\s+#\s+.*$/g, ''

#-----------------------------------------------------------------------------------------------------------
@$process_hentaigana = =>
  nr    = 0
  seen  = {}
  return $ ( d, send ) =>
    return send d unless d.section is 'hentaigana'
    nr       += +1
    e         = assign {}, d
    e.source  = "\\h-#{e.source}-#{nr}."
    e.target  = e.target.replace /\(.*$/g, ''
    send e
    f         = assign {}, d
    f.source  = "\\m-#{f.source}-#{nr}."
    f.target  = f.target.replace /^.+\((.+)\)$/g, '$1'
    send f unless seen[ f.target ]
    seen[ f.target ] = true


#-----------------------------------------------------------------------------------------------------------
@$add_katakana = =>
  seen = {}
  return $ ( d, send ) =>
    seen[ d.source ] = d.target
    send d
    #.......................................................................................................
    source  = d.source.toUpperCase()
    target  = JACONV.toKatakana d.target
    if source isnt d.source
      if source of seen
        urge "dropping #{source} -> #{target} in favor of #{seen[ source ]}"
      else
        if ( target isnt d.target )
          seen[ source ] = target
          e         = assign {}, d
          e.source  = source
          e.target  = target
          send e
    #.......................................................................................................
    source  = '^' + d.source
    target  = JACONV.toHanKana JACONV.toKatakana d.target
    if source isnt d.source
      if source of seen
        urge "dropping #{source} -> #{target} in favor of #{seen[ source ]}"
      else
        if ( target isnt d.target )
          seen[ source ] = target
          f         = assign {}, d
          f.source  = source
          f.target  = target
          send f
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@$postprocess = ->
  return PD.$watch ( triode ) =>
    triode.disambiguate_subkey 'n', 'n.'
    triode.disambiguate_subkey 'v', 'v.'
    # triode.disambiguate_subkey 'vv', 'vv.'
    triode.disambiguate_subkey 'N', 'N.'
    triode.disambiguate_subkey 'V', 'V.'
    triode.disambiguate_subkey '^n', '^n.'
    triode.disambiguate_subkey '^v', '^v.'
    # for subkey, superkeys of triode.get_all_superkeys()
    #   help "µ46474 resolving #{rpr subkey} -> #{rpr superkeys}"
    #   triode.apply_replacements_recursively subkey
    return null

#-----------------------------------------------------------------------------------------------------------
@$write_kbd = ( target_path ) =>
  pipeline = []
  pipeline.push PD.$watch ( triode ) =>
    if ( count = length_of ( superkeys = triode.get_all_superkeys() ) ) > 0
      for source, targets of superkeys
        warn "unresolved superkey: #{source} -> #{targets.join ', '}"
      warn "µ44875 detected #{count} unresolved superkeys (see listing above)"
      terminate()
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
    # pipeline.push PD.$split()
    pipeline.push PD.$split_wsv 2
    pipeline.push @$name_fields()
    pipeline.push @$add_sections()
    pipeline.push @$remove_inline_comments()
    pipeline.push @$resolve_entities()
    pipeline.push @$process_hentaigana()
    pipeline.push @$add_katakana()
    # pipeline.push PD.$show()
    pipeline.push @$feed_triode()
    pipeline.push @$postprocess()
    ( pipeline.push PD.$watch ( triode ) -> settings.postprocess triode ) if settings.postprocess?
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



















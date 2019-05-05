



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TESTS/TEE'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
new_numeral               = require 'numeral'
format_float              = ( x ) -> ( new_numeral x ).format '0,0.000'
format_integer            = ( x ) -> ( new_numeral x ).format '0,0'
#...........................................................................................................
types                     = require '../types'
{ isa
  validate
  declare
  size_of
  type_of }               = types
#...........................................................................................................
require                   '../exception-handler'



#-----------------------------------------------------------------------------------------------------------
show_ranges = ( ranges ) ->
  count = 0
  for range in ranges
    count += range[ 1 ] - range[ 0 ] + 1
  help "found #{format_integer count} glyphs for #{rpr pattern}"
  for range in ranges
    [ first_cid, last_cid, ]  = range
    last_cid                 ?= first_cid
    glyphs                    = []
    for cid in [ first_cid .. ( Math.min first_cid + 10, last_cid ) ]
      glyphs.push String.fromCodePoint cid
    glyphs = glyphs.join ''
    first_cid_hex = "0x#{first_cid.toString 16}"
    last_cid_hex  = "0x#{last_cid.toString 16}"
    count_txt     = format_integer last_cid - first_cid + 1
    help "#{first_cid_hex} .. #{last_cid_hex} #{glyphs} (#{count_txt})"

#-----------------------------------------------------------------------------------------------------------
cid_matches_pattern = ( pattern, cid ) ->
  R = String.fromCodePoint cid
  return R if pattern.test R
  return null

#-----------------------------------------------------------------------------------------------------------
ranges_from_pattern = ( pattern ) ->
  ### TAINT doesn't work for negated expressions like /^[^\p{White_Space}]$/u ###
  R           = []
  range       = null
  first_cid   = 0x0000
  # last_cid    = 0x2ebe0
  last_cid    = 0x10ffff
  cid         = first_cid - 1
  prv_matched = false
  #.........................................................................................................
  while cid < last_cid
    cid += +1
    #.......................................................................................................
    if ( cid_matches_pattern pattern, cid )?
      unless prv_matched
        range = [ cid, ]
        R.push range
      prv_matched = true
    #.......................................................................................................
    else
      if prv_matched
        range.push cid - 1
        range = null
      prv_matched = false
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
# pattern_A   = /^\p{Script=Latin}$/u
# pattern_B   = /^\p{Script_Extensions=Latin}$/u
### see https://github.com/mathiasbynens/regexpu-core/blob/master/property-escapes.md ###
patterns    = []
patterns.push /^\p{Script_Extensions=Latin}$/u
patterns.push /^\p{Script=Latin}$/u
# patterns.push /^\p{Script_Extensions=Cyrillic}$/u
# patterns.push /^\p{Script_Extensions=Greek}$/u
patterns.push /^\p{Unified_Ideograph}$/u
patterns.push /^\p{Script=Han}$/u
patterns.push /^\p{Script_Extensions=Han}$/u
patterns.push /^\p{Ideographic}$/u
patterns.push /^\p{IDS_Binary_Operator}$/u
patterns.push /^\p{IDS_Trinary_Operator}$/u
patterns.push /^\p{Radical}$/u
patterns.push /^\p{White_Space}$/u
patterns.push /^\p{Script_Extensions=Hiragana}$/u
patterns.push /^\p{Script=Hiragana}$/u
patterns.push /^\p{Script_Extensions=Katakana}$/u
patterns.push /^\p{Script=Katakana}$/u
# patterns.push /^\p{Script_Extensions=Hangul}$/u
for pattern in patterns
  show_ranges ranges_from_pattern pattern

info isa.text_with_hiragana 'あいうえおか'
info isa.text_with_hiragana 'あいうえおかx'
info isa.text_with_hiragana 'abc'
info isa.text_hiragana      'あいうえおか'
info isa.text_hiragana      'あいうえおかx'


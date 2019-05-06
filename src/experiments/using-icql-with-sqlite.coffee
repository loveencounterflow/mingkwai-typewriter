

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/EXPERIMENTS/ICQL+SQLITE'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
# FS                        = require 'fs'
PD                        = require 'pipedreams'
{ $
  $async
  select }                = PD
{ assign
  jr }                    = CND
#...........................................................................................................
join_path                 = ( P... ) -> PATH.resolve PATH.join P...
boolean_as_int            = ( x ) -> if x then 1 else 0
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
xrpr2                     = ( x ) -> inspect x, { colors: yes, breakLength: 80,       maxArrayLength: Infinity, depth: Infinity, }
#...........................................................................................................
ICQL                      = require 'icql'
INTERTYPE                 = require '../types'
DB                        = require '../db'

#-----------------------------------------------------------------------------------------------------------
@_prepare_db = ( db ) ->
  db.import_table_unames()
  db.import_table_uname_tokens()
  db.import_table_unicode_test()
  db.create_view_unicode_test_with_end_markers()
  db.fts5_create_and_populate_token_tables()
  db.spellfix_create_editcosts()
  db.spellfix_create_and_populate_token_tables()
  db.spellfix_populate_custom_codes()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@demo_fts5_token_phrases = ( db ) ->
  #.........................................................................................................
  whisper '-'.repeat 108
  urge 'demo_fts5_token_phrases'
  token_phrases = [
    'latin alpha'
    'latin alpha small'
    'latin alpha capital'
    'greek alpha'
    'greek alpha small'
    'cyrillic small a'
    ]
  for q in token_phrases
    urge rpr q
    info ( xrpr row ) for row from db.fts5_fetch_uname_token_matches { q, limit: 5, }
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@demo_fts5_broken_phrases = ( db ) ->
  #.........................................................................................................
  whisper '-'.repeat 108
  urge 'demo_fts5_broken_phrases'
  cache           = {}
  broken_phrases  = [
    'latn alp'
    'latn alp smll'
    'latn alp cap'
    'greek alpha'
    'cap greek alpha'
    'greek alpha small'
    'cyrillic small a'
    'ktkn'
    'katakana'
    'hirag no'
    'no'
    'xxx'
    'istanbul'
    'capital'
    'mycode'
    '123'
    '^'
    '´'
    '`'
    '"'
    '~'
    '~ a'
    '~ a small'
    '~ a capital'
    '_'
    '-'
    '~~'
    '%'
    '_'
    '~~'
    '%'
    '%0'
    '%0 sign'
    'kxr'
    'kxr tree'
    'n14 circled'
    'circled n14'
    'fourteen circled'
    '- l'
    ]
  ### TAINT `initials` should be in `db.$.settings` ###
  initials  = 2
  tokens    = []
  for broken_phrase in broken_phrases
    #.......................................................................................................
    for attempt in broken_phrase.split /\s+/
      if ( hit = cache[ attempt ] ) is undefined
        hit               = db.$.first_value db.match_uname_tokens_spellfix { q: attempt, initials, limit: 1, }
        cache[ attempt ]  = hit ? null
        # debug '27762', attempt, hit
      tokens.push hit if hit?
    #.......................................................................................................
    debug tokens
    if tokens.length < 1
      warn "no token matches for #{rpr broken_phrase}"
      continue
    #.......................................................................................................
    q = tokens.join ' '
    tokens.length = 0
    #.......................................................................................................
    urge ( CND.white broken_phrase ), ( CND.grey '-->' ), ( CND.orange rpr q )
    info ( xrpr row ) for row from db.fts5_fetch_uname_token_matches { q, limit: 5, }
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@demo_uname_tokens = ( db ) ->
  info ( xrpr row ) for row from db.$.query """select * from uname_tokens;"""

#-----------------------------------------------------------------------------------------------------------
@demo_spellfix = ( db ) ->
  whisper '-'.repeat 108
  urge 'demo_spellfix'
  # info ( xrpr row ) for row from db.$.query 'select * from spellfix_editcosts;'
  # db.$.execute """update spellfix_uname_tokens_vocab set k2 = upper( word );"""
  # db.$.execute """update spellfix_uname_tokens_vocab set k2 = 'CDACM';"""
  # info ( xrpr row ) for row from db.$.query """select * from spellfix_uname_tokens_vocab where word regexp '^[^0-9]' limit 30;"""
  words = [
    # 'were'
    # 'whether'
    # 'whater'
    # 'thosand'
    # 'fancy'
    # 'fort'
    # 'trof'
    # 'latn'
    # 'cap'
    # 'letr'
    # 'alif'
    # 'hirag'
    # 'hrg'
    # 'hrgn'
    # 'cyr'
    # 'grk'
    # 'grek'
    # 'no'
    # 'kata'
    # 'katak'
    # 'ktkn'
    # 'katkn'
    # 'ktkna'
    # 'ktakn'
    # 'standard'
    # 'hiero'
    # 'egt'
    'egyp'
    'hgl'
    'xxx'
    'istanbul'
    'capital'
    'mycode'
    '123'
    '^'
    '´'
    '`'
    '"'
    '~'
    '_'
    '-'
    '~~'
    '%'
    '_'
    '~~'
    '%'
    '%0'
    'kxr'
    ]
  ### TAINT `initials` should be in `db.$.settings` ###
  initials = 2
  t0 = Date.now()
  for q in words
    qphonehash = db.$.first_value db.get_spellfix1_phonehash { q, }
    # for row from db.match_uname_tokens_spellfix_with_scores { q, initials, limit: 15, }
    #   debug '----', q, 'I', initials, 'S', row.score, 'L', row.matchlen, 'D', row.distance, row.source, row.qphonehash, row.wphonehash, row.word
    hits = db.$.all_first_values db.match_uname_tokens_spellfix { q, initials, limit: 5, }
    hits = hits.join ', '
    info "#{q} (#{qphonehash}) --> #{hits}"
  t1  = Date.now()
  dt  = t1 - t0
  tps = dt / words.length
  urge "took #{dt} ms (#{tps.toFixed 1} ms per search)"
  return null

#-----------------------------------------------------------------------------------------------------------
@demo_json = ( db ) ->
  whisper '-'.repeat 108
  urge 'demo_json'
  info db.$.all_rows db.$.query """
    select
        x.words                       as words,
        json_array_length ( x.words ) as word_count
      from ( select
        json( get_words( 'helo world these are many words' ) ) as words ) as x
    ;"""
  whisper '---------------------------------------------'
  info row for row from db.$.query """
    select
        id,
        -- key,
        type,
        value
      from json_each( json( get_words( 'helo world these are many words' ) ) )
    ;"""
  whisper '---------------------------------------------'
  info row for row from db.$.query """
    select
        id,
        -- key,
        type,
        value
      from json_each( json( '[1,1.5,1e6,true,false,"x",null,{"a":42},[1,2,3]]' ) )
    ;"""
  whisper '---------------------------------------------'
  info row for row from db.$.query """
    select json_group_array( names.name )
      from (
        select null as name where false   union all
        select 'alice'                    union all
        select 'bob'                      union all
        select 'carlito'                  union all
        select 'domian'                   union all
        select 'franz'                    union all
        select null where false
        ) as names
    ;"""
  whisper '---------------------------------------------'
  info rpr JSON.parse db.$.first_value db.$.query """
    select
        json_group_object( staff.name, staff.extension ) as staff
      from (
        select null as name, null as extension where false  union all
        select 'alice',   123                               union all
        select 'bob',     150                               union all
        select 'carlito', 177                               union all
        select 'domian',  204                               union all
        select 'franz',   231                               union all
        select null, null where false
        ) as staff
    ;"""
  whisper '---------------------------------------------'
  info xrpr row for row from db.$.query """
    select
        id                            as nr,
        replace( fullkey, '$', '' )   as path,
        key                           as key,
        atom                          as value
      from json_tree( json( '[1,1.5,1e6,true,false,"x",null,{"a":42,"c":[1,{"2":"sub"},3]}]' ) ) as t
      where t.fullkey != '$'
    ;"""
  return null

#-----------------------------------------------------------------------------------------------------------
@demo_catalog = ( db ) ->
  for row from db.$.catalog()
    entry = []
    entry.push CND.grey   row.type
    entry.push CND.white  row.name
    entry.push CND.yellow "(#{row.tbl_name})" if row.name isnt row.tbl_name
    info entry.join ' '
  return null

#-----------------------------------------------------------------------------------------------------------
@demo_db_type_of = ( db, name ) ->
  return db.$.type_of name
  # for row from db.$.catalog()
  #   return row.type if row.name is name
  # return null

#-----------------------------------------------------------------------------------------------------------
@demo_longest_matching_prefix = ( db ) ->
  count = db.$.first_value db.$.query """select count(*) from uname_tokens;"""
  info "selecting from #{count} entries in uname_tokens"
  probes = [
    'gr'
    'alpha'
    'beta'
    'c'
    'ca'
    'cap'
    'capi'
    'omega'
    'circ'
    'circle'
    ]
  for probe in probes
    info ( CND.grey '--------------------------------------------------------' )
    nr = 0
    #.......................................................................................................
    for row from db.longest_matching_prefix_in_uname_tokens { q: probe, limit: 10, }
      nr += +1
      # info probe, ( xrpr row )
      info ( CND.grey nr ), ( CND.grey row.delta_length ), ( CND.blue probe ), ( CND.grey '->' ), ( CND.lime row.uname_token )
    #.......................................................................................................
    table = 'uname_tokens'
    field = 'uname_token'
    chrs  = Array.from db.$.first_value db.next_characters { prefix: probe, table, field, }
    info probe, '...', ( chrs.join ' ' )
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@demo_nextchr = ( db ) ->
  #.........................................................................................................
  # whisper '-'.repeat 108
  # for row from db.$.query """select * from unicode_test;"""
  #   info ( xrpr row )
  #.........................................................................................................
  whisper '-'.repeat 108
  probes = [
    '-'
    'っ'
    'か'
    '\\'
    'ku'
    'a'
    'x' ]
  # table = 'unicode_test'
  table = 'unicode_test_with_end_markers'
  field = 'word'
  for probe in probes
    chrs  = Array.from db.$.first_value db.next_characters { prefix: probe, table, field, }
    info probe, '...', ( chrs.join ' ' )
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@demo_edict2u = ( db ) ->
  # debug INTERTYPE.all_keys_of db.$
  db.create_table_edict2u()
  console.time 'populate-edict2u'
  path = join_path __dirname, '../../.cache/edict2u.sql'
  help "reading #{PATH.relative process.cwd(), path}"
  db.$.read path
  help "creating indexes"
  db.create_indexes_for_table_edict2u()
  console.timeEnd 'populate-edict2u'
  probes = [
    'ち'
    'ちゅ'
    'ちゅう'
    'ちゅうご'
    'ちゅうごく'
    'ちゅうごくの'
    'ちゅうごくのせ'
    'ちゅうごくのせい'
    'ちゅうごくのせいふ'
    ]
  limit = 10
  for probe in probes
    whisper '-'.repeat 108
    info probe
    nr = 0
    for row from db.longest_matching_prefix_in_edict2u { q: probe, limit, }
      nr += +1
      info ( CND.grey nr ), ( CND.grey row.delta_length ), ( CND.grey '->' ), ( CND.lime row.candidate ), ( CND.white row.reading )
  # for row from db.$.query "select * from edict2u where reading like 'ちゅうごく%' order by reading limit 5;"
  #   info row.candidate
  #.........................................................................................................
  return null



############################################################################################################
unless module.parent?
  DEMO = @
  do ->
    db = DB.new_db { clear: false, }
    # db = DB.new_db { clear: true, }
    # DEMO._prepare_db db
    # db = await DEMO.new_db()
    # DEMO.demo_uname_tokens db
    # DEMO.demo_fts5_token_phrases     db
    # urge '33342', db.$.first_value db.$.query """select plus( 34, 56 );"""
    # urge '33342', db.$.first_value db.$.query """select e( plus( 'here', 'there' ) );"""
    # info row for row from db.$.query """
    #   select split( 'helo world whassup', s.value ) as word
    #   from generate_series( 1, 10 ) as s
    #   where word is not null
    #   ;
    #   """
    # DEMO.demo_spellfix                 db
    # DEMO.demo_fts5_broken_phrases      db
    # DEMO.demo_json                     db
    DEMO.demo_catalog                  db
    info 'µ33344', rpr DEMO.demo_db_type_of db, 'edict2u'
    info 'µ33344', rpr DEMO.demo_db_type_of db, 'xxx'
    # DEMO.demo_longest_matching_prefix  db
    # DEMO.demo_edict2u                  db
    # DEMO.demo_nextchr                  db
    return null



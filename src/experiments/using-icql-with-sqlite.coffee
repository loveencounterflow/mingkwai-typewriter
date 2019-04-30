

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'IME/EXPERIMENTS/ICQL+SQLITE'
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

#-----------------------------------------------------------------------------------------------------------
@get_settings = ->
  ### TAINT path within node_modules might differ ###
  ### TAINT extensions should conceivably be configured in `*.icql` file or similar ###
  # R.db_path   = join_path __dirname, '../../db/data.db'
  R                 = {}
  R.connector       = require 'better-sqlite3'
  R.sqlitemk_path   = join_path __dirname, '../../../../sqlite-for-mingkwai-ime'
  R.db_path         = join_path __dirname, '../../src/experiments/using-intercourse-with-sqlite.db'
  R.icql_path       = join_path __dirname, '../../src/experiments/using-intercourse-with-sqlite.icql'
  return R

#-----------------------------------------------------------------------------------------------------------
@new_db = ->
  settings  = @get_settings()
  db        = ICQL.bind settings
  # db        = await ICQL.bind settings
  db.$.load join_path settings.sqlitemk_path, 'extensions/csv.so'
  db.$.load join_path settings.sqlitemk_path, 'extensions/spellfix.so'
  db.$.load join_path settings.sqlitemk_path, 'extensions/regexp.so'
  db.$.load join_path settings.sqlitemk_path, 'extensions/series.so'
  db.$.load join_path settings.sqlitemk_path, 'extensions/nextchar.so'
  # db.$.load join_path settings.sqlitemk_path, 'extensions/stmt.so'
  db.$.pragma 'foreign_keys = on'
  db.$.pragma 'synchronous = off' ### see https://sqlite.org/pragma.html#pragma_synchronous ###
  # info row for row in db.$.all_rows db.$.catalog()
  clear_count = db.$.clear()
  info "deleted #{clear_count} objects"
  @create_db_functions db
  # @add_functions db
  db.import_table_unames()
  db.import_table_uname_tokens()
  db.import_table_unicode_test()
  db.create_view_unicode_test_with_end_markers()
  db.fts5_create_and_populate_token_tables()
  db.spellfix_create_editcosts()
  db.spellfix_create_and_populate_token_tables()
  db.spellfix_populate_custom_codes()
  return db

#-----------------------------------------------------------------------------------------------------------
@create_db_functions = ( db ) ->
  # db.$.function 'add_spellfix_confusable', ( a, b ) ->
  # db.$.function 'spellfix1_phonehash', ( x ) ->
  #   debug '23363', x
  #   return x.toUpperCase()
  #.........................................................................................................
  db.$.function 'echo', { deterministic: false, varargs: true }, ( P... ) ->
    urge ( CND.grey 'DB' ), P...
    return null
  #.........................................................................................................
  db.$.function 'e', { deterministic: false, varargs: false }, ( x ) ->
    urge ( CND.grey 'DB' ), rpr x
    return x
  #.........................................................................................................
  db.$.function 'plus', { deterministic: true, varargs: false }, ( a, b ) ->
    debug '33444', a, b
    return a + b
  #.........................................................................................................
  db.$.function 'contains_word', { deterministic: true, varargs: false }, ( text, probe ) ->
    return if ( ( ' ' + text + ' ' ).indexOf ' ' + probe + ' ' ) > -1 then 1 else 0
  #.........................................................................................................
  db.$.function 'get_words', { deterministic: true, varargs: false }, ( text ) ->
    JSON.stringify ( word for word in text.split /\s+/ when word isnt '' )
  #.........................................................................................................
  db.$.function 'get_nth_word', { deterministic: true, varargs: false }, ( text, nr ) ->
    ### NB SQLite has no string aggregation, no string splitting, and in general does not implement
    table-returning user-defined functions (except in C, see the `prefixes` extension). Also, you can't
    modify tables from within a UDF because the connection is of course busy executing the UDF.

    As a consequence, it is well-nigh impossible to split strings to rows in a decent manner. You could
    probably write a 12-liner with a recursive CTE each time you want to split a string. Unnecessary to
    mention that SQLite does not support putting *that* thing into a UDF (because those can't return
    anything except a single atomic value). It's a whack-a-mole game of missing pieces really.

    The only ways out that I can see are either (1) preparing your data in the application code in such a
    way that you never have to perform string splitting in the DB, or else (2) write functions like this
    that accept a regular argument and a counter, query with a reasonable maximum counter value, and discard
    all invalid rows:

    ```sql
    select
        get_nth_word( 'helo world whassup', gs.value ) as word
      from generate_series( 1, 10 ) as gs
      where word is not null;
    ```

    Performance of this particular function could be improved by adding a small, short-lived cache, but I
    guess that will be counterproductive as long as the texts to split are unlikely to contain more than a
    very few words.

    **Update** Turns out the `json1` extension can help out:

    ```coffee
    db.$.function 'get_words', { deterministic: true, varargs: false }, ( text ) ->
      JSON.stringify ( word for word in text.split /\s+/ when word isnt '' )
    ```

    ```sql
    select
        id    as nr,
        value as word
      from
        json_each(
          json(
            get_words( 'helo world these are many words' ) ) );
    ```


    ###
    parts = text.split /\s+/
    return parts[ nr - 1 ] ? null
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
  console.timeEnd 'populate-edict2u'
  #.........................................................................................................
  return null



############################################################################################################
unless module.parent?
  IME = @
  do ->
    db = IME.new_db()
    # db = await IME.new_db()
    # IME.demo_uname_tokens db
    # IME.demo_fts5_token_phrases     db
    # urge '33342', db.$.first_value db.$.query """select plus( 34, 56 );"""
    # urge '33342', db.$.first_value db.$.query """select e( plus( 'here', 'there' ) );"""
    # info row for row from db.$.query """
    #   select split( 'helo world whassup', s.value ) as word
    #   from generate_series( 1, 10 ) as s
    #   where word is not null
    #   ;
    #   """
    # IME.demo_spellfix                 db
    # IME.demo_fts5_broken_phrases      db
    # IME.demo_json                     db
    # IME.demo_catalog                  db
    # IME.demo_longest_matching_prefix  db
    IME.demo_edict2u                  db
    # IME.demo_nextchr                  db
    return null



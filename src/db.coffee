

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/DB'
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
INTERTYPE                 = require './types'


#-----------------------------------------------------------------------------------------------------------
@get_settings = ->
  ### TAINT path within node_modules might differ ###
  ### TAINT extensions should conceivably be configured in `*.icql` file or similar ###
  # R.db_path   = join_path __dirname, '../../db/data.db'
  R                 = {}
  R.connector       = require 'better-sqlite3'
  R.sqlitemk_path   = join_path __dirname, '../../../sqlite-for-mingkwai-ime'
  R.db_path         = join_path __dirname, '../src/experiments/using-intercourse-with-sqlite.db'
  R.icql_path       = join_path __dirname, '../src/experiments/using-intercourse-with-sqlite.icql'
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
  # clear_count = db.$.clear()
  # info "deleted #{clear_count} objects"
  @create_db_functions db
  # db.import_table_unames()
  # db.import_table_uname_tokens()
  # db.import_table_unicode_test()
  # db.create_view_unicode_test_with_end_markers()
  # db.fts5_create_and_populate_token_tables()
  # db.spellfix_create_editcosts()
  # db.spellfix_create_and_populate_token_tables()
  # db.spellfix_populate_custom_codes()
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





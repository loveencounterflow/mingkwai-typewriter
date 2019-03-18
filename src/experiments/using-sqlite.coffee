

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
PATH                      = require 'path'
PD                        = require 'pipedreams'
{ $
  $async
  select }                = PD
{ assign
  jr }                    = CND


# db_path   = PATH.resolve PATH.join __dirname, '../../db/data.db'
Database      = require 'better-sqlite3'
sqlitemk_path = PATH.resolve PATH.join __dirname, '../../../../sqlite-for-mingkwai-ime'
db_path       = PATH.join sqlitemk_path, 'experiments/demo-amatch.db'
db            = new Database db_path, { verbose: urge }
db.loadExtension PATH.join sqlitemk_path, 'extensions/amatch.so'

source    = PD.new_push_source()
pipeline  = []
pipeline.push source
pipeline.push PD.$show()
pipeline.push PD.$drain()
PD.pull pipeline...

as_int = ( x ) -> if x then 1 else 0

#-----------------------------------------------------------------------------------------------------------
db.function 'matches', { deterministic: true, }, ( text, pattern ) ->
  return as_int ( text.match new RegExp pattern )?

#-----------------------------------------------------------------------------------------------------------
db.function 'regexp_replace', { deterministic: true, }, ( text, pattern, replacement ) ->
  return text.replace ( new RegExp pattern, 'g' ), replacement

#-----------------------------------------------------------------------------------------------------------
db.function 'cleanup_texname', { deterministic: true, }, ( text ) ->
  R = text
  R = R.replace /\\/g,    ''
  R = R.replace /[{}]/g,  '-'
  R = R.replace /-+/g,    '-'
  R = R.replace /^-/g,    ''
  R = R.replace /-$/g,    ''
  R = R.replace /'/g,     'acute'
  return R

r = ( strings ) -> return [ 'run',   ( strings.join '' ), ]
q = ( strings ) -> return [ 'query', ( strings.join '' ), ]


sqls = [
  # q""".tables"""
  r"""drop view if exists xxx;"""
  q"""select * from amatch_vtable
  where true
    and ( distance <= 100 )
    -- and ( word match 'abc' )
    -- and ( word match 'xxxx' )
    -- and ( word match 'cat' )
    -- and ( word match 'dog' )
    -- and ( word match 'television' )
    -- and ( word match 'treetop' )
    -- and ( word match 'bath' )
    -- and ( word match 'kat' )
    and ( word match 'laern' )
    -- and ( word match 'wheather' )
    -- and ( word match 'waether' )
    ;"""
  # r"""create view xxx as select
  #     "UNICODE DESCRIPTION"     as uname,
  #     latex                     as latex,
  #     cleanup_texname( latex )  as texname
  #   from unicode_entities
  #   where true
  #     and ( not matches( latex, '^\\s*$' ) );"""
  # q"""select * from xxx limit 2500;"""
  q"""select sqlite_version();"""
  ]

for [ mode, sql, ] in sqls
  urge sql
  try
    statement = db.prepare sql
  catch error
    whisper '-'.repeat 108
    warn "when trying to prepare statement"
    info sql
    warn "an error occurred:"
    info error.message
    whisper '-'.repeat 108
    throw error
  switch mode
    when 'run'
      debug statement.run()
    when 'query'
      source.send row for row from statement.iterate()
    else
      throw new Error "µ09202 unknown mode #{rpr mode}"



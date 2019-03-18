

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/DB'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
alert                     = CND.get_logger 'alert',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND

#...........................................................................................................
# db                        =
#   ### TAINT value should be cast by PTV reader ###
#   host:       '/var/run/postgresql'
#   port:       5432
#   database:   'mojikura'
#   user:       'mojikura'
# #...........................................................................................................
# pool                      = new ( require 'pg' ).Pool db
# #...........................................................................................................
# # require './exception-handler'
# #...........................................................................................................
# assign                    = Object.assign
# has_duplicates            = ( x ) -> ( new Set x ).size != x.length
# last_of                   = ( x ) -> x[ x.length - 1 ]
# keys_of                   = Object.keys


# #-----------------------------------------------------------------------------------------------------------
# @_get_query_object = ( q, settings... ) ->
#   switch type = CND.type_of q
#     when 'pod'
#       return assign {}, q, settings...
#     when 'text'
#       text    = q
#       values  = null
#     when 'list'
#       [ text, values..., ] = q
#     else throw new Error "expected a text or a list, got a #{type}"
#   return assign { text, values, }, settings...

#-----------------------------------------------------------------------------------------------------------
@query = ( q, settings... ) ->
  debug 'DB.query', q, settings
  return []

#   ### TAINT since this method uses `pool.query`, transactions across more than a single call will fail.
#   See https://node-postgres.com/features/transactions. ###
#   #.........................................................................................................
#   ### `result` is a single object with some added data or a list of such objects in the case of a multiple
#   query; we reduce the latter to the last item: ###
#   try
#     result = await pool.query @_get_query_object q, settings...
#   catch error
#     warn "an exception occurred when trying to query #{rpr db} using"
#     warn q
#     throw error
#   #.........................................................................................................
#   result = if CND.isa_list result then ( last_of result ) else result
#   #.........................................................................................................
#   ### We return an empty list in case the query didn't return anything: ###
#   return [] unless result?
#   #.........................................................................................................
#   ### We're only interested in the list of rows; again, if that list is empty, or it's a list of lists
#   (when `rowMode: 'array'` was set), we're done: ###
#   R = result.rows
#   return [] if R.length is 0
#   return R if CND.isa_list R[ 0 ]
#   #.........................................................................................................
#   ### Otherwise, we've got a non-empty list of row objects. If the query specified non-unique field names,
#   than like field names will clobber each other. To avoid silent failure, we chack for duplicates and
#   matching lengths of metadata and actual rows: ###
#   keys = ( field.name for field in result.fields )
#   #.........................................................................................................
#   if ( has_duplicates keys ) or ( keys.length != ( keys_of R[ 0 ] ).length )
#     error       = new Error "detected duplicate fieldnames: #{rpr keys}"
#     error.code  = 'fieldcount mismatch'
#     throw error
#   #.........................................................................................................
#   return ( assign {}, row for row in R )

# #-----------------------------------------------------------------------------------------------------------
# @query_lists = ( q, settings... ) ->
#   return await @query q, { rowMode: 'array', }, settings...

# #-----------------------------------------------------------------------------------------------------------
# @query_one = ( q, settings... ) ->
#   rows = await @query q, settings...
#   throw new Error "expected exactly one result row, got #{rows.length}" unless rows.length is 1
#   return rows[ 0 ]

# #-----------------------------------------------------------------------------------------------------------
# @query_one_list = ( q, settings... ) ->
#   return await @query_one q, { rowMode: 'array', }, settings...

# #-----------------------------------------------------------------------------------------------------------
# @query_single = ( q, settings... ) ->
#   R = await @query_one_list q, settings...
#   throw new Error "expected row with single value, got on with #{rows.length} values" unless R.length is 1
#   return R[ 0 ]

# #-----------------------------------------------------------------------------------------------------------
# @perform = ( q, settings... ) ->
#   { text, values, } = @_get_query_object q
#   lego  = ''
#   lego += 'ð' while ( text.indexOf lego ) >= 0
#   text += ';' unless text.endsWith ';'
#   text  = "do $#{lego}$ begin perform #{text} end; $#{lego}$;"
#   return await @query { text, values, }, settings...



# ############################################################################################################
# unless module.parent?
#   DB = @
#   do ->
#     info '01', await DB.query        'select 42 as a, 108 as b;'
#     info '02', await DB.query_one    'select 42 as a, 108 as b;'
#     info '03', await DB.query_lists  'select 42 as a, 108 as b;'
#     help '------------------------------------------------------------------------------------------'
#     try
#       info '04', await DB.query        'select 42, 108;'
#     catch error
#       throw error unless error.code is 'fieldcount mismatch'
#       warn error.message
#     help '------------------------------------------------------------------------------------------'
#     info '05', await DB.query            'select 42, 108;', rowMode: 'array'
#     info '06', await DB.query_lists      'select 42, 108;'
#     info '07', await DB.query_one_list   'select 42, 108;'
#     info '08', await DB.query_single     'select 42;'
#     help '------------------------------------------------------------------------------------------'
#     info '09', await DB.query            'select 42; select 108;'
#     info '10', await DB.query            'do $$ begin perform log( $a$helo$a$ ); end; $$;'
#     info '11', await DB.perform          'log( $$helo$$ );'
#     info '12', await DB.perform          'log( $ððð$helo$ððð$ );'




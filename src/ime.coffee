

'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/IME'
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
PATH                      = require 'path'
#...........................................................................................................
# parallel                  = require './parallel-promise'
DB                        = require './db'
#...........................................................................................................
# _format                   = require 'pg-format'
# I                         = ( value ) -> _format '%I', value
# L                         = ( value ) -> _format '%L', value
#...........................................................................................................
{ jr, }                   = CND
PD                        = require 'pipedreams'
{ remote, }               = require 'electron'
IF                        = require 'interflug'
XE                        = remote.require './xemitter'

XE.listen_to_all ( key, d ) ->
  debug       'µ21112-1', 'renderer', jr d
  console.log 'µ21112-2', 'renderer', jr d


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@query_for_regex_terms = ( S, text, offset, limit ) ->
  urge 'µ33377'
  urge 'µ33377', "#{process.type} process PID #{process.pid}" #, "window ID", await IF.wait_for_window_id_from_pid process.pid
  browser_window_id = await IF.wait_for_window_id_from_pid remote.process.pid
  urge 'µ33377', "#{remote.process.type} remote.process PID #{remote.process.pid}", "window ID", browser_window_id
  # debug 'µ38733', rpr text
  # debug 'µ33773', remote.getCurrentWindow()
  # # debug 'µ33773', ( k for k of remote.getCurrentWindow() )
  # # debug 'µ33773', ( k for k of remote.getGlobal() )
  # win = remote.getCurrentWindow()
  # win.setTitle 'helo world'
  # state = remote.require './state'
  ### TAINT don't use `global`, use module-level attribute, XEmitter ###
  # XE.emit PD.new_event '^test-event', 42
  if ( shared = remote.getGlobal 'shared' )?
    warn 'µ46632', shared.foo
    warn 'µ46632', shared.main.pid
    warn 'µ46632', "Window ID (1)", shared.main.wid
  return

  ##########################################################################################################
  ##########################################################################################################
  ##########################################################################################################
  terms     = ( term for term in text.split /\s+/ when term isnt '' )
  if S.bind_left or S.bind_right
    prefix = if S.bind_left   then '^' else ''
    suffix = if S.bind_right  then '$' else ''
    terms  = ( prefix + term + suffix for term in terms )
  R         = []
  R.push "select distinct"
  R.push "    -- e1.nr                                                         as nr,"
  R.push "    -- e1.source                                                     as source,"
  R.push "    e1.iclabel                                                    as iclabel,"
  R.push "    regexp_replace( e1.iclabel, ':.$', '' )                       as short_iclabel,"
  R.push "    e1.glyph                                                      as glyph,"
  R.push "    string_agg( e1.value, ' ' ) over w                            as value"
  R.push "  from IME.entries as e1"
  for term, idx in terms
    nr = idx + 2
    R.push "  join IME.entries as e#{nr} on ( e1.iclabel = e#{nr}.iclabel )"
  R.push "  where true                                                    "
  for term, idx in terms
    nr = idx + 2
    R.push "    and ( e#{nr}.value ~ #{L term} )"
  R.push "  window w as ( partition by e1.iclabel"
  R.push "    order by e1.source"
  R.push "    range between unbounded preceding and unbounded following )"
  R.push "  offset #{offset} limit #{limit};"
  return R.join '\n'



#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@fetch_rows = ( S, text ) ->
  # S.query  = S.keys.join ''
  # S.query  = '^' + S.query        if S.bind_left
  # S.query  =       S.query + '$'  if S.bind_right
  offset    = S.page_idx * S.page_height
  S.query   = @query_for_regex_terms S, text, offset, S.page_height
  # debug 'µ77633', S.query
  t0        = Date.now()
  try
    S.rows    = await DB.query S.query
    S.qdt     = Date.now() - t0
  catch error
    switch error.code
      when '2201B'
        warn "illegal regex #{rpr S.query}"
        rows = []
      else
        alert rpr error.code
        alert rpr error.name
        alert rpr error.message
        throw error
  @postprocess_rows S
  return null

#-----------------------------------------------------------------------------------------------------------
@postprocess_rows = ( S ) ->
  for row, idx in S.rows
    row.value = row.value.replace /[<>]/g, ''
  null

#-----------------------------------------------------------------------------------------------------------
@on_state_changed = ( S ) ->
  S.page_idx = 0
  S.row_idx  = 0

#-----------------------------------------------------------------------------------------------------------
###
???
XE.listen_to 'IME/input/add', @,
@on_ime_input_add = ( { S, row_idx, chr, } ) ->
  debug "update IME state with input #{chr}"
  # if ( row = S.rows[ S.row_idx ] )?
  #   S.buffer.push row.glyph
  #   CLIPBOARD.write S.buffer.join ''
  # S.keys.length = 0
  # S.query      = null
  # return null
###

#-----------------------------------------------------------------------------------------------------------
@announce = ( S, level, P... ) ->
  switch level
    when 'warn' then echo CND.red CND.reverse P...
    when 'help' then help CND.lime P...
    else
      throw new Error "(internal errror) unknown announcement level #{rpr level}"
  return null

#-----------------------------------------------------------------------------------------------------------
@label = ( S, position ) ->
  switch position
    when 'query'
      echo CND.blue ( CND.reverse ' ' + S.query + ' ' )
    when 'page_nr'
      echo CND.blue "page: #{S.page_idx + 1}"
    when 'qdt'
      echo CND.gold "qdt: #{S.qdt}"
    # when 'count' then help P...
    else
      throw new Error "(internal errror) unknown label position #{rpr label}"
  return null

###
  see https://electronjs.org/docs/api/accelerator
  see https://github.com/avocode/combokeys#readme

  #.........................................................................................................
  debug '45778', rpr key.name ? key.text
  switch key.name ? key.text
    when 'up'               then S.row_idx     = S.row_idx  - 1
    when 'down'             then S.row_idx     = S.row_idx  + 1
    when 'page-up'          then S.page_idx    = S.page_idx - 1
    when 'page-down'        then S.page_idx    = S.page_idx + 1
    when '^'                then S.bind_left   = not S.bind_left
    when '$'                then S.bind_right  = not S.bind_right
    when 'backspace'        then @pop S
    when 'space', 'return'  then @choose S
    else
      if ( /[()\[\]]/ ).test key.text
        @announce S, 'warn', "ignored key #{rpr key.name} #{rpr key.text}"
      else
        text = key.text
        # ## TAINT parametrize fuzzification ##
        if      text in [ 'o', 'u', ]   then text = '(?:o|u)'
        else if text == 'e'             then text = '(?:e|o)'
        @push S, text
  #.........................................................................................................
  S.row_idx  = Math.max 0, S.row_idx
  S.row_idx  = Math.min ( Math.max 0, Math.min S.rows.length - 1, S.page_height - 1 ), S.row_idx
  S.page_idx = Math.max 0, S.page_idx
  S.page_idx = Math.min 100, S.page_idx
  debug '38991', S.row_idx
###

# #-----------------------------------------------------------------------------------------------------------
# @find_matches = ( S, text ) ->
#   # echo CND.clear
#   # echo CND.grey key.name, ( rpr key.text )
#   # return
#   #.........................................................................................................
#   await @fetch_rows S
#   debug '55542-1', rpr S.query
#   if S.rows.length is 0
#     @announce S, 'warn', "no matches for #{rpr S.query}"
#     # S.keys.pop()
#     # [ S.query, S.rows, ] = await @fetch_rows()
#     # debug '55542-2', rpr S.query
#   #.........................................................................................................
#   @label S, 'query'
#   @label S, 'page_nr'
#   @label S, 'qdt'
#   for row, row_idx in S.rows
#     color   = if row_idx == S.row_idx then CND.white else CND.lime
#     iclabel = row.iclabel.replace /:.$/u, ''
#     echo color S.selectors[ row_idx ], iclabel, row.glyph, row.value, row.source, ( row.rank ? '/' )
#   #.........................................................................................................
#   echo CND.plum S.buffer.join ''
#   #.........................................................................................................
#   return null

# @key_handler = @key_handler.bind @

# ############################################################################################################
# unless module.parent?
#   IME       = @
#   help "matching strokeorders"
#   @key_handler { name: null, text: null, }
#   @listen_to_keys IME.key_handler




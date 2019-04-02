

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/OPS-DOCUMENTS'
# debug                     = CND.get_logger 'debug',     badge
# alert                     = CND.get_logger 'alert',     badge
# whisper                   = CND.get_logger 'whisper',   badge
# warn                      = CND.get_logger 'warn',      badge
# help                      = CND.get_logger 'help',      badge
# urge                      = CND.get_logger 'urge',      badge
# info                      = CND.get_logger 'info',      badge
PATH                      = require 'path'
FS                        = require 'fs'


#===========================================================================================================
# DOCUMENTS
#-----------------------------------------------------------------------------------------------------------
@restore_documents = ->
  ### Will be used to restore previous state, open new documents; for now, just opens the default file. ###
  ### TAINT auto-create file when not present ###
  file_path = PATH.resolve PATH.join __dirname, '../.cache/default.md'
  S.codemirror.editor.doc.setValue FS.readFileSync file_path, { encoding: 'utf-8', }
  return null

#-----------------------------------------------------------------------------------------------------------
@save_document = ->
  ### Will be used to save active document; currently just saves default file. ###
  path          = PATH.resolve PATH.join __dirname, '../.cache/default.md'
  relative_path = PATH.relative process.cwd(), path
  @log "µ38873 saving document to #{rpr relative_path}"
  FS.writeFileSync path, S.codemirror.editor.doc.getValue()
  return null

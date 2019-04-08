
'use strict'

#-----------------------------------------------------------------------------------------------------------
@dbg_set_debugging_globals = ->
  global.e      = S.codemirror.editor
  global.left   = jQuery('<span style="color:black;background:green;">(</span>')[0]
  global.right  = jQuery('<span style="color:black;background:red;">)</span>')[0]
  # console.log "loaded #{__filename}"

#-----------------------------------------------------------------------------------------------------------
@dbg_list_all_css_classes_in_document = ->
  ```
  var classes = [];
  jQuery('[class]').each(function(){
      jQuery(jQuery(this).attr('class').split(' ')).each(function() {
          if (this.length>0 && jQuery.inArray(this.valueOf(), classes) === -1) {
              classes.push(this.valueOf());
          }
      });
  });
  console.log("LIST START\n\n"+classes.join('\n')+"\n\nLIST END");
  ```


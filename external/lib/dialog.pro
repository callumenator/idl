;
;+
; NAME:
; 
;	DIALOG
;
; PURPOSE:
; 
;       A popup widget dialog box to get user input. Like
;       WIDGET_MESSAGE, which is better in some cases, but this widget
;       also includes fields and lists.
;
; CATEGORY:
; 
;	Widgets.
;
; CALLING SEQUENCE:
;
;	Result = DIALOG([TEXT])
;
; OPTIONAL INPUTS:
; 
;	TEXT - The label seen by the user.
;	
; KEYWORD PARAMETERS:
; 
;   There are 6 types of dialogs, each with unique behavior.  With
;   each default dialog type are associated buttons; these buttons can
;   be overridden with the BUTTONS keyword, except in the case of the
;   LIST and FIELD dialogs.
;
;       One of the following six keywords MUST be set:
;
;       ERROR - Display an error message; default BUTTONS =
;               ['Abort','Continue']
;
;       WARNING - Display a warning message.  default BUTTONS = ['OK']
;
;       INFO - Display an informational message; 
;              default BUTTONS = ['Cancel','OK']
; 
;       QUESTION - Ask a question.  default BUTTONS =
;                  ['Cancel','No','Yes']
;
;       LIST - Get a selection from a list of choices.  default
;              BUTTONS = ['Cancel','OK'] Must specify CHOICES = string
;              array of list choices.
;
;              Set the RETURN_INDEX keyword to cause the returned
;	       value to be the zero-based index of the selected
;	       list item.  
;
;       FIELD - Get user input, using CW_FIELD.  default BUTTONS =
;               ['Cancel','OK']. FLOAT, INTEGER, LONG, and STRING
;               keywords apply here, as does the VALUE keyword to set
;               an initial value.
;
;   GROUP - Group leader keyword.
;
;   TITLE - title of popup widget.
;	
; COMMON BLOCKS:
;
;       DIALOG
;
; OUTPUTS:
; 
;       In the case of LIST or FIELD dialogs, this function returns
;       the selected list element or the user input, respectively.
;       Otherwise, this function returns the name of the pressed
;       button.
;
; EXAMPLE:
; 
;	1. Create a QUESTION DIALOG widget.
;
;       D = DIALOG(/QUESTION,'Do you want to continue?')
;
;       2. Get the user to enter a number.
;
;       D = DIALOG(/FLOAT,VALUE=3.14159,'Enter a new value for pi.')
; 
;       3. Get the user to choose from a list of options.
;
;       D = DIALOG(/LIST,CHOICES=['Snoop','Doggy','Dog'])
;
; MODIFICATION HISTORY:
; 
;       David L. Windt, Bell Labs, March 1997
;
;       May 1997 - Added GROUP keyword, and modified use of MODAL
;                  keyword to work with changes in IDL V5.0
;                  
;       windt@bell-labs.com
;-

pro dialog_event,event
common dialog,selection,fieldid,cho,listid,listindex
on_error,0

; get uvalue of this event
widget_control,event.id,get_uvalue=uvalue

case uvalue of 

    'list': begin
        if listindex then selection=event.index else selection=cho(event.index)
        ;; if user double-clicks, then we're done:
        if event.clicks ne 2 then return
    end

    'field': begin
        widget_control,fieldid,get_value=selection
        return
    end

    'buttons': begin
        case 1 of

            ;; field widget?
            widget_info(fieldid,/valid): if (event.value eq 'Cancel') then  $
              selection=event.value else  $
              widget_control,fieldid,get_value=selection

            ;; list widget?
            widget_info(listid,/valid): begin
                if (event.value eq 'Cancel') then begin
                    if listindex then selection=-1 else selection=event.value 
                endif else begin
                    id=widget_info(listid,/list_select)
                    if listindex then selection=id else begin
                        if id ge 0 then selection=cho(id) else selection='Cancel'
                    endelse
                endelse
            end

            else: selection=event.value

        endcase
    end

endcase
widget_control,event.top,/destroy
return
end

function dialog,text,buttons=buttons, $
                error=error,warning=warning,info=info,question=question, $
                field=field,float=float,integer=integer, $
                long=long,string=string,value=value, $
                list=list,choices=choices,return_index=return_index, $
                title=title,group=group
common dialog
on_error,2

; set the list and field widget id's to zero, in case
; they've already been defined from a previous instance of dialog.
fieldid=0L
listid=0L
listindex=keyword_set(return_index)

if keyword_set(title) eq 0 then title='User Dialog'

; make widget base:
if keyword_set(group) eq 0 then group=0L
if (strmid(!version.release,0,1) eq '5') and $
  widget_info(long(group),/valid) then $
  base=widget_base(title=title,/column,/base_align_center,/modal,group=group) $
else base=widget_base(title=title,/column,/base_align_center) 

if keyword_set(float) then field=1
if keyword_set(integer) then field=1
if keyword_set(long) then field=1
if keyword_set(string) then field=1
if n_elements(value) eq 0 then value=0
if n_elements(choices) gt 0 then list=1

; widget configuration depends on type of dialog:
case 1 of
    keyword_set(error):begin
        if n_params() eq 0 then text='Error' else $
          text='Error: '+text
        label=widget_label(base,value=text,frame=0)
        if keyword_set(buttons) eq 0 then buttons=['Abort','Continue']
    end
    keyword_set(warning):begin
        if n_params() eq 0 then text='Warning' else $
          text='Warning: '+text
        label=widget_label(base,value=text,frame=0)
        if keyword_set(buttons) eq 0 then buttons=['OK']
    end
    keyword_set(info):begin
        if n_params() eq 0 then text=' '
        label=widget_label(base,value=text,frame=0)
        if keyword_set(buttons) eq 0 then buttons=['Cancel','OK']
    end
    keyword_set(question):begin
        if n_params() eq 0 then text='Question?' 
        label=widget_label(base,value=text,frame=0)
        if keyword_set(buttons) eq 0 then buttons=['Cancel','No','Yes']
    end
    keyword_set(field):begin
        isfield=1
        if n_params() eq 0 then text='Input: ' 
        sz=size(value)
        if keyword_set(string) and (sz(1) ne 7) then value=strtrim(value)
        fieldid=cw_field(base,title=text, $
                       uvalue='field', $  
                       value=value, $
                       /return_events, $
                       float=keyword_set(float), $
                       integer=keyword_set(integer), $
                       long=keyword_set(long), $
                       string=keyword_set(string))
        buttons=['Cancel','OK']
    end
    keyword_set(list):begin
        if keyword_set(choices) eq 0 then $
          message,'Must supply an array of choices for the list.'
        cho=choices
        if n_params() eq 0 then text='Choose: '
        label=widget_label(base,value=text,frame=0)
        listid=widget_list(base,value=choices, $
                           ysize=n_elements(choices) < 10, $
                           uvalue='list')
        buttons=['Cancel','OK']
        cho=choices             ; set common variable for event handler.
    end
endcase
; make widget buttons:
bgroup=cw_bgroup(base,/row,buttons,uvalue='buttons',/return_name)

; realize widget:
widget_control,base,/realize

; manage widget:
if (strmid(!version.release,0,1) eq '5') and  $
  widget_info(long(group),/valid) then $
  xmanager,'dialog',base,group=group  $
else xmanager,'dialog',base,/modal

; return selection:
return,selection
end




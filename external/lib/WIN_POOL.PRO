;==========================================================================================
;
; >>>> McObject Class: win_pool
;
; This file contains the McObject method code for win_pool objects. These objects 
; are used to maintain a "pool" of windows, addressable by name:
;
; Mark Conde (Mc), Bromley, August 1999.

;==========================================================================================
; This is the (required) "new" method for this McObject:

pro win_pool_new, instance, dynamic=dyn, creator=cmd
common winpool, winpool
    if not(keyword_set(dyn)) then dyn = 'None'
    if dyn eq ''             then dyn = 'None'
    obj_dquote, dyn, ddn
    
;   First, properties specific to this object:
    cmd = 'instance = {win_pool, '
    cmd = cmd +            'index: -1, '
    cmd = cmd +      '       name: ''Silly_one_that_nobody_will_use_(I_hope)'', '
    cmd = cmd +      '      owner: ''anonymous'', '
    cmd = cmd +           'author: ''Mark Conde'',' 

;   First, define the required header properties:
    cmd = cmd +       'class_name: ''win_pool'',' 
    cmd = cmd +      'description: ''Maintain a pool of windows'','
    cmd = cmd +          'purpose: ''Window pool'','
    cmd = cmd +      'idl_version: ''3.5.1'','
    cmd = cmd + 'operating_system: ''Windows 2000 Professional'','
    cmd = cmd +          'dynamic: ''' + ddn + ''' '
                
;   And, add structure specified by the dynamic keyword, (if any):                        
    if  dyn ne 'None' then cmd = cmd + ',' + dyn 

;   Finally, add the closing bracket:
    cmd = cmd + '}'
    
;   Now, create the instance:
    status = execute(cmd)
    winpool = instance
end

;==========================================================================================
; Now come the methods that are specific to this McObject:

pro win_pool_edit
    common winpool, winpool
    if n_elements(winpool) eq 0 then new_obj, 'win_pool', instance
    obj_edt, winpool, tagz=[0,1]
end

pro win_pool_newwin, title, xsize=xs, ysize=ys, xpos=xo, ypos=yo, owner=owner
common winpool, winpool

       idx = n_elements(winpool) 
       if idx eq 0 then begin
          new_obj, 'win_pool', instance 
       endif

       nmat = 0
       idx  = where(strpos(strupcase(winpool.name), strupcase(title)) ge 0, nmat)
       if nmat gt 0 then win_pool_del, title
       idx = n_elements(winpool) 
       winpool = [winpool, winpool(0)]

       device, get_screen_size=box
       if not(keyword_set(xs))    then    xs = 0.6*box(0)
       if not(keyword_set(ys))    then    ys = 0.6*box(1)
       if not(keyword_set(owner)) then owner = 'anonymous'
       if keyword_set(xo) then begin
          if keyword_set(yo) then window, title=title, /free, xsize=xs, ysize=ys, xpos=xo, ypos=yo else $
                                  window, title=title, /free, xsize=xs, ysize=ys, xpos=xo
       endif else begin
          if keyword_set(yo) then window, title=title, /free, xsize=xs, ysize=ys, ypos=yo else $
                                  window, title=title, /free, xsize=xs, ysize=ys
       endelse
       winpool(idx).name  = title
       winpool(idx).index = !d.window
       winpool(idx).owner = owner
end

pro win_pool_set, title, owner=owner
common winpool, winpool
    idx = n_elements(winpool) 
    if idx eq 0 then begin
       new_obj, 'win_pool', instance 
    endif

nmat = 0
idx  = where(strpos(strupcase(winpool.name), strupcase(title)) ge 0, nmat)
if nmat gt 0 then begin
   wset,  winpool(idx(0)).index
   wshow, winpool(idx(0)).index   
endif else begin
   win_pool_newwin, title, owner=owner
endelse
end

pro win_pool_gif, title=title, owner=owner, file=file, current=current
common winpool, winpool
if n_elements(winpool) lt 1 then return

if keyword_set(current) then goto, CURRENT

if keyword_set(title) then begin
   win_pool_set, title=title   
endif else begin
   if not(keyword_set(owner)) then begin
      mcchoice, 'Choose a window', winpool(1:*).name, choice
      win_pool_set, choice.name
   endif else begin
      nmat = 0
      idx  = where(strpos(strupcase(winpool.owner), strupcase(owner)) ge 0, nmat)
      if nmat gt 0 then begin
         mcchoice, 'Choose a window', winpool(idx).name, choice
         win_pool_set, choice.name
      endif 
   endelse
endelse

CURRENT:
gif_this, file=file
end

pro win_pool_namekill
common winpool, winpool
    if n_elements(winpool) gt 1 then begin
       mcchoice, 'Choose window to kill:', winpool(1:*).name, choice
       win_pool_del, choice.name
    endif
end

pro win_pool_del, title
common winpool, winpool
if n_elements(winpool) lt 1 then return
nmat = 0
idx  = where(strpos(strupcase(winpool.name), strupcase(title)) ge 0, nmat)
if nmat gt 0 then begin
   wset, winpool(idx(0)).index
   wdelete, winpool(idx(0)).index
   if !d.window eq winpool(idx(0)).index then wset, -1
   veceldel, winpool, idx(0)
endif
end

pro win_pool_disown, owner
common winpool, winpool
    if n_elements(winpool) lt 1 then return
    nown = 0
    owned = where(strpos(strupcase(winpool.owner), strupcase(owner)) ge 0, nown)
    if nown gt 0 then begin
       owned = reverse(owned(sort(owned)))
       for j=0,n_elements(owned)-1 do win_pool_del, winpool(owned(j)).name 
    endif
end

;==========================================================================================
; This is the (required) "autorun" method for this McObject. If no autorun action is 
; needed, then this routine should simply exit with no action:

pro win_pool_autorun, instance
end

;==========================================================================================
; This is the (required) class method for creating a new instance of the win_pool object. It
; would normally be an empty procedure, but it MUST be present, as the last procedure in 
; the methods file:

pro win_pool
end


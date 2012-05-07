;-------------------------------------------------------------
;+
; NAME:
;       BOX2B
; PURPOSE:
;       Simple two mouse button interactive box on image display.
; CATEGORY:
; CALLING SEQUENCE:
;       box2b, x1, x2, y1, y2
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         /STATUS  means display box size and position.
;         MENU=txtarr     Text array with exit menu options.
;           Def=['OK','Abort','Continue'].  'Continue is added.'
;         /NOMENU         Inhibits exit menu.
;         EXITCODE=code.  0=normal exit, 1=alternate exit.
;           If MENU is given then code is option index.
; OUTPUTS:
;       x1, x2 = min and max X.   out
;       y1, y2 = min and max Y.   out
; COMMON BLOCKS:
; NOTES:
;       Notes: Works in device coordinates.
;         Drag open a new box.  Corners or sides may be dragged.
;         Box may be dragged by clicking inside.
;         Click any other button to exit.
;         A returned value of -1 means box undefined.
; MODIFICATION HISTORY:
;       R. Sterner, 1997 Nov 10
;       R. Sterner, 1998 Feb  5 --- Fixed first erase box problem.
;       Better but not perfect.
;
; Copyright (C) 1997, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro box2b, x10, x20, y10, y20, status=stat, help=hlp, $
	  exitcode=exit, menu=menu, nomenu=nomenu
 
	if keyword_set(hlp) then begin
	  print,' Simple two mouse button interactive box on image display.'
	  print,' box2b, x1, x2, y1, y2'
	  print,'   x1, x2 = min and max X.   out'
	  print,'   y1, y2 = min and max Y.   out'
	  print,' Keywords:'
	  print,'   /STATUS  means display box size and position.'
          print,'   MENU=txtarr     Text array with exit menu options.'
          print,"     Def=['OK','Abort','Continue'].  'Continue is added.'
          print,'   /NOMENU         Inhibits exit menu.'
          print,'   EXITCODE=code.  0=normal exit, 1=alternate exit.' 
          print,'     If MENU is given then code is option index.'
	  print,' Notes: Works in device coordinates.'
	  print,'   Drag open a new box.  Corners or sides may be dragged.'
	  print,'   Box may be dragged by clicking inside.'
	  print,'   Click any other button to exit.'
	  print,'   A returned value of -1 means box undefined.'
	  return
	endif
 
	tol = 5				; Closeness tolerence (5 pixels).
	xmx = !d.x_size			; Max X coord.
	ymx = !d.y_size			; Max Y coord.
 
	xcl=-1 & ycl=-1			; Define last cursor position.
	noerase = 1			; Don't erase old box first time.
 
        ;----  Make sure exit menu is setup   ---------
        if n_elements(menu) eq 0 then menu=['OK','Abort']
        mvals = indgen(n_elements(menu))
 
	;-------  Set up status display?  -----------
	if keyword_set(stat) then begin
	  xbb,wid=wid,nid=nid,res=[0,1,2],lines=[$
	    'X1 X2 DX = 000  000  000',$
	    'Y1 Y2 DY = 000  000  000',$
	    'CX CY = 000  000']
	endif
 
	;-------  Use entry box if available  ------------
	if n_elements(x10) eq 0 then x10=-1	; Make sure box values
	if n_elements(x20) eq 0 then x20=-1	; are not undefined.
	if n_elements(y10) eq 0 then y10=-1
	if n_elements(y20) eq 0 then y20=-1
	if min([x10,x20,y10,y20]) ge 0 then begin
	  x1 = (x10<x20)>0<(xmx-1)	; Use given values but keep in range.
	  x2 = (x10>x20)>0<(xmx-1)
	  y1 = (y10<y20)>0<(ymx-1)
	  y2 = (y10>y20)>0<(ymx-1)
	  tvbox,x1,y1,x2-x1,y2-y1,-2		; Plot entry box.
	  if keyword_set(stat) then begin	; Update status.
	    widget_control,nid(0),set_val='X1  X2  DX  =  '+strtrim(x1,2)+$
		'   '+strtrim(x2,2)+'   '+strtrim(x2-x1+1,2)
	    widget_control,nid(1),set_val='Y1  Y2  DY  =  '+strtrim(y1,2)+$
		'   '+strtrim(y2,2)+'   '+strtrim(y2-y1+1,2)
	    widget_control,nid(2),set_val='CX  CY  =  '+strtrim((x1+x2)/2,2)+$
		'   '+strtrim((y1+y2)/2,2)
	  endif
	  goto, loop			; Go intereactive.
	endif
 
	;-------  Init box to first point  ----------
	cursor, x1, y1, 3, /device	; Wait for a button down.
        if !mouse.button gt 1 then return	; Other button.
	x2=x1 & y2=y1			; Got one, set box to single point.
 
	xcl = x1  &  ycl = y1		; Last cursor position.
 
	;================================================
	;	Main cursor loop
	;================================================
loop:
        cursor, xc, yc, 0, /device		; Look for new values.
        if ((xc eq xcl) and (yc eq ycl)) or $xi	 ; Not moved, or
           ((xc eq -1) and (yc eq -1)) then $	; moved out of window:
          cursor,xc,yc,2,/device		; wait for a change.
	xcl=xc  &  ycl=yc			; Save last position.
 
	;-------  Exit box routine  ------------
        if !mouse.button gt 1 then begin	; Other button.
          ;----  Exit options: OK, Abort, Continue. 
          if keyword_set(nomenu) then begin
            exit = 0
          endif else begin
            exit = xoption([menu,'Continue'],val=[mvals,-1],def=0)
          endelse
	  if exit ne -1 then begin
	    tvbox,x1,y1,x2-x1,y2-y1,-1		; Erase box and exit.
	    x10=x1 & x20=x2 & y10=y1 & y20=y2	; Return box.
	    if keyword_set(stat) then widget_control,wid,/dest
	    return
	  endif
	  tvcrs, xcl, ycl
	  goto, loop
	endif
 
	;-------  First point of a drag command  ----------
        if !mouse.button eq 1 then $
	  wait,.2 $				; Debounce. 
	  else goto, loop
 
	;------  Check if at a box corner  --------------
	ic = 0
	if inbox(xc,yc,x1-tol,x1+tol,y1-tol,y1+tol) then ic=1
	if inbox(xc,yc,x2-tol,x2+tol,y1-tol,y1+tol) then ic=2
	if inbox(xc,yc,x2-tol,x2+tol,y2-tol,y2+tol) then ic=3
	if inbox(xc,yc,x1-tol,x1+tol,y2-tol,y2+tol) then ic=4
 
	;------  Was at a corner, drag it  ---------------
	if ic gt 0 then begin			; Move a corner.
	  while !mouse.button eq 1 do begin	; Drag current corner.
          cursor, xc, yc, 0, /device		; Look for new values.
          if ((xc eq xcl) and (yc eq ycl)) or $xi	 ; Not moved, or
             ((xc eq -1) and (yc eq -1)) then $	; moved out of window:
	    repeat begin
              cursor,xc,yc,2,/device		; wait for a change.
	    endrep until (xc gt -1) and (yc gt -1)
	  xcl=xc  &  ycl=yc			; Save last position.
 
	  case ic of				; Process a corner move.
1:	  begin
	    x1=xc  & y1=yc
	    if (x1 gt x2) and (y1 gt y2) then begin	; Handle any crossover.
	      swap, x1, x2 & swap, y1,y2 & ic=3		; 1 --> 3
	    endif else if x1 gt x2 then begin
	      swap, x1, x2 & ic=2			; 1 --> 2
	    endif else if y1 gt y2 then begin
	      swap, y1, y2 & ic=4			; 1 --> 4
	    endif
	  end
2:	  begin
	    x2=xc  & y1=yc
	    if (x2 lt x1) and (y1 gt y2) then begin	; Handle any crossover.
	      swap, x1, x2 & swap, y1,y2 & ic=4		; 2 --> 4
	    endif else if x2 lt x1 then begin
	      swap, x1, x2 & ic=1			; 2 --> 1
	    endif else if y1 gt y2 then begin
	      swap, y1, y2 & ic=3			; 2 --> 3
	    endif
	  end
3:	  begin
	    x2=xc  & y2=yc
	    if (x2 lt x1) and (y2 lt y1) then begin	; Handle any crossover.
	      swap, x1, x2 & swap, y1,y2 & ic=1		; 3 --> 1
	    endif else if x2 lt x1 then begin
	      swap, x1, x2 & ic=4			; 3 --> 4
	    endif else if y2 lt y1 then begin
	      swap, y1, y2 & ic=2			; 3 --> 2
	    endif
	  end
4:	  begin
	    x1=xc  & y2=yc
	    if (x1 gt x2) and (y2 lt y1) then begin	; Handle any crossover.
	      swap, x1, x2 & swap, y1,y2 & ic=2		; 4 -- 2
	    endif else if x1 gt x2 then begin
	      swap, x1, x2 & ic=3			; 4 --> 3
	    endif else if y2 lt y1 then begin
	      swap, y1, y2 & ic=1			; 4 --> 1
	    endif
	  end
	  endcase
 
	    tvbox,x1,y1,x2-x1,y2-y1,-2,noerase=noerase	; Plot new box.
	    noerase = 0					; Erase from now on.
	    if keyword_set(stat) then begin	; Update status.
	      widget_control,nid(0),set_val='X1  X2  DX  =  '+strtrim(x1,2)+$
	  	'   '+strtrim(x2,2)+'   '+strtrim(x2-x1+1,2)
	      widget_control,nid(1),set_val='Y1  Y2  DY  =  '+strtrim(y1,2)+$
		'   '+strtrim(y2,2)+'   '+strtrim(y2-y1+1,2)
	      widget_control,nid(2),set_val='CX  CY  =  '+strtrim((x1+x2)/2,2)+$
		'   '+strtrim((y1+y2)/2,2)
	    endif
	  endwhile					; Keep dragging.
	  goto, loop			; Go look for another drag operation.
	endif
 
	;------  Check if at a box side  -----------------
	is = 0
	if inbox(xc,yc,x1-tol,x2+tol,y1-tol,y1+tol) then is=1
	if inbox(xc,yc,x2-tol,x2+tol,y1-tol,y2+tol) then is=2
	if inbox(xc,yc,x1-tol,x2+tol,y2-tol,y2+tol) then is=3
	if inbox(xc,yc,x1-tol,x1+tol,y1-tol,y2+tol) then is=4
 
	;------  Was at a side, drag it  ---------------
	if is gt 0 then begin			; Move a corner.
	  while !mouse.button eq 1 do begin	; Drag current corner.
          cursor, xc, yc, 0, /device		; Look for new values.
          if ((xc eq xcl) and (yc eq ycl)) or $xi	 ; Not moved, or
             ((xc eq -1) and (yc eq -1)) then $	; moved out of window:
	    repeat begin
              cursor,xc,yc,2,/device		; wait for a change.
	    endrep until (xc gt -1) and (yc gt -1)
	  xcl=xc  &  ycl=yc			; Save last position.
 
	  case is of				; Process a side move.
1:	  begin
	    y1 = yc
	    if y1 gt y2 then begin		; Handle any crossover.
	      swap, y1,y2 & is=3		; 1 --> 3
	    endif
	  end
2:	  begin
	    x2 = xc
	    if x2 lt x1 then begin		; Handle any crossover.
	      swap, x1, x2 & is=4		; 2 --> 4
	    endif
	  end
3:	  begin
	    y2 = yc
	    if y2 lt y1 then begin		; Handle any crossover.
	      swap, y1,y2 & is=1		; 3 --> 1
	    endif
	  end
4:	  begin
	    x1 = xc
	    if x1 gt x2 then begin		; Handle any crossover.
	      swap, x1, x2 & is=2		; 4 -- 2
	    endif
	  end
	  endcase
 
	    tvbox,x1,y1,x2-x1,y2-y1,-2		; Plot new box.
	    if keyword_set(stat) then begin	; Update status.
	      widget_control,nid(0),set_val='X1  X2  DX  =  '+strtrim(x1,2)+$
	  	'   '+strtrim(x2,2)+'   '+strtrim(x2-x1+1,2)
	      widget_control,nid(1),set_val='Y1  Y2  DY  =  '+strtrim(y1,2)+$
		'   '+strtrim(y2,2)+'   '+strtrim(y2-y1+1,2)
	      widget_control,nid(2),set_val='CX  CY  =  '+strtrim((x1+x2)/2,2)+$
		'   '+strtrim((y1+y2)/2,2)
	    endif
	  endwhile					; Keep dragging.
	  goto, loop			; Go look for another drag operation.
	endif
 
	;------  Inside box  -----------------------------
	if outbox(xc,yc,x1,x2,y1,y2) then goto, loop
 
	while !mouse.button eq 1 do begin	; Drag current corner.
          cursor, xc, yc, 0, /device		; Look for new values.
          if ((xc eq xcl) and (yc eq ycl)) or $ ; Not moved, or
             ((xc eq -1) and (yc eq -1)) then $	; moved out of window:
	    repeat begin
              cursor,xc,yc,2,/device		; wait for a change.
	    endrep until (xc gt -1) and (yc gt -1)
	  dcx=xc-xcl & dcy=yc-ycl		; Move in pixels.
	  xcl=xc  &  ycl=yc			; Save last position.
 
	  if ((x1+dcx) ge 0) and ((x2+dcx) lt xmx) then begin
	    x1 = x1+dcx  &  x2 = x2+dcx		; New box position.
	  endif
 
	  if ((y1+dcy) ge 0) and ((y2+dcy) lt ymx) then begin
	    y1 = y1+dcy  &  y2 = y2+dcy
	  endif
 
	  tvbox,x1,y1,x2-x1,y2-y1,-2		; Plot new box.
	  if keyword_set(stat) then begin	; Update status.
	    widget_control,nid(0),set_val='X1  X2  DX  =  '+strtrim(x1,2)+$
	      '   '+strtrim(x2,2)+'   '+strtrim(x2-x1+1,2)
	    widget_control,nid(1),set_val='Y1  Y2  DY  =  '+strtrim(y1,2)+$
	      '   '+strtrim(y2,2)+'   '+strtrim(y2-y1+1,2)
	    widget_control,nid(2),set_val='CX  CY  =  '+strtrim((x1+x2)/2,2)+$
	      '   '+strtrim((y1+y2)/2,2)
	  endif
 
	endwhile
 
	goto, loop
 
	end

;-------------------------------------------------------------
;+
; NAME:
;       CROSSI
; PURPOSE:
;       Interactive cross-hair cursor on screen or plot.
; CATEGORY:
; CALLING SEQUENCE:
;       crossi, [x, y, z]
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         /DATA   Causes data coordinates to be used (default).
;         /DEVICE Causes window device coordinates to be used.
;         /NORMAL Causes normalized coordinates to be used.
;         /ORDER  Reverse device y coordinate (0 at window top).
;         /PIXEL  Show pixel value.
;         COLOR=c Set color of line (ignored for /XOR).
;           Use -2 for dotted line.
;         LINESTYLE=s Line style.
;         MAG=m   Magnification for an optional magnified window.
;           Setting MAG turns window on. /MAG gives magnification 10.
;         SIZE=sz Mag window approx. size in pixels (def=200).
;         XFORMAT=xfn  These keywords are given names of functions
;         YFORMAT=yfn  that accept the numeric value of x or y
;           and return a corresponding string which is displayed
;           in place of the actual value.  For example, Julian
;           days could be displayed as a date with jd2date.
;         XSIZE=xs, YSIZE=ys  Coordinate display widths.
;         /JS  Means X axis is time in Julian seconds. Example:
;           x=maken(-2e8,-1.9e8,200) & y=maken(20,30,200)
;           z=bytscl(makez(200,200))
;           izoom,x,y,z,/js
;           crossi,/js
;         /NOSTATUS   Inhibits status display widget.
;         SETSTAT=st  May use the same status display widget on
;           each call to crossi (stays in same position).
;           On first call: the status widget structure is returned.
;           Following calls: send st.  Must use with /KEEP.
;           To delete status display widget after last box1 call:
;             widget_control,st.top,/dest (or drop /KEEP)
;         /KEEP   Do not delete status widget or mag window on exit.
;         /XMODE  Means use XOR plot mode instead of tvrd mode.
;         INSTRUCTIONS=t  String array with exit instructions.
;           Default: Press any button to exit.
;         /DIALOG Means give an exit dialog box.
;         MENU=m  A string array with exit dialog box options.
;           An option labeled Continue is always added. Def=Continue.
;         DEFAULT=def  Set exit menu default.
;         EXITCODE=x Returns exit code.  Always 0 unless a dialog
;           box is requested, then is selected exit option number.
;         BUTTON=b   Returned button code: 1=left, 2=middle, 4=right.
; OUTPUTS:
;       x = X coordinate of line.             in, out
;       y = Y coordinate of line.             in, out
;       z = optionally returned pixel value.  out
;         Only if /PIXEL is specified.
; COMMON BLOCKS:
;       js_com
; NOTES:
;       Note: data coordinates are default.
;         X and Y may be set to starting position in entry.
; MODIFICATION HISTORY:
;       R. Sterner, 1994 May 16
;       R. Sterner, 1994 May 19 --- Added mag window.
;       R. Sterner, 1995 May 12 --- Added exit menu default.
;       R. Sterner, 1995 Jun 30 --- Added /ORDER.
;       R. Sterner, 1995 Oct 17 --- Added /PIXEL and RGB display.
;       R. Sterner, 1995 Nov 30 --- Added color=-2 option.
;       R. Sterner, 1998 Jan 15 --- Dropped the use of !d.n_colors.
;
; Copyright (C) 1994, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
        pro crossi, x, y, zdv, color=color, linestyle=linestyle, $ 
          help=hlp, exitcode=exitcode, nostatus=nostat, nooptions=noop, $
          device=device, normal=norm, data=data, xmode=xmode,$
	  setstat=st, keep=keep, xformat=xfn, yformat=yfn, button=button, $
	  xsize=xsize, ysize=ysize, dialog=dialog,menu=menu,default=def, $
          instructions=instr, js=js, mag=mag0, size=msize0, order=order, $
	  pixel=pixel
 
	common js_com, jsoff
  
        if keyword_set(hlp) then begin 
          print,' Interactive cross-hair cursor on screen or plot.' 
          print,' crossi, [x, y, z]' 
          print,'   x = X coordinate of line.             in, out' 
          print,'   y = Y coordinate of line.             in, out' 
	  print,'   z = optionally returned pixel value.  out'
	  print,'     Only if /PIXEL is specified.'
          print,' Keywords:' 
          print,'   /DATA   Causes data coordinates to be used (default).'
          print,'   /DEVICE Causes window device coordinates to be used.'
          print,'   /NORMAL Causes normalized coordinates to be used.'
	  print,'   /ORDER  Reverse device y coordinate (0 at window top).'
	  print,'   /PIXEL  Show pixel value.'
          print,'   COLOR=c Set color of line (ignored for /XOR).' 
	  print,'     Use -2 for dotted line.'
          print,'   LINESTYLE=s Line style.'
	  print,'   MAG=m   Magnification for an optional magnified window.'
	  print,'     Setting MAG turns window on. /MAG gives magnification 10.'
	  print,'   SIZE=sz Mag window approx. size in pixels (def=200).'
	  print,'   XFORMAT=xfn  These keywords are given names of functions'
	  print,'   YFORMAT=yfn  that accept the numeric value of x or y'
	  print,'     and return a corresponding string which is displayed'
	  print,'     in place of the actual value.  For example, Julian'
	  print,'     days could be displayed as a date with jd2date.'
          print,'   XSIZE=xs, YSIZE=ys  Coordinate display widths.'
          print,'   /JS  Means X axis is time in Julian seconds. Example:'
	  print,'     x=maken(-2e8,-1.9e8,200) & y=maken(20,30,200)'
	  print,'     z=bytscl(makez(200,200))'
	  print,'     izoom,x,y,z,/js'
	  print,"     crossi,/js"
	  print,'   /NOSTATUS   Inhibits status display widget.'
	  print,'   SETSTAT=st  May use the same status display widget on'
	  print,'     each call to crossi (stays in same position).'
	  print,'     On first call: the status widget structure is returned.'
	  print,'     Following calls: send st.  Must use with /KEEP.'
	  print,'     To delete status display widget after last box1 call:'
	  print,'       widget_control,st.top,/dest (or drop /KEEP)'
	  print,'   /KEEP   Do not delete status widget or mag window on exit.'
          print,'   /XMODE  Means use XOR plot mode instead of tvrd mode.'
          print,'   INSTRUCTIONS=t  String array with exit instructions.'
          print,'     Default: Press any button to exit.'
          print,'   /DIALOG Means give an exit dialog box.'
          print,'   MENU=m  A string array with exit dialog box options.'
          print,'     An option labeled Continue is always added. Def=Continue.'
	  print,'   DEFAULT=def  Set exit menu default.'
          print,'   EXITCODE=x Returns exit code.  Always 0 unless a dialog' 
          print,'     box is requested, then is selected exit option number.'
	  print,'   BUTTON=b   Returned button code: 1=left, 2=middle, 4=right.'
          print,' Note: data coordinates are default.' 
          print,'   X and Y may be set to starting position in entry.' 
          return 
        endif 
  
        ;-------  If /JS make sure jsoff defined  ----------
        if keyword_set(js) then begin
          if n_elements(jsoff) eq 0 then begin
            print,' Error in crossi: cannot use /JS until a time series'
            print,'   plot has been made (by izoom,/js,... or jsplot).'
            bell
            return
          endif
          if n_elements(xsize) eq 0 then xsize=25
          if n_elements(xfn) eq 0 then xfn='dt_tm_fromjs'
        endif
 
	;-------  Coordinate system  ---------
        if n_elements(device) eq 0 then device=0
        if n_elements(norm) eq 0 then norm=0
        if n_elements(data) eq 0 then data=0
        if (device+norm) eq 0 then data=1
        if (!x.s(1) eq 0) and $ 
           (not keyword_set(device)) and $
           (not keyword_set(norm)) then begin 
          print,' Error in crossi: data coordinates not yet established.' 
          print,'  Must make a plot before calling crossi or use /DEVICE
          print,'   or /NORMAL keyword.' 
          return 
        endif 
        if device  eq 1 then ctyp = 0              ; Coordinate flag.
        if norm eq 1 then ctyp = 1
        if data eq 1 then ctyp = 2
 
        ;---------  Set defaults  -------------
	if n_elements(x) eq 0 then begin
	  case ctyp of
0:	    begin
	      x = !d.x_size/2
	      y = !d.y_size/2
	    end
1:	    begin
	      x = .25
	      y = .25
	    end
2:	    begin
	      x = midv(!x.crange)
	      y = midv(!y.crange)
	      if !x.type eq 2 then begin
		x = !map.out(9)*!radeg
		y = !map.out(8)*!radeg
	      endif
	    end
	  endcase
	endif else begin
	  ;-----  Handle y reversal  --------
	  if (ctyp eq 0) and keyword_set(order) then y=(!d.y_size-1)-y
	endelse
        if n_elements(color) eq 0 then color=!p.color
        clr = color
        if n_elements(linestyle) eq 0 then linestyle=!p.linestyle
        if keyword_set(xmode) then begin
          device,get_graph=old,set_graph=6
;          clr = !d.table_size-1
          clr = 255
        endif
	stat = keyword_set(nostat) eq 0
        top = -1L
        if n_elements(st) ne 0 then top=st.top
        if n_elements(menu) eq 0 then menu = ['Exit']
        if n_elements(def) eq 0 then def = n_elements(menu)
        if n_elements(instr) eq 0 then instr = ['Press any button to exit.']
        if n_elements(xsize) eq 0 then begin
          xsize=12
          if strupcase(!version.os) eq 'MACOS' then xsize=6
        endif
        if n_elements(ysize) eq 0 then begin
          ysize=12
          if strupcase(!version.os) eq 'MACOS' then ysize=6
        endif
 
	;-------  Find brightest and darkest colors  --------------
	tvlct,/get,r_curr,g_curr,b_curr
	;-----  4 lines lifted from ct_luminance (userslib)  ----
        lum= (.3 * r_curr) + (.59 * g_curr) + (.11 * b_curr)
        bright = max(lum, min=dark)
        c1 = where(lum eq bright)
        c2 = where(lum eq dark)
        bright=c1(0) & dark=c2(0)
	;------- Setup for color = -2  ---------------
	if clr eq -2 then begin
	  hor2 = bright+((indgen(!d.x_size) mod 6) lt 3)*(dark-bright)
	  ver2 = bright+((transpose(indgen(!d.y_size)) mod 6) lt 3)*$
	    (dark-bright)
	endif
 
	;-------  Deal with mag window  --------------
	win1 = !d.window				; Current window.
	if n_elements(mag0) eq 0 then mag0=0		; Force defined.
	if (n_elements(msize0) ne 0) and (mag0 eq 0) then mag0=1
	if mag0 ne 0 then begin
	  if n_elements(msize0) eq 0 then msize0 = 200	; Def mag win size.
	  msize = round(msize0)				; Rounded size.
	  mag = round(mag0)				; Rounded mag.
	  if mag eq 1 then mag = 10			; Def is 10.
	  rdsz = round(float(msize)/mag)		; Read size.
	  rdsz2 = rdsz/2				; Offset.
	  xmid = rdsz2*mag				; Mag win midpoint.
	  ymid = rdsz2*mag
	  wsz = rdsz*mag				; True mag win size.
	endif
 
        ;------  Find ranges and start in device coordinates  ----
        if keyword_set(device) then begin           ;----  DEVICE  -----
          xxdv=[0,!d.x_size-1]                        ; Device range.
          yydv=[0,!d.y_size-1]
          if n_elements(x) eq 0 then x=!d.x_size/2
	  x = x>0<(!d.x_size-1)
          if n_elements(y) eq 0 then y=!d.y_size/2
	  y = y>0<(!d.y_size-1)
        endif else if keyword_set(norm) then begin  ;---  NORMAL  -----
          xxdv=[0,!d.x_size-1]                        ; Normal range.
          yydv=[0,!d.y_size-1]
          if n_elements(x) eq 0 then x=.5
	  x = x>0<1.
          if n_elements(y) eq 0 then y=.5
	  y = y>0<1.
        endif else begin
          if !x.type eq 2 then begin                ;----  MAPS  ------
            xxdv = [0,!d.x_size-1]
            yydv = [0,!d.y_size-1]
            if n_elements(x) eq 0 then x = !map.out(9)*!radeg
            if n_elements(y) eq 0 then y = !map.out(8)*!radeg
          endif else begin                          ;----  DATA  ------
            xx = [min(!x.crange), max(!x.crange)]   ; Data range in x. 
            if !x.type eq 1 then xx=10^xx           ; Handle log x axis. 
            yy = [min(!y.crange), max(!y.crange)]   ; Data range in y. 
            if !y.type eq 1 then yy=10^yy           ; Handle log y axis. 
            tmp = convert_coord(xx,yy,/to_dev)      ; Convert to device coord. 
            xxdv = tmp(0,0:1)                       ; Device coord. range. 
            yydv = tmp(1,0:1)
	    xxdv = xxdv(sort(xxdv))		    ; Allow for reversed axes.
	    yydv = yydv(sort(yydv))
            if n_elements(x) eq 0 then x = total(xx)/2.
	    x = x>xx(0)<xx(1)
            if n_elements(y) eq 0 then y = total(yy)/2.
	    y = y>yy(0)<yy(1)
	  endelse
        endelse
 
	tmp = convert_coord(x,y,dev=device,norm=norm,data=data,/to_dev)
	xdv = tmp(0)<xxdv(1)  & ydv = tmp(1)<yydv(1)
 
        ;--------  Handle starting line  ---------- 
        tvcrs, xdv, ydv                         ; Place cursor.
        if not keyword_set(xmode) then begin
	  tsx=tvrd(xdv,0,1,!d.y_size) ; 1st col.
	  tsy=tvrd(0,ydv,!d.x_size,1) ; 1st row.
	endif
	if clr eq -2 then begin	      ; Dotted lines.
	  tv,ver2,xdv,0
	  tv,hor2,0,ydv
	endif else begin	      ; Normal lines.
          plots, [xdv,xdv],yydv,color=clr,linestyle=linestyle,/dev 
          plots, xxdv,[ydv,ydv],color=clr,linestyle=linestyle,/dev 
	endelse
        xl = xdv                                ; Last column. 
        yl = ydv                                ; Last row. 
        !mouse.button = 0                       ; Clear button flag. 
	tmp=convert_coord(xdv,ydv,/dev,to_dev=device,to_norm=norm,to_dat=data)
	xx0=tmp(0)  &  yy0=tmp(1)
 
	if mag0 ne 0 then begin
	  if n_elements(st) ne 0 then begin
	    device,window_state=state		; Check if window exists.
	    if state(st.win2) eq 1 then win2=st.win2 else begin $
;	      win2=st.win2
	      window, /free, xs=msize, ys=msize, title='Mag: '+strtrim(mag,2)
	      win2 = !d.window		 	; Mag window.
	    endelse
	  endif else begin
	    window, /free, xs=msize, ys=msize, title='Mag: '+strtrim(mag,2)
	    win2 = !d.window		 	; Mag window.
	  endelse
	  wset,win1				; Set back to starting window.
	endif
 
	;---------  Set up status widget  -------------
        if stat then begin
          if not widget_info(top,/valid_id) then begin
	    ;-------  Mag window creation  ------
	    if mag0 ne 0 then begin
;	      window, /free, xs=msize, ys=msize, title='Mag: '+strtrim(mag,2)
;	      win2 = !d.window				 ; Mag window.
;	      lum = ct_luminance(dark=dark, bright=bright) ; Center pix colors.
	      wset, win1				 ; Return to first win.
	    endif else begin
;	      lum = 0
	      win2 = 0
;	      dark = 0
;	      bright = 0
	    endelse
	    ;------  Widget setup  ------------
            top = widget_base(/column,title='Cross-hair cursor')
            id_typ = widget_label(top,val= ' ')
            b = widget_base(top,/row)              		; Position.
            id = widget_label(b,val='X')
            tx = widget_text(b,xsize=xsize)
            b = widget_base(top,/row)              		; Position.
            id = widget_label(b,val='Y')
            ty = widget_text(b,xsize=ysize)
	    tz = 0
	    trgb = 0
	    if keyword_set(pixel) then begin
              b = widget_base(top,/row)              		; Pixel value.
              id = widget_label(b,val='Z')
              tz = widget_text(b,xsize=5)
              id = widget_label(b,val='RGB')
              trgb = widget_text(b,xsize=12)
	      tvlct,rr,gg,bb,/get			; Get color table
	    endif
            xsz = max(strlen(instr))
            ysz = n_elements(instr)
            id = widget_text(top,xsize=xsz,ysize=ysz,val=instr)
            ;-------  Save widget IDs in a structure  --------
            st = {top:top, typ:id_typ, tx:tx, ty:ty, tz:tz, trgb:trgb,$
	      win2:win2}
;            st = {top:top, typ:id_typ, tx:tx, ty:ty, tz:tz, trgb:trgb,$
;	      lum:lum, win2:win2, dark:dark, bright:bright}
          endif  ; st not defined.
 
          ;--------  Initialize Stat widget   -------
          widget_control,st.typ,set_va=(['Device','Normalized','Data'])(ctyp)+$
            ' Coordinates'
          widget_control, st.tx, set_val=strtrim(xx0,2)
          widget_control, st.ty, set_val=strtrim(yy0,2)
	  if keyword_set(pixel) then begin
	    zdv = tvrd(xdv,ydv,1,1)+0
            widget_control, st.tz, set_val=strtrim(zdv,2)
	    rgb = string(/print,form='(3I4)',rr(zdv),gg(zdv),bb(zdv))
            widget_control, st.trgb, set_val=rgb
	  endif
          ;--------  Create  ---------
          widget_control, st.top, /real
        endif
 
 
	;===========================================================
        ;-------  Cursor loop  -----------
	xcl = -2  & ycl = -2
        while !mouse.button eq 0 do begin 
          ;------  Get mouse input  ----------
          cursor, xdv, ydv, 0, /dev               ; Read cursor. 
          if ((xdv eq xcl) and (ydv eq ycl)) or $ ; Not moved, or
             ((xdv eq -1) and (ydv eq -1)) then $ ; moved out of window:
            cursor,xdv,ydv,2,/device              ; wait for a change.
          ;------  Erase old line  --------------
          xdv = xdv > xxdv(0) < xxdv(1)           ; Keep in bounds.
          ydv = ydv > yydv(0) < yydv(1)           ; Keep in bounds.
	  xcl = xdv  & ycl = ydv
          if not keyword_set(xmode) then begin
            tv, tsx, xl, 0                        ; Replace last column. 
            tv, tsy, 0, yl                        ; Replace last row. 
            tsx = tvrd(xdv,0,1,!d.y_size)         ; Read new column.
            tsy = tvrd(0,ydv,!d.x_size,1)         ; Read new row.
          endif else begin
            plots, [xl,xl],yydv,color=clr,linestyle=linestyle,/dev
            plots, xxdv,[yl,yl],color=clr,linestyle=linestyle,/dev
	    empty			          ; Flush graphics.
          endelse
          xl = xdv                                ; Last column. 
          yl = ydv                                ; Last column. 
	  if keyword_set(pixel) then zdv=(tvrd(xdv,ydv,1,1)+0)(0) ; Read pix.
	  ;----------  Update mag window if any  --------------
	  if mag0 ne 0 then begin
	    t=tvrd2(xdv-rdsz2,ydv-rdsz2,rdsz,rdsz)  ; Read patch.
	    t = rebin(t,wsz,wsz,/samp)		    ; Magnify.
	    it = t(xmid,ymid)			    ; Mid pixel.
	    if lum(it) lt 128 then cc=bright $
	       else cc=dark  			    ; Outline color.
	    t(xmid:xmid+mag,ymid)=cc		    ; Draw mid pixel outline.
	    t(xmid:xmid+mag,ymid+mag)=cc
	    t(xmid,ymid:ymid+mag)=cc
	    t(xmid+mag,ymid:ymid+mag)=cc
	    win = win2
	    if n_elements(st) ne 0 then win=st.win2
	    wset, win				    ; Set to mag window.
	    tv, t				    ; Display mag view.
	    wset, win1				    ; Set back to original win.
	  endif
 
	  ;----------  Draw new cross-hairs  -----------------------
	  if clr eq -2 then begin
	    tv,ver2,xdv,0
	    tv,hor2,0,ydv
	  endif else begin
            plots, [xdv,xdv],yydv,color=clr,linestyle=linestyle,/dev 
            plots, xxdv,[ydv,ydv],color=clr,linestyle=linestyle,/dev 
	  endelse
	  empty				          ; Flush graphics.
          ;-------  Update status display  ------------
	  if stat then begin
	    tmp = convert_coord(xdv, ydv, /dev, $
	      to_dev=device, to_norm=norm, to_dat=data)
	    x=tmp(0) & y=tmp(1)
	    ;-----  Handle y reversal  --------
	    if (ctyp eq 0) and keyword_set(order) then y=(!d.y_size-1)-y
            if keyword_set(js) then x = x + jsoff
	    if n_elements(xfn) eq 0 then x=strtrim(x,2) $
	      else x=call_function(xfn, x)
	    if n_elements(yfn) eq 0 then y=strtrim(y,2) $
	      else y=call_function(yfn, y)
	    widget_control, st.tx, set_val=x
	    widget_control, st.ty, set_val=y
	    if keyword_set(pixel) then begin
	      widget_control,st.tz,set_val=strtrim(zdv,2)
	      rgb = string(/print,form='(3I4)',rr(zdv),gg(zdv),bb(zdv))
              widget_control, st.trgb, set_val=rgb
	    endif
	  endif
          ;-------  Handle button press  ----------
          if !mouse.button ne 0 then begin
            button = !mouse.button
            if keyword_set(dialog) then begin
              exitcode = xoption([menu,'Continue'],def=def)
              if exitcode eq n_elements(menu) then begin
                !mouse.button = 0
                tvcrs, xdv, ydv
              endif
            endif else begin
              exitcode = 0
            endelse
          endif
        endwhile 
	;===========================================================
 
	;--------  Erase last line  --------
        if keyword_set(xmode) then begin
          plots, [xdv,xdv],yydv,color=clr,linestyle=linestyle,/dev 
          plots, xxdv,[ydv,ydv],color=clr,linestyle=linestyle,/dev 
	  device,set_graph=old
	endif else begin
          tv, tsx, xl, 0                     ; Replace last column. 
          tv, tsy, 0, yl                     ; Replace last row.. 
	endelse
 
	;--------  return correct coordinate  --------
	tmp=convert_coord(xdv,ydv,/dev,to_dev=device,to_norm=norm,to_dat=data)
	x = tmp(0)
        if keyword_set(js) then x = x + jsoff
	y = tmp(1)
	;-----  Handle y reversal  --------
	if (ctyp eq 0) and keyword_set(order) then y=(!d.y_size-1)-y
 
        ;--------  Remove status display widget  -------
        if (not keyword_set(nostat)) and (not keyword_set(keep)) then begin
          widget_control, st.top, /dest
;	  if mag0 ne 0 then begin
;	    win = win2
;	    if n_elements(st) ne 0 then win=st.win2
;	    wdelete, win
;	  endif
        endif
	;-------  Remove mag window  --------------
	if not keyword_set(keep) then begin
	  if mag0 ne 0 then begin
	    win = win2
	    if n_elements(st) ne 0 then win=st.win2
	    wdelete, win
	  endif
	endif
 
        return
        end 

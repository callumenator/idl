;-------------------------------------------------------------
;+
; NAME:
;       PLTCRV
; PURPOSE:
;       Edit curve points with mouse.  Overlay spline.
; CATEGORY:
; CALLING SEQUENCE:
;       pltcrv, x, y
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         X2=x2, Y2=y2  Optional reference curve to plot.
;         SPLINE=n  Display n point spline curve.  n must
;           be more than the number of elements in x and y.
;         SX=sx, SY=sy  Returned spline curve points.
;         ERROR=err  Error flag: 0=ok, 1=aborted.
;         PLOT keywords also allowed.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Call pltcrv with initial x and y arrays.
;         These will be updated on exit.
; MODIFICATION HISTORY:
;       R. Sterner, 1994 Apr 13
;       R. Sterner, 1998 Jan 15 --- Dropped use of !d.n_colors.
;
; Copyright (C) 1994, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro pltcrv_u, x, y, ixx, iyy, spline=sp, sx=sx, sy=sy, $
	  x2=x2, y2=y2, pltopt=pltopt
 
	plot, x, y, psym=-6, pos=[.15,.15,.9,.9],chars=1.5,_extra=pltopt
	if n_elements(y2) ne 0 then begin
	  oplot, x2, y2, color=5
	endif
	out = convert_coord(x,y,/data,/to_dev)
	ixx = out(0,*)
	iyy = out(1,*)
	if n_elements(sp) ne 0 then begin
	  if (sp gt n_elements(x)) and (n_elements(x) ge 2) then begin
	    sx = maken(min(x),max(x),sp)
	    s = nr_spline(x,y)
	    sy = nr_splint(x,y,s,sx)
	    oplot,sx,sy,linestyle=3,color=2, thick=2
	  endif
	endif
 
	return
	end
 
;======================================================
;--------  pltcrv.pro = draw function.  -------------
;       R. Sterner, 1994 Apr 13
;======================================================
 
	pro pltcrv, x,y, spline=sp, sx=sx, sy=sy, $
	  error=err, x2=x2, y2=y2, _extra=pltopt, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Edit curve points with mouse.  Overlay spline.'
	  print,' pltcrv, x, y'
	  print,'   x,y = function x and y arrays.       in,out'
	  print,' Keywords:'
	  print,'   X2=x2, Y2=y2  Optional reference curve to plot.'
	  print,'   SPLINE=n  Display n point spline curve.  n must'
	  print,'     be more than the number of elements in x and y.'
	  print,'   SX=sx, SY=sy  Returned spline curve points.'
	  print,'   ERROR=err  Error flag: 0=ok, 1=aborted.'
	  print,'   PLOT keywords also allowed.'
	  print,' Notes: Call pltcrv with initial x and y arrays.'
	  print,'   These will be updated on exit.'
	  return
	endif
 
	xsav = x
	ysav = y
 
	;------  Handle current window  ---------
	win1 = !d.window			; win1 = Current window.
	if win1 lt 0 then erase
	win1 = !d.window			; win1 = Current window.
 
	tvlct,r0,g0,b0,/get
 
	tvlct,120, 60,  0,  0			; Background.
	tvlct,255,  0,  0,  1			; Hit.
	tvlct,  0,255,  0,  2			; Spline.
	tvlct,255,  0,  0,  3			; Linear start point.
	tvlct,  0,255,255,  4			; Linear end point.
	tvlct,255, 86, 86,  5			; Second curve.
	tvlct,255,225,125,topc()		; Curve.
	device,/cursor_orig
	defopt = 2
 
	pltcrv_u, x, y, ixx, iyy, spline=sp, sx=sx, sy=sy, pltopt=pltopt,$
	  x2=x2, y2=y2
 
	;===============  Main loop  ====================
	repeat begin
 
	;-------  Options  ----------------
	k = xoption(['Quit','Help','Edit Points (X and Y)',$
	  'Edit Points (Y only)','Sweep mode (Y only)',$
	  'Linear mode (Y only)','Data Cursor','Abort with no changes'],$
		val=['Q','H','M','MY','S','L','C','A'], def=defopt, $
		title='Plot Curve options')
 
	if k eq 'MY' then begin
	  lockx = 1
	  k = 'M'
	endif else lockx=0
 
	;---------  Options loop  -------------
	case k of
	;--------------------------------------------
'Q':	begin		; Quit
	  err = 0
	end
	;--------------------------------------------
'A':	begin		; Abort
	  err = 1
	  x = xsav
	  y = ysav
	  k = 'Q'
	  xmess,'No change made to input data'
	end
	;--------------------------------------------
'C':	begin		; Data Cursor
	  wset, win1
	  wshow
	  xcursor,/data
	end
	;--------------------------------------------
'H':	begin		; Help
	  xhelp,title='Plot Curve help',$
	    ['Use the right mouse button to exit from an option mode.',' ',$
	     'Quit: exit pltcrv.',' ',$
	     'Help: Display this text.',' ',$
	     'Edit Points (X and Y): move individual points in both X and Y.',$
	     ' ',$
	     'Edit Points (Y only): move individual points in Y only.',' ',$
	     'Sweep mode: use mouse to sweep across points moving them to',$
	     '    mouse Y position.  May be useful for rough positioning.',' ',$
	     'Linear mode: precisely position points along a specified line',$
	     '    moving only Y.',' ',$
	     'Data cursor: Display data coordinates of the cursor.',' ',$
             'Abort: exit with no changes to input arrays.']
	end
	;--------------------------------------------
'L':	begin		; Linear mode
	  wshow, win1
	  if n_elements(ixl) ne 0 then tvcrs,ixl,iyl
	  xhelp, title='Linear Mode help',$
	     ['May adjust Y values of points linearly between two',$
	      'points: P1 and P2.  P1 is red and P2 is blue.',$
	      ' ',$
	      'Point P1 may be moved by the mouse.  Fix it in',$
	      'position by clicking left button.  Point P1 may be',$
	      'moved again by clicking the left button again.',$
	      ' ',$
	      'Point P2 is blue and starts on top of fixed P1.',$
              'When P2 is correctly positioned click middle button',$
	      'to linearly interpolate between P1 and P2.',$
	      ' ',$
	      'P2 becomes the new P1.'], /nowait,wid=wid
	  !mouse.button = 0
	  ixl=-2 & iyl=-2
	  sflag = 0				; Start point flag.
	  bbflag = 0				; No coord display yet.
	  while !mouse.button lt 4 do begin	; Linear mode loop.
	    ;----------  Get cursor position  ---------
	    wset, win1
	    cursor, ix,iy,/dev,/nowait
	    if (ix eq ixl) and (iy eq iyl) then begin
	      cursor, ix,iy,/dev,/change
	    endif
	    ixl=ix & iyl=iy
	    d = abs(ix-ixx)
	    w = (where(d eq min(d)))(0)
	    ;--------  Display coordinates  -------------
	    if bbflag eq 0 then begin
	      xbb,lines=['Data Coordinates','------------------'],$
	        res=[1],nid=nid,wid=bbwid
	      bbflag = 1
	    endif
	    out = convert_coord(ix,iy,/dev,/to_data)
	    xd=x(w) & yd=out(1,0)
	    widget_control,nid(0),$
	      set_val=string(xd,yd,form='(2f15.5)')
	    pltcrv_u, x,y,ixx,iyy,spline=sp, sx=sx, sy=sy, pltopt=pltopt,$
	      x2=x2, y2=y2
	    ;-----  Display start point  ----------
	    if sflag eq 0 then begin
	      plots,xd,yd,psym=1,color=3		; Moving Start.
	    endif else begin
	      plots,x0,y0,psym=1,color=3,symsize=2	; Fixed Start.
	      plots,xd,yd,psym=1,color=4		; Moving End.
	    endelse
	    ;---------  Left Button: Set start point  -----------
	    if !mouse.button eq 1 then begin
	      if sflag eq 0 then begin
	        x0=xd & y0=yd				; Start pt in dev.
		w0 = w					; Start index.
	        sflag = 1
	      endif else begin
	        sflag = 0
	      endelse
	    endif
	    ;---------  Middle button: Linearly interpolate  ------
	    if !mouse.button eq 2 then begin
	      if sflag ne 0 then begin			; Must have set start.
		x1=xd & y1=yd				; End point.
		w1 = w					; End index.
		if w0 ne w1 then begin			; Move be distinct pts.
		  step = sign(w1-w0)
		  for w=w0, w1, step do begin		; Interpolate.
		    x(w) = x0 + (x1-x0)*float(w-w0)/float(w1-w0)
		    y(w) = y0 + (y1-y0)*float(w-w0)/float(w1-w0)
		  endfor
		  x0=x1 & y0=y1
		  w0 = w1
		endif
	      endif  ; sflag ne 0.
	    endif  ; !mouse.button ne 2.
	  endwhile  ; Not right button.
	  if wid ne 0 then widget_control,wid,/dest	 ; Help widget.
	  if bbflag ne 0 then widget_control,bbwid,/dest ; Coordinate widget.
	end
	;--------------------------------------------
'S':	begin		; Sweep mode
	  wshow, win1
	  if n_elements(ixl) ne 0 then tvcrs,ixl,iyl
	  xhelp, title='Sweep Mode help',$
	     ['While holding down left button sweep out',$
	      'desired curve (somewhat slowly).'], /nowait,wid=wid
	  !mouse.button = 0
	  ixl=-2 & iyl=-2
	  while !mouse.button lt 4 do begin
	    wset, win1
	    cursor, ix,iy,/dev,/nowait
	    if (ix eq ixl) and (iy eq iyl) then begin
	      cursor, ix,iy,/dev,/change
	    endif
	    ixl=ix & iyl=iy
	    d = abs(ix-ixx)
	    w = (where(d eq min(d)))(0)
	    if d(w) lt 10 then begin
	      if !mouse.button eq 1 then begin
	        out = convert_coord(ix,iy,/dev,/to_data)
	        y(w) = out(1,0)
	        pltcrv_u, x,y,ixx,iyy,spline=sp,sx=sx,sy=sy,pltopt=pltopt,$
		  x2=x2,y2=y2
	      endif
	    endif
	  endwhile  ; Not right button.
	  widget_control,wid,/dest	; Help widget.
	end
	;--------------------------------------------
'M':	begin		; Point move
	  if n_elements(ixl) ne 0 then tvcrs,ixl,iyl
	  xhelp, title='Edit Points help',$
	     ['Move a point: drag it with left button.',' ',$
	      'Drop a point: click on point to drop',$
	      '   with middle button.',' ',$
	      'Add a point: click between two points',$
	      '   with middle button.',' ',$
	      'Exit edit mode: press right button.'],/nowait,wid=wid
	  wshow, win1
	  !mouse.button = 0
	  ixl=-2 & iyl=-2
	  while !mouse.button lt 4 do begin
	    wset, win1
	    cursor, ix,iy,/dev,/nowait
	    if (ix eq ixl) and (iy eq iyl) then begin
	      cursor, ix,iy,/dev,/change
	    endif
	    ixl=ix & iyl=iy
	    d = (ix-ixx)^2 + (iy-iyy)^2
	    w = (where(d eq min(d)))(0)
	    if d(w) lt 10 then begin
		hit = w
		plots,ixx(hit),iyy(hit),/dev,psym=6,col=1
	    endif else begin
	      hit = -1
	      plots,ixx(w),iyy(w),/dev,psym=6
	    endelse
	    ;---------  Move a point  ----------
	    lx = n_elements(x)-1
	    if !mouse.button eq 1 then begin
	      if hit ge 0 then begin
		xbb,lines=['Data Coordinates','------------------'],$
		  res=[1],nid=nid,wid=bbwid
		widget_control,nid(0),$
		  set_val=string(x(w),y(w),form='(2f15.5)')
		while !mouse.button eq 1 do begin
		  cursor,xd,yd,/change,/data
		  y(w)=yd
		  if not keyword_set(lockx) then begin
		    if w eq 0 then x(w)=xd<x(w+1)
		    if w eq lx then x(w)=x(w-1)>xd
		    if (w gt 0) and (w lt lx) then x(w)=x(w-1)>xd<x(w+1)
		  endif
		  widget_control,nid(0),$
		    set_val=string(x(w),y(w),form='(2f15.5)')
		  pltcrv_u,x,y,ixx,iyy,spline=sp,sx=sx,sy=sy,pltopt=pltopt,$
		    x2=x2,y2=y2
		endwhile  ; !mouse
		widget_control,bbwid,/dest
	      endif  ; hit
	      defopt = 0
	    endif  ; !mouse
	    ;---------  End move a point  --------------
	    ;---------  Add or drop a point  -----------
	    if !mouse.button eq 2 then begin
	      ;--------  On a point (hit), drop it  ------------
	      if hit ge 0 then begin	; Drop point.
		if w eq 0 then begin	; Drop first.
		  if n_elements(x) gt 2 then begin
		    x=x(1:*) & y=y(1:*)
		  endif
		endif
		if (w gt 0) and (w lt lx) then begin	; Drop mid.
		  x = [x(0:w-1),x(w+1:*)]
		  y = [y(0:w-1),y(w+1:*)]
		endif
		if w eq lx then begin	; Drop last.
		  if n_elements(x) gt 2 then begin
		    x=x(0:lx-1) & y=y(0:lx-1)
		  endif
		endif
	      ;--------  End drop  ----------------
	      ;--------  Start add point  ----------------
	      endif else begin
		if (ix gt ixx(0)) and (ix lt ixx(lx)) then begin
		  w = (where(ix lt ixx))(0)	; Next point up.
		  x = [x(0:w-1),.5*(x(w-1)+x(w)), x(w:*)]
		  y = [y(0:w-1),.5*(y(w-1)+y(w)), y(w:*)]
		endif  ; In add point range.
	      endelse
	      ;-------   End add point  ------------------
	      pltcrv_u,x,y,ixx,iyy,spline=sp,sx=sx,sy=sy,pltopt=pltopt,$
		x2=x2,y2=y2
	      wait,.5
	      defopt = 2
	    endif  ; Add or drop (Middle button).
	  endwhile  ; Not right button.
	  widget_control,wid,/dest	; Help widget.
	end
	;--------------------------------------------
else:
	endcase
 
	endrep until k eq 'Q'
 
	tvlct,r0,g0,b0
 
	return
	end

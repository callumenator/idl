; NEWPAGE
;*****************************************************************************
; IDL graphics utility to start and end X-window or PostScript graphs with
; a set of common procedures.  The type of graph produced depends only on the
; name of the current output device, as established with SET_PLOT, and held
; in !D.NAME.   The X-window display will look a lot like the paper plot.
; Measurements in "centimeters" can be used to start both PostScript plots
; and X Windows.
;   An important component of this utility is the TVPAGE routine, which
; specifies both the image location and size, in "centimeters".  The PostScript
; device already had this capability, due to scalable pixel size.  The TVPAGE
; routine will expand the image to the given size if the device is set for X.
;
; Routines:
;	NEWPAGE
;	TVPAGE
;	ENDPAGE
;	SETPS
;	SETX
;*****************************************************************************
PRO NEWPAGE,name,xdim,ydim,ColorT=ColorT,inches=inches
; Create an X-Window or a PostScript file.
; First save some system plot/device variables which we will change

Common pagesave,pscale,pxlen,pylen,pfont,pthick,xthick,ythick,bakcolor,forcolor

  xlen=xdim
  ylen=ydim
  IF keyword_set(inches) THEN BEGIN
    xlen=xlen*2.54
    ylen=ylen*2.54
  ENDIF

CASE !D.NAME OF
 'X':	BEGIN
          device, retain=2
;	  pscale=27.
	  pscale=40.
	  devxlen=LONG(xlen*pscale)
	  devylen=LONG(ylen*pscale)
	  WINDOW,TITLE=name,XSIZE=devxlen,YSIZE=devylen,/FREE
	  IF keyword_set(ColorT) THEN Loadct,ColorT
; reverse black and white indices for X-window display
	  bakcolor=!P.BACKGROUND
	  forcolor=!P.COLOR
	  !P.BACKGROUND=forcolor
	  !P.COLOR=bakcolor
	  ERASE
	END
 'PS':	BEGIN
	  pscale=1000.
	  filename=name+'.PS'
	  DEVICE,FILENAME=filename
	  DEVICE,BITS_PER_PIXEL=8
	  IF keyword_set(ColorT) THEN BEGIN
	    DEVICE,/COLOR
	    loadct,ColorT
	  ENDIF
	  pfont=!p.font
	  pthick=!p.thick
	  xthick=!x.thick
	  ythick=!y.thick
;change some system variables which make the PS plots look better
	  !p.font=0
	  !p.thick=2
	  !x.thick=2
	  !y.thick=2

	  IF (xlen GT ylen AND xlen GT 19.) THEN BEGIN
		DEVICE,/LANDSCAPE
		maxx=27.
		maxy=20.
		xlen=MIN([maxx,xlen])
		ylen=MIN([maxy,ylen])
		xoff=1.0+(maxy-ylen)/2.
		yoff=0.5+maxx - (maxx-xlen)/2.
	  ENDIF ELSE BEGIN
		DEVICE,/PORTRAIT
		maxx=20.
		maxy=27.
		xlen=MIN([maxx,xlen])
		ylen=MIN([maxy,ylen])
		xoff=1.0+(maxx-xlen)/2.
		yoff=0.5+(maxy-ylen)/2.
	  ENDELSE
; centimeters are default:
	  DEVICE,xsize=xlen,ysize=ylen,xoffset=xoff,yoffset=yoff

	END
  ELSE: Print,'Invalid device type for NEWPAGE'
ENDCASE
pxlen=xlen
pylen=ylen
RETURN
END
;*****************************************************
PRO ENDPAGE
common pagesave,pscale,pxlen,pylen,pfont,pthick,xthick,ythick,bakcolor,forcolor
CASE !D.NAME OF
 'X':	BEGIN
	  !P.BACKGROUND=bakcolor
	  !P.COLOR=forcolor
	END
 'PS':	BEGIN
	  DEVICE,/close_file
	  !p.font=pfont
	  !p.thick=pthick
	  !x.thick=xthick
	  !y.thick=ythick
	END
ENDCASE
RETURN
END
;*****************************************************
PRO TVPAGE,image,xpos,ypos,xlen,ylen
; Use this routine instead of TV to get similar results in both X and PS
common pagesave,pscale,pxlen,pylen,pfont,pthick,xthick,ythick,bakcolor,forcolor
CASE !D.NAME OF
 'X':	BEGIN
; expand (or shrink) the image dimensions
; First calculate size in device units
	  devxpos=LONG(xpos*pscale)
	  devypos=LONG(ypos*pscale)
	  devxlen=LONG(xlen*pscale)
	  devylen=LONG(ylen*pscale)
          imx=CONGRID(image,devxlen,devylen)
	  TV,imx,devxpos,devypos
	  imx=0
	END
 'PS':	BEGIN
	  TV,image,xpos,ypos,XSIZE=xlen,YSIZE=ylen,/CENTIMETERS
	END
ENDCASE
RETURN
END
;*****************************************************
PRO setX
set_plot,'X'
RETURN
END
;*****************************************************
PRO setPS
set_plot,'PS'
RETURN
END

;+
;******************** HIGH FREQUENCY RADAR DIVISION, SRL **********************
;*************************** Ionospheric Effects ******************************
;HELP
;1 TH_IMAGE_CONT
;	Overlays an image and a contour plot and optionally adds a scale bar.
;	Based on the IDL USERLIB routine IMAGE_CONT. This routine supersedes 
;	the USERLIB one, having far more functionality, yet capable of EXACTLY
;	reproducing the effect of IMAGE_CONT. Scale bar appears on the 
;	right-hand-side unless /NOBAR is set. NB: the scale bar is
;	automatically created by a recursive call to this routine using the
;	same colour and image parameters 
;
; Format:
;	In its simplest form (allowing all parameters to default)
;
;    IDL> TH_IMAGE_CONT, IMAGE
;
;	And in its most complex form, specifying ALL parameter
;
;    IDL> TH_IMAGE_CONT, IMAGE, $
;		ASPECT=aspect, $
;		BADPTS=badpts,$
;		BAR_RANGE=bar_range, $
;		BAR_SEPARATION=bar_separation, $
;		BAR_TICKLEN=bar_ticklen, $
;		BAR_TICKNAME=bar_tickname, $
;		BAR_TICKS=bar_ticks, $
;		BAR_TICKV=bar_tickv,$
;		BARSZ_CHARS=barsz_chars, $
;		BOTTOMCOLOUR=bottomcolour,$
;		C_COLORS=c_colors,$
;		C_LINESTYLE=c_linestyle, $
;		C_THICK=c_thick, $
;		CONGRID=congrid, $
;		CONT=cont, $
;		CRANGE=crange, $
;		CT=ct, $
;		CUBIC=cubic, $
;		DEBUG=debug, $
;		EXACT=exact, $
;		RAISE_PTITLE=raise_ptitle
;		IMAGE_WINDOW=image_window, $
;		INTERP=interp,$
;		LEVELS=levels,$
;		MAX_VALUE=max_value, $
;		NLEVELS=nlevels, $
;		NOBAR=nobar, $
;		NOCONT=nocont, $
;		NOERASE=noerase,$
;		TOPCOLOUR=topcolour,$
;		TSIZE=tsize, $
;		WINDOW_SCALE=window_scale, $
;		XRANGE=xrange, $
;		YRANGE=yrange
; 
;2	IMAGE
;		2-dimensional array to display as an image.
;
;2	/ASPECT
;		set to retain image's aspect ratio.  Assumes square
;		pixels.  If /WINDOW_SCALE is set, the aspect ratio is retained.
;
;2	BADPTS
;		indices into IMAGE data which define the bad points.
;		These will not be contoured
;
;2	BAR_RANGE	
;	 	set the range limits for the colour scale bar
;		(same as CRANGE, defaults to autoscaling if
;		 BAR_TICKV not set)
;
;2	BAR_SEPARATION	
;		the separation, in characters (default = 2), between the scale
;		bar and the image. Note that the |y-ticklength| will be added
;		to this value if y-ticklength < 0.
;		Both the image and the colour bar need to fit 
;		into the space allowed for the plot window, otherwise an
;		informative message will be printed and unpredictable results
;		may occur for the displayed image 
;
;2	BAR_TICKS
;		set the number of tick intervals for the labelling
;		of the scale bar 
;		(defaults to !z.ticks)
;
;2	BAR_TICKV
;		the values to label on the scale bar. If this is set
;		then the scale bar will have AT LEAST this range
;		(defaults to !z.tickv)
;
;2	BAR_TICKNAME
;		the labels to use on the scale bar 
;		(defaults to !z.range)
;
;2	BAR_TICKLEN
;		the length of the ticks on the scale bar  in fractions of tick
;		bar window, (defaults to !z.ticklen)
;
;2	BARSZ_CHARS
;		the size of the scale bar in characters (default = 2). 
;		Both the image and the colour bar need to fit 
;		into the space allowed for the plot window, otherwise an
;		informative message will be printed and unpredictable results
;		may occur for the displayed image. If the value of this
;		keyword is <=0 then no bar will be displayed BUT the scaling
;		and window size will be calculated as those a colour bar is to
;		be used. This is useful when doing multiple plots per page
;		where only some scale bars are not required but you want the
;		plots to all be the same size. Set BARSZ_CHARS = -#chars to
;		allow room for a bar of #chars size but not to put a scale bar
;		on the plot. Then set BARSZ_CHARS = +#chars to plot the bar on
;		alongside another plot, to end up with images of the same
;		size. Useful in collaboration with the SIDES procedure (which
;		will set flags for when the plot is on the Left,Right,Top and
;		Bottom of the plot window).
;
;
;2	BOTTOMCOLOUR
;		Set this keyword to the colour index of the desired bottom
;		colour (range from 0 to TOPCOLOUR-1).
;		Note that the default value for this keyword is 1,
;		which allows the colour of the image to
;		be independent of the background and axes colours
;		(!P.background and !P.color). If the user sets this keyword
;		then allowance should be made for these colours as they are
;		generally swapped for POSTSCRIPT and X-Window devices
;
;2	/CONGRID 	
;		if the image has to be resampled then use the USERLIB CONGRID
;		routine 
;
;2	/CONT 	
;		only do the contouring (no image)
;
;2	CRANGE	
;		set the range limits for the colour scale bar
;		(same as BAR_RANGE, defaults to autoscaling if
;		 BAR_TICKV not set)
;
;2	CT	
;		load a color table (uses LOADCT)
;
;2	/CUBIC	
;		if the image has to be resampled AND interpolated then use the
;		CUBIC interpolation rather than the bi-linear (see INTERP
;		Keyword) 
;
;2	/DEBUG	
;		write out some inforamtion as it goes
;
;
;2	/EXACT
;		When set this will force the contour routine to fit to the
;		exact positions relative to the image.
;		When data is displayed as an image each datum is expanded out
;		to fill a pixel of finite dimensions. The assignment of where
;		the "data value" resides within this space is open to debate,
;		but is most appropriately (to this author) assigned to the
;		geometric centre of the pixel. Most defaults assign this
;		position to be at the bottom left-hand corner of the
;		pixel. Contour will fit to the 2-d plane assuming that the
;		data value is associated with the bottom left-hand corner. To
;		reconcile this with the notion of the value being in the
;		middle of the pixel the contour call is made with the x/y
;		values and ranges for the image adjusted (effectively by half
;		a pixel in the x/y directions). This is the EXACT mapping. By
;		default, the mapping will be the default contour one.
;
;2	RAISE_PTITLE
;		Raise the plot title by this many character units above the
;		plot to allow room to put a label on the top x-axis. Default
;		is raise by 1 char. If not called then the default y-position
;		is 1 char unit above plot (allowing room for xticks, and
;		scaled by !P.charsize)
;
;2	IMAGE_WINDOW
;		the position of the image window, can be used to set
;		!p.position so you can over-plot the image.
;		Only useful when the scale-bar has been used
;
;2	/INTERP 
;		set to bi-linear interpolate if image is resampled.
;		(see also the CUBIC keyword)
;
;2	/NOBAR 
;		dont put a scale bar on the right-hand-side
;
;2	/NOCONT
;		only do the imaging (no contours)
;
;2	/NOERASE
;		dont erase the previous plot
;
;2	TOPCOLOUR
;		Set this keyword to the colour index of the desired bottom
;		colour (range from BOTTOMCOLOUR+1 to !D.n_colors-1). Note that
;		the default value for this keyword is !D.n_colors-2, which
;		allows the colour of the image to be independent of the
;		background and axes colours (!P.background and !P.color). If
;		the user sets this keyword then allowance should be made for
;		these colours as they are generally swapped for POSTSCRIPT and
;		X-Window devices 
;
;2	TSIZE	
;		size of the plot title (default = 1)
; 
;2	/WINDOW_SCALE
;		set to scale the window size to the image size,
;		otherwise the image size is scaled to the window size.
;		Ignored when outputting to devices with scalable pixels.
;
;2	XRANGE
;		will set the ranges for the x-axes labelling
;
;2	YRANGE
;		will set the ranges for the y-axes labelling
;
;2	Contour
;		most of the CONTOUR parameters are passed directly
;
;2 Examples
; IDL>   th_image_cont, image
;
; IDL>	th_image_cont, image, /nocont, /nobar
;
; IDL>	!p.title = "!17 This is an example of what can be done"
; IDL>	!x.title = "X Title"	& !y.title = "Y Title"	& !z.title = "Z Title"
; IDL>	!x.ticklen = -0.02	& !y.ticklen = -0.02	& !z.ticklen = -0.02
; IDL>	!p.charsize = 1.5
; IDL>	levels = findgen(5)*2
; IDL>	image = findgen(20,20)/40.
; IDL>	th_image_cont, image, crange=[0,10], /follow, level=levels, $
;			tsize=1.5*!p.charsize, bar_tickv=levels, c_char=1.5
;
;2 Error_responses
; Returns to the calling procedure on an error
;
;2 Limitations/Assumptions 
;	The currently selected display is affected.
;	If the device has scalable pixels then the image is written over
;	the plot window.
;	As with all TV style image displays, the axes range is independent of 
;	the image, so it is up to the user the ensure correct labelling of the
;	axes.
;	NOTE: if the user aborts while this routine is processing then the 
;	system variables (in particular !p.position) will have 
;	been changed, causing subsequent plots to appear different. Issue the 
;	command "resetplt,/all" to reset all the system variables back to the 
;	startup state.
;
;2 References 
; 	See USERLIB IMAGE_CONT
;
;2 Keywords
;	Graphics images contours
;
;2 Build_details
; Project: IEgroup:[IDL.LIBRARY.HARRIS]
; Source:  TH_IMAGE_CONT.PRO
; Help:    GET/HELP/LIBRARY=IEgroup:[IDL.LIBRARY.HARRIS] TH_IMAGE_CONT.PRO
;
;2 Amendments;	
; 	May, 1988, DMS		1.00
;
;	May 1991, T.J.H.	2.00
;		Numerous mods - (1) to allow passing parameters to CONTOUR
;				(2) to put scale bar on side of image
;				(3) contour or no contour options
;			        (4) made it safe to call with any plot
;				   device set
;				(5) reverse the colours for postscript output
;				(6) plot title and subtitle now set relative 
;				   to the tick lengths (to overcome a 
;				   short-coming in IDL v2.1.0 when ticklen < 0)
;				(7) safe to call with any !p.multi setting
;				(8) debug option allows monitoring of progress
;		Trevor J Harris
;
;	Apr 1992, T.J.H.	2.09
;		added BADPTS so that contour will handle bad points correctly
;		by setting image(badpts) = 10*max(image) and max_val = max+1
;
;	Sept 1992, T.J.H.	2.10
;		reduced colour range to free up the first and last colour 
;		indices. This is to allow the user to change the colours of 
;		the axes and background (usually indices 0 and 255) without 
;		affecting their image colours (disabled for BW PostScript)
;
;	Oct 1992, T.J.H.	2.11
;		Added clause for Colour PostScript so that colour PS is 
;		treated the same as any other device except that image values 
;		at 0b are replace with max_col so that dark background become 
;		light
;		Requires use of common PSET which is set by the psetup routines
;
;	Dec 1992, T.J.H.	2.12
;		Now Colour PS is treated EXACTLY the same as any other device
;
;	Nov 1993, T.J.H.	2.13
;		Updated the common PSET so that conflicts do not occur with
;		PSETUP routines
;
;	Dec 1993, T.J.H.	2.14
;		Added keywords CRANGE and BAR_RANGE. 
;		Made BAR values default to the system !z values (except range)
;		Now uses bytscl min/max parameters to restrict or expand the 
;		colour range used for the image.
;		
;	Dec 1993, T.J.H.	2.15
;		Amended the positioning of the image window and bar to allow 
;		for large numbers along the bar.
;
;	Feb 1994, T.J.H.	2.16 
;		Corrected bug introduced by mods v2.14 ("Now uses bytscl  
;		min/max parameters to restrict or expand the colour range used 
;		for the image.") which incorrectly handled Grey_scale_PS due  
;		to the image being inverted (a=-a) but the min and max  
;		variables used in bytscl were not !!.
;
;	Apr 1994, T.J.H.	2.17
;		Now use the _EXTRA keyword feature to pass any extra parameters
;		directly to CONTOUR. Corrected minor bug with colours of
;		contours when the BAR_RANGE differed from the value range of
;		the image
;
;	Jun 1994, T.J.H.	2.18
;		Added ability to choose between CONGRID and POLY_2D for image
;		resampling. Incorporated the new CUBIC feature for
;		interpolation for POLY_2D and CONGRID. Added the TOPCOLOUR and
;		BOTTOMCOLOUR keywords to allow the user to choose specific
;		colour ranges for the image. Modified the separation of the
;		colour bar from the image, and the height of the image and bar.
;		The BAR_RANGE and BAR_TICKV keywords are now checked and
;		interpretted regardless of whether the NOBAR keyword is set or
;		not (these keywords used to be only checked if a bar was
;		requested). The way that Grey_scale Postscript is detected has
;		been changed so that colour PS can be created without the use
;		of the PSCOLOUR,/COLOUR or PSETUP,/COLOUR calls.
;		In order to get PS grey-scale output then one of the following
;		has to be done:
;			1. Use PSCOLOUR,/GREY before calling TH_IMAGE_CONT,
;			regardless of whether PSETUP or Set_plot,'PS' has been
;			used 
;			2. use LOADCT,0 before calling TH_IMAGE_CONT
;			3. Do NOT load a colour table (the default table is
;			B/W Linear) but proceed to set the PS device using
;			either Set_plot,'PS' or PSETUP, and call TH_IMAGE_CONT
;
;	Aug 1994, T.J.H.	2.19
;		Added BAR_SEPARATION keyword
;
;	Aug 1994, T.J.H.	2.20
;		Forced to make ammendments to the contour calls to be
;		consistent with changes in that routine in going from IDL
;		VMS/AXP v3.5 --> v3.6. Specifically, the /DEV and /NOERASE
;		calls behaved differently on the second call to
;		contour. Replaced by the /OVERPLOT call. 
;		Added EXACT keyword and modified the default axes ranges.
;
;	Aug 1994, T.J.H.	2.21
;		Further mods to accomodate BUG in v3.6 which causes the plot
;		call to IGNORE the (x/y)range values but trim to the data.
;		The combination of PLOT and the /OVERPLOT keyword on CONTOUR
;		means that the plot call was setting the axes ranges now
;		rather than contour as before. Therefore the plot call
;		requires a style=1 bitmask
;
;	Oct 1994, T.J.H.	2.22
;		Mods to handle 24-bit colour displays. Specifically,
;			- Changed the definition of the bardat array by
;                         limiting !D.n_colors < !D.table_size
;                         (a not too big number).
;                       - Limited the top colour variable, topc, to be 
;                         < !D.table_size -2 
;		Nb: Can detect 24-bit by the !D.flag (true OR pseudo-color)
;		but there is no need.
;		Removed the -0.5 in the default x/yrange setting.
;		Use the EXACT keyword to get this action.
;
;	Nov 1994, T.J.H.	2.23
;		Allowed BARSZ_CHARS to be negative or zero. If <-0 then no bar
;		is produced although the calc are done for it and space
;		allowed. Values of <0 allow space for a bar of size
;		|BARSZ_CHARS| but no bar is produced.
;		Limited the top colour variable, topc,
;		to be < !D.table_size-1 again !! but default value is
;		!D.table_size-2 so user can use entire colour table.
;		Added keyword RAISE_PTITLE to allow the plot title position to
;		be modified. Default is the same value used prior to this MOD
;		(=1char unit * !P.charsize)
;
;
; IDENT = "2.23" ! The ident number must be incremented by .01
;                ! for every revision and reflected in amendments.
;-
;**************************** TH_IMAGE_CONT Code *****************************
;-----------------------------------------------------------------
PRO Th_image_cont, image, $
                   WINDOW_SCALE=window_scale, $
                   ASPECT=aspect, $
                   DEBUG=debug,  $
                   INTERP=interp, $
                   CONT=cont, $
                   NOCONT=nocont,  $
                   IMAGE_WINDOW=image_window, $
                   NOERASE=noerase, $
                   NOBAR=nobar,  $
                   CT=ct, $
                   MAX_VALUE=max_value, $
                   LEVELS=levels,  $
                   C_COLORS=c_colors, $
                   C_LINESTYLE=c_linestyle,  $
                   C_THICK=c_thick, $
                   NLEVELS=nlevels, $
                   XRANGE=xrange,  $
                   YRANGE=yrange, $
                   BADPTS=badpts, $
                   BAR_TICKS=bar_ticks, $
                   BAR_TICKNAME=bar_tickname, $
                   BAR_TICKV=bar_tickv, $
                   BAR_TICKLEN=bar_ticklen, $
                   BARSZ_CHARS=barsz_chars, $
                   TSIZE=tsize, $
                   BAR_RANGE=bar_range, $
                   CRANGE=crange,  $
                   CUBIC=cubic, $
                   CONGRID=congrid_keyword, $
                   TOPCOLOUR=topc, $
                   BOTTOMCOLOUR=bottomc, $
                   BAR_SEPARATION=bar_separation, $
                   EXACT=exact, $
                   RAISE_PTITLE=raise_ptitle, $
                   _EXTRA=_extra

  COMMON Pset, n, lfile, encaps, colour, bppix

  IF (KEYWORD_SET(debug) ) THEN  $
    message, /INFO, ' Entered Procedure......... please wait '

  IF (!D.name EQ 'NULL') THEN RETURN ;no more to do

  a = image * 1.0
  maximage = max(a, MIN=minimage) 
  maxbar = maximage & minbar = minimage
  
  ;; the defaults for the top and bottom colours allow the image colours to be
  ;; independent of the axes and background colours !P.color and !P.background
  ;; (normally 0 and !D.n_colors-1) 
  ;; NB: cant use KEYWORD_SET as 0 is a valid entry !!
  IF N_ELEMENTS(topc) EQ 0 THEN topc = !D.n_colors -2 ;Brightest color
                                ;(but allow room for plot and axes colours) 
  IF N_ELEMENTS(bottomc) EQ 0 THEN bottomc = 1 ;Dullest color
  
  ;;ensure that the top colour is in the colour table 
  topc = ((topc > 1) <(!D.n_colors -1) ) <(!D.table_size -1) 
  ;;and the bottom colour is less than the top
  bottomc = (bottomc <(topc -1) ) > 0
  ;;help,!d,/st

  on_error, 2                   ;Return to caller if an error occurs
  sz = size(a)                  ;Size of image
  IF sz(0) LT 2 THEN message, 'Parameter not 2D'

  IF (KEYWORD_SET(xrange) ) THEN !X.range = float(xrange) 
  IF (KEYWORD_SET(yrange) ) THEN !Y.range = float(yrange) 
  IF (KEYWORD_SET(crange) ) THEN bar_range = crange
  
  ;; NB: cant use KEYWORD_SET as 0 is a valid entry !!
  IF (N_ELEMENTS(bar_ticks) LE 0) THEN bar_ticks = !Z.ticks
  IF (NOT KEYWORD_SET(bar_tickv) ) THEN $
    IF (bar_ticks GT 0) THEN bar_tickv = !Z.tickv(0:bar_ticks) 
  IF (NOT KEYWORD_SET(bar_ticklen) ) THEN bar_ticklen = !Z.ticklen
  IF (NOT KEYWORD_SET(bar_tickname) ) THEN bar_tickname = !Z.tickname

  IF (!X.charsize GT 0) THEN xcharsize = !X.charsize ELSE xcharsize = 1.0
  IF (!P.charsize GT 0) THEN pcharsize = !P.charsize ELSE pcharsize = 1.0
  IF (NOT KEYWORD_SET(tsize) ) THEN tsize = pcharsize
  IF (N_ELEMENTS(raise_ptitle) LE 0 ) THEN raise_ptitle = 1

  pposition = !P.position
  pmulti = !P.multi
  
  IF (KEYWORD_SET(cont) ) THEN nobar = 1
  IF (KEYWORD_SET(nobar) ) THEN put_scale_bar = 0 ELSE put_scale_bar = 1
  
  ;;use plot to set the full window dimensions
  IF (!X.range(0) EQ !X.range(1) ) THEN xtmp = [ 0, sz(1) ] $ ;-0.5 $ 25/10/94
  ELSE xtmp = !X.range
  IF (!Y.range(0) EQ !Y.range(1) ) THEN ytmp = [ 0, sz(2) ] $ ;-0.5 $ 25/10/94
  ELSE ytmp = !Y.range
  plot, xtmp, ytmp, /NODATA, XSTYLE=5, YSTYLE=5,  $
    TITLE=' ', SUBTITLE=' ', XTITLE=' ', YTITLE=' ',  $
    NOERASE=KEYWORD_SET(noerase) 
    ;;XRANGE = xtmp, YRANGE=ytmp
                                ;get the full window dimensions
  xwin_sz = !X.window
  ywin_sz = !Y.window
                                ;x-char size in normalised coords is:
  xchar_sz = float(!D.x_ch_size) /float(!D.x_vsize) 
  
  ;;redefine the y size to allow enough room to put a Plot Title (!P.title) on
  ;;the image when the x-ticks are pointing out ! (this should really be
  ;;handled by the IDL internal routines but isnt YET !)
  yshrink_for_title = 2 * tsize * xchar_sz
  !P.position = [ xwin_sz(0),  $
                  ywin_sz(0), $
                  xwin_sz(1), $
                  ywin_sz(1) - yshrink_for_title]
  
                                ;size of window for scale bar
                                ;this needs to be outside put_scale_bar loop
                                ;for the recursive call ! 
  IF (N_ELEMENTS(barsz_chars) LE 0) THEN barsz_chars = 2.
  bar_sz = barsz_chars * xchar_sz

  IF (put_scale_bar) THEN BEGIN
    
    ;; NB: cant use KEYWORD_SET as 0 is a valid entry !!
    IF N_ELEMENTS(bar_separation) GT 0 THEN BEGIN
      bar_image_separation = bar_separation * xchar_sz
    ENDIF ELSE BEGIN
      bar_image_separation = 2. * xchar_sz
    ENDELSE
    bar_label_space = 2. * xchar_sz

    ;;now redefine the plot window width to allow enough room for a scale bar
    ;;!P.position(2) = !P.position(2) - (bar_sz*4.5) - (-2.*!Y.ticklen > 0.0)
    !P.position(2) = !P.position(2) $ ;the user defined position of RHS
      - abs(bar_sz)  $               ;but allow enough room for the colour bar
      -( -2. * !Y.ticklen > 0.0) $ ;and the ticks on both the bar and image
      - bar_image_separation $  ;and space between bar and image and
      - bar_label_space         ;space for the label on the bar and the title
    
    
    IF !P.position(2) LT !P.position(0) THEN BEGIN 
      IF (KEYWORD_SET(debug) ) THEN message, /INFO, ' WARNING...'  
      message, /INFO, 'There is NOT enough room for the colour scale bar' 
      message, /INFO, 'to fit into the plotting window !!!' 
      !P.position(2) = !P.position(2) >(!P.position(0) +xchar_sz) 
    ENDIF
  ENDIF                         ;put_scale_bar
  
  ;;if bar_tickv set then force the image to have at least this range
  IF (KEYWORD_SET(bar_tickv) ) THEN BEGIN
    maxbar = max([ bar_tickv, maximage, minimage], MIN=minbar) 
    ;;        IF (maxbar GT maximage) THEN a(sz(1)-1, sz(2)-1) = maxbar
    ;;        IF (minbar LT minimage) THEN a(sz(1)-1, 0) = minbar
  ENDIF ELSE BEGIN
    maxbar = maximage
    minbar = minimage
  ENDELSE

  ;;if bar_range set then force the image to have exactly this range
  ;; (over-rides the bar_tickv forcing)
  IF (KEYWORD_SET(bar_range) ) THEN BEGIN
    IF (bar_range(0) NE bar_range(1) ) THEN BEGIN
      maxbar = bar_range(1) & minbar = bar_range(0) 
      ;;            IF (maxbar GT maximage) THEN a(sz(1)-1, sz(2)-1) = maxbar
      ;;            IF (minbar LT minimage) THEN a(sz(1)-1, 0) = minbar
      ;;            ;;clip the image array if necessary
      ;;            a = a > minbar < maxbar
      ;;            ;;the array is now clipped at the bytscl stage

                                ;if (keyword_set(debug)) then begin
      IF (maxbar LT maximage) THEN BEGIN
        IF (KEYWORD_SET(debug) ) THEN BEGIN
          message, /INFO, $
            " WARNING...Maximum image value out of range, Image CLIPPED"
        ENDIF ELSE BEGIN
          message, /INFO, $
            "...Maximum image value out of range, Image CLIPPED"
        ENDELSE
      ENDIF
      IF (minbar GT minimage) THEN BEGIN
        IF (KEYWORD_SET(debug) ) THEN BEGIN
          message, /INFO, $
            " WARNING...Minimum image value out of range, Image CLIPPED"
        ENDIF ELSE BEGIN
          message, /INFO, $
            "...Minimum image value out of range, Image CLIPPED"
        ENDELSE
      ENDIF

    ENDIF                       ;valid bar_range
  ENDIF                         ; bar_range

  ;;use plot to set the scaling with the new window
  plot, xtmp, ytmp, /NODATA, XSTYLE=5, YSTYLE=5, $
    TITLE=' ', SUBTITLE=' ', XTITLE=' ', YTITLE=' ', /NOERASE
  ;;XRANGE=xtmp, YRANGE=ytmp

  ;;MOVED to the bytscl code ~20 lines down
  ;; reverse the colour sense of the image if producing greyscale PS output 
  ;;if (!d.name eq 'PS') then a = -a
  
  grey_scale_PS = 0b            ;default is IN COLOUR for ALL devices
  IF (!D.name EQ 'PS') THEN BEGIN ;the output device is PostScript
    IF KEYWORD_SET(debug) THEN message, /INFO, 'PostScript device Detected'
    ;;if the PSETUP suite of routines have been used and the colour variable
    ;;has been set then dont worry about checking for grey-scales
    IF N_ELEMENTS(colour) GT 0 THEN BEGIN
      IF KEYWORD_SET(debug) THEN message, /INFO, '"colour" variable is defined'
      IF KEYWORD_SET(debug) THEN help, colour
      grey_scale_PS = NOT colour
    ENDIF ELSE BEGIN
      ;;decide if the default grey-scale has been loaded
      IF KEYWORD_SET(debug) THEN message, /INFO, 'Getting current colour table'
      tvlct, /GET, r, g, b      ;load in the colour table
      grey_scale_PS = min((r AND g AND b) EQ r) 
    ENDELSE
    IF KEYWORD_SET(debug) THEN help, grey_scale_PS
  ENDIF

  image_window = [ !X.window(0), !Y.window(0), !X.window(1), !Y.window(1) ]

  px = !X.window * !D.x_vsize	;Get size of window in device units
  py = !Y.window * !D.y_vsize
  swx = px(1) -px(0)            ;Size in x in device units
  swy = py(1) -py(0)            ;Size in Y
  six = float(sz(1) )           ;Image sizes
  siy = float(sz(2) ) 
  aspi = six / siy		;Image aspect ratio
  aspw = swx / swy		;Window aspect ratio
  f = aspi / aspw               ;Ratio of aspect ratios

  IF (!D.name NE 'TEK') AND (NOT KEYWORD_SET(cont) ) THEN BEGIN 
    ;;we can use tvscl

    IF (KEYWORD_SET(debug) ) THEN message, /INFO, ' .......... Imaging....'

    IF (N_ELEMENTS(ct) GT 0) THEN loadct, ct

    IF (grey_scale_PS) THEN BEGIN
      IF (KEYWORD_SET(debug) ) THEN BEGIN
        message, /INFO, 'Grey-Scale PostScript Image...'
        message, /INFO, '   ... reversing colour sense of image so dark '
        message, /INFO, '   backgrounds come out light'
      ENDIF
      
      a = -a                    ;reverse the colour sense of the image if
                                ;producing postscript output so that those
                                ;dark backgrounds come out light !!
      
      ;;rescale into the allowed colour range then shift up to the bottom
      ;;colour index 
      bbb = bytscl(a, MIN=-maxbar, MAX=-minbar, TOP=topc -bottomc) +  $
        bottomc
      
    ENDIF ELSE BEGIN
      IF (KEYWORD_SET(debug) ) THEN BEGIN
        message, /INFO, 'Colour Image...  '
      ENDIF
      ;;rescale into the allowed colour range then shift up to the bottom
      ;;colour index 
      bbb = bytscl(a, MIN=minbar, MAX=maxbar, TOP=topc -bottomc) + bottomc
      ;;if (!d.name eq 'PS') then bbb(where(bbb eq 1b)) = topc
    ENDELSE
    
    IF (KEYWORD_SET(debug) ) THEN BEGIN
      fstr =  $
        '("[",f8.2,",",f8.2,"] ==> [",f8.2,",",f8.2,"] ==> [",i3,",",i3,"]")'
      message, /INFO, 'byte scaled....' + $
        strcompress( string( minimage, maximage,  $
                             minbar, maxbar, min(bbb), max(bbb), $
                             FORM=fstr) ) 
                                ;help,/dev
    ENDIF

    IF (!D.flags AND 1) NE 0 THEN BEGIN	;Scalable pixels?
      IF (KEYWORD_SET(debug) ) THEN  $
        message, /INFO, 'Scalable pixels detected'
      
      IF KEYWORD_SET(aspect) THEN BEGIN ;Retain aspect ratio?
        IF f GE 1.0 THEN swy = swy / f  $
        ELSE swx = swx * f      ;Adjust window size
      ENDIF

      tv, bbb, px(0), py(0), XSIZE=swx, YSIZE=swy, /DEVICE

    ENDIF ELSE BEGIN            ;END scalable pixels	
      IF (KEYWORD_SET(debug) ) THEN  $
        message, /INFO, 'NON-Scalable pixels detected'
      IF KEYWORD_SET(window_scale) THEN BEGIN ;Scale window to image?
        tv, bbb, px(0), py(0)   ;Output image
        swx = six		;Set window size from image
        swy = siy
      ENDIF ELSE BEGIN          ;End Scale window to image
        IF (KEYWORD_SET(debug) ) THEN  $
          message, /INFO, 'Scale image to window'
        IF KEYWORD_SET(aspect) THEN BEGIN
          IF f GE 1.0 THEN swy = swy / f ELSE swx = swx * f
        ENDIF                   ;aspect
        
        ;;Have to resample image
        IF KEYWORD_SET(congrid_keyword) THEN BEGIN
          resampled_image = congrid(bbb, $
                                    swx,  $
                                    swy,  $
                                    INTERP=KEYWORD_SET(interp), $
                                    CUBIC=KEYWORD_SET(cubic) ) 
        ENDIF ELSE BEGIN
          resampled_image = poly_2d(bbb, $	
                                    [[ 0, 0], [ six /swx, 0]],  $
                                    [[ 0, siy /swy], [ 0, 0]], $
                                    KEYWORD_SET(interp),  $
                                    swx,  $
                                    swy,  $
                                    CUBIC=KEYWORD_SET(cubic) ) 
        ENDELSE
        
        tv, resampled_image, px(0), py(0) 
        
      ENDELSE			;End Scale image to window
    ENDELSE                     ;scalable pixels
  ENDIF

  ;;use contour to give the axes all the time
  ppmulti = !P.multi
  !P.multi = pmulti
  IF (!X.style EQ 2) THEN xstyle = 1
  IF ((!X.style MOD 2) EQ 0) THEN xstyle = 1 +!X.style ELSE xstyle = !X.style
  IF (!Y.style EQ 2) THEN ystyle = 1
  IF ((!Y.style MOD 2) EQ 0) THEN ystyle = 1 +!Y.style ELSE ystyle = !Y.style
  c_sz = sz
  IF KEYWORD_SET(exact) THEN BEGIN
    c_x = ((indgen(c_sz(1) ) +0.5) *(xtmp(1) -xtmp(0) ) /(c_sz(1) ) )  $
      +xtmp(0) 
    c_y = ((indgen(c_sz(2) ) +0.5) *(ytmp(1) -ytmp(0) ) /(c_sz(2) ) )  $
      +ytmp(0) 
  ENDIF ELSE BEGIN
    c_x = (indgen(c_sz(1) ) *(xtmp(1) -xtmp(0) ) /(c_sz(1) -1 ) ) +xtmp(0) 
    c_y = (indgen(c_sz(2) ) *(ytmp(1) -ytmp(0) ) /(c_sz(2) -1 ) ) +ytmp(0) 
  ENDELSE
  
  contour, a, c_x, c_y, /NOERASE, /NODATA,  $
    XRANGE=xtmp, YRANGE=ytmp, $
    XSTYLE=xstyle, YSTYLE=ystyle, TITLE=' ', SUBTITLE=' '

  ;;find the position for the title and put it there
  xpos = 0.5 * total(!X.window) 
  ;;if (!x.charsize gt 0) then xcharsize=!x.charsize else xcharsize=1.0
  ;;if (!p.charsize gt 0) then pcharsize=!p.charsize else pcharsize=1.0
  ;;if (not keyword_set(tsize)) then tsize = pcharsize
  ch_dev_to_norm = pcharsize * !D.y_ch_size /!D.y_vsize 
  ;;ypos = !y.window(1) + (-!x.ticklen > 0.0) +2.7*xcharsize*ch_dev_to_norm
  ypos = !Y.window(1) +( -!X.ticklen > 0.0)  $
    +raise_ptitle * xcharsize * ch_dev_to_norm
  xyouts, xpos, ypos, !P.title, ALIGNMENT=0.5, /NORM, SIZE=tsize * 1.2

  ;;find the position for the subtitle and put it there
  ypos = !Y.window(0) -( -!X.ticklen > 0.0)  $
    -(2.7 * xcharsize +tsize) * ch_dev_to_norm
  xyouts, xpos, ypos, !P.subtitle, ALIGNMENT=0.5, /NORM, SIZE=tsize

  cloop = 0
  IF (NOT KEYWORD_SET(nocont) ) THEN BEGIN

    ;;use contour to give data contours on top of the image
    IF (KEYWORD_SET(debug) ) THEN message, /INFO, ' .......... Contouring....'

    ;;need to reset the ranges because the axis labels are independent 
    ;;of the way contour works (plots as index numbers)
    save_p = !P
    save_x = !X
    save_y = !Y	
    save_z = !Z	
    resetplt, /ALL
    clearplt, /ALL
    !X.style = 5
    !Y.style = 5
    !P.multi = pmulti
    IF (!P.thick LE 0) THEN !P.thick = 1

                                ;plot contours
    IF (KEYWORD_SET(levels) ) THEN csz = N_ELEMENTS(levels) $
    ELSE IF (KEYWORD_SET(nlevels) ) THEN csz = nlevels +1 ELSE csz = 6
    IF (NOT KEYWORD_SET(max_value) ) THEN max_value = maximage +1

    keyc_colors = KEYWORD_SET(c_colors) 
    keyc_linestyle = KEYWORD_SET(c_linestyle) 
    keyc_thick = KEYWORD_SET(c_thick) 

    cont_image = image * 1.0
    IF (KEYWORD_SET(badpts) ) THEN BEGIN
      IF (badpts(0) GE 0) THEN cont_image(badpts) = 10 * maximage
    ENDIF
    
    c_sz = size(cont_image) 
    IF KEYWORD_SET(exact) THEN BEGIN
      c_x = ((indgen(c_sz(1) ) +0.5) *(xtmp(1) -xtmp(0) ) /(c_sz(1) ) )  $
        +xtmp(0) 
      c_y = ((indgen(c_sz(2) ) +0.5) *(ytmp(1) -ytmp(0) ) /(c_sz(2) ) )  $
        +ytmp(0) 
    ENDIF ELSE BEGIN
      c_x = (indgen(c_sz(1) ) *(xtmp(1) -xtmp(0) ) /(c_sz(1) -1 ) ) +xtmp(0) 
      c_y = (indgen(c_sz(2) ) *(ytmp(1) -ytmp(0) ) /(c_sz(2) -1 ) ) +ytmp(0) 
    ENDELSE
      
  
    IF (KEYWORD_SET(levels) ) THEN BEGIN
      cloop = 1
      IF (NOT keyc_colors) THEN c_colors =  $
        (fix((((levels -minbar) /float(maxbar -minbar) ) * 0.5 + 0.75)  $
             *(topc -bottomc) ) MOD(topc -bottomc +1) ) + bottomc
      IF (NOT keyc_linestyle) THEN c_linestyle = levels * 0
      IF (NOT keyc_thick) THEN c_thick = levels * 0 +!P.thick
      zero = where(levels EQ 0, count) 
      zero = zero(0) 
      IF (count * zero GT 0) THEN BEGIN
        ;; do special things to highlight the zero contour
        IF (NOT keyc_colors) AND (KEYWORD_SET(cont) ) THEN $
          c_colors(zero) = topc
        IF (NOT keyc_thick) THEN BEGIN
          IF (KEYWORD_SET(cont) ) THEN  $
            c_thick(zero) = 2.5 * !P.thick  $
          ELSE  $
            c_thick(zero) = 2.0 * !P.thick
        ENDIF
        IF (NOT keyc_linestyle) AND  $
          (KEYWORD_SET(cont) ) THEN c_linestyle(0:zero -1) = 1 
      ENDIF
      IF (NOT keyc_colors) AND (grey_scale_PS) AND (KEYWORD_SET(cont) ) THEN  $
        c_colors = topc
                                ;invert line colors if b/w postscript output
      IF (grey_scale_PS) THEN usec_cols = topc - c_colors + bottomc $
      ELSE usec_cols = c_colors

      contour, cont_image, c_x, c_y, /OVERPLOT, $
        POS=[ px(0), py(0), px(0) +swx, py(0) +swy], $
        MAX_VALUE=max_value, C_COLORS=usec_cols, $
        C_LINESTYLE=c_linestyle, C_THICK=c_thick, $
        LEVELS=levels, _EXTRA=_extra

    ENDIF ELSE BEGIN
      cloop = 2
      IF (NOT keyc_colors) THEN c_colors =  $
        [ replicate(topc, (csz /2 > 1) ),  $
          replicate(bottomc +(topc -bottomc) /4, (csz /2 +1 > 1) ) ]
      IF (NOT keyc_linestyle) THEN c_linestyle = replicate(0, csz) 
      IF (NOT keyc_thick) THEN c_thick = [ !P.thick]
      IF (NOT KEYWORD_SET(nlevels) ) THEN nlevels = csz -1
      
                                ;invert line colors if b/w postscript output
      IF (grey_scale_PS) THEN usec_cols = topc - c_colors + bottomc $
      ELSE usec_cols = c_colors

      contour, cont_image, c_x, c_y, /OVERPLOT, $
        POS=[ px(0), py(0), px(0) +swx, py(0) +swy], $
        MAX_VALUE=max_value, C_COLORS=usec_cols, $
        C_LINESTYLE=c_linestyle, C_THICK=c_thick, $
        NLEVELS=nlevels, _EXTRA=_extra

    ENDELSE

    cont_image = 0              ;release some space NOW

    !P = save_p
    !X = save_x
    !Y = save_y
    !Z = save_z
  ENDIF

  IF put_scale_bar AND (bar_sz GT 0) THEN BEGIN
    ;;add a scale bar by calling this routine AGAIN
    
    IF (KEYWORD_SET(debug) ) THEN  $
      message, /INFO, ' .......... adding Scale Bar....'

    ;;do it !!!
    ;;now redefine the plot position for a scale bar
    ;;Note that the y pos must be re-enlarged for the shrinkage that took place
    ;;for the Plot title, as the recursive call will do the shrinkage AGAIN !!
    
    !P.position = [ !X.window(1) +  $
                    bar_image_separation + ( -!Y.ticklen > 0.0), $
                    !Y.window(0), $
                    !X.window(1) +  $
                    abs(bar_sz) + bar_label_space +( -!Y.ticklen > 0.0), $
                    !Y.window(1) + yshrink_for_title]
                                ;use image_cont again to do scale bar
    save_p = !P
    save_x = !X
    save_y = !Y
    clearplt, /X, /Y, /P
    !P.multi = pmulti
    !P.thick = save_p.thick
    !P.ticklen = save_p.ticklen
    !X.minor = -1 & !X.ticklen = 0.000001
                                ;if bar_tickv set then force the image to
                                ;have at least this range
                                ;maxscl = max([maxbar,maximage])
                                ;minscl = min([minbar,minimage])
    ;;bardat = (findgen(!D.n_colors) /(!D.n_colors -1) *(maxbar -minbar) ) $
    ;;  + minbar
    bar_dim = !D.n_colors < !D.table_size
    bardat = (findgen(bar_dim) /(bar_dim -1) *(maxbar -minbar) ) + minbar
    bardat = transpose([[ bardat], [ bardat]]) 
    !X.style = 1
    !Y.style = 1
    
    CASE (cloop) OF
      
      0: th_image_cont, bardat, /NOBAR, /NOERASE,  $
        NOCONT=KEYWORD_SET(nocont), TOPC=topc, BOTTOMC=bottomc
      
      1: th_image_cont, bardat, /NOBAR, /NOERASE,  $
        NOCONT=KEYWORD_SET(nocont), TOPC=topc, BOTTOMC=bottomc, $
        MAX_VALUE=max_value, C_COLORS=c_colors, $
        C_LINESTYLE=c_linestyle, C_THICK=c_thick, LEVELS=levels, $
        _EXTRA=_extra
      
      2: th_image_cont, bardat, /NOBAR, /NOERASE,  $
        NOCONT=KEYWORD_SET(nocont), TOPC=topc, BOTTOMC=bottomc, $
        MAX_VALUE=max_value, C_COLORS=c_colors, $
        C_LINESTYLE=c_linestyle, C_THICK=c_thick, NLEVELS=nlevels, $
        _EXTRA=_extra
      
    ENDCASE
    resetplt, /Y
    !P.charsize = save_p.charsize
    !Y.charsize = save_y.charsize
    !Y.ticklen = save_y.ticklen
    IF (N_ELEMENTS(bar_ticks) GT 0) THEN !Y.ticks = bar_ticks ELSE $
      IF (NOT KEYWORD_SET(bar_range) ) AND ((maxbar -minbar) LE 10.0) $
      THEN !Y.ticks = 2
    IF (KEYWORD_SET(bar_tickv) ) THEN BEGIN
      !Y.tickv = bar_tickv
      !Y.ticks = N_ELEMENTS(bar_tickv) -1
    ENDIF
    !Y.range = [ minbar, maxbar]
    IF (KEYWORD_SET(bar_tickname) ) THEN !Y.tickname = bar_tickname
    IF (KEYWORD_SET(bar_ticklen) ) THEN !Y.ticklen = bar_ticklen
    !Y.ticklen = !Y.ticklen *  $
      (image_window(2) -image_window(0) )  $
      /(save_p.position(2) -save_p.position(0) ) 
    axis, /YAX, YTITLE=!Z.title, YSTYLE=1, /NOERASE
    
    !P = save_p
    !X = save_x
    !Y = save_y
  ENDIF

  !P.position = pposition
  !P.multi = ppmulti

  RETURN
END


PRO XV_Colors_Set, info
   COMMON COLORS, rr, gg, bb, rc, gc, bc
   rc =  rr
   gc =  gg
   bc =  bb

   IF(info.currentBottom GT info.currentTop) THEN BEGIN
      isReversed = 1
      bottom = info.bottom + info.ncolors - 1
      top =  info.bottom
   END ELSE BEGIN
      isReversed = 0
      bottom =  info.bottom
      top =  info.top
   END

   rc(info.bottom:info.currentbottom) = rr(bottom)
   gc(info.bottom:info.currentbottom) = gg(bottom)
   bc(info.bottom:info.currentbottom) = bb(bottom)
   rc(info.currenttop:info.top) = rr(top)
   gc(info.currenttop:info.top) = gg(top)
   bc(info.currenttop:info.top) = bb(top)

   number = abs(info.currenttop-info.currentbottom) + 1
   gamma = info.gamma

   index = Findgen(info.ncolors)
   distribution = index^gamma
   index = Round(distribution * (info.ncolors-1) / Max(distribution))

   IF (isReversed EQ 0) THEN BEGIN
      rc(info.currentbottom:info.currenttop) = Congrid(rr(index), number)
      gc(info.currentbottom:info.currenttop) = Congrid(gg(index), number)
      bc(info.currentbottom:info.currenttop) = Congrid(bb(index), number )
   ENDIF ELSE BEGIN
      rc(info.currentTop:info.currentBottom) = $
       Reverse(Congrid(rr(index), number))
      gc(info.currentTop:info.currentBottom) = $
       Reverse(Congrid(gg(index), number))
      bc(info.currentTop:info.currentBottom) = $
       Reverse(Congrid(bb(index), number))
   ENDELSE

   TVLCT, rc, gc, bc
   OLD_WINDOW = !D.WINDOW
   WSet, info.windowindex
   TV, info.colorimage
   WSet, OLD_WINDOW

   ;; Are there widgets to notify?
   s = SIZE(info.notifyID)
   IF s(0) EQ 1 THEN count = 0 ELSE count = s(2)-1
   FOR j=0,count DO BEGIN
      colorEvent = { XV_COLORS_LOAD, $
                     ID:info.notifyID(0,j), $
                     TOP:info.notifyID(1,j), $
                     HANDLER:0L, $
                     R:rc, $
                     G:gc, $
                     B:bc }
      IF Widget_Info(info.notifyID(0,j), /Valid_ID) THEN $
       Widget_Control, info.notifyID(0,j), Send_Event=colorEvent
   ENDFOR
END


PRO XV_COLORS_GAMMA_SLIDER, event
   COMMON XV_FLAGS, Flags
   Flags.CDF_COLOR =  0
   ;; Get the info structure from storage location.
   Widget_Control, event.top, Get_UValue=info, /No_Copy

   ;; Get the gamma value from the slider.
   Widget_Control, event.id, Get_Value=gamma
   gamma = 10^((gamma/50.0) - 1)
   info.gamma = gamma

   ;; Update the gamma label.
   Widget_Control, info.gammaID, Set_Value=String(gamma, Format='(F6.3)')

   ;; Load the colors.
   XV_Colors_Set, info

   ;; Put the info structure back in storage location.
   Widget_Control, event.top, Set_UValue=info, /No_Copy
END



PRO XV_COLORS_COLORTABLE, event
   COMMON COLORS, rr, gg, bb, rc, gc, bc

   ;; Get the info structure from storage location.
   Widget_Control, event.top, Get_UValue=info, /No_Copy

   LoadCt, event.index, File=info.file, /Silent, $
    NColors=info.ncolors, Bottom=info.bottom

   TVLct, r, g, b, /Get
   rr = r
   gg = g
   bb = b
   rc = r
   gc = g
   bc = b

   ;; Update the slider positions and values.
   Widget_Control, info.botSlider, Set_Value=0
   Widget_Control, info.topSlider, Set_Value=info.ncolors-1
   Widget_Control, info.gammaSlider, Set_Value=50
   Widget_Control, info.gammaID, Set_Value=String(1.0, Format='(F6.3)')
   info.currentBottom = info.bottom
   info.currentTop = info.top
   info.gamma = 1.0

   ;; Update the colors.
   XV_Colors_Set, info

   ;; Put the info structure back in storage location.
   Widget_Control, event.top, Set_UValue=info, /No_Copy
END



PRO XV_COLORS_BOTTOM_SLIDER, event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit, Record2
   COMMON XV_FLAGS, Flags
   Flags.CDF_COLOR =  0
   ;; Get the info structure from storage location.
   Widget_Control, event.top, Get_UValue=info, /No_Copy

   ;; Update the current bottom value of the slider.
   info.currentBottom = info.bottom + event.value
   Curr_Limit(0) = info.currentBottom(0)

   ;; Error handling. Is currentBottom = currentTop?
   IF info.currentBottom EQ info.currentTop THEN BEGIN
      info.currentBottom = info.currentTop
      Widget_Control, info.botSlider, Set_Value=(info.currentBottom-info.bottom)
   ENDIF

   ;; Update the colors.
   XV_Colors_Set, info

   ;; Put the info structure back in storage location.
   Widget_Control, event.top, Set_UValue=info, /No_Copy
END


PRO XV_COLORS_PROTECT_COLORS, event
   ;; Get the info structure from storage location.
   Widget_Control, event.top, Get_UValue=info, /No_Copy

   ;; Update the colors.
   XV_Colors_Set, info

   Widget_control,event.id, INPUT_FOCUS=0
   ;; Put the info structure back in storage location.
   Widget_Control, event.top, Set_UValue=info, /No_Copy
END


PRO XV_COLORS_TOP_SLIDER, event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FLAGS, Flags
   Flags.CDF_COLOR =  0
   ;; Get the info structure from storage location.
   Widget_Control, event.top, Get_UValue=info, /No_Copy

   ;; Update the current top value of the slider.
   info.currentTop = info.bottom + event.value
   Curr_Limit(1) =  info.currentTop

   ;; Update the colors.
   XV_Colors_Set, info

   ;; Put the info structure back in storage location.
   Widget_Control, event.top, Set_UValue=info, /No_Copy
END


PRO XV_RESET, event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FLAGS, Flags
   COMMON XV_COLORS, Limits
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   Widget_Control, event.top, Get_UValue=info

   Ncolors =  info.ncolors
   ratio = float(ncolors) / 256.0

   Limits(0) = FIX(Record.limit_lo * ratio)
   Limits(1) = FIX(Record.limit_hi * ratio)
   CURR_LIMIT = Limits

   XV_LOAD_COLOR_TABLE, Fid
   event = {WIDGET_SLIDER, ID:info.botSlider, TOP:event.top, HANDLER:0L, VALUE:Limits(0), DRAG:0}
   WIDGET_CONTROL, info.botSlider, send_event=event, SET_VALUE=Limits(0)

   event = {WIDGET_SLIDER, ID:info.topSlider, TOP:event.top, HANDLER:0L, VALUE:Limits(1), DRAG:0}
   WIDGET_CONTROL, info.topSlider, send_event=event, SET_VALUE=Limits(1)

   event =  {WIDGET_SLIDER, ID:info.gammaSlider, TOP:event.top, HANDLER:0L, VALUE:50, DRAG:0}
   WIDGET_CONTROL, info.gammaSlider, send_event=event, SET_VALUE=50
END


PRO XV_COLORS_DISMISS, event
   Widget_Control, event.top, /Destroy
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This program is a modified version of David Fannings XCOLORS program.
;;; http://www.dfanning.com
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO XV_COLORS, NColors=ncolors, Bottom=bottom, Title=title, File=file, $
             Group_Leader=group, XOffset=xoffset, YOffset=yoffset, Just_Reg=jregister, $
             NotifyID=notifyID, Range=range
   COMMON COLORS, rr, gg, bb, rc, bc, gc
   COMMON XV_COLORS, Limits

   ;; This is a procedure to load color tables into a
   ;; restricted color range of the physical color table.
   ;; It is a highly simplified version of XLoadCT.
   On_Error, 1

   ;; Make sure colors are initiated.
   thisWindow = !D.Window
   Window, /Free, /Pixmap, XSize=10, YSize=10
   WDelete, !D.Window
   IF thisWindow GE 0 THEN WSet, thisWindow

   ;; Check keyword parameters. Define defaults.
   IF N_Elements(range) EQ 2 THEN Limits =  range ELSE $
    IF(N_ELEMENTS(Limits) EQ 0) THEN Limits =  [0,255]
   IF N_Elements(ncolors) EQ 0 THEN ncolors = 256 < !D.N_Colors
   IF N_Elements(bottom) EQ 0 THEN bottom = 0
   top = bottom + (ncolors-1)
   IF N_Elements(title) EQ 0 THEN title = 'Load Color Tables'
   IF N_ELements(file) EQ 0 THEN $
    file = Filepath(SubDir=['resource','colors'], 'colors1.tbl')
   IF N_Elements(notifyID) EQ 0 THEN notifyID = [-1L, -1L]

   ;; Find the center of the display.
   DEVICE, GET_SCREEN_SIZE=screenSize
   xv_center = FIX(screenSize(0) / 2.0)
   yCenter = FIX(screenSize(1) / 2.0)

   IF N_ELEMENTS(xoffset) EQ 0 THEN xoffset = xv_center - 150
   IF N_ELEMENTS(yoffset) EQ 0 THEN yoffset = yCenter - 200

   IF N_Elements(xoffset) EQ 0 THEN xoffset = 100
   IF N_Elements(yoffset) EQ 0 THEN yoffset = 100
   registerName = 'XV_COLORS:' + title

   ;; Only one XV_COLORS with this title.
   IF XRegistered(registerName) THEN RETURN

   ;; Create the top-level base. No resizing.
   tlb = Widget_Base(Title=title, TLB_Frame_Attr=1, $
                     XOffSet=xoffset, YOffSet=yoffset,/COLUMN)

   ;; Create a draw widget to display the current colors.
   draw = Widget_Draw(tlb, retain=0,$
                      XSize=256, YSize=40, /FRAME, $
                      event_PRO='xv_colors_protect_colors')

   ;; Create sliders to control stretchs and gamma correction.
   sliderbase = Widget_Base(tlb, Column=1, Frame=1)
   botSlider = Widget_Slider(sliderbase, Value=Limits(0), Min=0, $
                             Max=ncolors-1, XSize=256, /Drag, Event_Pro='XV_Colors_Bottom_Slider', $
                             Title='Stretch Bottom')
   topSlider = Widget_Slider(sliderbase, Value=Limits(1), Min=0, $
                             Max=ncolors-1, XSize=256, /Drag, Event_Pro='XV_Colors_Top_Slider', $
                             Title='Stretch Top')
   gammaID = Widget_Label(sliderbase, Value=String(1.0, Format='(F6.3)'))
   gammaSlider = Widget_Slider(sliderbase, Value=50.0, Min=0, Max=100, $
                               /Drag, XSize=256, /Suppress_Value, Event_Pro='XV_Colors_Gamma_Slider', $
                               Title='Gamma Correction')

   ;; Get the colortable names for the list widget.
   colorNames=''
   LoadCt, Get_Names=colorNames
   FOR j=0,N_Elements(colorNames)-1 DO $
    colorNames(j) = StrTrim(j,2) + ' - ' + colorNames(j)
   filebase = Widget_Base(tlb, Column=1, /Frame)
   listlabel = Widget_Label(filebase, Value='Select Color Table...')
   list = Widget_List(filebase, Value=colorNames, YSize=8, Scr_XSize=256, $
                      Event_Pro='XV_Colors_ColorTable')

   ;; Dialog Buttons
   reset =  WIDGET_BUTTON(tlb, VALUE='Reset Color Table',$
                          Event_PRO= 'XV_Reset', UVALUE='RESET')
   dismiss = Widget_Button(tlb, Value='Accept', $
                           Event_Pro='XV_Colors_Dismiss', UVALUE='ACCEPT')
   Widget_Control, tlb, /Realize

   ;; Get window index number of the draw widget.
   Widget_Control, draw, Get_Value=windowIndex
   OLD_WINDOW =  !D.WINDOW
   WSet, windowIndex

   ;; Put a picture of the color table in the window.
   colorImage = BIndgen(256,40)
   colorRow = BIndgen(ncolors)
   colorRow = Congrid(colorRow, 256)
   FOR j=0,39 DO colorImage(*,j) = colorRow
   colorImage = BytScl(colorImage, Top=ncolors-1) + bottom
   Tv, colorImage
   Wset, OLD_WINDOW

   ;; Create an info structure to hold information to run the program.
   info = {  windowIndex:windowIndex, $ ; The WID of the draw widget.
             botSlider:botSlider, $ ; The widget ID of the bottom slider.
             topSlider:topSlider, $ ; The widget ID of the top slider.
             gammaSlider:gammaSlider, $ ; The widget ID of the gamma slider.
             currentBottom:Limits(0), $ ; The current bottom slider value.
             currentTop:Limits(1), $  ; The current top slider value.
             gammaID:gammaID, $ ; The widget ID of the gamma label
             ncolors:ncolors, $ ; The number of colors we are using.
             gamma:1.0, $       ; The current gamma value.
             file:file, $       ; The name of the color table file.
             bottom:bottom, $   ; The bottom color index.
             top:top, $         ; The top color index.
             notifyID:notifyID, $ ; Notification widget IDs.
             colorimage:colorimage } ; The color table image.

   ;; Store the info structure in the user value of the top-level base.
   Widget_Control, tlb, Set_UValue=info, /No_Copy
   XManager,registerName,tlb,group=group,/NO_BLOCK

   ; Use psuedo structure to initialize the program
   psuedo = {  windowIndex:windowIndex, $ ; The WID of the draw widget.
               botSlider:botSlider, $ ; The widget ID of the bottom slider.
               topSlider:topSlider, $ ; The widget ID of the top slider.
               gammaSlider:gammaSlider, $ ; The widget ID of the gamma slider.
               currentBottom:Limits(0), $ ; The current bottom slider value.
               currentTop:Limits(1), $ ; The current top slider value.
               gammaID:gammaID, $ ; The widget ID of the gamma label
               ncolors:ncolors, $ ; The number of colors we are using.
               gamma:1.0, $     ; The current gamma value.
               file:file, $     ; The name of the color table file.
               bottom:bottom, $ ; The bottom color index.
               top:top, $       ; The top color index.
               notifyID:notifyID, $ ; Notification widget IDs.
               colorimage:colorimage } ; The color table image.
   XV_COLORS_SET, psuedo
END

;----------------------------------------------------------
; PURPOSE:
;  Converts rectangular coordinates to spherical coordinates.
;
; CALLING SEQUENCE:
;  pt = [1.3, 3.2, 1.8]
;  RECSPHD, PT, R, THETA, PHI
;
; INPUTS:
;  LOC   == A 3-element array or a 3xN element array representing
;           cartesian points in 3 space.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  R     == A named variable returning the spherical radius
;  THETA == A named variable returning the THETA angle in DEGREES
;           Theta is the angle relative to the Z axis.
;  PHI   == A named variable returning the PHI angle in DEGREES
;           PHI is the angle in the XY plane.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FORWARD_FUNCTION arrayNorm

PRO recsphd, loc, r, theta, phi
   sz =  size(loc)
   IF(sz(0) EQ 1) THEN BEGIN
      sz = 1
   END ELSE sz = sz(2)

   PHI = dblarr(sz)
   Theta = phi
   R =  arrayNORM(DOUBLE(LOC))

   j =  where(r LE 0, count)
   IF(count GT 0) THEN BEGIN
      THETA(j) =  0.0
      RETURN
   END

   j =  where(r GT 0, count)
   IF(count GT 0) THEN BEGIN
      THETA(j) = ACOS( loc[2,*] / r ) * !RADEG

      PHI(j) =  ATAN(loc[1,*], loc[0,*]) * !RADEG
      k =  where(phi LT 0,count)
      IF(count GT 0) THEN phi(k) = phi(k) + 360.0D0
   END


;   IF (R LE 0) THEN BEGIN
;      THETA = 0.0
;      RETURN
;   END ELSE BEGIN
;      THETA = ACOS( LOC[2] / R ) * !RADEG
;      IF (THETA EQ 0 OR THETA EQ 180) THEN RETURN
;
;      PHI = ATAN(LOC[1], LOC[0]) * !RADEG
;      IF (PHI LT 0) THEN PHI = PHI + 360.0D0
;   END
END


;----------------------------------------------------------
; PURPOSE:
;  Solves the quadratic equation AQ*X*X + QB*X + QC = 0
;
; CALLING SEQUENCE:
;  QA = 3.1
;  QB = 2.2
;  QC = .3
;  QUAD,QA,QB,QC,NP,X1,X2
;
; INPUTS:
;  QA == Scalar coefficient of X^2
;  QB == Scalar coefficient of X^1
;  QC == Scalar coefficient of X^0
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  NP == Number of solutions found.  Will be either 0,1,2.
;  X1 == Solution 1 if exists.
;  X2 == Solution 2 if exists.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO QUAD2,QA,QB,QC,NP,X1,X2
   sz = N_ELEMENTS(qa)
   IF(N_ELEMENTS(Qb) NE sz OR N_ELEMENTS(QC) NE sz) THEN BEGIN
      print,'Quad::input arrays not of equal length'
      return
   END

   j =  where(qa EQ 0, count)
   IF(count EQ 0) THEN BEGIN
      np = dblarr(sz)
      RETURN
   END

   FOURAC = 4.D0 * DOUBLE(QA) * DOUBLE(QC)
   BXB = DOUBLE(QB)*DOUBLE(QB)

   Test = BXB - FOURAC
   IF(Test lt 0) THEN BEGIN
      NP = 0
      RETURN
   END ELSE IF(Test eq 0) THEN BEGIN
      NP = 1
      X1 = -QB / (2.D0 * QA)
      RETURN
   END ELSE IF(Test gt 0) THEN BEGIN
      NP = 2
      SQRT_TERM =  SQRT(BXB - FOURAC)
      QA2 = 2.D0 * QA
      X1 = (-QB - SQRT_TERM)/ QA2
      X2 =  (-QB + SQRT_TERM)/ QA2
      RETURN
   END
END





;----------------------------------------------------------
; PURPOSE:
;  Solves the quadratic equation AQ*X*X + QB*X + QC = 0
;
; CALLING SEQUENCE:
;  QA = 3.1
;  QB = 2.2
;  QC = .3
;  QUAD,QA,QB,QC,NP,X1,X2
;
; INPUTS:
;  QA == Scalar coefficient of X^2
;  QB == Scalar coefficient of X^1
;  QC == Scalar coefficient of X^0
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  NP == Number of solutions found.  Will be either 0,1,2.
;  X1 == Solution 1 if exists.
;  X2 == Solution 2 if exists.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO QUAD,QA,QB,QC,NP,X1,X2
   sz = N_ELEMENTS(qa)
   IF(N_ELEMENTS(Qb) NE sz OR N_ELEMENTS(QC) NE sz) THEN BEGIN
      print,'Quad::input arrays not of equal length'
      help,qa
      help,qb
      help,qc
      return
   END

   NP =  dblarr(sz)
   x1 =  dblarr(sz)
   x2 =  dblarr(sz)

   j =  where(qa NE 0, count)
   IF(count EQ 0) THEN RETURN ELSE NP(j) = 0

   FOURAC = 4.D0 * DOUBLE(QA) * DOUBLE(QC)
   BXB = DOUBLE(QB)*DOUBLE(QB)

   Test = BXB - FOURAC

   j =  where(test LT 0, count)
   IF(count GT 0) THEN BEGIN
      NP(j) = 0
   END

   j =  where(test EQ 0, count)
   IF(count GT 0) THEN BEGIN
      np(j) = 1
      x1(j) =  -qb(j) / (2.d0 * qa(j))
   END

   j = where(test GT 0, count)
   IF(count GT 0) THEN BEGIN
      np(j) =  2
      sqrt_term =  sqrt(bxb(j) - fourac(j))
      qa2 =  2.d0 * qa(j)
      x1(j) =  (-qb(j) - sqrt_term) / qa2
      x2(j) =  (-qb(j) + sqrt_term) / qa2
   END
END



;----------------------------------------------------------
; PURPOSE:
;  Initializes the radius routine.  The earth radius
;  data is cached once which allows for quick read
;  access during execution.  This shouldnt be called
;  externally.
;
; CALLING SEQUENCE:
;  NONE
;
; INPUTS:
;  NONE
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; COMMON BLOCKS:
;  XV_EARTH
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO INITIALIZE_EARTH_RADIUS
   COMMON XV_EARTH, EARTH_RADIUS, MAX_RADIUS, MIN_RADIUS
   MIN_RADIUS = 6356.774D0
   MAX_RADIUS = 6378.16D0

   AxA = 40680924.985599995D0
   BxB = 40408575.687076002D0
   AxB = 40544521.65584D0

   ARRAY_SIZE =  1800
   EARTH_RADIUS = DBLARR(ARRAY_SIZE)
   FOR GLAT= 0,ARRAY_SIZE-1 DO BEGIN
      SINANG = SIN(!DTOR*GLAT/10.0)
      SINSQRD = SINANG*SINANG
      COSANG = SQRT( 1.- SINSQRD)
      EARTH_RADIUS(GLAT) = AxB / SQRT(AxA * SINSQRD+ BxB *COSANG*COSANG)
   END
END


;----------------------------------------------------------
; PURPOSE:
;  Returns the earths radius at a specified latitude
;
; CALLING SEQUENCE:
;  NONE
;
; INPUTS:
;  IN_GLAT == Latitude in degress in [-90..90]
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  Scalar radius
;
; COMMON BLOCKS:
;  XV_EARTH
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION RADIUS, IN_GLAT
   COMMON XV_EARTH, EARTH_RADIUS, MAX_RADIUS, MIN_RADIUS

   IF(N_ELEMENTS(EARTH_RADIUS) EQ 0) THEN INITIALIZE_EARTH_RADIUS

;   IF(IN_GLAT LT -90 OR IN_GLAT GT 90) THEN print,'RADIUS::Glat out of range: ',glat
   GLAT =  IN_GLAT

   j = where(glat LT 0.0, count)
   WHILE(count GT 0) DO BEGIN
      glat(j) = 180.0 + glat(j)
      j =  where(glat LT 0.0, count)
   END

   j =  where(glat GT 180.0, count)
   WHILE(count GT 180.0) DO begin
      glat(j) = glat(j) - 180.0
      j =  where(glat GT 180.0, count)
   END

   return, earth_radius(FIX(GLAT*10.0))
END


;----------------------------------------------------------
; PURPOSE:
;  Converts 2 digit years into 4 digit years.
;
; CALLING SEQUENCE:
;  NONE
;
; INPUTS:
;  TIME == A 3 element array of [YEAR, DOY, MSEC in DAY]
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  Scalar Year value
;
; COMMON BLOCKS:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION YEAR4, Time
   Year =  Time(0)
   IF (YEAR LT 100) THEN BEGIN
      IF (YEAR GT 50) THEN BEGIN
         YEAR4 = 1900 + YEAR
      END ELSE YEAR4 = 2000 + YEAR
   END ELSE YEAR4 = YEAR
   return,Year4
END



FUNCTION arrayNorm, vec
   vxv =  vec*vec
   return,sqrt(vxv(0,*) + vxv(1,*) + vxv(2,*))
END


;----------------------------------------------------------
; PURPOSE:
;  Given a sc position relative to the earth and a
;  a directional vector, compute the points of intersection
;  with the earth.
;
; CALLING SEQUENCE:
;  NONE
;
; INPUTS:
;  SC_POS == SC position in GCI coordinates.
;  LOOK   == a vector originating at the SC
;  ALT    == Assumed altitude of emissions
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  NP     == Number of intersections with the earth.
;            Will be either 0,1,2.
;  POS1   == First position if NP >= 1.
;  POS2   == Second position if NP == 2.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;----------------------------------------------------------
PRO VPOINT, SC_POS, LOOK, ALT, NP, POS1, POS2
   A = 6378.164D0 + ALT                 ; radius at equator
   B = 6356.779D0 + ALT                 ; radius at pole

   sz = N_ELEMENTS(look) / 3.0
   x = dblarr(sz)
   y = dblarr(sz)
   z = dblarr(sz)
   pos1 =  dblarr(3,sz)
   pos2 =  dblarr(3,sz)


   SC_POS = DOUBLE(SC_POS)
   LOOK =  double(LOOK)
   FACTOR =  1.5 * norm(sc_pos[*,0])
   Point2 = sc_pos + (look * factor)

   X2 =  Point2(0,*)
   y2 =  point2(1,*)
   z2 =  point2(2,*)

   x1 = sc_pos(0,*)
   y1 = sc_pos(1,*)
   z1 = sc_pos(2,*)

   AxA =  a*a
   BxB =  b*b
   x1_sqr =  x1*x1
   y1_sqr =  y1*y1
   z1_sqr =  z1*z1

   cq =  x1_sqr/AxA + (y1_sqr + z1_sqr)/BxB - 1

   bq =  2*(x2*x1 - x1_sqr)/AxA + $
         2*(y2*y1 - y1_sqr)/BxB + $
         2*(z2*z1 - z1_sqr)/BxB

   aq =  (x2-x1)^2 / AxA + $
         (y2-y1)^2 / BxB + $
         (z2-z1)^2 / BxB

   QUAD, AQ, BQ, CQ, NP, ROOT1, ROOT2

   j =  where(np GE 1, count)
   IF(count GT 0) THEN BEGIN
      x(j) =  x1(j) + root1(j) * (x2(j) -x1(j))
      y(j) =  y1(j) + root1(j) * (y2(j) -y1(j))
      z(j) =  z1(j) + root1(j) * (z2(j) -z1(j))
      pos1(0,j) =  x(j)
      pos1(1,j) =  y(j)
      pos1(2,j) =  z(j)
   END

   j =  where(np EQ 2, count)
   IF(count GT 0) THEN BEGIN
      x(j) =  x1(j) + root2(j) * (x2(j) -x1(j))
      y(j) =  y1(j) + root2(j) * (y2(j) -y1(j))
      z(j) =  z1(j) + root2(j) * (z2(j) -z1(j))
      pos2(0,j) = x(j)
      pos2(1,j) = y(j)
      pos2(2,j) = z(j)

      j =  where(arrayNorm(SC_POS-POS1) GT arrayNORM(SC_POS-pos2), count)
      IF(count GT 0) THEN BEGIN
         tmp =  pos2(*,j)
         pos2(*,j) =  pos1(*,j)
         pos1(*,j) =  tmp
      END
   END
END



;----------------------------------------------------------
; NAME:   GCIGEO
;
; PURPOSE:
;  Compute the geographic latitude, longitude, and altitude
;  for the input geocentric inertial vector and UT.
;
; CALLING SEQUENCE:
;  NONE
;
; INPUTS:
;  TIME  == 3 element array containing [YEAR, DOY, MSEC in DAY]
;  SUNRA == Right ascension of the sun
;  GCI_CRDS == 3 element array containg GCI coordinates.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  GLAT == Geographic latitude in degrees.
;  GLON == Geographic longitude in degrees.
;  ALT  == Geographic altitude in kilometers.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;----------------------------------------------------------
PRO GCIGEO, Time, SUNRA, GCI_CRDS, GLAT, GLONG, ALT
   GEIGSE, GCI_CRDS, SUNRA, GSE_CRDS

   EQTIME, Time, SOLMSEC
   GSEGEO, GSE_CRDS, SOLMSEC, GLAT, GLONG

   j =  where(finite(glat) EQ 1, count)
   IF(count GT 0) THEN begin
      ALT = NORM(gci_crds) - RADIUS(GLAT)
   END ELSE ALT =  0.0
END


;----------------------------------------------------------
; PURPOSE:
;  Rotates a GEI vector to GSE coordinates
;
; CALLING SEQUENCE:
;  NONE
;
; INPUTS:
;  GEI_CRD = 3 element array of GEI coordinates.
;  SUNRA  == Right ascension of the sun in degrees.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  GSE_CRD == 3 element array containing the GSE coordinates
;             that correspond the the input GEI coordinates.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;----------------------------------------------------------
PRO GEIGSE, GEI_CRD, SUNRA, GSE_CRD
   SUNRA_IN_RADS =  !DTOR * SUNRA

   SUNRA_COS =  COS(SUNRA_IN_RADS)
   SUNRA_SIN =  SIN(SUNRA_IN_RADS)

   GSE_CRD =  GEI_CRD
   GSE_CRD(0,*) = SUNRA_COS * GEI_CRD(0,*) + SUNRA_SIN * GEI_CRD(1,*)
   GSE_CRD(1,*) = - SUNRA_SIN * GEI_CRD(0,*) + SUNRA_COS * GEI_CRD(1,*)
   GSE_CRD(2,*) = GEI_CRD(2,*)
END


;----------------------------------------------------------
; PURPOSE:
;  Convert GSE to GEI coordinates
;
; CALLING SEQUENCE:
;  NONE
;
; INPUTS:
;  GSE_CRD == GSE coordinate
;  SUN_RA  == Right ascension of sun.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  GEI_CRD == GEI coordinates
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;----------------------------------------------------------
PRO GSEGEI, GSE_CRD, SUNRA, GEI_CRD
   SUNRA_IN_RADS =  !DTOR * SUNRA

   SUNRA_COS =  COS(SUNRA_IN_RADS)
   SUNRA_SIN =  SIN(SUNRA_IN_RADS)

   GEI_CRD = DBLARR(3)
   GEI_CRD(0) = SUNRA_COS * GSE_CRD(0) - SUNRA_SIN * GSE_CRD(1)
   GEI_CRD(1) = SUNRA_SIN * GSE_CRD(0) + SUNRA_COS * GSE_CRD(1)
   GEI_CRD(2) = GSE_CRD(2)
END


;----------------------------------------------------------
; PURPOSE:
;  Rotates the GSE vector to geographic Latitude and Longitude.
;
; CALLING SEQUENCE:
;  NONE
;
; INPUTS:
;  GSE_CRDS == 3 element array or GSE coordinates.
;  SOLMSEC  == apparent solar time in milliseconds.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  GLAT == geographic latitude.
;  GLON == geographic longitude.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;----------------------------------------------------------
PRO GSEGEO, GSE_CRDS, SOLMSEC, GLAT, GLONG
   RECSPHD,GSE_CRDS,R,THETA,PHI
   GLAT = 90.0 - THETA
   GLONG = (PHI-(DOUBLE(SOLMSEC)-43200000.D0)*.4166667D-5) MOD 360.D0
END

;----------------------------------------------------------
; PURPOSE:
;  Converts universal time to apparent solar time.
;
; CALLING SEQUENCE:
;  NONE
;
; INPUTS:
;  Time == A 3 element array of [DAY, DOY, MSEC in DAY]
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  SOLMSEC == apparent solar time.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;----------------------------------------------------------
PRO EQTIME, Time, SOLMSEC
   Year =  Time(0)
   DOY =  TIME(1)
   UTMSEC =  Time(2)

   YR = YEAR4(YEAR)
   DAYS = DOY + (YR-1981)*365.0 + (YR-1981)/4
   ANG = 279.58D0 + 0.985647D0*(DAYS+DOUBLE(UTMSEC)/864.D5)
   E = -104.7*SIN(!DTOR*ANG) + 596.2*SIN(!DTOR*2.*ANG) + 4.3*SIN(!DTOR*3.*ANG) $
       - 12.7*SIN(!DTOR*4.*ANG) - 429.3*COS(!DTOR*ANG) - 2.0*COS(!DTOR*2.*ANG) $
       + 19.3*COS(!DTOR*3.*ANG)
   SOLMSEC = UTMSEC + ROUND(E*1.D3)
END

PRO draw_map,lat,lon,coast
   lati =  round(lat*5)+450
   loni =  round(lon*5)

   lati =  reform(lati,65536)
   loni =  reform(loni,65536)

   cs = bytarr(9,1802,902)
   cs[0,1:1800,1:900] =  coast
   cs[1,0:1799,0:899] =  coast
   cs[2,0:1799,1:900] =  coast
   cs[3,0:1799,2:901] =  coast
   cs[4,1:1800,0:899] =  coast
   cs[5,1:1800,2:901] =  coast
   cs[6,2:1801,0:899] =  coast
   cs[7,2:1801,1:900] =  coast
   cs[8,2:1801,2:901] =  coast

   tvscl,reform(avg(cs[*,loni,lati],256,256))
END
;----------------------------------------------------------
; PURPOSE:
;  Returns an image or sequence of images beginning with
;  rec_number.
;
; CALLING SEQUENCE:
;  fid = cdf_open(filename)
;  images = xv_get_image(fid,0,1)
;
; INPUTS:
;   FID = A fileId that has been created with the CDF_OPEN routine.
;   REC_NUMBER = Where to begin loading images withing the CDF file.
;   NUM_RECORDS = How many images to load
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  A 256x256xN array of images
;
; COMMON BLOCKS:
;  None
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_GET_IMAGE, fid, rec_number, num_records
   countsid = CDF_VARNUM(fid,'Image_Counts')
   CDF_VARGET,fid,countsid,image,rec_start=rec_number,rec_count=num_records,/ZVARIABLE
   return,image
END

;----------------------------------------------------------
; PURPOSE:
;  Returns the number of images present in the CDF file.
;
; CALLING SEQUENCE:
;  fid = cdf_open(filename)
;  images = xv_get_num_records(fid)
;
; INPUTS:
;   FID = A fileId that has been created with the CDF_OPEN routine.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  The number of images in the CDF file.
;
; COMMON BLOCKS:
;  None
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_GET_NUM_RECORDS,fid
   countsid = CDF_VARNUM(fid,'Image_Counts')
   CDF_CONTROL,fid,variable=countsid,/Zvariable,get_var_info=info
   return, info.maxrec
END


;----------------------------------------------------------
; PURPOSE:
;  Returns the header
;
; CALLING SEQUENCE:
;  fid = cdf_open(filename)
;  images = xv_get_header(fid)
;
; INPUTS:
;   FID = A fileId that has been created with the CDF_OPEN routine.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  Header
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_GET_HEADER, fid
   HeaderId =  CDF_VARNUM(fid,'Headers')
   CDF_VARGET, fid, HeaderId, Header,/zvariable,rec_start=1
   return, Header
END



;----------------------------------------------------------
; NAME:    XV_GET_LOOK_VECTOR
;
; PURPOSE:
;  Returns the look direction vectors.
;
; CALLING SEQUENCE:
;  fid = cdf_open(filename)
;  vec = xv_get_look_vector(fid)
;
; INPUTS:
;   FID = A fileId that has been created with the CDF_OPEN routine.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  A 3x256x256 matrix representing a 3 vector for each pixel
;  in the image.  This matrix can be used to compute the direction
;  that each pixel is pointed.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;   04-MAY-2005 MRD  Reads the look vector array from the file LV.DAT
;                    if available in the current directory; otherwise,
;                    gets the look vector array from the CDF variable
;                    Look_Vctr.
;----------------------------------------------------------
FUNCTION XV_GET_LOOK_VECTOR, fid

   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit

   Look_Vector = FLTARR(3,256,256)
   LVF = FindFile('LV.DAT',COUNT=FCount)
   IF (FCount EQ 0) THEN BEGIN
       result = DIALOG_MESSAGE( ['The Look Vector file was not found.',$
	      'The CDF variable Look_Vctr will be used.'],/error)
       LookId =  CDF_VARNUM(fid,'Look_Dir_Vctr')
       CDF_VARGET, fid, LookId, Look_Vctr, /zvariable, rec_start=1
       Look_Vector = Look_Vctr
   END ELSE BEGIN
       LVFile = LVF(0)
       OpenR,11,LVFile
       ReadF,11,Look_Vector
       IF (record.sensor NE 0) THEN ReadF,11,Look_Vector
       Close,11
   END
   return, Look_Vector
END


;----------------------------------------------------------
; NAME:   XV_GET_RECORD
;
; PURPOSE:
;  Returns the record structure for each record.  This is
;  basically any information contained in an individual
;  record with the exception of the image itself.
;
; CALLING SEQUENCE:
;  fid = cdf_open(filename)
;  vec = xv_get_record(fid,rec_number)
;
; INPUTS:
;   FID = A fileId that has been created with the CDF_OPEN routine.
;   REC_NUMBER = the number of the record to obtain.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  A structure containing the tags in the 'Names' local variable.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_GET_RECORD, fid, rec_number
;   Names =  ['Time_PB5', 'Rotatn_Matrix', 'Filter', $
;             'V_Zenith', 'Sun_Vctr', 'D_Qual', 'Post_Gap', 'AltF',$
;             'Sensor', 'SC_Pos_GCI', 'SC_Vel_GCI',$
;             'SC_SpinV_GCI','Limit_Lo','Limit_Hi','Int_Time_Half']

   Names =  ['Time_PB5','Sensor','Int_Time_Half','Filter','AltF','PPitch',$
	     'SC_Pos_GCI','SC_Vel_GCI','SC_SpinV_GCI','Rotatn_Matrix',$
	     'V_Zenith','Sun_Vctr','Limit_Lo','Limit_Hi','D_Qual','Post_Gap']

   Result =  {RECORD:Rec_number}
   FOR i=0,N_ELEMENTS(Names)-1 DO BEGIN
      VarId =  CDF_VARNUM(fid,Names(i))
      IF(VarId GT 0) THEN BEGIN
         CDF_VARGET,fid,VarId,Val,/zvariable,rec_start=rec_number
      END
      Result =  CREATE_STRUCT(Names(i), Val, Result)
   END
   return,Result
END

;----------------------------------------------------------
; NAME:   XV_GET_RECORD2
;
; PURPOSE:
;  For visible camera images, returns the supplementary record structure
;  containing mirror elevation and azimuth angles
;
; CALLING SEQUENCE:
;  fid = cdf_open(filename)
;  vec = xv_get_record2(fid,rec_number)
;
; INPUTS:
;   FID = A fileId that has been created with the CDF_OPEN routine.
;   REC_NUMBER = the number of the record to obtain.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  A structure containing the tags in the 'Names' local variable.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;	Rae Dvorsky, 19 March 2005
;
;----------------------------------------------------------
FUNCTION XV_GET_RECORD2, fid, rec_number

   Names =  ['Mirr_Elv','Mirr_Azm']

   Result =  {RECORD:Rec_number}
   FOR i=0,N_ELEMENTS(Names)-1 DO BEGIN
      VarId =  CDF_VARNUM(fid,Names(i))
      IF(VarId GT 0) THEN BEGIN
         CDF_VARGET,fid,VarId,Val,/zvariable,rec_start=rec_number
      END
      Result =  CREATE_STRUCT(Names(i), Val, Result)
   END
   return,Result
END


;----------------------------------------------------------
; PURPOSE:
;  Creates a printable version of an arbitrary? structure.
;
; CALLING SEQUENCE:
;  fid = cdf_open(filename)
;  st = xv_get_record(fid,0)
;  Strings = struct_to_string(st)
;
; INPUTS:
;  StructVar == any structure
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  A string array containing a printable version of the
;  given structure.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION STRUCT_TO_STRING, StructVar
   result =  STRARR(500)
   count =  0
   Names =  tag_names(structVar)
   FOR i=0,N_TAGS(Structvar)-1 DO BEGIN
      result(count) =  names(i)
      count = count + 1
      sz =  size(StructVar.(i))

      ;; If Variable is BYTES then TURN it into FIXes
      ;; since bytes are interpreted as ASCII values
      IF(sz(sz(0)+1) EQ 1) THEN ValRep =  STRING(FIX(StructVar.(i))) $
      ELSE ValRep = STRING(StructVar.(i))

      ;; Now Format according do dimensionality
      IF(sz(0) EQ 0) THEN $
       result(count) = ValRep $
      ELSE IF(sz(0) EQ 1) THEN BEGIN
         FOR j = 0,sz(1)-1 DO BEGIN
            result(count) =  result(count) + ValRep(j)
         END
      END ELSE BEGIN
         FOR dim1=0,sz(1)-1 DO BEGIN
            FOR dim2=0,sz(2)-1 DO BEGIN
               result(count) =  result(count) + ValRep(dim1,dim2)
            END
            count =  count + 1
         END
      END

      count =  count + 1
      result(count) =  ""
      count =  count + 1
   END

   return,result(0:count)
END


;----------------------------------------------------------
; PURPOSE:
;  Returns a string array containing information about the image.
;
; CALLING SEQUENCE:
;  fid = cdf_open(filename)
;  info = xv_get_image_info(fid,0)
;
; INPUTS:
;  FID = file ID created with CDF_OPEN
;  REC_NUMBER = number of image to retrieve information from.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  A string array containing a printable version of the image
;  information structure.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_GET_IMAGE_INFO, fid, rec_number
   return, STRUCT_TO_STRING(XV_GET_RECORD(fid,rec_number))
END


;----------------------------------------------------------
; PURPOSE:
;  Loads the color table contained in the CDF file.
;
; CALLING SEQUENCE:
;  fid = cdf_open(filename)
;  XV_LOAD_COLOR_TABLE, fid
;
; INPUTS:
;  FID = file id created using CDF_OPEN
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Loads the color table with the values in the CDF file.
;  These values are scaled (if necessary) to fit into
;  the table.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_LOAD_COLOR_TABLE,fid
   COMMON COLORS, ro,go,bo,rc,gc,bc
   colortable =  intarr(3,256)

   tableid = CDF_VARNUM(fid,'RGBColorTable')
   if(tableid ge 0) THEN BEGIN
      CDF_VARGET,fid,tableid,table,/zvariable
      colortable = table
   END ELSE BEGIN
      rgb = INDGEN(256)
      colortable(0,*) = rgb
      colortable(1,*) = rgb
      colortable(2,*) = rgb
   END

   red = CONGRID(reform(colortable(0,*)), 256 < !D.table_size)
   green = CONGRID(reform(colortable(1,*)),256 < !D.table_size)
   blue =  CONGRID(reform(colortable(2,*)),256 < !D.table_size)
   tvlct, red, green, blue
   ro = red
   go = green
   bo = blue
   rc = red
   gc = green
   bc = blue
END


;----------------------------------------------------------
; PURPOSE:
;  Returns a string array representing the global attributes
;  of the CDF file.
;
; CALLING SEQUENCE:
;  fid = cdf_open(filename)
;  st = xv_get_gattributes(fid,0)
;
; INPUTS:
;  StructVar == any structure
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  A string array containing a printable version of the
;  files global attributes.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_GET_GATTRIBUTES, fid
   CDF_CONTROL,fid,GET_NUMATTRS=attrs
   result = STRARR(500)
   count = 0
   for i=0,attrs(0)-1 do BEGIN
      CDF_ATTINQ,fid,i,Name,scope,maxentry,maxzentry
      result(count) = name
      count = count + 1
      CDF_CONTROL,fid,GET_ATTR_INFO=att_info,ATTRIBUTE=i
      for j=0,att_info.numgentries-1 do BEGIN
         CDF_ATTGET,fid,i,j,VALUE
         result(count) = STRING(VALUE)
         count = count + 1
      END
      result(count) = ""
      count = count + 1
   END
   return,result(0:count)
END
;-------------------------------------------------------------
;+
; NAME:
;       RUNLENGTH
; PURPOSE:
;       Give run lengths for array values.
; CATEGORY:
; CALLING SEQUENCE:
;       y = runlength(x,[r])
; INPUTS:
;       x = 1-d array of values.                  in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       y = X with multiple values squeezed out.  out
;       r = run length of each element in Y.      out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       RES  30 Jan, 1986.
;       R. Sterner, 25 Sep, 1990 --- converted to IDL V2.
;       Johns Hopkins University Applied Physics Laboratory.
;
; Copyright (C) 1986, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
FUNCTION RUNLENGTH,X,R, help=hlp

   if (n_params(0) lt 1) or keyword_set(hlp) then begin
      print,' Give run lengths for array values.'
      print,' y = runlength(x,[r])'
      print,'   x = 1-d array of values.                  in'
      print,'   y = X with multiple values squeezed out.  out'
      print,'   r = run length of each element in Y.      out'
      return, -1
   endif

   ;;---  The easiest way to understand how this works is to try
   ;;---  these statements interactively.
   A = X - SHIFT(X,1)           ;; Distance to next value.
   A(0) = 1                     ;; Always want first value.
   W = WHERE(A NE 0)            ;; Look for value changes.
   Y = X(W)                     ;; Pick out unique values.
   IF N_PARAMS(0) LT 2 THEN RETURN, Y
   R = ([W,N_ELEMENTS(X)])(1:(N_ELEMENTS(Y))) - W ; run lengths.
   RETURN, Y
END


;-------------------------------------------------------------
;+
; NAME:
;       INTERSECT
; PURPOSE:
;       Return the elements common to two given arrays.
; CATEGORY:
; CALLING SEQUENCE:
;       z = intersect(x,y)
; INPUTS:
;       x, y = arrays (not necessarily same size).  in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       z = array of elements in common.            out
; COMMON BLOCKS:
; NOTES:
;       Note: if z is a scalar 0 then no elements were
;         in common.
; MODIFICATION HISTORY:
;       R. Sterner  19 Mar, 1986.
;       R. Sterner, 4 Mar, 1991 --- converted to IDL v2.
;
; Copyright (C) 1986, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
function intersect,x,y, help=hlp

   if (n_params(0) lt 2) or keyword_set(hlp) then begin
      print,' Return the elements common to two given arrays.'
      print,' z = intersect(x,y)'
      print,'   x, y = arrays (not necessarily same size).  in'
      print,'   z = array of elements in common.            out'
      print,' Note: if z is a scalar 0 then no elements were'
      print,'   in common.'
      return, -1
   endif

   xs = runlength(x(sort(x)))   ; Keep only unique elements.
   ys = runlength(y(sort(y)))

   zs = [xs,ys]                 ; Merge the 2 arrays.
   zs = zs(sort(zs))            ; Sort.

   d = zs - shift(zs,1)         ; Find differences between elements.

   w = where(d eq 0, count)     ; Elements common to both arrays
                                ; occur twice, giving 0 diffs.

   if count eq 0 then return, 0 ; Scalar 0 means no common elements.
   return, zs(w)                ; Vector of common elements.

end

;-------------------------------------------------------------
;+
; NAME:
;       GET_COURIER_FONT
; PURPOSE:
;       Seeks a font name with COURIER as a substring
; CATEGORY:
;
; CALLING SEQUENCE:
;       f = get_courier_font()
; INPUTS:
;       NONE
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;       f = STRING
; COMMON BLOCKS:
;       NONE
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 1/23/98
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-------------------------------------------------------------
FUNCTION GET_COURIER_FONT
   device, font ='*', get_fontname=fonts ;Get the fonts

   ;; Get any courier fonts
   nf = n_elements(fonts)
   Selected =  STRARR(nf)
   counter =  0
   FOR i=0,nf-1 DO BEGIN
      IF(strpos(fonts[i],'courier') GE 0) THEN BEGIN
         Selected[counter] = fonts[i]
         counter =  counter + 1
      END
   END

   IF(counter Gt 0) THEN BEGIN
      FONTS = Selected[0:counter-1]
   END ELSE RETURN, ""

   ;; Get an -r- fonts
   nf = n_elements(fonts)
   Selected =  STRARR(nf)
   counter =  0
   FOR i=0,nf-1 DO BEGIN
      IF(strpos(fonts[i],'-r-') GE 0) THEN BEGIN
         Selected[counter] = fonts[i]
         counter =  counter + 1
      END
   END

   IF(counter Gt 0) THEN BEGIN
      FONTS = Selected[0:counter-1]
   END ELSE RETURN, fonts[0]

   ;; Get a --14 font
   nf = n_elements(fonts)
   Selected =  STRARR(nf)
   counter =  0
   FOR i=0,nf-1 DO BEGIN
      IF(strpos(fonts[i],'--14') GE 0) THEN BEGIN
         Selected[counter] = fonts[i]
         counter =  counter + 1
      END
   END

   IF(counter Gt 0) THEN BEGIN
      return, Selected[0]
   END ELSE RETURN, fonts[0]

end

;-------------------------------------------------------------
;+
; NAME:
;       DATETOSTRING
; PURPOSE:
;       Converts a TIME array into a printable string
; CATEGORY:
;
; CALLING SEQUENCE:
;       DATE = DATETOSTRING(TIME_ARRAY)
; INPUTS:
;       TIME_ARRAY = INTARR(3)
;       TIME_ARRAY[0] is the year (e.g. 1997)
;       TIME_ARRAY[1] is the day of year
;       TIME_ARRAY[2] is the number of milliseconds in the day
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;       DATE = STRING
; COMMON BLOCKS:
;       NONE
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-------------------------------------------------------------
FUNCTION DateToString, Time, format_in
   Months =  ["Jan", "Feb", "Mar", "Apr", $
              "May", "Jun", "Jul", "Aug", $
              "Sep", "Oct", "Nov", "Dec"]


   hour =  LONG(time(2)) / 3600000L
   temp =  time(2) - Long(hour) * 3600000L
   min =  long(temp) / 60000L
   temp = temp - long(min) * 60000L
   sec =  long(temp) / 1000L
   Format = '(I2.2)'
   HMS =  STRTRIM(STring(Hour,FORMAT=format),2) + $
    ":" + STRTRIM(STRING(Min,FORMAT=format),2) + $
    ":" + STRTRIM(STRING(SEC,FORMAT=format),2)


   IF(format_in EQ 0) THEN BEGIN
      date =  STRTRIM(STRING(Time[0],FORMAT='(I4.4)'),2) + $
       " " + STRTRIM(STRING(Time[1],FORMAT='(I3.3)'),2) + " " + HMS
   END ELSE IF(format_in EQ 1) THEN BEGIN
      DOY_TO_MON_DAY, Time[0], Time[1], MONTH=Month, DAY=day
      Date = Months[Month-1] + " " + STRTRIM(STRING(Day,format='(i2.2)'),2) + " " + $
      STRTRIM(STRING(Time[0],FORMAT = '(I4.4)'),2) + " " + HMS
   END ELSE BEGIN
      DOY_TO_MON_DAY, Time[0], Time[1], MONTH=Month, DAY=day
      Date = Months[Month-1] + " " + STRTRIM(STRING(Day,format='(i2.2)'),2) + " " + $
       STRTRIM(STRING(Time[0],FORMAT = '(I4.4)'),2) + " (" +  $
       STRTRIM(STRING(Time[1],FORMAT='(I3.3)'),2) + ") " + HMS
   END
   return, date
END


PRO DOY_TO_MON_DAY, YEAR, DOY, MONTH=MONTH, DAY=DAY
   DAYS =  [59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
   LEAP = 0
   IF ((YEAR MOD 4) EQ 0 AND ((YEAR MOD 100 NE 0) OR (YEAR MOD 400) EQ 0)) THEN  LEAP = 1

   IF((DOY GT 365 AND LEAP EQ 0) OR (DOY GT 366 AND LEAP EQ 1) OR DOY LT 1) THEN BEGIN
      print,"Invalid DATE:", year, doy
      return
   END

   IF (DOY LT 32) THEN BEGIN
      MONTH = 1
      DAY = DOY
   END ELSE BEGIN
      j =  where(doy GT days + Leap, count)
      IF(count GT 0) THEN BEGIN
         MONTH = j[N_ELEMENTS(j)-1] + 3
         Last = Days[j[N_ELEMENTS(j)-1]] + Leap
      END ELSE BEGIN
         last =  31
         MONTH = 2
      END
      DAY = DOY - last
   END
END




;+
; NAME:
;  XV_UNDISTORT
;
; PURPOSE:
;  'Warps' a 256 by 256 pixel VIS image to display
;  the image in the correct spatial resolution
;
; CATEGORY:
;  VIS image analysis
;
; INPUTS:
;  A VIS image
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  An 'undistorted' image
;
; COMMON BLOCKS:
;  XV_FILE_DATA
;
; SIDE EFFECTS:
;  None
;
; RESTRICTIONS:
;  None
;
; EXAMPLE:
;  NewImage = XV_UNDISTORT(Image)
;
; MODIFICATION HISTORY:
;  Written by Kenny Hunt, 9/97
;-
FUNCTION XV_UNDISTORT, Image
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort

   newimage =  bytarr(548,475)
   nonzeros =  where(undistort GE 0)
   newimage(nonzeros) =  image(undistort(nonzeros))

   return,newimage
END

;-------------------------------------------------------------
; NAME: MAKE_ROTATION_MATRIX
;
; PURPOSE:
;       Contructs a view coordinate system basis for one image,
;       to be used instead of record.rotatn_matrix
; CATEGORY:
;
; CALLING SEQUENCE:
;       rotation_matrix = MAKE_ROTATION_MATRIX()
; INPUTS:
;
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;       3x3 image view matrix
;
; COMMON BLOCKS:
;       XV_FILE_DATA
;       XV_RECORD_DATA
; NOTES:
;
; MODIFICATION HISTORY:
;	Rae Dvorsky, 3/19/05
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-------------------------------------------------------------
FUNCTION MAKE_ROTATION_MATRIX
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit, Record2

; set up initial coordinate basis: Z axis is the spin axis,
;                  X axis points toward nadir, Y axis is Z-cross-X
   SCX = DBLARR(3)
   SCY = SCX
   SCZ = SCX
   SCZ = record.sc_spinv_gci
   sc_pos_len =  norm(record.sc_pos_gci)
   norm_sc2Earth = transpose(-record.sc_pos_gci / sc_pos_len)
   tempY = CROSSP( SCZ, norm_sc2Earth )
   tempY_len = norm(tempY)
   SCY = tempY / tempY_len
   tempX = CROSSP( SCY, SCZ )
   tempX_len = norm(tempX)
   SCX = tempX / tempX_len
   BASIS1 = [SCX,SCY,SCZ]
   BASIS1 = REFORM(BASIS1,3,3,/OVERWRITE)

; apply mirror pointing angles and alignment corrections
   IF (record.sensor EQ 0) THEN BEGIN
        HDUMP = FIX(HEADER(38) AND 15)*256 + FIX(HEADER(37)) - 20
	IF (record.time_pb5(0) EQ 1996 AND record.time_pb5(1) LT 110) THEN $
	    Zdeg = ( 10.+Hdump-24.+5.)*.0390625 $
	ELSE Zdeg = ( 10.+Hdump-16.+5.)*.0390625
	Ydeg = (39.+8.)*.0390625
   ENDIF
   IF (record.sensor EQ 1) THEN BEGIN
	Zdeg = -(record2.Mirr_Elv - 108) * .08660
	Ydeg = -(record2.Mirr_Azm - 68 ) * .09375 $
		 - (.25022*(record2.Mirr_Elv-108)^2.)/(80.^2.)
	Zdeg = Zdeg + 50. * .01171875
	Ydeg = Ydeg + 73. * .01171875
   ENDIF
; find image center line-of-sight vector
   Theta = 90. - Zdeg
   Phi = Ydeg - record.ppitch/10.0
   CLOSV = [ SIN(Theta*!DTOR)*COS(Phi*!DTOR), $
		SIN(Theta*!DTOR)*SIN(Phi*!DTOR), COS(Theta*!DTOR) ]
; rotate to GCI with initial basis matrix
   CLOSV_GCI = CLOSV ## BASIS1

; set up the image coordinate basis: X axis is the center line-of-sight,
;	Y axis is spin axis-cross-X (up),
;	Z axis is X-cross-Y (rightward in the spin - line-of-sight plane);
;    for the visible camera, Y and Z are additionally rotated by an angle
;    determined from the mirror elevation
   tempX_len = NORM(CLOSV_GCI)
   IMX = TRANSPOSE(CLOSV_GCI/tempX_len)
   tempY = CROSSP( SCZ, TRANSPOSE(IMX) )
   tempY_len = NORM(tempY)
   IMY = TRANSPOSE( tempY/tempY_len )
   tempZ = CROSSP( TRANSPOSE(IMX), TRANSPOSE(IMY) )
   tempZ_len = NORM(tempZ)
   IMZ = TRANSPOSE( tempZ/tempZ_len )

; apply the additional rotation for the elevation of the visible camera
   IF (record.sensor EQ 1) THEN BEGIN
   	Angle = 2.5 * (record2.Mirr_Elv) / 64.0
   	CosAng = COS(Angle*!DTOR)
   	SinAng = SIN(Angle*!DTOR)
   	tempZ = SinAng*IMY + CosAng*IMZ
   	tempZ_len = NORM(TRANSPOSE(tempZ))
   	IMZ = tempZ/tempZ_len
   	tempY = CosAng*IMY - SinAng*IMZ
   	tempY_len = NORM(TRANSPOSE(tempY))
   	IMY = tempY/tempY_len
   ENDIF

; return IMX,IMY,IMZ as the Rotation Matrix for this image
   Return,REFORM([IMX,IMY,IMZ],3,3,/OVERWRITE)
END


;-------------------------------------------------------------
;+
; NAME:
;       XV_LOOKV_TO_GCI
; PURPOSE:
;       Converts the XVIS LOOK vector to GCI coordinates
; CATEGORY:
;
; CALLING SEQUENCE:
;       XV_LOOKV_TO_GCI
; INPUTS:
;       NONE
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;       NONE
; COMMON BLOCKS:
;       XV_RECORD_DATA
;       XV_FILE_DATA
;       XV_DERIVED_DATA
;       XV_FLAGS
; NOTES:
;       This routine is useful only within the XVIS application
;       It uses COMMON blocks extensively and certain values within
;       the blocks must be set prior to invocation.
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;	Rae Dvorsky, 03/19/05
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-------------------------------------------------------------
PRO XV_LOOKV_TO_GCI
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags

   IF(FLAGS.LV EQ 1) THEN RETURN

   ROTATION = MAKE_ROTATION_MATRIX()
   LOOKV_GCI =  REFORM(TRANSPOSE(ROTATION##TRANSPOSE(REFORM(LookVector,3,65536))),3,256,256)

   Flags.LV = 1
END


;------------------------------------------------------------------
;+
; NAME:
;       XV_GET_PHIS
; PURPOSE:
;       Computes the PHI angles at every pixel within an XVIS image.
; CATEGORY:
;
; CALLING SEQUENCE:
;       XV_GET_PHIS
; INPUTS:
;       NONE
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;       NONE
; COMMON BLOCKS:
;       XV_RECORD_DATA
;       XV_FILE_DATA
;       XV_DERIVED_DATA
;       XV_FLAGS
; NOTES:
;       This routine is useful only within the XVIS application
;       It uses COMMON blocks extensively and certain values within
;       the blocks must be set prior to invocation.
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-----------------------------------------------------------------
PRO XV_GET_PHIS
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags

   IF(FLAGS.PHI EQ 1) THEN RETURN

   XV_LOOKV_TO_GCI

   phis =  dblarr(256,256,/NOZERO)
   sc_pos = record.sc_pos_gci
   normal_sc_pos =  TRANSPOSE(-sc_pos / norm(sc_pos))

   Phis = REFORM(acos(reform(lookv_gci,3,65536) ## normal_sc_pos),256,256)

;   FOR col=0,255 DO BEGIN
;      Phis(*,col) =  REFORM(acos(lookv_gci(*,*,col) ## normal_sc_pos))
;      help,phis(*,col)
;      help,normal_sc_pos
;      help,lookv_gci(*,*,col)
;   END

   FLAGS.PHI = 1
END


;------------------------------------------------------------------
;+
; NAME:
;       XV_GET_ALTLS
; PURPOSE:
;       Computes the ALTLS value (altitude at line-of-sight) for every
;       pixel of an XVIS image.
; CATEGORY:
;
; CALLING SEQUENCE:
;       XV_GET_ALTLS
; INPUTS:
;       NONE
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;       NONE
; COMMON BLOCKS:
;       XV_RECORD_DATA
;       XV_FILE_DATA
;       XV_DERIVED_DATA
;       XV_FLAGS
; NOTES:
;       This routine is useful only within the XVIS application
;       It uses COMMON blocks extensively and certain values within
;       the blocks must be set prior to invocation.
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-----------------------------------------------------------------
PRO XV_GET_ALTLS
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags

   IF(FLAGS.ALTLS EQ 1) THEN RETURN

   XV_LOOKV_TO_GCI
   XV_GET_PHIS
   ALTLS =  norm(record.sc_pos_gci) * sin(phis)

   FLAGS.ALTLS =  1
END


PRO XV_ALT_SZA
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_EARTH, EARTH_RADIUS, MAX_RADIUS, MIN_RADIUS
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags

   IF(FLAGS.ALT EQ 1  AND FLAGS.SZA EQ 1) THEN RETURN

   AssumedAlt =  record.altf
   SUN_VCTR =  record.sun_vctr
   SC_POS_LEN =  norm(record.sc_pos_gci)

   XV_LOOKV_TO_GCI
   XV_GET_PHIS
   XV_GET_ALTLS

   szas =  dblarr(256,256,/NOZERO)
   LOCs =  dblarr(3,256,256)
   Alts =  ALTLS
   coss =  cos(phis) * sc_pos_len
   szas(*) =  -1
   sc_pos = dblarr(3,65536)
   sc_pos(0,*) = record.sc_pos_gci(0)
   sc_pos(1,*) = record.sc_pos_gci(1)
   sc_pos(2,*) = record.sc_pos_gci(2)

   locs = reform(locs,3,65536)
   lookv_gci =  reform(lookv_gci,3,65536)
   coss =  reform(coss,65536)

   VPOINT, sc_pos, lookv_gci, assumedalt, np, loc1, loc2

   j =  where(np EQ 0, count)
   IF(count GT 0) THEN BEGIN
      locs(0,j) =  sc_pos(0,j) + lookv_gci(0,j) * coss(j)
      locs(1,j) =  sc_pos(1,j) + lookv_gci(1,j) * coss(j)
      locs(2,j) =  sc_pos(2,j) + lookv_gci(2,j) * coss(j)
   END

   j =  where(np gt 0, count)
   IF(count GT 0) THEN BEGIN
      locs(*,j) =  loc1(*,j)
      alts(j) = arrayNorm(loc1(*,j))
      norms =  loc1(*,j) / [alts(j), alts(j), alts(j)]
      sun_vec =  dblarr(3,N_ELEMENTS(j))
      sun_vec(0,*) = record.sun_vctr(0)
      sun_vec(1,*) = record.sun_vctr(1)
      sun_vec(2,*) = record.sun_vctr(2)
      szas(j) = acos(total( sun_vec * norms , 1)) * !RADEG
   end

   locs =  reform(locs,3,256,256)
   lookv_gci =  reform(lookv_gci,3,256,256)

   j =  WHERE(finite(szas) EQ 0, count)
   IF(count GT 0) THEN BEGIN
      szas(j) = 180.0
   end

   FLAGS.ALT = 1
   FLAGS.SZA = 1
   FLAGS.LOC = 1
END


;-------------------------------------------------------------
;+
; NAME:     GCI_TO_GEO
;
; PURPOSE:
;       Converts a GCI coordinate into geographic lat,lon,alt
; CATEGORY:
;
; CALLING SEQUENCE:
;       GCI_TO_GEO, Pos, gla, glo, alt
; INPUTS:
;       POS == a position in GCI coordinates
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;       GLA == geographic latitude
;       GLO == geographic longitude
;       ALT == altitude
; COMMON BLOCKS:
;       XV_RECORD_DATA
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-------------------------------------------------------------
PRO GCI_TO_GEO, Pos, gla, glo, alt
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   sunra = atan(record.sun_vctr(1), record.sun_vctr(0)) * !RADEG
   GCIGEO, Record.time_pb5, sunra, pos, gla, glo, alt
END


;-------------------------------------------------------------
;+
; NAME:
;       GCI_TO_SZA
; PURPOSE:
;       Converts a GCI coordinate into a solar zenith angle
; CATEGORY:
;
; CALLING SEQUENCE:
;       SAngle = GCI_TO_SZA(Loc)
; INPUTS:
;       Pos == a position in GCI coordinates
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;       Solar zenith angle in degrees
; COMMON BLOCKS:
;       XV_RECORD_DATA
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-------------------------------------------------------------
FUNCTION GCI_TO_SZA, Pos
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   return, acos(total(record.sun_vctr * (pos / norm(pos)))) * !RADEG
END
;+

;-------------------------------------------------------------
;+
; NAME:      SINGLE_PIXEL_CRD
;
; PURPOSE:
;       Computes coordinates for one image pixel location
; CATEGORY:
;
; CALLING SEQUENCE:
;       coord = SINGLE_PIXEL_CRD( X, Y, ON_EARTH )
; INPUTS:
;       X,Y == pixel location column and row
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;       If look direction at input pixel location intersects Earth,
;       GCI coordinates of position on surface of Earth closer to spacecraft;
;       else GCI unit vector for look direction
;
;       ON_EARTH == number of points of intersection with Earth, 0, 1, or 2
;
; COMMON BLOCKS:
;       XV_FILE_DATA
;       XV_RECORD_DATA
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;	Rae Dvorsky, 3/19/05
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-------------------------------------------------------------
FUNCTION SINGLE_PIXEL_CRD, X, Y, ON_EARTH
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit

   ROTATION_MATRIX = MAKE_ROTATION_MATRIX()
   OLDlookv =  reform(record.rotatn_matrix ## lookvector(*,x,y))
   LookV = REFORM( ROTATION_MATRIX ## LookVector(*,X,Y) )
   vpoint, record.sc_pos_gci, lookv, record.altf, ON_EARTH, loc1, loc2
   ON_EARTH =  ON_EARTH[0]
   IF(ON_EARTH EQ 0) THEN BEGIN
      sc_pos_len =  norm(record.sc_pos_gci)
      normal_sc_pos =  transpose(-record.sc_pos_gci / sc_pos_len)
      OLDPhi =  (acos(OLDlookv ## normal_sc_pos))(0)
      Phi =  (acos(lookv ## normal_sc_pos))(0)
      return, record.sc_pos_gci + lookv * cos(phi) * sc_pos_len
   END ELSE return, loc1
END


;-------------------------------------------------------------

;-------------------------------------------------------------
;+
; NAME:
;       COMPUTE_CRDS
; PURPOSE:
;       Computes all the variables in the XV_DERIVED_DATA block
;       for an entire image
; CATEGORY:
;
; CALLING SEQUENCE:
;       Must set up the common block information properly.  This
;       routine is tightly integrated into the XVIS package.
; INPUTS:
;       None
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;       RA and DEC values
; COMMON BLOCKS:
;       numerous
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-
PRO COMPUTE_CRDS
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_DEBUG, dalts

   IF(FLAGS.GLAT EQ 1) THEN RETURN

   GLATS = DBLARR(256,256)
   GLONS = DBLARR(256,256)
   Dalts = dblarr(256,256)

   SC_POS =  record.sc_pos_GCI
   AssumedAlt =  record.altf
   SUN_VCTR =  record.sun_vctr
   sunra = atan(sun_vctr(1), sun_vctr(0)) * !RADEG

   XV_ALT_SZA

   valid =  where(szas GE 0, count)
   IF(count GT 0) THEN BEGIN
      GCIGEO, Record.Time_pb5, SUNRA, (REFORM(locs,3,65536))[*,valid], GLA, GLO, ALT
      GLATS(valid) =  gla
      GLONS(valid) =  glo
      DALTS(valid) =  alt
   END

;   valid =  where(szas GE 0, count)
;   XV_UNPACK_WHERE,valid,rows,cols
;   IF(count GT 0) THEN BEGIN
;      FOR i=0L,N_ELEMENTS(valid)-1 DO BEGIN
;         ;; compute the glats & glons per pixel here
;         GCIGEO, REcord.Time_pb5, SUNRA, Locs(*,rows(i),cols(i)), GLA, GLO, ALT
;         Glats(valid(i)) =  gla
;         GLons(valid(i)) =  glo
;         Dalts(valid(i)) =  alt
;      END
;   END

   FLAGS.GLAT =  1
END

;-------------------------------------------------------------
;+
; NAME:
;       DAYGLOW
; PURPOSE:
;       Computes percentage parameters for the dayglow subtract
;       routine
; CATEGORY:
;
; CALLING SEQUENCE:
;
; INPUTS:
;       SZA == solar zenith angle
;       Day == day of year
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;       percentages parameterized on solar zenith angles
; COMMON BLOCKS:
;       None
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-
FUNCTION DAYGLOW, SZA, Day
   SZAINTEN =  [[25.0, 20.0, 16.3,  8.3,  0.0,   0.0],$
                [50.0, 40.0, 32.5, 16.5,  0.0,   0.0]]
   SZAANGLE =  [0.0, 30.0, 40.0, 75.0, 90.0, 180.0]

   IF(Day LT 241) THEN BEGIN
      RETURN, INTERPOL(SZAINTEN(*,0),szaangle,sza)
   END ELSE BEGIN
      RETURN, INTERPOL(SZAINTEN(*,1), szaangle,sza)
   END
END


;-------------------------------------------------------------
;+
; NAME:
;       XV_UNPACK_WHERE
; PURPOSE:
;       An often used utility that converts a single value
;       index into a vis image into it's respective row,col
;       values.
; CATEGORY:
;
; CALLING SEQUENCE:
;
; INPUTS:
;       INDEX == array of indices into a vis image.
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;       ROW == array of row indices
;       COL == array of column indices
; COMMON BLOCKS:
;       None
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-
PRO XV_UNPACK_WHERE, index, row, col
   col = index MOD 256
   row = index / 256
END


;-------------------------------------------------------------
;+
; NAME:
;       WRITE_PS
; PURPOSE:
;       Writes an image as a postscript file.
; CATEGORY:
;
; CALLING SEQUENCE:
;
; INPUTS:
;       Image == Vis image
;       Dims == size of the plot
; KEYWORD PARAMETERS:
;       ENCAPSULATED == save as an eps or a ps
; OUTPUTS:
;       postscript file
; COMMON BLOCKS:
;       None
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-
PRO WRITE_PS, Image, dims, Encapsulated=encapsulated
   filename = dialog_pickfile()
   IF(filename ne "") THEN BEGIN
      SET_PLOT,'ps'
      IF KEYWORD_SET(Encapsulated) THEN DEVICE, /ENCAPSULATED
      DEVICE, BITS_PER_PIXEL=8, /COLOR, $
       FILENAME=filename, XSIZE=dims, YSIZE=dims
      TV,Image
      DEVICE,/CLOSE
      SET_PLOT,'x'
   END
END


;-------------------------------------------------------------
;+
; NAME:
;       INIT_COMPRESSION_TABLES
; PURPOSE:
;       Vis images are often compressed and uncompressed.  To
;       do this we create arrays to quickly perform the compression.
; CATEGORY:
;
; CALLING SEQUENCE:
;
; INPUTS:
;       None
; KEYWORD PARAMETERS:
;       None
; OUTPUTS:
;       None
; COMMON BLOCKS:
;       Sets up the COMPRESSION_TABLES common block variables
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-
PRO INIT_COMPRESSION_TABLES
   COMMON COMPRESSION_TABLES, PACK_T, UNPACK_T

   UNPACK_T = INTARR(4096)
   ILOW = INTARR(256)
   IHIGH = INTARR(256)

   UNPACK_T(0:63) = INDGEN(64)
   UNPACK_T(64:127) = 64 + INDGEN(64)/2
   UNPACK_T(128:255) = 96 + INDGEN(128)/4
   UNPACK_T(256:511) = 128 + INDGEN(256)/8
   UNPACK_T(512:1023) = 160 + INDGEN(512)/16
   UNPACK_T(1024:2047) =  192 + INDGEN(1024)/32
   UNPACK_T(2048:4095) =  224 + INDGEN(2048)/64

   FOR j=0,255 do BEGIN
      K = WHERE(UNPACK_T eq J)
      ILow(j) = K(0)
      IHigh(j) = K(N_ELEMENTS(K)-1)
   END

   PACK_T = fix((ILow+IHigh)/2.0 + .5)
END

;-------------------------------------------------------------
;+
; NAME:
;       UNPACK
; PURPOSE:
;       Uncompress a compressed image
; CATEGORY:
;
; CALLING SEQUENCE:
;       UncompressedImage = UNPACK(CompressedImage)
; INPUTS:
;       Image
; KEYWORD PARAMETERS:
;       None
; OUTPUTS:
;       An uncompressed image
; COMMON BLOCKS:
;       COMPRESSION_TABLES
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-
FUNCTION UNPACK, Image
   COMMON COMPRESSION_TABLES, PACK_T, UNPACK_T
   IF(N_ELEMENTS(PACK_T) EQ 0) THEN INIT_COMPRESSION_TABLES
   newImage =  PACK_T(Image)
   RETURN,newImage
END

;-------------------------------------------------------------
;+
; NAME:
;       PACK
; PURPOSE:
;       Compress an un- compressed image
; CATEGORY:
;
; CALLING SEQUENCE:
;       CompressedImage = UNPACK(UncompressedImage)
; INPUTS:
;       Image
; KEYWORD PARAMETERS:
;       None
; OUTPUTS:
;       An uncompressed image
; COMMON BLOCKS:
;       COMPRESSION_TABLES
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-
FUNCTION PACK, Image
   COMMON COMPRESSION_TABLES, PACK_T, UNPACK_T
   IF(N_ELEMENTS(UNPACK_T) EQ 0) THEN INIT_COMPRESSION_TABLES
   newImage =  UNPACK_T(Image)
   return,BYTE(newImage)
END



;-------------------------------------------------------------
;+
; NAME:
;       CLIP
; PURPOSE:
;       Grab a subregion of a vis image ensuring that the
;       edges are taken care of.
; CATEGORY:
;
; CALLING SEQUENCE:
;       region = CLIP(x,y,3,3,0)
; INPUTS:
;       X = column
;       Y = row
;       DX = delta x value
;       DY = delta y value
; KEYWORD PARAMETERS:
;       None
; OUTPUTS:
;       Offset contains the number of pixels that are off
;       of the image in the x and y directions.
; COMMON BLOCKS:
;       None
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-
FUNCTION CLIP, x,y,DX,DY,OFFSETS
   XLo = x-dx
   XHi = x+dx
   Ylo = y-dy
   Yhi = y+dy

   if(ARG_PRESENT(OFfsets)) THEN BEGIN
      xshift = 0
      yshift = 0
      IF(Xlo lt 0) THEN BEGIN
         XSHIFT = -Xlo
      END

      IF(ylo lt 0) THEN BEGIN
         YSHIFT = -ylo
      END

      OFFSETS = [xshift,yshift]
   END

   IF(XLo lt 0) THEN Xlo = 0
   IF(XHi gt 255) THEN XHi = 255
   IF(YLo lt 0) THEN Ylo = 0
   IF(YHi gt 255) THEN YHi = 255

   return,[xlo,ylo,xhi,yhi]
END


;-------------------------------------------------------------
;+
; NAME:
;       Region
; PURPOSE:
;       Grab a subregion of a vis image ensuring that the
;       edges are taken care of.
; CATEGORY:
;
; CALLING SEQUENCE:
;       region = REGION(x,y,3,3,/PAD)
; INPUTS:
;       X = column
;       Y = row
;       DX = delta x value
;       DY = delta y value
; KEYWORD PARAMETERS:
;       PAD == The X by Y numer of pixels off of the image that
;              the region covers.
; OUTPUTS:
;       An array of indices into a vis image the correspond to
;       the DX by DY subregion centered at X,Y.  Regions off of
;       the image are set to -1.
; COMMON BLOCKS:
;       None
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-
FUNCTION REGION, x,y,DX,DY,PAD
   COMMON xv_region, indexes
   Pts = CLIP(x,y,dx,dy,offset)

   IF(n_elements(Indexes) EQ 0) THEN indexes = LINDGEN(256,256)

   if(ARG_PRESENT(PAD)) THEN BEGIN
      result = LONARR(1+2*dx,1+2*dy,/NOZERO)
      result(*,*) = -1
      xdim = Pts(2)-Pts(0)
      ydim = Pts(3)-Pts(1)
      result(Offset(0):offset(0)+xdim,offset(1):offset(1)+ydim) = $
       Indexes(Pts(0):Pts(2),Pts(1):Pts(3))
      pad = offset
      return, REVERSE(result,2)
   END ELSE BEGIN
      return, REVERSE(indexes(pts(0):pts(2),pts(1):pts(3)),2)
   END
END


;-------------------------------------------------------------
;+
; NAME:      XV_CIRCLE
; PURPOSE:
;       returns the indices into an image that outline a circle
; CATEGORY:
;
; CALLING SEQUENCE:
;       circle = xv_circle(xc,yc,radius)
; INPUTS:
;       xcenter == col index to the center of the circle
;       ycenter == row index to the center of the circle
;       radius == radius of circle in pixels
; KEYWORD PARAMETERS:
;       None
; OUTPUTS:
;       indices into an image that outline a circle.
; COMMON BLOCKS:
;       None
; NOTES:
;
; MODIFICATION HISTORY:
;       Written by Kevin Ivory from Max Plank Institute
;-
FUNCTION XV_CIRCLE,xcenter,ycenter,Radius
   points = (2 * !PI / 99.0) * FINDGEN(100)
   x = xcenter + radius * COS(points )
   y = ycenter + radius * SIN(points )
   RETURN, TRANSPOSE([[x],[y]])
END



;-------------------------------------------------------------
;+
; NAME:
;       COMPUTE_BEST_SLOPE
; PURPOSE:
;       Examines a vis image and determines the best slope
;       to use for the XV_SUB_SLOPE routine.
; CATEGORY:
;
; CALLING SEQUENCE:
;       slope = compute_best_slope(im, /vertical)
; INPUTS:
;       A vis image
; KEYWORD PARAMETERS:
;       VERTICAL == use vertical slope if set, otherwise
;                   default to horizontal slope.
; OUTPUTS:
;       structure containing the following tags:
;         A:
;         B:
;         SLOPE:
;         INDEX:
; COMMON BLOCKS:
;       None
; NOTES:
;
; MODIFICATION HISTORY:
;-
FUNCTION COMPUTE_BEST_SLOPE, Image, Vertical=vertical
   OldError = 999999.0
   Index = 0
   Xs = indgen(246) + 5
   for i=5,250 do BEGIN

      IF KEYWORD_SET(Vertical) THEN BEGIN
         Slice = Image(i,5:250)
      END ELSE BEGIN
         Slice = Image(5:250,i)
      END

      params = LINFIT(Xs,Slice,Chisq = Error)
      IF(Error lt OldError) THEN BEGIN
         result = params
         OldError = error
         Index = i
      END
   END

   return,{a:result(0),b:result(1),slope:FIX(result(1)*256),index:index}
END


;-------------------------------------------------------------
;+
; NAME:
;       XV_SCALE_COLOR_TABLE
; PURPOSE:
;       Fits the color table from the CDF file into the table
;       size used in the current IDL session and the min/max
;       values specified.
; CATEGORY:
;
; CALLING SEQUENCE:
;       XV_SCALE_COLOR_TABLE
; INPUTS:
;       MIN = actual colors begin here.  Anything under this value
;             is set to the min value.
;       MAX = actual colors end here.  Anything over this value
;             is set to the max value.
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; COMMON BLOCKS:
;       COLORS
; NOTES:
;
; MODIFICATION HISTORY:
;-
PRO XV_SCALE_COLOR_TABLE, min, max
   COMMON COLORS, rr, gg, bb, rc, gc, bc
   tsize =  n_elements(rr)
   ;;; need to scale min and max
   ratio = float(tsize) / 256.0
   min = FIX(ratio * min)
   max = FIX(ratio * max)
   IF(tsize GT 0) THEN BEGIN
      ncolors =  max-min+1
      rc(0:min) =  rr(0)
      gc(0:min) =  gg(0)
      bc(0:min) =  bb(0)
      rc(max:*) =  rr(tsize-1)
      gc(max:*) =  gg(tsize-1)
      bc(max:*) =  bb(tsize-1)
      rc(min:max) =  congrid(rr,ncolors)
      gc(min:max) =  congrid(gg,ncolors)
      bc(min:max) =  congrid(bb,ncolors)
      tvlct,rc,gc,bc
   END
END



;-------------------------------------------------------------
;+
; NAME:
;       ADD_MAP
; PURPOSE:
;       An experimental procedure to add maps to a vis image
; CATEGORY:
;
; CALLING SEQUENCE:
;
; INPUTS:
;       None
; KEYWORD PARAMETERS:
;       NONE
; OUTPUTS:
;
; COMMON BLOCKS:
;
; NOTES:
;
; MODIFICATION HISTORY:
;       Kenny Hunt, 9/1/97
;
; Copyright (C) 1998, The University of Iowa Department of Physics and Astronomy
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;-
function ADD_MAP
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_DEBUG, dalts

   compute_crds
   earthCenter,xpix,ypix,polat,polon,bbox

   base = widget_base()
   dummy = widget_draw(base,xsize=bbox[2]-bbox[0]+1,ysize=bbox[3]-bbox[1]+1)
   widget_control,base,/realize
   widget_control,dummy,get_value=wnum
   wset,wnum
   center = where(glats EQ max(glats))
   center = center[0]
   xv_unpack_where,center,c_row,c_col
   gamma =  atan(bbcenter[0]-c_col, bbcenter[1]-c_row) * !RADEG
   gamma =  360.0 - gamma
   print,gamma

   col1 = bbox[0]
   row1 = bbox[1]
   col2 = bbox[2]
   row2 = bbox[3]
   actual_dist = norm(reform(locs(*,col1,row1,*)) - reform(locs(*,col2,row2)))
   print,actual_dist

   map_set, /satellite, sat_p=[norm(record.sc_pos_gci) / 6371.0, 0, gamma], $
    glats[bbcenter[0]], glons[bbcenter[1]], $
    /continents,/noborder
   junk =  tvrd()
   subi = image(bbox[0]:bbox[2],bbox[1]:bbox[3])
   j =  where(junk GT 0)
   subi(j) = 255
;   image(bbox[0]:bbox[2],bbox[1]:bbox[3]) =  subi
   widget_control,base,/destroy
   return,subi
END


PRO EarthCenter,xpix,ypix,glat,glon,bbox
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   compute_crds

   junk =  where(szas GE 0)
   xv_unpack_where,junk,rows,cols
   bbox = [min(cols),min(rows),max(cols),max(rows)]
   xpix = FIX((bbox[2]-bbox[0])*.5 + bbox[0])
   ypix = FIX((bbox[3]-bbox[1])*.5 + bbox[1])
   GCI_TO_GEO, record.sc_pos_gci * 6371.0 / NORM(record.sc_pos_gci), GLAT, GLON
   glat =  glat[0]
   glon = glon[0]
END

PRO SatelliteParams, altitude, gamma, omega
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit

   earthcenter,xpix,ypix,glat,glon,bbox
   altitude = norm(record.sc_pos_gci) / 6371.0
   p1 = record.sc_pos_gci - Locs(*,xpix,ypix)
   p2 = record.sc_pos_gci - Locs(*,xpix,128)
   omega =  acos( total(p1*p2) / (2*norm(p1)*norm(p2))) * !RADEG
   gamma =  glon - glons(xpix,ypix)
END


FUNCTION PixelsWide
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort

   dax = .00148471 ;angle per pixel in x direction
   day = .00128924 ;angle per pixel in y direction

   rad =  radius(0)
   l =  norm(record.sc_pos_gci)
   return, ROUND([2.0 * rad/ (sin(day)*l), 2.0 * rad / (sin(dax)*l)])
END



function GET_MAP
   COMMON mapper, mapwid, drawwid, image_map

   old =  !D.Window

   IF(N_ELEMENTS(mapwid) EQ 0) THEN mapwid =  LONG(0)
   isVAlid = WIDGET_INFO(mapwid,/VALID)
   IF(NOT IsValid) THEN BEGIN
      mapwid = widget_base()
      drawwid = widget_draw(mapwid,xsize=512,ysize=512,retain=2)
      widget_control,mapwid,/realize,map=0
   END


   WIDGET_CONTROL,drawwid,get_value=wnum
   WSET,wnum

   earthCenter,xpix,ypix,polat,polon,bbox
   SatelliteParams, alt, gamma, omega
   map_set, polat,polon,/satellite, sat_p=[alt,omega,gamma],/continents,/noborder,/grid
   image_map =  tvrd()

   WIDGET_CONTROL,mapwid,/destroy
   WSET,old
   return,image_map
END

PRO ADD_MAP2
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount

   x =  get_map()
   earthCenter,xp,yp
   bbox =  pixelswide()

END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; JOHN -------------------EDIT THIS FUNCTION-----------------------------------;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION MAPTOPOLAR
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount

   ;;; Time is a 3 element array where
   ;;; time[0] -> Year
   ;;; time[1] -> DOY
   ;;; time[2] -> Milliseconds of day
   time =  record.time_pb5

   ;;; This funciton computes all the XV_DERIVED_DATA information.  Without
   ;;; the COMPUTE_COORDS call, there is no guarantee that the information
   ;;; in this common block is correct.
   compute_crds

   ;;; The returned image should be a 256x256 array.  If not, then we'll have
   ;;; to do something different than the way it is currently set up.
   result = Dist(256,256)
   return, Result
END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; JOHN------------------------END EDIT--------------------------------------------;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO RC_PLOT_EVENT, event
   WIDGET_CONTROL,event.top,GET_UVALUE=data

   CASE event.id OF
      Data.DrawWin: BEGIN
         IF(event.Press ne 1) THEN RETURN

         OLD_WINDOW = !D.WINDOW
         WIDGET_CONTROL,data.drawwin,GET_VALUE=wnum
         WSET,wnum
         WIDGET_CONTROL,Data.RC,GET_VALUE=mode

         IF(mode eq 0) THEN BEGIN
            IY = (612-event.y-50)/2
            IF(IY lt 0) THEN IY = 0 ELSE IF(IY GT 255) THEN IY = 255
            Profile = Data.Image(*,IY)
            XS = [50,562]
            YS = [event.y,event.y]
            Label = 'Row: ' + STRING(IY+1,FORMAT='(I3)')
         END ELSE BEGIN
            IX = (event.x-50)/2
            IF(IX lt 0) THEN IX = 0 ELSE IF(IX GT 255) THEN IX = 255
            Profile = reverse(reform(DATA.Image(IX,*)))
            XS = [IX*2+50,IX*2+50]
            YS = [50,562]
            Label = 'Col: ' + STRING(IX+1,FORMAT='(I3)')
         END

         WIDGET_CONTROL,Data.Label,SET_VALUE=Label

         ERASE
         TV,REBIN(Data.IMAGE,512,512),50,50,/ORDER
         IF(Mode eq 0) THEN BEGIN
            PLOT,Profile,/noerase,/dev,pos=[50,50,562,562],$
             xrange=[0,256],xstyle=1,xmargin=0,ymargin=0
         END ELSE BEGIN
            PLOT,Profile,indgen(512),/noerase,/dev,$
             pos=[50,50,562,562],yrange=[0,256],$
             ystyle=1,xmargin=0,ymargin=0
         END

         PLOTS,xs,ys,/dev
         WSET,OLD_WINDOW
      END
      Data.Close: WIDGET_CONTROL,event.top,/DESTROY
      ELSE: x=1
   END
END

PRO XV_RC, parent,Image
   Base = WIDGET_BASE(GROUP_LEADER=parent,TITLE='Row/Col Plot',/COLUMN)
   Draw = WIDGET_DRAW(Base,XSIZE=612,YSIZE=612,/BUTTON_EVENTS,retain=2)

   RowBase = WIDGET_BASE(Base,/ROW)

   Pos = WIDGET_LABEL(RowBase,VALUE='Row: Null',FRAME=3)
   RowCol = CW_BGROUP(RowBase,['Row','Col'],FRAME=3,/EXCLUSIVE,SET_VALUE=0,/ROW)
   Close = WIDGET_BUTTON(RowBase,VALUE='Close')

   Data = {Base:Base,$
           Image:Image,$
           Label:Pos,$
           Close:Close,$
           RC:RowCol,$
           DrawWin:Draw}

   WIDGET_CONTROL,Base,/REALIZE,SET_UVALUE=data
   XMANAGER,"RC_PLOT",Base,/NO_BLOCK
   RC_PLOT_EVENT, {ID:Draw, Top:Base, HANDLER:0L, X:306, Y:306, PRESS:1}
END
;+++++++++++++++++++++++++++++++++++++++++
;  Register a widget so it will be notified
;  of cursor motion in the active window.
;-----------------------------------------
PRO XV_REGISTER_VIEW_HANDLER, Widget
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_VW_WIDS, Hidden, Dummy

   IF(HCOUNT eq N_ELEMENTS(Handlers)-1) THEN BEGIN
      print,"XV_REGISTER_VIEW_HANDLER_ERROR"
      return
   END
   Handlers(HCount) = Widget
   HCount = HCount + 1
END


;+++++++++++++++++++++++++++++++++++++++++
;  Unregister a widget from the active
;  window.
;-----------------------------------------
PRO XV_UNREGISTER_VIEW_HANDLER, Widget
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_VW_WIDS, Hidden, Dummy

   junk = WHERE(Handlers eq Widget, count)
   if(count eq 1) THEN BEGIN
      Low = Junk(0)
      HANDLERS(Low:HCount-1) = Handlers(Low+1:HCount)
   END
   HCount = HCount - 1
END


;+++++++++++++++++++++++++++++++++++++++++
; Convenience procedure to activate the draw
; widget or to create a new one if needed
;-----------------------------------------
PRO XV_SET_DRAW_WIN
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_VW_WIDS, Hidden, Dummy

   isValid = WIDGET_INFO(ViewWid,/VALID_ID)
   IF(isValid eq 0) THEN XV_CREATE_VIEW_WINDOW, MainWid

   WIDGET_CONTROL, DrawWid, GET_VALUE=WinNum
   WSET, WinNum
END


;+++++++++++++++++++++++++++++++++++++++++
; Update the view window
;-----------------------------------------
PRO XV_UPDATE_VIEW_WINDOW, ROI_VAL, USE_IMAGE=use_image
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_EARTH, EARTH_RADIUS, MAX_RADIUS, MIN_RADIUS
   COMMON XV_VW_WIDS, Hidden, Dummy

   IF(Flags.Loaded EQ 0) THEN RETURN

   IF(N_PARAMS() eq 0) THEN ROI_VAl = 255
   WIDGET_CONTROL, MainWid, GET_UVALUE=Wids
   WIDGET_CONTROL, Wids.Zoom1, GET_UVALUE=Z1
   WIDGET_CONTROL, Wids.Zoom2, GET_UVALUE=Z2
   WIDGET_CONTROL, Wids.Zoom3, GET_UVALUE=Z3

   isValid = WIDGET_INFO(ViewWid,/VALID_ID)
   IF(isValid eq 0) THEN XV_CREATE_VIEW_WINDOW, MainWid
   WIDGET_CONTROL, DrawWid, GET_VALUE=WinNum
   OLD_WINDOW = !D.WINDOW
   WSET, WinNum

   order =  1

   IF(KEYWORD_SET(use_image) NE 0) THEN BEGIN
      IF( !D.TABLE_SIZE LT 256) THEN TVImage = FIX(TVImage * (FLOAT(!D.TABLE_SIZE) / 256.0))
      TV, USE_IMAGE,ORDER=order
      WSET, OLD_WINDOW
      RETURN
   END ELSE BEGIN
      TVImage =  Image

      junk = WHERE(ROI lt 0, count)
      IF(count eq 0) THEN TVImage(ROI) =  ROI_Val
      IF(Flags.Dist EQ 1) THEN TVImage =  CONGRID(XV_UNDISTORT(Temporary(TVIMAGE)),256,256)
      IF(Flags.XPand EQ 1) THEN TVImage =  Bytscl(unpack(tvimage))

      IF( !D.TABLE_SIZE LT 256) THEN TVImage = FIX(TVImage * (FLOAT(!D.TABLE_SIZE) / 256.0))
      IF(Z1 EQ 1) THEN TV,TVImage,ORDER=order $
      ELSE IF(Z2 EQ 1) THEN TV,REBIN(TVImage,512,512),ORDER=order $
      ELSE IF(Z3 EQ 1) THEN TV,REBIN(TVImage,768,768),ORDER=order

      IF(MaxRecs EQ 0) THEN BEGIN
         diff = Curr_limit[1] - Curr_limit[0]
         IF(DIFF GT 0) THEN text_color = diff/2.0 + curr_limit[0] ELSE text_color =  !D.table_size/2.0
         xyouts,.1,.5,'No data for this day',color=text_color,/norm
      END

      WSET,OLD_WINDOW
   END
END

;+++++++++++++++++++++++++++++++++++++++++
; Handle any events generated by the DRAW WIN
; Pass the event up the widget tree for further
; handling
;-----------------------------------------
PRO VIEW_EVENT, Event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_VW_WIDS, Hidden, Dummy
   COMMON XV_CURSOR, Xsc, Ysc, Xim, Yim, Xcd, Ycd, Xlb, Ylb

   WIDGET_CONTROL, MainWid, GET_UVALUE=Wids
   type = tag_names(event,/STRUCTURE_NAME)

   IF(type eq 'WIDGET_DRAW') THEN BEGIN ;-------------------Case 1--------------------
      IF(event.x LT 0 OR event.y LT 0) THEN return
      geo = WIDGET_INFO(Event.id,/GEOMETRY)
      IF(event.x GE geo.DRAW_XSIZE OR event.y GE geo.DRAW_YSIZE) THEN RETURN

      IF(geo.DRAW_XSIZE eq 512) THEN BEGIN
         Xsc = event.x/2
         Ysc = event.y/2
      END ELSE IF(geo.DRAW_XSIZE eq 768) THEN BEGIN
         Xsc = event.x/3
         Ysc = event.y/3
      END ELSE BEGIN
         Xsc = event.x
         Ysc = event.y
      END

      xim = xsc
      yim = 255-ysc

      IF(record.sensor EQ 0) THEN begin
         xcd = xsc
         ycd = 255-ysc
      END ELSE BEGIN
         xcd = 255-xsc
         ycd = ysc
      end

      IF(record.sensor EQ 0) THEN BEGIN
         xlb = xsc + 1
         ylb = 256 -ysc
      END ELSE BEGIN
         xlb = 256 -xsc
         ylb = ysc + 1
      END

      ;; Check type of event and call correct functions
      ;; Event.TYPE = {PRESS,RELEASE,MOTION,SCROLLBAR,EXPOSURE}
      ;; Use FORTRAN style indices so increment positions by 1
      IF(Event.TYPE lt 3) THEN BEGIN
         msg = '(' + STRING(Xlb,FORMAT='(I3)') + $
          ',' + STRING(Ylb,FORMAT='(I3)') + $
          ')=' + STRING(FIX(Image(Xim,Yim)),FORMAT='(I4)')
         WIDGET_CONTROL, Wids.ROWCOL, SET_VALUE=string(msg)
      END ELSE XV_UPDATE_VIEW_WINDOW

      FOR i=0,HCOUNT-1 DO BEGIN
         IF(WIDGET_INFO(Handlers(i),/VALID_ID) eq 1) THEN BEGIN
            WIDGET_CONTROL,send_event=event,Handlers(i)
         END
      END

   END ELSE IF(type eq 'WIDGET_TRACKING') THEN BEGIN ;--------------------Case 2------------------
      IF(event.enter eq 1) THEN BEGIN
         WIDGET_CONTROL, Hidden, SET_TEXT_SELECT=[4,0], /ALL_TEXT_EVENTS
      END ELSE BEGIN
         WIDGET_CONTROL, Hidden, SET_TEXT_SELECT=[4,0], ALL_TEXT_EVENTS=0
      END

   END ELSE IF(type eq 'WIDGET_TEXT_SEL') THEN BEGIN ;--------------------Case 3-------------------
      WIDGET_CONTROL, Wids.Zoom1, GET_UVALUE=Z1
      WIDGET_CONTROL, Wids.Zoom2, GET_UVALUE=Z2
      WIDGET_CONTROL, Wids.Zoom3, GET_UVALUE=Z3

      if(Z1 eq 1) THEN BEGIN
         Factor = 1
         Max = 255
      END ELSE IF(Z2 eq 1) THEN BEGIN
         Factor = 2
         Max = 511
      END ELSE BEGIN
         Factor = 3
         Max = 767
      END

      dx = 0
      dy = 0
      IF(event.offset eq 0) THEN dy = 1 ELSE $
       IF(event.offset eq 4) THEN dy = -1 ELSE $
       IF(event.offset eq 1) THEN dx = -1 ELSE $
       IF(event.offset eq 3) THEN dx = 1 ELSE BEGIN
         WIDGET_CONTROL, Hidden, SET_TEXT_SELECT=[2,0], /CLEAR_EVENTS
         RETURN
      END

      X = (Xsc+dx)*Factor
      Y = (Ysc+dy)*Factor
      IF((X le Max) AND (X ge 0) AND (Y le Max) AND (Y ge 0)) THEN BEGIN
         WIDGET_CONTROL, DrawWid, GET_VALUE=WinNum
         OLD_WINDOW = !D.WINDOW
         WSET, WinNum

         TVCRS,x,y
         FakeButtonPush = {WIDGET_DRAW, $
                           ID:DrawWid,$
                           TOP:ViewWid,$
                           HANDLER:0L,$
                           TYPE:0,$
                           X:X,$
                           Y:Y,$
                           Press:0,$
                           RELEASE:0,$
                           CLICKS:1}
         WIDGET_CONTROL,send_event=FakeButtonPush,DrawWid

         WSET,OLD_WINDOW
      END
      WIDGET_CONTROL, Hidden, SET_TEXT_SELECT=[2,0], /CLEAR_EVENTS

   END ELSE IF(type eq 'WIDGET_TEXT_CH') THEN BEGIN ;-------------------Case 4-----------------
      IF(FIX(event.ch) eq 10) THEN BEGIN
         WIDGET_CONTROL, Wids.Zoom1, GET_UVALUE=Z1
         WIDGET_CONTROL, Wids.Zoom2, GET_UVALUE=Z2
         WIDGET_CONTROL, Wids.Zoom3, GET_UVALUE=Z3

         if(Z1 eq 1) THEN BEGIN
            Factor = 1
         END ELSE IF(Z2 eq 1) THEN BEGIN
            Factor = 2
         END ELSE BEGIN
            Factor = 3
         END

         FakeButtonPush = {WIDGET_DRAW, $
                           ID:DrawWid,$
                           TOP:ViewWid,$
                           HANDLER:0L,$
                           TYPE:0,$
                           X:Xsc*Factor,$
                           Y:Ysc*Factor,$
                           Press:1,$
                           RELEASE:0,$
                           CLICKS:1}
         WIDGET_CONTROL,send_event=FakeButtonPush,DrawWid
         WIDGET_CONTROL,Hidden,SET_TEXT_SELECT=[2,0], SET_VALUE=['1','2','3'],/CLEAR_EVENTS
      END
   END ELSE IF(type EQ 'XV_COLORS_LOAD') THEN BEGIN
      OLD_WINDOW =  !D.window
      WIDGET_CONTROL, DrawWid, GET_VALUE=WinNum
      WSET, WinNum
      tvlct,event.r,event.g,event.b
      wset,OLD_WINDOW
      XV_UPDATE_VIEW_WINDOW
   END
END


FUNCTION extract_basename, fullfilename, path
   pathlen =  strlen(path)
   filenamelen = strlen(fullfilename)
   return, strmid(fullfilename,pathlen,filenamelen-pathlen)
END

;+++++++++++++++++++++++++++++++++++++++++
; Create a separate graphics window for
; viewing the selected image
;-----------------------------------------
PRO XV_CREATE_VIEW_WINDOW, parent
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_VW_WIDS, Hidden, Dummy
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort

   IF XREGISTERED("VIEW") THEN RETURN

   title = extract_basename(filename,path)
   ViewWid = WIDGET_BASE(GROUP_LEADER=parent, TLB_FRAME_ATTR=1, TITLE=title)
   DrawWid = WIDGET_DRAW(ViewWid, XSIZE=256, YSIZE=256,$
                         COLORS=256,$
                         /BUTTON_EVENTS, /MOTION_EVENTS, $;/EXPOSE_EVENTS,$
                         RETAIN=2,$
                         /TRACKING_EVENT)

   Hidden = WIDGET_TEXT(ViewWid,VALUE=['1','2','3'],$
                        FRAME=0,xsize=3,ysize=3,/ALL)

   WIDGET_CONTROL,Hidden,SET_TEXT_SELECT=[2,0]
   WIDGET_CONTROL, ViewWid, /REALIZE
   XMANAGER, "VIEW", ViewWid, /NO_BLOCK
   WIDGET_CONTROL, DrawWid, TIMER=.1
END
FUNCTION XV_LoadImage, filename
   type = STRUPCASE(STRTRIM((str_sep(filename,"."))(1),2))

   CASE type OF
      'BMP': newImage = READ_BMP(Filename)
      'GIF': READ_GIF,filename, newImage
      'PIC': READ_PICT,filename,newimage
      'PPM': READ_PPM, filename,newimage
      'DAT': BEGIN
         restore,filename
         newimage= binimage
      END
      ELSE: BEGIN
         print,'Unknown data format'
         RETURN, [-1]
      END
   END
   return, newimage
END

PRO XV_STACK_EVENT, event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_STACK, StackWid, Stack, StackSize, StackLabels, MaxSize
   WIDGET_CONTROL,event.top,GET_UVALUE=Wids
   selected = WIDGET_INFO(wids.nameswid,/list_select)

   CASE event.id OF
      Wids.ClearBid: BEGIN
         StackSize =  0
         StackLabels(*) =  ""
         WIDGET_CONTROL,Wids.NamesWid,SET_VALUE=StackLabels
      END
      Wids.AvgBid: BEGIN
         result = intarr(256,256)
         FOR i=0,StackSize-1 DO BEGIN
            result =  result + Stack(i,*,*)
         END
         Image = BYTSCL(result/double(StackSize))
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.SumBid: BEGIN
         result = intarr(256,256)
         FOR i=0,StackSize-1 DO BEGIN
            Temp =  Stack(i,*,*)
            junk =  where(Temp LT 15,count)
            IF(count GT 0) THEN Temp(junk) = 15
            Temp = Temp - 15
            result(*,*) =  result(*,*) + Temp
         END
         Image = BYTSCL(result)
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.nameswid: BEGIN
         check =  where(selected EQ -1,count)
         IF(count GT 0 OR selected GT StackSize-1) THEN return
         Image = Stack(selected,*,*)
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.AddABid: BEGIN
         Stack(StackSize,*,*) =  Image
         StackLabels(StackSize) = DateToString(record.time_pb5)
         StackSize =  StackSize + 1
         WIDGET_CONTROL,Wids.NamesWid,SET_VALUE=StackLabels
      END
      Wids.AddNBid: BEGIN
         filename = dialog_pickfile()
         IF(filename NE "") THEN BEGIN
            newImage = XV_LoadImage(filename)
            test =  where(newimage LT 0,count)
            IF(count GT 0) THEN BEGIN
               print,"error loading file"
            END ELSE BEGIN
               Stack(StackSize,*,*) =  newImage
               StackLabels(StackSize) = filename
               StackSize =  StackSize + 1
               WIDGET_CONTROL,Wids.NamesWid,SET_VALUE=StackLabels
            END
         END
      END
      Wids.DelBid: BEGIN
         check =  where(selected EQ -1,count)
         IF(count GT 0 OR selected GT StackSize-1) THEN return
         FOR i=selected,StackSize-1 DO BEGIN
            Stack(i,*,*) =  Stack(i+1,*,*)
            StackLabels(i) = StackLabels(i+1)
         END
         StackLabels(StackSize-1) =  ''
         StackSize =  StackSize-1
         WIDGET_CONTROL,Wids.NamesWid,SET_VALUE=StackLabels
      END
      Wids.CloseBid: BEGIN
         WIDGET_CONTROL,event.top,/DESTROY
      END
      ELSE: print,'Unknown option'
   END

END


;+++++++++++++++++++++++++++++++++++++++++
; Create a separate graphics window for
; viewing the selected image
;-----------------------------------------
PRO XV_CREATE_STACK_WINDOW, parent
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_STACK, StackWid, Stack, StackSize, StackLabels, MaxSize

   IF XREGISTERED("XV_STACK") THEN RETURN

   MaxSize =  10
   StackSize =  0
   StackLabels =  strarr(maxsize)

   ;; Initialize Stack if this is the first time in
   IF((size(stack))(1) EQ 0) THEN Stack = BYTARR(MaxSize,256,256)

   StackWid = WIDGET_BASE(GROUP_LEADER=parent, TLB_FRAME_ATTR=1,/COLUMN,$
                          MBAR=StackMenu)
   ImageWid =  WIDGET_BUTTON(StackMenu,VALUE="Image",/menu)
   FilterWid =  WIDGET_BUTTON(StackMenu,VALUE="Filter",/menu)

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ; Create Image Menu Pulldowns
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   AddABid = WIDGET_BUTTON(ImageWid, VALUE="Add Active")
   AddNBid = WIDGET_BUTTON(ImageWid, VALUE="Add From File")
   DelBid = WIDGET_BUTTON(ImageWid, VALUE="Remove")

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ; Create Filters Pulldown
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   SumBid = WIDGET_BUTTON(FilterWid, VALUE="Sum")
   AvgBid = WIDGET_BUTTON(FilterWid, VALUE="Avg")

   Nameswid =  WIDGET_LIST(StackWid,VALUE="",YSIZE=10,xsize=20)
   ClearBid =  WIDGET_BUTTON(StackWid, VALUE="Clear")
   Closebid =  WIDGET_BUTTON(StackWid,VALUE="Close")

   Wids =  {AddABid:AddABid,$
            AddNBid:AddNBid,$
            DelBid:DelBid,$
            SumBid:SumBid,$
            AvgBid:AvgBid,$
            NamesWid:Nameswid,$
            ClearBid:ClearBid,$
            CloseBid:CloseBid}


   WIDGET_CONTROL, StackWid, /REALIZE, set_uvalue=wids
   XMANAGER, "XV_STACK", StackWid, /NO_BLOCK
END
FUNCTION XV_CW_ROI_EVENT, event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_CURSOR, Xsc, Ysc, Xim, Yim, Xcd, Ycd, Xlb, Ylb

   Base = event.handler
   Child = WIDGET_INFO(BAse,/CHILD)
   WIDGET_CONTROL,CHild,Get_UVALUE=State,/NO_COPY
   WIDGET_CONTROL,State.MODEBid,GET_VALUE=Mode
   WIDGET_CONTROL,State.VAlueBid,GET_VALUE=REGIONSIZE

   junk = WHERE(State.ROI lt 0, NilRoi)
   Propagate = 0
   NumPts = State.NumPts
   XPts = State.XPts
   YPts = State.YPts
   ROI = State.ROI
   ModeBid = State.MODEBid
   ValueBid = State.VAlUEBid
   ClearBid = State.CLEARBid

   CASE event.id OF
      event.handler: BEGIN
         IF(MODE eq 0) THEN BEGIN ;Square
            IF(event.PRESS eq 1) THEN BEGIN
               Delta = REgionSize/2
               Xd = [Xim-Delta,Xim-Delta,Xim+Delta,Xim+Delta]
               Yd = [Yim-Delta,Yim+Delta,Yim+Delta,Yim-Delta]
               Reg = POLYFILLV(Xd,Yd,256,256)
               IF(NilRoi eq 1) THEN BEGIN
                  ROI = Reg
               END ELSE BEGIN
                  ROI = [ROI,Reg]
                  ROI = ROI(UNIQ(ROI,SORT(ROI)))
               END
               Propagate = 1
            END
         END ELSE IF(MODE eq 1) THEN BEGIN ;Circle
            IF(event.PRESS eq 1) THEN BEGIN
               Reg = XV_CIRCLE(Xim,Yim,RegionSize/2)
               Reg = Polyfillv(Reg(0,*),Reg(1,*),256,256)
               IF(NilRoi eq 1) THEN BEGIN
                  ROI = Reg
               END ELSE BEGIN
                  ROI = [ROI,Reg]
                  ROI = ROI(UNIQ(ROI,SORT(ROI)))
               END
               Propagate = 1
            END
         END ELSE IF(MODE eq 2) THEN BEGIN ;Rect
            IF(event.PRESS eq 1) THEN BEGIN
               IF(NumPts eq 0) THEN BEGIN
                  XPts = [Xim]
                  YPts = [Yim]
                  NumPts = 1
               END ELSE BEGIN
                  XPts = [XPts,XPts,Xim,Xim]
                  YPts = [YPTs,Yim,Yim,YPts]
                  Reg = POLYFILLV(XPts,YPts,256,256)
                  IF(NilRoi eq 1) THEN BEGIN
                     ROI = Reg
                  END ELSE BEGIN
                     ROI = [ROI,Reg]
                     ROI = ROI(UNIQ(ROI,SORT(ROI)))
                  END
                  NumPts = 0
                  Propagate = 1
               END
            END
         END ELSE IF(MODE eq 3) THEN BEGIN ;POLY
            IF(event.PRESS eq 4 AND NumPts ge 2) THEN BEGIN
               XPts = [XPts,Xim]
               YPts = [YPts,Yim]
               Reg = POLYFILLV(XPts,YPts,256,256)
               IF(NilRoi eq 1) THEN     ROI = Reg ELSE BEGIN
                  ROI = [ROI,Reg]
                  ROI = ROI(UNIQ(ROI,SORT(ROI)))
               END
               NumPts = 0
               Propagate = 1
            END ELSE IF(event.PRESS eq 4) THEN BEGIN
               print,'Error: need at least 3 points'
               NumPts = 0
            END ELSE IF(event.PRESS eq 1 AND NumPts eq 0) THEN BEGIN
               XPts = [Xim]
               YPts = [Yim]
               NumPts = 1
            END ELSE IF(event.PRESS eq 1) THEN BEGIN
               XPts = [XPts,Xim]
               YPts = [YPts,Yim]
               NumPts = NumPts + 1
            END
         END
      END
      State.MODEBid: BEGIN
         IF(Mode eq 0) THEN BEGIN
            label = WIDGET_INFO(State.ValueBid,/CHILD)
            WIDGET_CONTROL,Label,SET_VALUE='Edge Length'
            WIDGET_CONTROL,State.ValueBid,/MAP
         END ELSE IF(Mode eq 1) THEN BEGIN
            label = WIDGET_INFO(State.ValueBid,/CHILD)
            WIDGET_CONTROL,Label,SET_VALUE='Diameter'
            WIDGET_CONTROL,State.ValueBid,/MAP
         END ELSE WIDGET_CONTROL,State.VAlueBid,MAP=0
         NumPts = 0
      END
      State.ClearBid: BEGIN
         ROI = [-1]
         Propagate = 1
      END
      ELSE: BEGIN
         WIDGET_CONTROL,Child,SET_UVALUE=State,/NO_COPY
         RETURN,0
      END
   ENDCASE

   NewState = {Roi:ROI,$
               NumPts:NumPts,$
               XPts:XPts,$
               YPts:YPts,$
               ModeBid:ModeBid,$
               ValueBid:ValueBid,$
               ClearBid:CLearBid }

   WIDGET_CONTROL,Child,SET_UVALUE=NewState
   IF(Propagate eq 1) THEN return,{CW_ROI, ID:base,TOP:event.top,HANDLER:0L}$
   ELSE return,0
END

PRO XV_CW_SET_VALUE, id, Value
   stash = WIDGET_INFO(id, /CHILD)
   WIDGET_CONTROL,stash,GET_UVALUE=state

   NewState = {Roi:Value,$
               NumPts:0,$
               XPts:-1,$
               YPts:-1,$
               ModeBid:State.ModeBid,$
               ValueBid:State.ValueBid,$
               ClearBid:State.CLearBid }

   WIDGET_CONTROL,stash,SET_UVALUE=NewState
END


FUNCTION XV_CW_GET_VALUE, id
   stash = WIDGET_INFO(id, /CHILD)
   WIDGET_CONTROL,stash,GET_UVALUE=state
   return,state.ROI
END


PRO XV_CW_KILL, DyingWidget
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   XV_UNREGISTER_VIEW_HANDLER, DyingWidget
   ROI = [-1]
END


FUNCTION XV_CW_ROI, Parent, TITLE=title, UValue=uvalue, Frame=frame
   IF NOT KEYWORD_SET(Uvalue) THEN uvalue = 0
   IF NOT KEYWORD_SET(Frame) THEN frame = 0

   Base = WIDGET_BASE(Parent,/COLUMN,EVENT_FUNC='XV_CW_ROI_EVENT', FRAME=frame,$
                      FUNC_GET_VALUE='XV_CW_GET_VALUE',$
                      PRO_SET_VALUE='XV_CW_SET_VALUE',KILL_NOTIFY='XV_CW_KILL')

   Child = WIDGET_BASE(Base)

   IF(KEYWORD_SET(Title)) THEN junk = WIDGET_LABEL(Base,VALUE=title)

   ModeBid = CW_BGROUP(Base,["Square","Circle","Rect","Poly"],$
                       /EXCLUSIVE, SET_VALUE=0, /ROW)

   ValueBid = CW_FIELD(Base,VALUE=7, /INTEGER, $
                       XSIZE=3, /ALL_EVENTS,TITLE="Edge Length")

   ClearBid = WIDGET_BUTTON(Base, VALUE="CLEAR")

   State = {Roi:[-1],$
            NumPts:0,$
            XPts:-1,$
            YPts:-1,$
            ModeBid:ModeBid,$
            ValueBid:ValueBid,$
            ClearBid:CLearBid }

   WIDGET_CONTROL, CHILD, SET_UVALUE=State
   XV_REGISTER_VIEW_HANDLER,Base
   return,base
END
;----------------------------------------------------------
; PURPOSE:
;  Event handler for the surfer dialog.
;
; CALLING SEQUENCE:
;  Called only via the IDL event dispatcher.
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Sets the common block variables
;
; COMMON BLOCKS:
;  XV_SURFER_DIALOG
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_SURFER_DIALOG_EVENT, event
   COMMON XV_SURFER_DIALOG, New, Factor, Mode, Zrot, XRot, ZSc
   FactorVals = [2,3,4,5,6,7,8,9,10,16]
   WIDGET_CONTROL,Event.Top,GET_UVALUE=Wids

   CASE event.id OF
      Wids.SURFBid: BEGIN
         FactSel = WIDGET_INFO(Wids.SURFBid,/DROPLIST_SELECT)
         Factor = FactorVals(FactSel)
      END
      Wids.MODEBid: BEGIN
         Mode = WIDGET_INFO(Wids.ModeBid,/DROPLIST_SELECT)
      END
      Wids.XRotBid: BEGIN
         WIDGET_CONTROL, Wids.XRotBid, GET_VALUE=XRot
      END
      Wids.ZrotBid: BEGIN
         WIDGET_CONTROL, Wids.ZROTBid, GET_VALUE=Zrot
      END
      Wids.ZScBid: BEGIN
         ZSC =  WIDGET_INFO(Wids.ZSCBid,/DROPLIST_SELECT)
      END
      Wids.OKBid: BEGIN
         new = 1
         WIDGET_CONTROL,event.top,/DESTROY
      END
      Wids.CancelBid: BEGIN
         new = 0
         WIDGET_CONTROL,event.top,/DESTROY
      END
   END
END


;----------------------------------------------------------
; PURPOSE:
;  Collects the parameters for the surfer window.
;
; CALLING SEQUENCE:
;
; INPUTS:
;  PARENT == widget id of the parent
;  State == current parameters of the surfer window.
;           A structure with tags {mode,xrot,zrot,zsc,factor,new}
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  returns a structure with tags:
;  MODE: 0 == Continuous or 1 == Click
;  XROT: xaxis viewing angle rotation in degrees
;  ZROT: zaxis viewing angle rotation in degrees
;  ZSc:  scaling to apply to the surfer
;
; SIDE EFFECTS:
;  None
;
; COMMON BLOCKS:
;  XV_SURFER_DIALOG
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_SURFER_DIALOG, Parent, State
   COMMON XV_SURFER_DIALOG, New, Factor, Mode, Zrot, XRot, ZSc
   FactorVals = [2,3,4,5,6,7,8,9,10,16]

   Base = WIDGET_BASE(GROUP_LEADER=parent, TITLE='SURFer Parameters', $
                      /COLUMN, /MODAL)
   SURFBid = WIDGET_DROPLIST(Base,VALUE=['2','3','4','5','6','7','8','9','10','16'],$
                             TITLE='Factor')
   ModeBid = WIDGET_DROPLIST(Base, VALUE=["Continuous","Click"],TITLE='Mode')


   XRotBid = WIDGET_SLIDER(Base, $
                           SCR_XSIZE=180, Minimum=-90,MAXIMUM=90, VALUE=30, TITLE='X-Axis Rotation')
   ZrotBid = WIDGET_SLIDER(Base, $
                           SCR_XSIZE=180, Minimum=-90,MAXIMUM=90, VALUE=30, TITLE='Z-Axis Rotation')
   ZScBid =  WIDGET_DROPLIST(Base,VALUE=["Constant","Variable"], TITLE='Z Scaling')


   OKBid = WIDGET_BUTTON(Base, VALUE='OK')
   CANCELBid = WIDGET_BUTTON(Base, VALUE='Cancel')

   new = 0
   Mode = state.mode
   XRot =  state.xrot
   Zrot =  state.zrot
   ZSC =  State.ZSc
   Factor = state.factor
   junk = WHERE(state.factor eq factorVals)
   WIDGET_CONTROL,SURFBid,SET_DROPLIST_SELECT=junk(0)
   WIDGET_CONTROL,ModeBid,SET_DROPLIST_SELECT=State.mode
   WIDGET_CONTROL,XRotBid,SET_VALUE=XRot
   WIDGET_CONTROL,ZrotBid,SET_VALUE=Zrot
   WIDGET_CONTROL,ZScBid,SET_DROPLIST_SELECT=ZSc

   Wids =  {SurfBid:SurfBid,$
            ModeBid:ModeBid,$
            OKBid:OKBid,$
            CancelBid:CancelBid,$
            XRotBid:XRotBid,$
            ZrotBid:ZrotBid,$
            ZScBid:ZScBid}

   WIDGET_CONTROL,Base,/REALIZE, SET_UVALUE=Wids
   XMANAGER,"XV_SURFER_DIALOG",Base
   return,{new:new,Mode:mode,Factor:Factor,XRot:XRot,Zrot:Zrot,ZSc:ZSC}
END


;----------------------------------------------------------
; PURPOSE:
;  Event handler for the detain window events.
;
; CALLING SEQUENCE:
;  Called only via IDL event dispatcher.
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  sets common block variables
;
; COMMON BLOCKS:
;  XV_DETAIL_DIALOG
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_DETAIL_DIALOG_EVENT, event
   COMMON XV_DETAIL_DIALOG, MaskBid, ModeBid, UnitBid, New, OK, Cancel, MaskSize, Mode, Unit
   CASE event.id OF
      UnitBid: BEGIN
         Unit =  WIDGET_INFO(UnitBid, /DROPLIST_SELECT)
      END
      MaskBid: BEGIN
         WIDGET_CONTROL,MaskBid,GET_VALUE=MaskSize
         IF(NOT MaskSize) THEN BEGIN
            MaskSize = MaskSize + 1
            WIDGET_CONTROL,MaskBid,SET_VALUE=MaskSize
         END
      END
      MODEBid: BEGIN
         Mode = WIDGET_INFO(ModeBid,/DROPLIST_SELECT)
      END
      OK: BEGIN
         WIDGET_CONTROL,MaskBid,GET_VALUE=MaskSize
         IF(NOT MaskSize) THEN BEGIN
            MaskSize = MaskSize + 1
            WIDGET_CONTROL,MaskBid,SET_VALUE=MaskSize
         END
         Mode = WIDGET_INFO(ModeBid,/DROPLIST_SELECT)
         new = 1
         WIDGET_CONTROL,event.top,/DESTROY
      END
      Cancel: BEGIN
         WIDGET_CONTROL,MaskBid,GET_VALUE=MaskSize
         IF(NOT MaskSize) THEN BEGIN
            MaskSize = MaskSize + 1
            WIDGET_CONTROL,MaskBid,SET_VALUE=MaskSize
         END
         Mode = WIDGET_INFO(ModeBid,/DROPLIST_SELECT)
         new = 0
         WIDGET_CONTROL,event.top,/DESTROY
      END
   END
END


;----------------------------------------------------------
; PURPOSE:
; Collect parameters for the detail dialog window.
;
; CALLING SEQUENCE:
;
; INPUTS:
;  Parent == Widget id of the parent
;  State == structure containing the present state of the
;           detail dialog window.  Has the following tags:
;           {new:new,Mode:mode,Mask:Masksize,Unit:Unit}
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  Structure containing the following tags:
;   NEW: 0 if parameters should updated, 1 if parameters are same
;   Mode: 0 for Continuous, 1 for Click
;   Mask: Mask size for detail window
;   Unit: 0 for compressed, 1 for uncompressed
;
; SIDE EFFECTS:
;   Sets XV_DETAIL_DIALOG common block variables
;
; COMMON BLOCKS:
;  XV_DETAIL_DIALOG
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_DETAIL_DIALOG, Parent, State
   COMMON XV_DETAIL_DIALOG, MaskBid, ModeBid, UnitBid, New, OK, Cancel, MaskSize, Mode, Unit

   Base = WIDGET_BASE(GROUP_LEADER=parent, TITLE='Detail Parameters', $
                      /COLUMN, /MODAL)
   MaskBid = CW_FIELD(Base, VALUE=STRING(state.Mask), $
                      /INTEGER, XSIZE=3, TITLE='Mask Size')
   ModeBid = WIDGET_DROPLIST(Base, VALUE=["Continuous","Click"],TITLE='Mode')
   UnitBid =  WIDGET_DROPLIST(Base, VALUE=["Compressed","UnCompressed"], TITLE='Units')
   OK = WIDGET_BUTTON(Base, VALUE='OK')
   CANCEL = WIDGET_BUTTON(Base, VALUE='Cancel')

   new = 0
   Mode = state.mode
   MaskSize = state.mask
   Unit =  state.unit
   WIDGET_CONTROL,ModeBid,SET_DROPLIST_SELECT=State.mode
   WIDGET_CONTROL,UnitBid,SET_DROPLIST_SELECT=State.unit
   WIDGET_CONTROL,Base,/REALIZE
   XMANAGER,"XV_DETAIL_DIALOG",Base

   return,{new:new,Mode:mode,Mask:Masksize,Unit:Unit}
END



;----------------------------------------------------------
; PURPOSE:
;  Event handler for the zoomer dialog window.
;
; CALLING SEQUENCE:
;  Called only via the IDL event dispatcher.
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Sets common block varialbles
;
; COMMON BLOCKS:
;  XV_ZOOMER_DIALOG
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_ZOOMER_DIALOG_EVENT, event
   COMMON XV_ZOOMER_DIALOG, ZoomBid, ModeBid, New, OK, Cancel, Factor, Mode
   FactorVals = [2,3,4,5,6,7,8,9,10,16]

   CASE event.id OF
      ZoomBid: BEGIN
         FactSel = WIDGET_INFO(ZoomBid,/DROPLIST_SELECT)
         Factor = FactorVals(FactSel)
      END
      MODEBid: BEGIN
         Mode = WIDGET_INFO(ModeBid,/DROPLIST_SELECT)
      END
      OK: BEGIN
         new = 1
         WIDGET_CONTROL,event.top,/DESTROY
      END
      Cancel: BEGIN
         new = 0
         WIDGET_CONTROL,event.top,/DESTROY
      END
   END
END



;----------------------------------------------------------
; PURPOSE:
;
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_ZOOMER_DIALOG, Parent, State
   COMMON XV_ZOOMER_DIALOG, ZoomBid, ModeBid, New, OK, Cancel, Factor, Mode
   FactorVals = [2,3,4,5,6,7,8,9,10,16]

   Base = WIDGET_BASE(GROUP_LEADER=parent, TITLE='Zoomer Parameters', $
                      /COLUMN, /MODAL)
   ZoomBid = WIDGET_DROPLIST(Base,VALUE=['2','3','4','5','6','7','8','9','10','16'],$
                             TITLE='Factor')
   ModeBid = WIDGET_DROPLIST(Base, VALUE=["Continuous","Click"],TITLE='Mode')
   OK = WIDGET_BUTTON(Base, VALUE='OK')
   CANCEL = WIDGET_BUTTON(Base, VALUE='Cancel')

   new = 0
   Mode = state.mode
   Factor = state.factor
   junk = WHERE(state.factor eq factorVals)
   WIDGET_CONTROL,ZoomBid,SET_DROPLIST_SELECT=junk(0)
   WIDGET_CONTROL,ModeBid,SET_DROPLIST_SELECT=State.mode
   WIDGET_CONTROL,Base,/REALIZE
   XMANAGER,"XV_ZOOMER_DIALOG",Base
   return,{new:new,Mode:mode,Factor:Factor}
END

;+++++++++++++++++++++++++++++++++++++++++
; NAME:
;  XV_SLOPE_EVENT
;
; PURPOSE:
;  EVENT HANDLER FOR XV_GET_SLOPE_PARAMS
;
; CALLING SEQUENCE:
;  Called only via IDL event dispatcher
;
; INPUTS:
;  None
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  NONE
;
; COMMON BLOCKS:
;  XV_SLOPE_PARAMS
;
; MODIFICATION HISTORY:
;       Written by:     Kenny Hunt 7/8/97
;------------------------------------------
PRO XV_SLOPE_EVENT, Event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_SLOPE_PARAMS, Wids, Orientation, Low, High

   CASE event.id OF
      Wids.Optimal:BEGIN
         WIDGET_CONTROL,Wids.HV, GET_VALUE=Orientation
         slopeinfo = COMPUTE_BEST_SLOPE(Image,Vertical=Orientation)
         WIDGET_CONTROL,Wids.Low,SET_VALUE=0
         WIDGET_CONTROL,Wids.High,SET_VALUE=slopeinfo.slope
      END
      Wids.OK: BEGIN
         WIDGET_CONTROL, Wids.Low, GET_VALUE=low
         WIDGET_CONTROL, Wids.High, GET_VALUE=high
         WIDGET_CONTROL, Wids.HV, GET_VALUE=orientation
         WIDGET_CONTROL, event.top, /DESTROY
         LastImage = Image
         WIDGET_CONTROL, /HOURGLASS, Wids.Parent
         XV_SUB_SLOPE, Image, Low, High, VERTICAL=ORIENTATION
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL, HOURGLASS=1, Wids.Parent
      END
      Wids.CANCEL: BEGIN
         WIDGET_CONTROL, event.top, /DESTROY
      END
      ELSE: return
   END
END


;----------------------------------------------------------
; PURPOSE:
;  Collect parameters for the slope subtract routine
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Sets COMMON block variables
;
; COMMON BLOCKS:
;   XV_RECORD_DATA
;   XV_FILE_DATA
;   XV_SLOPE_PARAMS
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_SLOPE_SUB_DIALOG, Parent
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_SLOPE_PARAMS, Wids, Orientation, Low, High

   IF XREGISTERED("XV_SLOPE") THEN RETURN

   ;; Turn off the control widget to go into pseudo-modal model
   WIDGET_CONTROL, Parent, SENSITIVE=0

   Base = WIDGET_BASE(GROUP_LEADER=Parent,/COLUMN,$
                      TITLE="Slope Subtract Parameters")
   HVBid = CW_BGROUP(Base,["Horizontal","Vertical"],$
                     /EXCLUSIVE,FRAME=3, /ROW, SET_VALUE=0)
   bbase = WIDGET_BASE(Base,/ROW,FRAME=3)
   LowBid = CW_FIELD(bBase,VALUE="", /INTEGER, TITLE='Low', XSIZE=3)
   HighBid = CW_FIELD(bBase,VALUE="", /INTEGER, TITLE='High', XSIZE=3)
   OptimalBid = WIDGET_BUTTON(Base,VALUE="Compute Slope")
   OKBid = WIDGET_BUTTON(Base, VALUE="OK")
   CANCELBid = WIDGET_BUTTON(Base, VALUE="CANCEL")
   Wids = { HV:HVBid,$
            Low:LowBid,$
            High:HighBid,$
            Optimal:OptimalBid,$
            OK:OKBid,$
            Parent:Parent,$
            CANCEL:CANCELBid}

   WIDGET_CONTROL,Base,/REALIZE
   XMANAGER,"XV_SLOPE",Base
   ;; Turn the control panel back on
   WIDGET_CONTROL, Parent, SENSITIVE=1
END


;----------------------------------------------------------
; PURPOSE:
;  Collect parameters for the slope subtract routine
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Sets COMMON block variables
;
; COMMON BLOCKS:
;   XV_RECORD_DATA
;   XV_FILE_DATA
;   XV_SLOPE_PARAMS
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_SUB_COSMIC_EVENT, event
   COMMON XV_SUB_COSMIC, Wids, Mode, MaskSize, New
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount

   CASE event.id OF
      Wids.BASE: BEGIN
         print,'sub_cosmic_event: base'
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.ROIBid: BEGIN
         WIDGET_CONTROL, Wids.ROIBid, GET_VALUE=ROI
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.Mask: BEGIN
         WIDGET_CONTROL, Wids.Mask, GET_VALUE=MaskSize
      END
      Wids.MODE: BEGIN
         WIDGET_CONTROL, Wids.Mode, GET_VALUE=Mode
         IF(Mode eq 0) THEN BEGIN
            WIDGET_CONTROL, Wids.RoiBid, MAP=0
         END ELSE WIDGET_CONTROL, Wids.RoiBid, /MAP
      END
      Wids.APPLY: BEGIN
         WIDGET_CONTROL,/HOURGLASS,event.top,SENSITIVE=0
;         XV_SUB_COSMIC_RAY, Image, ROI, Mode, MaskSize, 30
         XV_SUB_COSMIC_RAY, Image, ROI, Mode, MaskSize, 40
         WIDGET_CONTROL,Wids.ROIBid,SET_VALUE=[-1]
         ROI = [-1]
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL,HOURGLASS=0,event.top,/SENSITIVE
      END
      Wids.OK: BEGIN
         WIDGET_CONTROL, Wids.Mode, GET_VALUE=Mode
         WIDGET_CONTROL, Wids.Mask, GET_VALUE=MaskSize
         WIDGET_CONTROL,/HOURGLASS,event.top,SENSITIVE=0
;         XV_SUB_COSMIC_RAY, Image, ROI, Mode, MaskSize, 30
         XV_SUB_COSMIC_RAY, Image, ROI, Mode, MaskSize, 40
         new =  1
         ROI =  [-1]
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL,HOURGLASS=0,event.top,/SENSITIVE
         WIDGET_CONTROL,event.top,/DESTROY
      END
      Wids.CANCEL: BEGIN
         New = 0
         Image = LastImage
         WIDGET_CONTROL, event.top, /DESTROY
      END
      ELSE: return
   ENDCASE
END


;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; NAME:
;       XV_GET_SUB_COSMIC_PARAMS
;
; PURPOSE:
;  GUI TO INPUT PARAMETERS FOR THE XV_SUB_COSMIC ROUTINE
;
; CALLING SEQUENCE:
;  PARAMS = XV_GET_SUB_COSMIC_PARAMS(PARENT_WID, IMAGE)
;
; INPUTS:
;  PARENT WIDGET, IMAGE TO WHICH THE PARAMATERS WILL APPLY
;
; KEYWORD PARAMETERS:
;  NONE
;
; OUTPUTS:
;  A STRUCTURE WITH NAMED ITEMS:
;    New:               0 IF the CANCEL button has been selected, 1 otherwise
;    Mode:              0 for Auto, 1 for Manual, 2 for EXCLUDE
;    Region:    A vector of indices into IMAGE
;    MaskSize: Size of the square mask to apply
;
; COMMON BLOCKS:
;  XV_SUB_COSMIC
;  XV_RECORD_DATA
;  XV_FILE_DATA
;  XV_WIDS
;
; MODIFICATION HISTORY:
;       Written by:     Kenny Hunt 7/8/97
;----------------------------------------------------------
FUNCTION XV_SUB_COSMIC_DIALOG, Parent
   COMMON XV_SUB_COSMIC, Wids, Mode, MaskSize, New
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount

   IF XREGISTERED("XV_SUB_COSMIC") THEN RETURN, {New:0}

   ;; Turn off Parent to go into psuedo-modal mode
   WIDGET_CONTROL, Parent, GET_UVALUE=PWids, SENSITIVE=0

   Base = WIDGET_BASE(GROUP_LEADER=Parent,/COLUMN,$
                      TITLE="Cosmic Ray Subtract Parameters",$
                      EVENT_PRO='SUB_COSMIC_EVENT')

   MaskBid = CW_FIELD(Base,VALUE=7, /INTEGER, $
                      XSIZE=3, FRAME=3,/ALL_EVENTS,TITLE="Mask Size")

   Dummy = WIDGET_BASE(Base,FRAME=3,/COLUMN)
   ModeBid = CW_BGROUP(Dummy,["Auto","Man","Excl"],$
                       /EXCLUSIVE, SET_VALUE=0, /ROW)

   RoiBid = XV_CW_ROI(Base,FRAME=3)

   ApplyBid = WIDGET_BUTTON(Base,VALUE="APPLY")
   OKBid = WIDGET_BUTTON(Base, VALUE="OK")
   CANCELBid = WIDGET_BUTTON(Base, VALUE="CANCEL")

   ;; Initialize COMMON BLOCK variables
   MaskSize = 7
   Mode = 0
   New = 0

   Wids = { Base:Base,$
            RoiBid:RoiBid,$
            Mode:ModeBid,$
            Mask:MaskBid,$
            Apply:ApplyBid,$
            OK:OKBid,$
            CANCEL:CancelBid}

   WIDGET_CONTROL,Base,/REALIZE
   WIDGET_CONTROL,RoiBid,MAP=0

   XMANAGER,"XV_SUB_COSMIC",Base

   ;; restore sensitivity to parent
   WIDGET_CONTROL,SENSITIVE=1,parent
   ROI = [-1]

   return,new
END


;----------------------------------------------------------
; PURPOSE:
;  Event handler for the flat-field dialog
;
; CALLING SEQUENCE:
;  Called only via IDLs event dispatcher.
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  XV_RECORD_DATA
;  XV_FILE_DATA
;  XV_FF_DIALOG
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_FF_DIALOG_EVENT, Event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_FF_DIALOG, New, xvFF, IBias, Shift
   WIDGET_CONTROL,event.top,GET_UVALUE=Wids

   s = size(XVFF)
   IF(S(0) ne 2) THEN FFLoaded = 0 $
   ELSE FFLoaded = 1

   CASE event.id OF
      Wids.CBid: BEGIN
         new = 0
         WIDGET_CONTROL, event.top, /DESTROY
      END
      Wids.OkBid: BEGIN
         if(FFLoaded ne 1) THEN BEGIN
            junk = DIALOG_MESSAGE('FLAT-FIELD Image must be selected',/error)
         END ELSE BEGIN
            new = 1
            WIDGET_CONTROL,Wids.Ibid,GET_VALUE=Ibias
            WIDGET_CONTROL,Wids.ShftBid,GET_VALUE=Shift
            WIDGET_CONTROL,event.top,/destroy
         END
      END
      Wids.Compute: BEGIN
         junk = COMPUTE_BEST_SLOPE(Image)
         WIDGET_CONTROL,Wids.IBid,SET_VALUE=FIX(junk.a)
      END
      Wids.LBid: BEGIN
         iFilename = dialog_pickfile(Filter='*.dat')
         IF(ifilename ne '') THEN BEGIN
            FF = 0
            restore,ifilename
            ;; FF should be the only variable in the restored file
            s = size(Ff)
            IF(S(0) ne 2) THEN BEGIN
               junk = dialog_message('No Flat-field variable in file',/error)
            END ELSE BEGIN
               XVFF = ff
               WIDGET_CONTROL,Wids.FFWin,GET_VALUE=wnum & wSET, wnum
               TVSCL,XVFF
            END
         END
      END
      WIds.FFWin: BEGIN
         IF(FFloaded eq 1) THEN BEGIN
            WIDGET_CONTROL,Wids.FFWin,GET_VALUE=wnum & wSET, wnum
            TVSCL,XVFF
         END
      END
      ELSE: x = 1
   END
END


;----------------------------------------------------------
; PURPOSE:
;  collect the parameters for the flat field function
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  XV_FF_DIALOG
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_FLAT_FIELD_DIALOG, Parent
   COMMON XV_FF_DIALOG, New, xvFF, IBias, Shift

   Shift = 0
   IBias = 0
   XvFF = 0
   New = 0
   IF XREGISTERED("SUB_COSMIC") THEN RETURN, {New:0, FF:0, IBias:0, Shift:0}

   Base = WIDGET_BASE(GROUP_LEADER=Parent,TITLE='Flat Field Parameters',/COLUMN,/MODAL)
   FFWin = WIDGET_DRAW(Base,XSIZE=256,YSIZE=256,/EXPOSE_EVENTS)
   Lbid = WIDGET_BUTTON(Base,VALUE='Load Flat Field')
   Ibid = CW_FIELD(Base,VALUE='0',/INTEGER,TITLE='IBias',XSIZE=3)
   ShftBid = CW_FIELD(Base,VALUE='0',/INTEGER,TITLE='Shift',XSIZE=3)
   ComputeBid = WIDGET_BUTTON(Base,VALUE='Compute Bias')
   OkBid = WIDGET_BUTTON(BAse,VALUE='OK')
   Cbid = WIDGET_BUTTON(Base,VALUE='Cancel')

   Wids = { LBid:Lbid,$
            Ibid:Ibid,$
            CBid:Cbid,$
            Base:Base,$
            Compute:ComputeBid,$
            OkBid:OkBid,$
            FFWin:FFWin,$
            ShftBid:ShftBid}

   WIDGET_CONTROL,Base,/REALIZE,SET_UVALUE=Wids
   XMANAGER,"XV_FF_DIALOG",Base
   return, {New:New,Ibias:Ibias,FF:XVFF,Shift:Shift}
END



;----------------------------------------------------------
; PURPOSE:
;  Event handler for the scale intensity dialog.
;
; CALLING SEQUENCE:
;  Called only via the IDL event dispatcher.
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  XV_SCALE_I
;  XV_RECORD_DATA
;  XV_FILE_DATA
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_SCALE_I_EVENT, event
   COMMON XV_SCALE_I, New, Offset, ScaleFactor, OriginalImage
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   WIDGET_CONTROL, event.top, GET_UVALUE=Wids

   CASE event.id OF
      Wids.ScaleBid: BEGIN
         WIDGET_CONTROL,Wids.ScaleBid,GET_VALUE=ScaleFactor
         WIDGET_CONTROL,Wids.OffsetBid,GET_VALUE=Offset
         Image =  OriginalImage
         XV_SCALE_INTENSITY, Image, Offset, ScaleFactor
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.CancelBid: BEGIN
         Image =  OriginalImage
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL,event.top,/DESTROY
      END
      Wids.OKBid: BEGIN
         new = 1
         Image = OriginalImage
         WIDGET_CONTROL,Wids.ScaleBid,GET_VALUE=ScaleFactor
         WIDGET_CONTROL,Wids.OffsetBid,GET_VALUE=Offset
         XV_SCALE_INTENSITY, Image, Offset, ScaleFactor
         WIDGET_CONTROL,event.top,/DESTROY
         XV_UPDATE_VIEW_WINDOW
      END
   END
END



;----------------------------------------------------------
; PURPOSE:
;  Collects parameters for the XV_SCALE_INTENSITY filter
;
; CALLING SEQUENCE:
;
; INPUTS:
;  Widget ID of the parent
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  returns in integer indicating
;   0:  the image has not changed
;   1:  the image has changed
;
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_SCALE_INTENSITY, Parent
   COMMON XV_SCALE_I, New, Offset, ScaleFactor, OriginalImage
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   ScaleFactor = 1.0
   Offset = 0
   New = 0
   OriginalImage =  Image
   IF XREGISTERED("XV_SCALE_I") THEN RETURN, New

   Base = WIDGET_BASE(GROUP_LEADER=Parent,TITLE='Scale Intensity',/COLUMN,/MODAL)
   Offsetbid = CW_FIELD(Base,VALUE='0',/INTEGER,TITLE='Offset',XSIZE=4)
   ScaleBid = CW_FSLIDER(Base,VALUE='1.0',FORMAT='(G5.3)',TITLE='Scale Factor',XSIZE=300,$
                         MINIMUM=.1, MAXIMUM=10.0, /DRAG, /EDIT)

   OkBid = WIDGET_BUTTON(BAse,VALUE='OK')
   CancelBid = WIDGET_BUTTON(Base,VALUE='Cancel')

   Wids = { Base:Base,$
            OffsetBid:OffsetBid,$
            ScaleBid:ScaleBid,$
            OkBid:OkBid,$
            CancelBid:CancelBid}

   WIDGET_CONTROL,Base,/REALIZE,SET_UVALUE=Wids
   XMANAGER,"XV_SCALE_I",Base
   return, New
END


;----------------------------------------------------------
; PURPOSE:
;  Event handler for the fill_zeros dialog
;
; CALLING SEQUENCE:
;  Called only via the IDL event dispatcher.
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_FILL_ZEROS_EVENT, event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILL_Z, New, Level, OriginalImage
   WIDGET_CONTROL, event.top, GET_UVALUE=Wids

   CASE event.id OF
      Wids.CancelBid: BEGIN
         Image = OriginalImage
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL, event.top, /DESTROY
      END
      Wids.APPLYBid: BEGIN
         WIDGET_CONTROL, Wids.Base, /HOURGLASS, SENSITIVE=0
         Image =  OriginalImage
         XV_FILL_ZEROS, Image, Level
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL, Wids.Base, HOURGLASS=0, /SENSITIVE
         new = 1
      END
      Wids.OKBid: BEGIN
         WIDGET_CONTROL,event.top,/DESTROY
      END
      Wids.LevelBid: BEGIN
         WIDGET_CONTROL,Wids.LevelBid,GET_VALUE=Level
      END
   END
END


;----------------------------------------------------------
; PURPOSE:
;  Collects parameters for the fill zeros filter.
;
; CALLING SEQUENCE:
;
; INPUTS:
;  Parent == widget id of the parent
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  integer flag indicating:
;   0) the image has not changed
;   1) the image has changed
;
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_FILL_ZEROS_DIALOG, Parent
   COMMON XV_FILL_Z, New, Level, OriginalImage
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit

   IF XREGISTERED("XV_FILL_ZEROS") THEN RETURN, 0
   New =  0
   Level = 16
   OriginalImage =  Image

   ;; Turn off Parent to go into psuedo-modal mode
   WIDGET_CONTROL, Parent, GET_UVALUE=PWids, SENSITIVE=0

   Base = WIDGET_BASE(GROUP_LEADER=Parent,TITLE='Fill Zeros',/COLUMN,/MODAL)
   LevelBid = WIDGET_SLIDER(Base, $
                            SCR_XSIZE=256, MAXIMUM=255,VALUE=Level,TITLE='Level')

   ApplyBid = WIDGET_BUTTON(BAse, VALUE="Apply")
   OkBid = WIDGET_BUTTON(BAse,VALUE='OK')
   Cbid = WIDGET_BUTTON(Base,VALUE='Cancel')

   Wids = { Base:Base,$
            LevelBid:LevelBid,$
            ApplyBid:ApplyBid,$
            OkBid:OkBid,$
            CancelBid:CBid}

   WIDGET_CONTROL,Base,/REALIZE,SET_UVALUE=Wids
   WIDGET_CONTROL,LevelBid,TIMER=0.2
   XMANAGER,"XV_FILL_ZEROS",Base

   WIDGET_CONTROL,Parent,/SENSITIVE
   return, New
END

;----------------------------------------------------------
; PURPOSE:
;  Event handler for the fill_bytes filter
;
; CALLING SEQUENCE:
;  Called only via the IDL event dispatcher
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  XV_FILL_B
;  XV_RECORD_DATA
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------

PRO XV_FILL_BYTES_EVENT, event
   COMMON XV_FILL_B, New, MinLevel, MaxLevel, OriginalImage
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit

   WIDGET_CONTROL, event.top, GET_UVALUE=Wids

   CASE event.id OF
      Wids.CancelBid: BEGIN
         new = 0
         Image =  OriginalImage
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL,event.top,/DESTROY
      END
      Wids.OKBid: BEGIN
         new = 1
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL,event.top,/DESTROY
      END
      Wids.MinBid: BEGIN
         WIDGET_CONTROL,Wids.MinBid,GET_VALUE=MinLevel
         Image =  OriginalImage
         junk = WHERE(Image lt MinLevel, count)
         IF(count GT 0) THEN Image(junk) =  MinLevel
         junk = WHERE(Image GT MaxLevel, count)
         IF(count GT 0) THEN Image(junk) =  MaxLevel
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.MaxBid: BEGIN
         WIDGET_CONTROL,Wids.MaxBid,GET_VALUE=MaxLevel
         Image = OriginalImage
         junk = WHERE(Image lt MinLevel, count)
         IF(count GT 0) THEN Image(junk) =  MinLevel
         junk = WHERE(Image GT MaxLevel, count)
         IF(count GT 0) THEN Image(junk) =  MaxLevel
         XV_UPDATE_VIEW_WINDOW
      END
   END
END

;----------------------------------------------------------
; PURPOSE:
;  Collect the parameters for the xv_fill_bytes filter
;
; CALLING SEQUENCE:
;
; INPUTS:
;  Parent == widget id of the parent
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  XV_FILL_B
;  XV_RECORD_DATA
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_FILL_BYTES_DIALOG, Parent
   COMMON XV_FILL_B, New, MinLevel, MaxLevel, OriginalImage
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit

   IF XREGISTERED("XV_FILL_BYTES") THEN RETURN, 0
   OriginalImage =  Image
   New = 0
   MinLevel =  0
   FillValue =  0
   MaxLevel = 255


   Base = WIDGET_BASE(GROUP_LEADER=Parent,TITLE='Fill Bytes',/COLUMN,/MODAL)
   SliderBase = WIDGET_BASE(Base,/COLUMN,FRAME=3)
   MinBid = WIDGET_SLIDER(SliderBase,/DRAG, VALUE=MinLevel, $
                          SCR_XSIZE=256, MAXIMUM=255,TITLE='Min')

   MaxBid = WIDGET_SLIDER(SliderBase,/DRAG, VALUE=MaxLevel, $
                          SCR_XSIZE=256, MAXIMUM=255,TITLE='Max')

   OkBid = WIDGET_BUTTON(BAse,VALUE='OK')
   Cbid = WIDGET_BUTTON(Base,VALUE='Cancel')

   Wids = { Base:Base,$
            MinBid:MinBid,$
            MaxBid:MaxBid,$
            OkBid:OkBid,$
            CancelBid:CBid}

   WIDGET_CONTROL,Base,/REALIZE,SET_UVALUE=Wids
   WIDGET_CONTROL,MaxBid,TIMER=0.25
   XMANAGER,"XV_FILL_BYTES",Base
   return, New
END



;----------------------------------------------------------
; PURPOSE:
;  Event handler for the blacktape_dialog window
;
; CALLING SEQUENCE:
;  Called only via the IDL event dispatcher
;
; INPUTS:
;
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  XV_BLACKTAPE
;  XV_RECORD_DATA
;  XV_FILE_DATA
;  XV_WIDS
;
; MODIFICATION HISTORY:
;----------------------------------------------------------
PRO XV_BLACKTAPE_EVENT, event
   COMMON XV_BLACKTAPE, FillValue, New
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount

   WIDGET_CONTROL, event.top, GET_UVALUE=Wids

   CASE event.id OF
      Wids.ROIBID: BEGIN
         WIDGET_CONTROL,Wids.ROIBID,GET_VALUE=ROI
         WIDGET_CONTROL, Wids.FILL, GET_VALUE=FillValue
         XV_UPDATE_VIEW_WINDOW,FillValue
      END
      Wids.FILL: BEGIN
         WIDGET_CONTROL, Wids.FILL, GET_VALUE=FillValue
         XV_UPDATE_VIEW_WINDOW, FillValue
      END
      Wids.APPLY: BEGIN
         New =  1
         XV_BLACKTAPE, Image, ROI, FillValue
         ROI =  [-1]
         WIDGET_CONTROL, Wids.ROIBID, SET_VALUE=[-1]
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.OK: BEGIN
         WIDGET_CONTROL, Wids.FILL, GET_VALUE=FillValue
         junk = WHERE(ROI lt 0, NotValid)
         IF(NotValid gt 0) THEN New = 0 ELSE New = 1
         XV_BLACKTAPE,image,roi,fillvalue
         WIDGET_CONTROL,event.top,/DESTROY
      END
      Wids.CANCEL: BEGIN
         ROI = [-1]
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL, event.top, /DESTROY
      END
      ELSE: Return
   ENDCASE
END


;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; NAME:
;
;
; PURPOSE:
;  Collects parameters for the blacktape filter
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; COMMON BLOCKS:
;   XV_BLACKTAPE
;   XV_RECORD_DATA
;   XV_FILE_DATA
;   XV_WIDS
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_BLACKTAPE_DIALOG, Parent
   COMMON XV_BLACKTAPE, FillValue, New
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount

   New =  0
   IF XREGISTERED("XV_BLACKTAPE") THEN RETURN, New
   fillvalue = 0

   ;; Turn off Parent to go into psuedo-modal mode
   WIDGET_CONTROL, Parent, GET_UVALUE=PWids, SENSITIVE=0

   Base = WIDGET_BASE(GROUP_LEADER=Parent,/COLUMN,TITLE="BlackTape")

   ROIBid = XV_CW_ROI(Base,FRAME=3)

   FillBid = WIDGET_SLIDER(Base,/DRAG, $
                           SCR_XSIZE=256, MAXIMUM=255,VALUE=16,TITLE='Fill Value')

   ApplyBid = WIDGET_BUTTON(Base,VALUE="APPLY")
   OKBid = WIDGET_BUTTON(Base, VALUE="OK")
   CANCELBid = WIDGET_BUTTON(Base, VALUE="CANCEL")

   Wids = { Base:Base,$
            Fill:FillBid,$
            ROIBID:ROIBid,$
            APPLY:APPLYBid,$
            OK:OKBid,$
            CANCEL:CancelBid}

   WIDGET_CONTROL,Base,/REALIZE,SET_UVALUE=Wids

   XMANAGER,"XV_BLACKTAPE",Base

   ;; restore sensitivity to parent
   WIDGET_CONTROL,SENSITIVE=1,parent
   RETURN, New
END



;----------------------------------------------------------
; PURPOSE:
;  Event handler for the solar event dialog.
;
; CALLING SEQUENCE:
;  Not called directly.  Invoked by IDL event handler.
;
; INPUTS:
;  Mode == 0 for FILL mode.  Sets values between MinAngle
;                            and MaxAngle to the FillValue.
;          1 for MIN mode.   Sets values between MinAngle
;                            and MaxAngle to the Minimum
;                            value of Image(i,j) and FillValue.
;          2 for MAX mode.   Sets values between MinAngle
;                            and MaxAngle to the Maximum
;                            value of Image(i,j) and FillValue.
;          3 for CUT mode    Sets values OUTSIDE of MinAngle
;                            and MaxAngle to the FillValue.
;  MinAngle == Minimum solar zenith angle in degrees
;  MaxAngle == Maximum solar zenith angle in degrees
;  FillValue == used in different ways depending on the mode as
;               described above.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_SOLAR_ZENITH_EVENT, event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_BLACKTAPE_SZ, Mode, MinAngle, MaxAngle, FillValue, New
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons

   WIDGET_CONTROL, event.top, GET_UVALUE=Wids

   CASE event.id OF
      Wids.ModeBid: BEGIN
         IF(event.SELECT EQ 0) THEN RETURN
         WIDGET_CONTROL, Wids.ModeBid, GET_VALUE=Mode
         XV_GET_SOLAR_ZENITH_PIXELS, Mode, MinAngle, MaxAngle, FillValue
         XV_UPDATE_VIEW_WINDOW,FillValue
      END
      Wids.MinAngBid: BEGIN
         WIDGET_CONTROL, Wids.MinAngBid, GET_VALUE=MinAngle
         XV_GET_SOLAR_ZENITH_PIXELS, Mode, MinAngle,MaxAngle,FillValue
         XV_UPDATE_VIEW_WINDOW,FillValue
      END
      Wids.MaxAngBid: BEGIN
         WIDGET_CONTROL, Wids.MaxAngBid, GET_VALUE=MaxAngle
         XV_GET_SOLAR_ZENITH_PIXELS, Mode, MinAngle,MaxAngle,FillValue
         XV_UPDATE_VIEW_WINDOW,FillValue
      END
      Wids.FILL: BEGIN
         WIDGET_CONTROL, Wids.FILL, GET_VALUE=FillValue
         XV_GET_SOLAR_ZENITH_PIXELS,Mode,MinAngle,MaxAngle,FillValue
         XV_UPDATE_VIEW_WINDOW,FillValue
      END
      Wids.APPLY: BEGIN
         new =  1
         XV_BLACKTAPE, Image, ROI, FillValue
      END
      Wids.OK: BEGIN
         XV_BLACKTAPE, Image, ROI, FillValue
         new =  1
         ROI = [-1]
         WIDGET_CONTROL,event.top,/DESTROY
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.CANCEL: BEGIN
         ROI = [-1]
         WIDGET_CONTROL, event.top, /DESTROY
         XV_UPDATE_VIEW_WINDOW
      END
      ELSE: Return
   ENDCASE
END


;----------------------------------------------------------
; PURPOSE:
;  Provides an interface to the filters that depend on
;  the solar zenith angles.
;
; CALLING SEQUENCE:
;
;
; INPUTS:
;  Widget ID of the parent
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_SOLAR_ZENITH_DIALOG, Parent
   COMMON XV_BLACKTAPE_SZ, Mode, MinAngle, MaxAngle, FillValue, New
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount

   New = 0
   IF XREGISTERED("XV_SOLAR_ZENITH") THEN RETURN, New
   Mode =  0
   fillvalue = 0
   MaxAngle = 180
   MinAngle = 90

   ;; Turn off Parent to go into psuedo-modal mode
   WIDGET_CONTROL, Parent, GET_UVALUE=PWids, SENSITIVE=0, /HOURGLASS
   XV_ALT_SZA
   WIDGET_CONTROL, Parent, HOURGLASS=0

   Base = WIDGET_BASE(GROUP_LEADER=Parent,/COLUMN,TITLE="BlackTape Solar Zenith")

   MinAngBid =  WIDGET_SLIDER(Base,/DRAG,$
                              SCR_XSIZE=256,MAXIMUM=180,VALUE=minangle,TITLE='MinAngle')

   MaxAngBid =  WIDGET_SLIDER(Base,/DRAG,$
                              SCR_XSIZE=256,MAXIMUM=180,VALUE=maxangle,TITLE='MaxAngle')

   FillFrame =  WIDGET_BASE(Base,/FRAME,/COLUMN)
   FillBid = WIDGET_SLIDER(FillFrame,/DRAG, $
                           SCR_XSIZE=256, MAXIMUM=255,VALUE=fillvalue,TITLE='Pixel Value')
   ModeBid =  CW_BGROUP(FillFrame,["Fill","Min","Max","Cut"],/EXCLUSIVE,/FRAME,$
                        Label_Top= "Mode",SET_VALUE=0,/ROW)

   ApplyBid =  WIDGET_BUTTON(BASE,VALUE="APPLY")
   OKBid = WIDGET_BUTTON(Base, VALUE="OK")
   CANCELBid = WIDGET_BUTTON(Base, VALUE="CANCEL")

   Wids = { Base:Base,$
            Apply:ApplyBid,$
            Fill:FillBid,$
            ModeBid:ModeBid,$
            MinAngBid:MinAngBid,$
            MaxAngBid:MaxAngBid,$
            OK:OKBid,$
            CANCEL:CancelBid}

   WIDGET_CONTROL,Base,/REALIZE,SET_UVALUE=Wids

   WIDGET_CONTROL,MinAngBid,TIMER=0.2
   XMANAGER,"XV_SOLAR_ZENITH",Base

   ;; restore sensitivity to parent
   WIDGET_CONTROL,SENSITIVE=1,parent
   RETURN, New
END






;----------------------------------------------------------
; Procedure name: XV_SMOOTH
; PURPOSE:
;  Applies a smoothing filter to an image
;
; CALLING SEQUENCE:
;  im = DIST(256,256)
;  XV_SMOOTH,im
;
; INPUTS:
;  IMAGE == A 2D array of bytes
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Smooths the Image
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
Pro XV_Smooth, Image
   Image = UNPACK(image)
   sz = SIZE(image)
   m = sz(1)
   n = sz(2)
   IM2 = INTARR(M+2,N+2)
   IM2(1:M,1:N) = Image
   IM2(0,1:N) = IM2(1,1:N)
   IM2(M+1,1:N) = IM2(M,1:N)
   IM2(0:M+1,0) = IM2(0:M+1,1)
   IM2(0:M+1,N+1) = IM2(0:M+1,N)
   New_image = .4 * Image                         $
    + .1 * (IM2(0:M-1,1:N)+IM2(2:M+1,1:N)+IM2(1:M,0:N-1)+IM2(1:M,2:N+1)) $
    +.05*(IM2(0:M-1,0:N-1)+IM2(2:M+1,0:N-1)+IM2(0:M-1,2:N+1)+IM2(2:M+1,2:N+1))

   Image =  PACK(round(New_image))
End


;----------------------------------------------------------
; Procedure name: XV_REMOVE_WEAVE
; PURPOSE:
;  Corrects for the weave pattern in an image
;
; CALLING SEQUENCE:
;  im = DIST(256,256)
;  XV_REMOVE_WEAVE,im
;
; INPUTS:
;  IMAGE == A 2D array of bytes
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Corrects the Image
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
Pro XV_Remove_Weave, Image

   XV_SUB_COSMIC_RAY, Image, [-1], 0, 7, 40

   Image = UNPACK(image)
   sz = SIZE(image)
   cols = sz(1)
   rows = sz(2)

   isum = INTARR(5)
   idelavg = INTARR(5)
   colindex = INDGEN((cols-10)/5)*5 + 5
   FOR row=0,rows-1 DO BEGIN
       FOR i=0,4 DO BEGIN
           c = colindex + i
           isum(i) = TOTAL(Image(c,row))
       ENDFOR
       amean = TOTAL(isum)/5.0
       idelavg = FIX((FLOAT(isum)-amean)/49.0)
       FOR c=0,cols-1 DO BEGIN
           i = c MOD 5
           Image(c,row) = Image(c,row) - idelavg(i)
       ENDFOR
   ENDFOR
   Image =  PACK(Image)
End


;----------------------------------------------------------
; NAME:  XV_SUB_COSMIC_RAY
;
; PURPOSE:
;  Eliminates the effects of heavy particle events on
;  VIS images.
;
; DISCUSSION:
;  The constant threshold level (as opposed to a level based on a local
;  determination of the standard deviation) is used for several reasons.
;  First we are not removing random noise, but in fact are attempting to
;  remove a real signal, that is the charge liberated by the penetrating
;  high energy particle (e.g. cosmic rays, etc.).  Empirical tests of the
;  cosmic rays indicate that they leave a minimum charge in the CCD pixel
;  of around 30 dn (digital number or "counts").  Second, empirical tests of
;  the standard deviations of the brightest portions of the VIS Earth
;  Camera images where no cosmic rays have penetrated indicate standard
;  deviations of between 8 and 15 dn.  Thus the constant threshold level
;  of 30 corresponds to 2 to 3 or more standard deviations above the mean.
;
;  The setting of a constant threshold level becomes particularly important
;  as we begin entry into the radiation belts.  The increased number of high
;  energy particles would lead to an increase in the number of cases in
;  which the calculation of the local standard deviation is in error (i.e.
;  considerably larger due to neighboring penetrating particle events).
;  Consequently, these events would not be removed under a locally varying
;  threshold condition.  However, with apriori knowledge of the variation of
;  the underlying atmospheric measurement helping to determine a constant
;  threshold, these events can be removed reliably.
;
;  As for a written description of the algorithm, for each pixel the median
;  is determined for the 7 x 7 pixel block centered on that pixel (assuming
;  a mask size of 7).  A median instead of average is used in order to
;  eliminate the adverse impact of the cosmic ray outliers.  Pixels that are
;  more than the threshold above their medians are replaced with their
;  median values. From the above discussion we see that these pixels are
;  2 to 3 or more standard deviations higher than the median value
;  for their 7 x 7 pixel block.  Because the penetrating particles often
;  impact neighboring pixels but to a lesser intensity, these pixels are
;  also replaced with their median values.
;
; CALLING SEQUENCE:
;  im = DIST(256,256)
;  XV_SUB_COSMIC_RAY, IM, [-1], 0, 7, 40
;
; INPUTS:
;  IMAGE == A 2D array of bytes
;  RegionPts == a specified region of interest (indices into the image).
;  Mode == one of 0,1,2.
;          Mode 0:  Automatically performs the routine on entire image.
;          Mode 1:  Do only specified region
;          Mode 2:  Do everything except specified region
;  MaskSize == a scalar designating the NxN subregion
;  Threshold == a scalar designating the cutoff value
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_SUB_COSMIC_RAY, Image, RegionPts, Mode, MaskSize, ThreshHold
   Image = UNPACK(Image)
   NewImage = Image
   Dx = FIX(MaskSize/2)
   ;;;;;;;;;;;;;;;;;;;;;;;
   ;;; Handle AUTO mode
   ;;;;;;;;;;;;;;;;;;;;;;;
   IF(mode eq 0) THEN BEGIN
      Med =  median(image,masksize)

      FOR i=0,dx-1 DO BEGIN
         Med(i,*) = median(reform(image(i,*)),masksize)
         Med(255-i,*) = median(reform(image(255-i,*)),masksize)
         Med(*,i) =  median(image(*,i),masksize)
         Med(*,255-i) = median(image(*,255-i),masksize)
      END

      junk = where((image-med) GT threshHold,count)
      IF(count GT 0) THEN BEGIN
         junk = [junk-257, junk-256, junk-255, $
                 junk-1, junk, junk+1, $
                 junk+255, junk+256, junk+257]
         Image(junk) =  Med(junk)
         Image = PACK(image)
      END
      RETURN
   END

   ;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Handle modes 1 and 2
   ;;;;;;;;;;;;;;;;;;;;;;;;
   IF(mode eq 2) THEN BEGIN
      x = LINDGEN(256,256)
      x(RegionPts) = -1
      RegionPts = WHERE(x ge 0)
   END

   Check = WHERE(RegionPts lt 0, NotValid)
   IF(NotValid gt 0) THEN return

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Set up Median array
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   Med =  median(image,masksize)
   FOR i=0,dx-1 DO BEGIN
      Med(i,*) = median(reform(image(i,*)),masksize)
      Med(255-i,*) = median(reform(image(255-i,*)),masksize)
      Med(*,i) =  median(image(*,i),masksize)
      Med(*,255-i) = median(image(*,255-i),masksize)
   END

   junk = where((image-med) GT threshHold,count)
   IF(count GT 0) THEN BEGIN
      junk = intersect(RegionPts, junk)
      IF(N_ELEMENTS(junk) GT 0) THEN BEGIN
         junk = [junk-257, junk-256, junk-255, $
                 junk-1, junk, junk+1, $
                 junk+255, junk+256, junk+257]
         Image(junk) =  Med(junk)
         Image = PACK(image)
      END ELSE Image=PACK(image)
      RETURN
   END

   Image =  PACK(image)
END


;----------------------------------------------------------
; PURPOSE:
;  Compensates for the drift of the CCD bias in a
;  given scan line.
;
; CALLING SEQUENCE:
;  im = DIST(256,256)
;  XV_SUB_SLOPE, Im, 0, 10
;
; INPUTS:
;  IMAGE == A 2D array of bytes
;  Low   == The average value at the low end of the image.
;  High  == The average value at the high end of the image.
;
; KEYWORD PARAMETERS:
;  VERTICAL == eliminate a vertical slope if set otherwise
;              eliminate a horizontal slope.
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_SUB_SLOPE, Image, Low, High, VERTICAL = vertical
   Image = UNPACK(Image)
   newImage = FLOAT(Image)
   seed = 100323

   perturbedImage = Image + (randomu(seed,256,256) - 0.5)
   factor = (high-low) / 255.0
   percentages = (FINDGEN(256) * factor) + low

   IF(KEYWORD_SET(VERTICAL)) THEN BEGIN ;VERTICAL SLOPE SUBTRACT
      FOR i = 0,255 DO BEGIN
         newImage(i,*) = perturbedImage(i,*) - percentages
      END
   END ELSE BEGIN               ;HORIZONTAL SLOPE SUBTRACT BY DEFAULT
      FOR i = 0,255 DO BEGIN
         newImage(*,i) = perturbedImage(*,i) - percentages
      END
   END

   Image = PACK(newImage)
END


;----------------------------------------------------------
; PURPOSE:
;  Corrects for features of the CCD
;
; CALLING SEQUENCE:
;  Im = DIST(256,256)
;  XV_FLAT_FIELD, Im, FlatField, IBias, ShifVal
;
; INPUTS:
;  IMAGE == A 2D array of bytes
;  FlatField
;  IBias
;  ShiftVal
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_FLAT_FIELD, Image, FlatField, IBias, ShiftVal
   ;; IF shiftval is outside [0..40] then probably corrupted data
   IF(ShiftVal gt 40 OR ShiftVal lt 0) THEN RETURN

   ShiftVal = ShiftVal/2
   Image = UNPACK(Image)

   Signal = Image - IBias
   ChangeIt = WHERE(Signal gt 0, Count)

   IF(Count gt 0) THEN BEGIN
      Image(ChangeIt) = (Float(Signal) / FlatField)(ChangeIt)
      Image(ChangeIt) = Image(ChangeIt) + (.5 + ibias)
   END

   ChangeIt = WHERE(Signal lt 0, Count)
   IF(Count gt 0) THEN $
    Image(ChangeIt) = 0

   Image = PACK(Image)
END


;----------------------------------------------------------
; PURPOSE:
;  Contrast stretching
;
; CALLING SEQUENCE:
;  Im = DIST(256,256)
;  XV_SCALE_INTENSITY, Im, 30, 3.4
;
; INPUTS:
;  IMAGE == A 2D array of bytes
;  Offset == every pixel below this threshold will be set to
;            zero.
;  ScaleFactor == After thresholding, all pixels will be
;                 multiplied by this factor and truncated
;                 at 255.
;
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_SCALE_INTENSITY, Image, Offset, ScaleFactor
   newImage = UNPACK(Image)
   newImage =  newImage - OffSet

   negatives =  where(newImage LT 0,count)
   IF(count GT 0) THEN newIMage(negatives) =  0
   newImage =  FIX(newImage * ScaleFactor)
   Image = PACK(newImage)
END



;----------------------------------------------------------
; PURPOSE:
;
;
; CALLING SEQUENCE:
;  Im = BYTSCL(256,256)
;  XV_FILL_ZEROS, Im, 30
;
; INPUTS:
;   Im == Image
;   Level == a threshold level
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_FILL_ZEROS, Image, Level
   zeros = WHERE(Image le Level, Count)
   IF(COUNT gt 0) THEN BEGIN
      XV_UNPACK_WHERE,zeros,rows,cols
      for index=0L,LONG(N_ELEMENTS(zeros)-1) DO BEGIN
         yi = rows(index)
         xi = cols(index)
         IF(xi ge 1 AND xi le 253 AND yi ge 1 AND yi le 253) THEN BEGIN
            IF(Image(xi,yi+1) lt Level) THEN BEGIN
               Image(xi,yi) = (2*Image(xi,yi-1) + Image(xi,yi+2) + 1) / 3
            END ELSE Image(xi,yi) = (Image(xi,yi-1) + Image(xi,yi+1) + 1) / 2
         END
      END
   END
END


;----------------------------------------------------------
; PURPOSE:
;
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_FILL_ZEROS_TEST, Image, Level
   zeros = WHERE(Image le Level, Count)
   IF(COUNT gt 0) THEN BEGIN
      XV_UNPACK_WHERE,zeros,rows,cols
      Legit =  WHERE(rows GE 1 AND rows LE 253 AND cols GE 1 AND cols LE 253)
      IF(Count GT 0) THEN BEGIN
         rows = rows(legit)
         cols = cols(legit)
      END

      Test =  WHERE(Image(rows,cols+1) LT Level, count)
      IF(COUNT GT 0) THEN BEGIN
         rows2 =  rows(test)
         cols2 =  cols(test)
         Image(rows2,cols2) =  (2*Image(rows2,cols2-1) + Image(rows2,cols2+2) + 1) / 3
      END

      Test = WHERE(Image(rows,cols+1) GE Level, Count)
      IF(COUNT GT 0) THEN BEGIN
         rows2 = rows(test)
         cols2 = cols(test)
         Image(rows,cols) =  (Image(rows,cols-1) + Image(rows,cols+1) + 1) / 2
      END
   END
END


;----------------------------------------------------------
; PURPOSE:
;
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_DAYGLOW_SUBTRACT, Image, Record, LookVector
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons

   newImage = UNPACK(Image)
   TIME = Record.Time_PB5
   SC_POS =  Record.SC_POS_GCI
   SUN_VCTR =  Record.SUN_VCTR
   IM_TO_GCI = Record.Rotatn_Matrix
   ALTF =  Record.ALTF
   MaxAlt =  6356.774D0 + 500.D0
   BackGround =  15
   Day =  Time(1)

   XV_LOOKV_TO_GCI
   XV_ALT_SZA

   Junk =  where( Alts GT MaxAlt, Count)
   IF(count GT 0) THEN BEGIN
      zeros =  where(newImage(junk) Lt BackGround, Count)
      IF(Count GT 0) THEN BEGIN
         x =  newImage(junk)
         x(zeros) =  BackGround
         newImage(junk) =  x

      END
      newImage(junk) =  newImage(junk) - BackGround
   END

   Junk = where(SZAs LT 0 AND Alts LT MaxAlt, Count)
   IF(count GT 0) THEN BEGIN
      DayGlows =  DayGlow(SZAs(junk),Day) - BackGround
      Percentages =  1.0 - (Alts(Junk) - ALTF) / (MaxAlt - ALTF)
      newImage(junk) =  newImage(junk) - DayGLows * Percentages
   END

   Junk =  where(Szas GT 0, Count)
   IF(count GT 0) THEN BEGIN
      newImage(junk) =  newImage(junk) - DayGlow(SZAs(junk),Day)
   END


   Image = PACK(newImage)
END


;----------------------------------------------------------
; PURPOSE:
;  Sets the global ROI value for the solar zenith angle
;  filters.
;
; CALLING SEQUENCE:
;
;
; INPUTS:
;  Mode == 0 for FILL mode.  Finds pixels P where
;                            MinValue <= P <= MaxValue
;          1 for MIN mode.   Finds pixels P where the SZA
;                            MinValue <= SZA <= MaxValue AND
;                            P < FillValue
;          2 for MAX mode.   Finds pixels P where
;                            MinValue <= SZA <= MaxValue AND
;                            P > FillValue
;          3 for CUT mode    Finds pixels P where
;                            MinValue >= P OR P >= MaxValue
;  MinAngle == Minimum solar zenith angle in degrees
;  MaxAngle == Maximum solar zenith angle in degrees
;  FillValue == used in different ways depending on the mode as
;               described above.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Sets ROI common block variable
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_GET_SOLAR_ZENITH_PIXELS, Mode, MinAngle, MaxAngle, FillValue
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons

   IF(record.sensor NE 0) THEN BEGIN
      szas_local = rotate(szas,2)
   END ELSE szas_local = szas

   XV_ALT_SZA
   IF(MODE EQ 0) THEN BEGIN
      ROI = WHERE(SZAS_local GE MinAngle AND SZAS_local LE MaxAngle)
   END ELSE IF(MODE EQ 1) THEN BEGIN
      ROI = WHERE(SZAS_local GE MinAngle AND SZAS_local LE MaxAngle AND Image LT FillValue)
   END ELSE IF(MODE EQ 2) THEN BEGIN
      ROI = WHERE(SZAS_local GE MinAngle AND SZAS_local LE MaxAngle AND Image GT FillValue)
   END ELSE IF(MODE EQ 3) THEN BEGIN
      ROI = WHERE(SZAs_local LE MinAngle OR SZAS_local GE MaxAngle)
   END
END


;----------------------------------------------------------
; PURPOSE:
;  Sets all values in the ROI of the current image to the
;  filvalue
;
; CALLING SEQUENCE:
;
;
; INPUTS:
;  Image == image
;  ROI   == an array of indices into image.  If ROI contains
;           any negative values then it is assumed to be NULL
;  FillValue == value to be assigned to the ROI pixels.
;
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  alters the input image
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_BLACKTAPE, Image, ROI, FillValue
   junk =  where(ROI LT 0, Count)
   IF(Count LE 0) THEN Image(ROI) =  FillValue
END


;----------------------------------------------------------
; PURPOSE:
;
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Alters the input image.
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_HORIZ_SMOOTH, IM1
   IM3 = IM1
   Tmp = INDGEN(16)+1

   FOR j=6,249 DO BEGIN
      ISUM1 =  FIX(TOTAL(IM1(0:15,j-5:j-1)))
      ISUM2 =  FIX(TOTAL(IM1(0:15,j)))
      ISUM3 =  FIX(TOTAL(IM1(0:15,j+1:j+5)))

      IAVG1 = (isum1+40) / 80
      IAVG2 = (isum2+8) / 16
      IAVG3 = (isum3+40) / 80

      IAVG = (IAVG1 + IAVG3 + 1) / 2
      IDEL2 =  IAVG - IAVG2

;      IM3(0:7,j) = IM1(0:7,j) + IDEL2
      IM3(4:7,j) = IM1(4:7,j) + IDEL2

      FOR i=16,255,16 DO BEGIN
         IDEL1 = IDEL2
         ISUM1 = FIX(TOTAL(IM1(i:i+15,j-5:j-1)))
         ISUM2 = FIX(TOTAL(IM1(i:i+15,j)))
         ISUM3 = FIX(TOTAL(IM1(i:i+15,j+1:j+5)))

         IAVG1 = (isum1+40) / 80
         IAVG2 = (isum2+8) / 16
         IAVG3 = (isum3+40) / 80

         IAVG = (IAVG1 + IAVG3 + 1) / 2
         IDEL2 = IAVG - IAVG2

         IM3(i-8:i+7,j) = IM1(i-8:i+7,j) + (TMP*(idel2-idel1)+8)/16 + idel1
      END

      IM3(248:255,j) = IM1(248:255,j) + idel2
   END

   IM1 = IM3
END


;----------------------------------------------------------
; PURPOSE:
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;
; COMMON BLOCKS:
;  None
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
;PRO XV_REMOVE_WEAVE, Image
;   Im3 = UNPACK(image)
;
;   ;; Set up the indexes
;   Indexes = intarr(5,50)
;   FOR i=0,4 DO Indexes(i,*) = indgen(50)*5 + i
;
;   FOR j=0,255 DO BEGIN
;
;      ISum = intarr(5)
;      FOR i=0,4 DO Isum(i) =  TOTAL(Im3(j,Indexes(i,*)))
;
;      x = min(isum,IndexMin)
;      FOR i=19+IndexMin,239+IndexMin,5 DO BEGIN
;         Image(j,i) = im3(j,i) + $
;          (float(im3(j,i-7)+2.0*im3(j,i-4)-3.0*im3(j,i-5) $
;                 +im3(j,i+3)+2.0*im3(j,i+6)-3.0*im3(j,i+5))/6.0) + 0.5
;
;         Image(j,i-1) = im3(j,i-1) + $
;          (float(2.0*im3(j,i-7)+im3(j,i-4)-3.0*im3(j,i-6) $
;                 +2.0*im3(j,i+3)+im3(j,i+6)-3.0*im3(j,i+4))/6.0) + 0.5
;      END
;   END
;
;   Image =  PACK(FIX(Image))
;END

PRO XV_UPDATE_SURVEY, Top, DrawWid, start
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort

   WIDGET_CONTROL, /HOURGLASS, SENSITIVE=0, Top
   OLDWIN =  !D.WINDOW
   oldMulti =  !p.multi
   WIDGET_CONTROL, DrawWid, get_value=wnum
   WSET,WNUM

   !p.multi =  [0,4,2]
   images =  xv_get_image(fid,start,8)

   FOR I=0,7 DO BEGIN
      IMAGES(0:3,*,I) = 0
   ENDFOR

   IF(record.sensor NE 0) THEN BEGIN
      FOR i=0,7 DO BEGIN
         images(*,*,i) =  rotate(images(*,*,i),2)
      END
   END

   display = bytarr(1024,642)

   FOR i=0,7 DO BEGIN
      col =  i MOD 4
      IF i GE 4 THEN row =  1 ELSE row =  0
      display( col*256 : col*256+255, row*305+50 : row*305+305) =  images(*,*,i)
   END

   tv,display,/order

   ;;; Add annotation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   XPixel = 1.0/1024.0
   YPixel = 1.0/642.0

   xyouts, 5*XPixel, 7*YPixel, "The University of Iowa", /charsize
   xyouts, 1019*XPixel, 7*YPixel,"Visible Imaging System/POLAR",/charsize,alignment=1.0

   dates =  strarr(8)
   FOR i=0,7 DO BEGIN
      rec =  xv_get_record(fid,start+i)
      dates(i) = datetostring(rec.time_pb5,0)
   END

   IF(record.sensor EQ 0) THEN $
    Title= "Earth Camera" ELSE $
    IF(record.sensor EQ 1) THEN $
    Title= "Low Resolution Camera" ELSE $
    IF(record.sensor EQ 2) THEN $
    Title= "Med Resolution Camera"

   FOR i=0,7 DO BEGIN
      col = i MOD 4
      IF i GE 4 THEN row = 0 ELSE row = 1
      xyouts, (col*256.0+128.0) * XPixel, (row*305+293)*YPixel, dates(i),alignment=.5,charsize=.75
      xyouts, (col*256.0+128.0) * XPixel, (row*305+312)*YPixel, title,alignment=.5,charsize=.75
   END
   ;;; End of Annotation;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


   wset,oldwin
   !p.multi =  oldmulti
   WIDGET_CONTROL, HOURGLASS=0, SENSITIVE=1, Top
END


PRO XV_SURVEY_EVENT, event
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort

   widget_control,event.top,get_uvalue=wids
   CASE event.id  OF
      wids.next: BEGIN
         widget_control,get_value=start,wids.record
         start =  (start+8) < (MaxRecs-7)
         widget_control,set_value=start,wids.record
         XV_UPDATE_SURVEY, event.top, Wids.Draw, start
      END
      wids.prev: BEGIN
         widget_control,get_value=start,wids.record
         start =  start-8 > 0
         widget_control,set_value=start,wids.record
         XV_UPDATE_SURVEY, event.top, Wids.Draw, start
      END
      wids.close: BEGIN
         WIDGET_CONTROL,Wids.Base,/DESTROY
      END
      wids.Record: BEGIN
         widget_control,get_value=start,wids.record
         Start =  start <  (MaxRecs-7)
         start =  start >  0
         widget_control,set_value=start,wids.record
         XV_UPDATE_SURVEY, event.top, Wids.Draw, start
      END
      DEFAULt: BEGIN
         print,'Shouldnt be here'
      END
   END

END


;----------------------------------------------------------
; PURPOSE:
;  Displays multiple images on a single plot.
;
; INPUTS:
;  Parent (actually the group leader) of the window.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  Construct and realizes the multiple image plotter.
;
; COMMON BLOCKS:
;  None
;
; PROCEDURE:
;  XV_SURVEY, Parent
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_CREATE_SURVEY, Parent
   IF XREGISTERED("XV_SURVEY") THEN RETURN

   Base = WIDGET_BASE(GROUP_LEADER=Parent,/COLUMN,TITLE='Survey')
   Draw = WIDGET_DRAW(Base,XSIZE=1024,ysize=642,retain=2) ; leave 50 pixels for titles
   BBase = WIDGET_BASE(base,/row,frame=1)
   Record =  CW_FIELD(bBase,/INTEGER,TITLE='Beginning Record',VALUE=0,/RETURN_EVENTS,xsize=5)
   Next = WIDGET_BUTTON(bBase,Value='Next')
   Prev = WIDGET_BUTTON(bBAse,Value='Prev')
   Close = WIDGET_BUTTON(bBase,VALUE='Close')

   Wids = {Base:Base,$
           Draw:Draw,$
           Next:Next,$
           Prev:Prev,$
           Close:Close,$
           Record:Record}

   WIDGET_CONTROL,Base,/REALIZE,SET_UVALUE=Wids
   XMANAGER,"XV_SURVEY",Base,/NO_BLOCK
   XV_SURVEY_EVENT, {ID:Record, TOP:base, HANDLER:Record}
END


;----------------------------------------------------------
; PURPOSE:
;  Insures that a dying window unregisters itself
;  from the View window when the widget dies.  It must
;  be a cleanup procedure since the window could be
;  killed via the window manager.
;
; CALLING SEQUENCE:
;  Called by IDL when widgets using this as their
;  cleanup procedure are destroyed.
;
; INPUTS:
;  The dying widget
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; COMMON BLOCKS:
;  None
;
; PROCEDURE:
;  This is not a public procedure.  Shouldn't be called directly.
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_CLEANUP, DyingWidget
   XV_UNREGISTER_VIEW_HANDLER, DyingWidget
END


;----------------------------------------------------------
; PURPOSE:
;  Event handler for the Surface window.
;
; INPUTS:
;  Event from the Surface window.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  Updates the Surface window when the cursor is moved over
;  the view window.
;
; COMMON BLOCKS:
;  XV_RECORD_DATA
;  XV_FILE_DATA
;
; PROCEDURE:
;  This is not a public procedure.  Shouldn't be called directly.
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_SURF_EVENT, Event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_CURSOR, Xsc, Ysc, Xim, Yim, Xcd, Ycd, Xlb, Ylb

   WIDGET_CONTROL,Event.top,GET_UVALUE = Wids

   CASE event.id OF
      Wids.Base: BEGIN
         type = tag_names(event,/structure_name)
         IF(type NE 'WIDGET_DRAW') THEN RETURN
         IF(wids.mode EQ 1 AND event.press EQ 0) THEN RETURN
         Delta = 128 / Wids.Factor
         xlo = Xim-Delta
         ylo = Yim-Delta
         TwoDelta = 2*Delta
         WIDGET_CONTROL,Wids.Draw,GET_VALUE=WNum
         OLD_WINDOW =  !D.WINDOW
         WSET,WNum
         IF(wids.ZSC EQ 1) THEN BEGIN
            shade_surf,Extrac(Image,xlo,ylo,twodelta,twodelta),$
             indgen(twodelta)+xlo,$
             reverse(indgen(twodelta)+ylo),$
             xticks=2,$
             yticks=2,$
             xstyle=1,$
             ystyle=1,$
             ytickname=string([ylo+twodelta,ylo+delta,ylo]),$
             ax=wids.xrot,$
             az=wids.zrot
         END ELSE BEGIN
            shade_surf,Extrac(Image,xlo,ylo,twodelta,twodelta),$
             indgen(twodelta)+xlo,$
             reverse(indgen(twodelta)+ylo),$
             xticks=2,$
             yticks=2,$
             xstyle=1,$
             ystyle=1,$
             ytickname=string([ylo+twodelta,ylo+delta,ylo]),$
             zrange=[0,255],$
             ax=wids.xrot,$
             az=wids.zrot
         END
         WSET,OLD_WINDOW
      END
      Wids.Close: BEGIN
         WIDGET_CONTROL,event.top,/DESTROY
      END
      Wids.Options: BEGIN
         opts = XV_SURFER_DIALOG(Wids.base,$
                                 {Mode:Wids.Mode,$
                                  Factor:Wids.Factor,$
                                  Xrot:Wids.Xrot,$
                                  Zrot:Wids.Zrot,$
                                  ZSc:Wids.ZSc})
         Wids.Factor = opts.factor
         Wids.Mode = opts.mode
         Wids.XRot =  opts.xrot
         Wids.Zrot = opts.zrot
         Wids.ZSc = opts.Zsc
         WIDGET_CONTROL,Event.top,SET_UVALUE=Wids
      END
   ENDCASE
END


;----------------------------------------------------------
; PURPOSE:
;  Displays a surface view of an image.
;
; INPUTS:
;  Parent (actually the group leader) of the window.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  Constructs and realizes the surfer window.
;
; COMMON BLOCKS:
;  None
;
; PROCEDURE:
;  XV_SURFER, Parent
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_SURFER, Parent
   IF XREGISTERED("XV_SURF") THEN RETURN

   Base = WIDGET_BASE(GROUP_LEADER=Parent,/COLUMN,TITLE='SURF',TLB_FRAME_ATTR=1)
   Draw = WIDGET_DRAW(Base,XSIZE=256,YSIZE=256)
   Options = WIDGET_BUTTON(Base,VALUE='Options')
   Close = WIDGET_BUTTON(Base,VALUE='Close')
   Wids = {Base:Base,Draw:Draw,Options:Options,Close:Close,Factor:4,Mode:0,XRot:70,Zrot:10,ZSc:0}

   XV_REGISTER_VIEW_HANDLER, Base
   WIDGET_CONTROL,Base,/REALIZE,SET_UVALUE=Wids
   XMANAGER,"XV_SURF",Base,/NO_BLOCK,CLEANUP='XV_CLEANUP'
   XV_SURF_EVENT,{ID:base,TOP:base,HANDLER:0L,x:128,y:128,PRESS:1}
END



;----------------------------------------------------------
; PURPOSE:
;  Event handler for the coordinate window.
;
; INPUTS:
;  Event structure
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Updates the coordinate window.
;
; COMMON BLOCKS:
;  XV_RECORD_DATA
;  XV_DERIVED_DATA
;
; PROCEDURE:
;  This is not a public procedure.  Should not be called directly.
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_CRD_EVENT, event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_CURSOR, Xsc, Ysc, Xim, Yim, Xcd, Ycd, Xlb, Ylb
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   WIDGET_CONTROL,event.top,GET_UVALUE=Wids
   WIDGET_CONTROL,Wids.Opt,GET_UVALUE=mode

   CASE event.id OF
      Wids.Close: BEGIN
         WIDGET_CONTROL,Wids.Base,/DESTROY
      END
      Wids.Opt: BEGIN
         IF(mode EQ 0) THEN BEGIN
            mode =  1
            newValue = 'Click Mode'
         END ELSE BEGIN
            mode =  0
            newVAlue = 'Continuous Mode'
         END
         WIDGET_CONTROL, Wids.Opt, SET_UVALUE=mode, SET_VALUE=newValue
      END
      Wids.Base: BEGIN
         IF(event.press EQ 0 AND mode EQ 1) THEN return

         WIDGET_CONTROL,Wids.PixLabel,SET_VALUE='(' + $
          STRING(Xlb,FORMAT='(I3)') + ',' + $
          STRING(Ylb,FORMAT='(I3)') + ')'

         coord =  SINGLE_PIXEL_CRD(Xcd,Ycd,ON_EARTH)
         x =  STRING(coord(0),FORMAT='(F8.1)')
         y =  STRINg(coord(1),FORMAT='(F8.1)')
         z =  STRINg(coord(2),FORMAT='(F8.1)')
         result =  "GCI  : " + x + ",   " + y + ",   " + z
         WIDGET_CONTROL,Wids.GCILabel,SET_VALUE=result

         WIDGET_CONTROL,Wids.SZALabel,SET_VALUE="SZA  : " + $
          STRING(GCI_TO_SZA(coord),FORMAT='(F8.1)')

         IF(ON_EARTH GT 0) THEN BEGIN
            GCI_TO_GEO, Coord, Lat, Lon, Alt
            lat =  STRING(LAT, FORMAT='(F8.1)')
            lon =  STRING(LON, FORMAT='(F8.1)')
            alt =  STRING(ALT, FORMAT='(F8.1)')
            result =  "GEO  : " + lat + " N, " + lon + " E, " + alt + " alt"
            WIDGET_CONTROL,Wids.GEOLabel, SET_VALUE=result
            WIDGET_CONTROL,Wids.RADECLabel,SET_VALUE="RADEC:"
         END ELSE BEGIN
            XV_LOOKV_TO_GCI
;;;            coord =  coord / norm(coord)
            coord =  LookV_GCI[*,Xcd,Ycd]
            RA =  atan(coord(1), coord(0)) * !RADEG
            IF(RA LT 0) THEN ra =  ra + 360.0D0
            RA = STRING(RA, FORMAT='(F8.1)')
            Dec =  STRING(asin(coord(2)) * !RADEG , FORMAT='(F8.1)')
            result =  "RADEC: " + RA + ",   " + DEC
            WIDGET_CONTROL,Wids.GEOLabel, SET_VALUE="GEO  :"
            WIDGET_CONTROL,Wids.RADECLAbel, SET_VALUE=result
         END
      END
   END
END


;----------------------------------------------------------
; PURPOSE:
;  Creates and realizes a window to display the geographic
;  coordinates of the pixel pointed to by the cursor.
;
; INPUTS:
;  Parent (actually the group leader) of the window.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  creates and manages the coordinate window
;
; COMMON BLOCKS:
;  None
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_CRD, Parent
   IF XREGISTERED("XV_CRD")THEN RETURN

   Base = WIDGET_BASE(GROUP_LEADER=Parent,/COLUMN,TITLE='COORDINATES',TLB_FRAME_ATTR=1)

   PixLabel =  WIDGET_LABEL(Base, Frame=3,xsize=550,/align_center,VALUE='(row,col)')

   CrdBase =  WIDGET_BASE(Base,FRAME=3,/COLUMN)
   Szalabel =  WIDGET_LABEL(CrdBase,Frame=0,xsize=550,/align_left,$
                            VALUE="SZA:")

   GCILabel = WIDGET_LABEL(CrdBase,Frame=0,xsize=550,/align_left,$
                           VALUE="GCI:")

   GEOLabel = WIDGET_LABEL(CrdBase,Frame=0,xsize=550,/align_left,$
                           VALUE="GEO:")

   RADecLabel = WIDGET_LABEL(CrdBase,Frame=0,xsize=550,/align_left,$
                             VALUE="RADEC:")

   Opt =  WIDGET_BUTTON(Base, VALUE='Continuous Mode', UVALUE=0)

   Close = WIDGET_BUTTON(Base,VALUE='Close')
   Wids = {Base:Base,$
           Parent:Parent,$
           PixLabel:PixLabel,$
           SzaLabel:SzaLabel,$
           GCILabel:GCILabel,$
           GEOLabel:GEOLabel,$
           RADecLabel:RADecLabel,$
           Opt:Opt,$
           Close:Close}

   XV_REGISTER_VIEW_HANDLER, Base
   WIDGET_CONTROL,Base,/REALIZE,SET_UVALUE=Wids
   XMANAGER,"XV_CRD",Base,/NO_BLOCK,CLEANUP='XV_CLEANUP'
END


;----------------------------------------------------------
; PURPOSE:
;  Reads a single record from a CDF file.
;
; INPUTS:
;  None.  All the relevant information is passed via COMMON
;  blocks.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Sets appropriate flags.
;
; COMMON BLOCKS:
;   XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
;   XV_FLAGS, Flags
;   XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
;   XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
;   XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
;   COLORS, rr,gg,bb,rc,gc,bc
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_READ_RECORD
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit, Record2
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON COLORS, rr,gg,bb,rc,gc,bc

   WIDGET_CONTROL, MainWid, GET_UVALUE=TopWids
   WIDGET_CONTROL, TopWids.CWin, GET_UVALUE=Wids

   Image =  XV_GET_IMAGE(Fid,ImageNum,1)
   Image(0:3,*) = 0
   RECORD =  XV_GET_RECORD(Fid,ImageNum)
   IF(record.sensor EQ 1) THEN BEGIN
	Image = rotate(image,2)
	RECORD2 = XV_GET_RECORD2(Fid,ImageNum)
   ENDIF
   tsize =  n_elements(rr)
   min =  record.limit_lo
   max =  record.limit_hi
   ratio = float(tsize) / 256.0
   min = FIX(ratio * min)
   max = FIX(ratio * max)
   IF(tsize GT 0 AND Flags.CDF_COLOR EQ 1) THEN BEGIN
      CURR_LIMIT = [min,max]
      ncolors =  record.limit_hi-record.limit_lo+1
      rc(0:min) =  rr(0)
      gc(0:min) =  gg(0)
      bc(0:min) =  bb(0)
      rc(max:*) =  rr(tsize-1)
      gc(max:*) =  gg(tsize-1)
      bc(max:*) =  bb(tsize-1)
      rc(min:max) =  congrid(rr,max-min+1)
      gc(min:max) =  congrid(gg,max-min+1)
      bc(min:max) =  congrid(bb,max-min+1)
      tvlct,rc,gc,bc
   END

   Flags.LV = 0
   Flags.ALT = 0
   Flags.ALTLS = 0
   Flags.PHI =  0
   Flags.SZA = 0
   Flags.LOC =  0
   Flags.GLAT = 0
   Flags.GLON = 0

   WIDGET_CONTROL, Wids.Scale, SET_VALUE=ImageNum
   StartTime = record.time_pb5
   StartTime[2] = StartTime[2] - FIX(record.int_time_half) + 1000 ; add 1 second (1000 msec)
   WIDGET_CONTROL, TopWids.StartDateBid, SET_VALUE="Start : " + DateToString(StartTime,2)
   WIDGET_CONTROL, TopWids.CenterDateBid, SET_VALUE="Center: " + DateToString(record.time_pb5,2)

   XV_UPDATE_VIEW_WINDOW
   XV_UPDATE_IMAGE_INFO
END


;----------------------------------------------------------
; PURPOSE:
;  Event handler for the zoom window.
;
; INPUTS:
;  Event structure.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;   None
;
; COMMON BLOCKS:
;   XV_RECORD_DATA
;   XV_FILE_DATA
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_ZOOM_EVENT, Event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_CURSOR, Xsc, Ysc, Xim, Yim, Xcd, Ycd, Xlb, Ylb

   WIDGET_CONTROL,Event.top,GET_UVALUE = Wids

   CASE event.id OF
      Wids.Base: BEGIN
         type = tag_names(event,/structure_name)
         IF(type NE 'WIDGET_DRAW') THEN RETURN
         IF(wids.mode EQ 1 AND event.press EQ 0) THEN RETURN
         Delta = 128 / Wids.Factor
         xlo = Xim-Delta
         ylo = Yim-Delta
         TwoDelta = 2*Delta
         WIDGET_CONTROL,Wids.Draw,GET_VALUE=WNum
         OLD_WINDOW =  !D.WINDOW
         WSET,WNum
         TV,CONGRID(Extrac(Image,xlo,ylo,TwoDelta,TwoDelta),256,256),/ORDER
         WSET,OLD_WINDOW
      END
      Wids.Close: BEGIN
         WIDGET_CONTROL,event.top,/DESTROY
      END
      Wids.Options: BEGIN
         opts = XV_ZOOMER_DIALOG(Wids.base,{Mode:Wids.Mode,Factor:Wids.Factor})
         Wids.Factor = opts.factor
         Wids.Mode = opts.mode
         WIDGET_CONTROL,Event.top,SET_UVALUE=Wids
      END
   ENDCASE
END


;----------------------------------------------------------
; PURPOSE:
;  Creates and realizes a 'zoom' window for the active image.
;  The zoom window displays a bilinearly interpolated subregion
;  of the image centered on the cursor position.
;
; INPUTS:
;  Parent (or group leader) of the zoom window.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;   None
;
; COMMON BLOCKS:
;
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_ZOOMER, Parent
   IF XREGISTERED("XV_ZOOM") THEN RETURN

   Base = WIDGET_BASE(GROUP_LEADER=Parent,/COLUMN,TITLE='Zoom',TLB_FRAME_ATTR=1)
   Draw = WIDGET_DRAW(Base,XSIZE=256,YSIZE=256)
   Options = WIDGET_BUTTON(Base,VALUE='Options')
   Close = WIDGET_BUTTON(Base,VALUE='Close')
   Wids = {Base:Base,Draw:Draw,Options:Options,Close:Close,Factor:4,Mode:0}

   XV_REGISTER_VIEW_HANDLER, Base
   WIDGET_CONTROL,Base,/REALIZE,SET_UVALUE=Wids
   XMANAGER,"XV_ZOOM",Base,/NO_BLOCK,CLEANUP='XV_CLEANUP'
   XV_ZOOM_EVENT,{ID:base,TOP:base,HANDLER:0L,x:128,y:128,PRESS:1}
END


;----------------------------------------------------------
; PURPOSE:
;  Event handler for the control panel widget.
;
; INPUTS:
;  Event structure.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  None
;
; COMMON BLOCKS:
;  XV_RECORD_DATA
;  XV_FILE_DATA
;  XV_WIDS
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_CONTROL_PANEL_EVENT, Event
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount

   WIDGET_CONTROL, Event.top, GET_UVALUE=TopWids
   WIDGET_CONTROL, TopWids.CWin, GET_UVALUE=Wids

   CASE Event.id OF
      Wids.Mode: BEGIN
         WIDGET_CONTROL,Wids.ModeState,GET_UVALUE=modeState
         IF(event.index EQ 0) THEN DeltaT = 1 $ ;loop once
         ELSE IF(event.index EQ 1) THEN DeltaT = 1 $ ;loop forward
         ELSE IF(event.index EQ 2) THEN DeltaT = -1 $ ;loop backwards
         ELSE DeltaT = modeState.DT ; loop circular
         modeState = {DT:DeltaT,Mode:event.index}
         WIDGET_CONTROL,Wids.Modestate,SET_UVALUE=modeState
      END
      TopWids.CWin: BEGIN
         WIDGET_CONTROL, Wids.Pause, GET_UVALUE = paused
         IF(paused EQ 0) THEN BEGIN
            WIDGET_CONTROL, Wids.ModeState, GET_UVALUE=modeState
            ImageNum = ImageNum + ModeState.DT

            IF(ImageNum GT MaxRecs) THEN BEGIN
                  IF(modeState.mode EQ 0) THEN BEGIN ;forward once
                  paused = 1
                  WIDGET_CONTROL, Wids.Pause, SET_UVALUE = paused
                  END ELSE BEGIN
                     IF(modeState.mode EQ 1) THEN BEGIN ;forward loop
                        ImageNum = 0
                     END ELSE BEGIN
                        IF(MaxRecs EQ 0) THEN ImageNum = 0 ELSE ImageNum = MaxRecs-1
                        WIDGET_CONTROL,Wids.ModeState,$
                        SET_UVALUE={DT:-modestate.dt,mode:modestate.mode}
                     END
                     WIDGET_CONTROL, TopWids.CWin, TIMER= 0.05
                     XV_READ_RECORD
                  END
               END ELSE BEGIN
                  IF (ImageNum LT 0) THEN BEGIN
                     IF(modeState.mode EQ 2) THEN BEGIN
                        ImageNum = MaxRecs
                     END ELSE BEGIN
                        IF(MaxRecs EQ 0) THEN ImageNum = 0 ELSE ImageNum =  1
                        WIDGET_CONTROL,Wids.ModeState,$
                        SET_UVALUE={DT:-modestate.dt,mode:modestate.mode}
                     END
               END
                  WIDGET_CONTROL, TopWids.CWin, TIMER= 0.05
                  XV_READ_RECORD
               END
            END
      END
      Wids.First: BEGIN
         ImageNum = 0
         XV_READ_RECORD
      END
      Wids.Last: BEGIN
         ImageNum = MaxRecs
         XV_READ_RECORD
      END
      Wids.Prev: BEGIN
         ImageNum = ImageNum-1
         IF(ImageNum LT 0) THEN ImageNum = 0
         XV_READ_RECORD
      END
      Wids.Next: BEGIN
         ImageNum = ImageNum+1
         IF(ImageNum GT MaxRecs) THEN ImageNum = ImageNum-1
         XV_READ_RECORD
      END
      Wids.Scale: BEGIN
         WIDGET_CONTROL, Wids.Scale, GET_VALUE=ScaleValue
         ImageNum = ScaleValue
         XV_READ_RECORD
      END
      Wids.Play: BEGIN
         WIDGET_CONTROL, Wids.Play, SET_UVALUE = 1, SENSITIVE=0
         WIDGET_CONTROL, Wids.Pause, SET_UVALUE = 0, /SENSITIVE
         WIDGET_CONTROL, TopWids.CWin, TIMER = 0.05
         WIDGET_CONTROL, Wids.Scale, SENSITIVE=0
         WIDGET_CONTROL, Wids.Prev, SENSITIVE=0
         WIDGET_CONTROL, Wids.First, SENSITIVE=0
         WIDGET_CONTROL, Wids.Next, SENSITIVE=0
         WIDGET_CONTROL, Wids.Last, SENSITIVE=0
      END
      Wids.Pause: BEGIN
         WIDGET_CONTROL, Wids.Play, SET_UVALUE = 0, /SENSITIVE
         WIDGET_CONTROL, Wids.Pause, SET_UVALUE = 1, SENSITIVE=0
         WIDGET_CONTROL, Wids.Scale, /SENSITIVE
         WIDGET_CONTROL, Wids.Prev, /SENSITIVE
         WIDGET_CONTROL, Wids.First, /SENSITIVE
         WIDGET_CONTROL, Wids.Next, /SENSITIVE
         WIDGET_CONTROL, Wids.Last, /SENSITIVE
      END
      ELSE: print,"CONTROL_PANEL_EVENT::Event not handled"
   END
END


;----------------------------------------------------------
; PURPOSE:
;  Creates and realizes a control panel widget.  The organization
;  is not so good (it should probably be a compound widget).  The
;  control panel has a number of buttons controlling which image
;  within a file is viewed.
;
; INPUTS:
;  The parent, maximum number of records in the file, and the value
;  of the current image to be displayed.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  None
;
; COMMON BLOCKS:
;  XV_RECORD_DATA
;  XV_FILE_DATA
;  XV_WIDS
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
FUNCTION XV_CREATE_CONTROL_PANEL, parent
   LastBitmap = BYTE([ [0, 0],[16, 40],[48, 40],[112, 40], $
                       [240, 40],[240, 41],[240, 43],[240, 47],$
                       [240, 47],[240, 43],[240, 41],[240, 40],$
                       [112, 40],[48, 40],[16, 40],[0, 0]])

   PauseBitmap = BYTE([[0,0],[96,6],[96,6],[96,6],$
                       [96,6],[96,6],[96,6],[96,6],$
                       [96,6],[96,6],[96,6],[96,6],$
                       [96,6],[96,6],[96,6],[96,6],$
                       [96,6],[96,6],[0,0]])

   NextBitmap = BYTE([[0, 0],[16, 8],[48, 8],[112, 8],$
                      [240, 8],[240, 9],[240, 11],[240, 15],$
                      [240, 15],[240, 11],[240, 9],[240, 8],$
                      [112, 8],[48, 8],[16, 8],[0, 0]])

   PlayBitmap = BYTE([[0, 0],[16, 0],[48, 0],[112, 0],$
                      [240, 0],[240, 1],[240, 3],[240, 7],$
                      [240, 7],[240, 3],[240, 1],[240, 0],$
                      [112, 0],[48, 0],[16, 0],[0, 0]])

   FirstBitmap = BYTE([[0, 0],[40, 16],[40, 24],[40, 28],$
                       [40, 30],[40, 31],[168, 31],[232, 31],$
                       [232, 31],[168, 31],[40, 31],[40, 30],$
                       [40, 28],[40, 24],[40, 16],[0, 0]])

   PrevBitmap = BYTE([[0, 0],[16, 8],[16, 12],[16, 14],$
                      [16, 15],[144, 15],[208, 15],[240, 15],$
                      [240, 15],[208, 15],[144, 15],[16, 15],$
                      [16, 14],[16, 12],[16, 8],[0, 0]])


   Base = WIDGET_BASE(parent, /COLUMN, EVENT_PRO="XV_CONTROL_PANEL_EVENT")

   ModeBase = WIDGET_BASE(Base,/ROW,FRAME=1,UVALUE={DT:1,MODE:0})
   ModeLabel = WIDGET_LABEL(ModeBase, VALUE="Loop Mode:")
   ModeButtons =  WIDGET_DROPLIST(ModeBase,$
       Value=["Forward Once","Forward Loop","Reverse Loop","Circular"])

   SelectBase = WIDGET_BASE(Base,/Column, FRAME=1)
   Scale = WIDGET_SLIDER(SelectBase, /DRAG, MAXIMUM=100, MINIMUM=0, XSIZE=300)

   ButtonBase = WIDGET_BASE(SelectBase,/ROW)
   FirstButton = WIDGET_BUTTON(ButtonBase, Value=FirstBitmap)
   PrevButton = WIDGET_BUTTON(ButtonBase, Value=PrevBitmap)
   NextButton = WIDGET_BUTTON(ButtonBase, Value=NextBitmap)
   LastButton = WIDGET_BUTTON(ButtonBase, Value=LastBitmap)
   PauseButton = WIDGET_BUTTON(ButtonBase, Value=PauseBitmap, UVALUE = 1)
   WIDGET_CONTROL,PauseButton,SENSITIVE=0
   PlayButton = WIDGET_BUTTON(ButtonBase, Value=PlayBitmap, UVALUE=0)

   Wids = { Mode:ModeButtons,$
            First:FirstButton,$
            Prev:PrevButton,$
            Next:NextButton,$
            Last:LastButton,$
            Pause:PauseButton,$
            Play:PlayButton,$
            Scale:Scale,$
            ModeState:ModeBase}

   WIDGET_CONTROL,SET_UVALUE=Wids,Base,SENSITIVE=0
   return, Base
END


;----------------------------------------------------------
; PURPOSE:
;  Destroys the XVIS application.
;
; INPUTS:
;  An Event structure.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Everything goes away.
;
; COMMON BLOCKS:
;  XV_RECORD_DATA
;  XV_FILE_DATA
;  XV_WIDS
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_EXIT, Event
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_FLAGS, Flags
   IF(Flags.Loaded EQ 1) THEN CDF_CLOSE,Fid
   WIDGET_CONTROL, event.top, /DESTROY
END


;----------------------------------------------------------
; PURPOSE:
;  Opens a VIS CDF file.
;
; INPUTS:
;  An event structure.
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  Opens the CDF file.  Reads in the first image.  Loads
;  the color table.  Load the record.  Displays the loaded
;  image.  Sets certain appropriate flags.
;
; COMMON BLOCKS:
;  XV_DERIVED_DATA
;  XV_FLAGS
;  XV_RECORD_DATA
;  XV_FILE_DATA
;  COLORS
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_OPEN, Event
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON colors,rr,gg,bb,rc,gc,bc
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount

   WIDGET_CONTROL, Event.top, GET_UVALUE=TopWids
   WIDGET_CONTROL, TopWids.CWin, GET_UVALUE=Wids

   Filename = DIALOG_PICKFILE(FILTER="*.cdf", /MUST_EXIST, /READ, GET_PATH=Path, PATH=Path)
   IF(filename NE "") THEN BEGIN
;	PRINT,FILENAME
      WIDGET_CONTROL, /HOURGLASS, SENSITIVE=0, Event.top

      CATCH, Error
      IF ERROR NE 0 THEN BEGIN
         junk =  ['Error while opening file.',!ERR_STRING]
         result = DIALOG_MESSAGE(junk,/ERROR)
         WIDGET_CONTROL, HOURGLASS=0, /SENSITIVE, Event.top
         return
      END

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; If a file is already open, destroy the
      ;; active window.
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      isValid = WIDGET_INFO(ViewWid,/VALID_ID)
      IF(isValid eq 1) THEN WIDGET_CONTROL, ViewWid, /DESTROY



      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; set XV_FILE_DATA variables
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      Fid = CDF_OPEN(Filename)
      ImageNum=0
      MaxRecs = XV_GET_NUM_RECORDS(Fid)
      Header =  XV_GET_HEADER(Fid)

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; set XV_RECORD_DATA variables
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      XV_LOAD_COLOR_TABLE,Fid
      XV_READ_RECORD

      LookVector =  XV_GET_LOOK_VECTOR(Fid)
      LastImage = Image

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; set XV_RECORD_DATA variables
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      FLAGS.LOADED = 1
      FLAGS.LV = 0
      FLAGS.ALT = 0
      FLAGS.ALTLS = 0
      FLAGS.PHI = 0
      FLAGS.SZA = 0
      FLAGS.LOC = 0
      FLAGS.GLAT = 0
      FLAGS.GLON = 0

      WIDGET_CONTROL, Wids.Scale, SET_SLIDER_MAX=MaxRecs, SET_VALUE=ImageNum
      WIDGET_CONTROL,TopWids.CWin,/SENSITIVE
      WIDGET_CONTROL,TopWids.EMenu,/SENSITIVE
      WIDGET_CONTROL,TopWids.VMenu,/SENSITIVE
      WIDGET_CONTROL,TopWids.WMenu,/SENSITIVE
      WIDGET_CONTROL,HourGlass=0,/SENSITIVE,event.top

      XV_UPDATE_VIEW_WINDOW
   END
END



;----------------------------------------------------------
; PURPOSE:
;  Creates a histogram window and plots the histogram.
;
; INPUTS:
;  Parent (actually the group leader) and image
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  Histogram window
;
; SIDE EFFECTS:
;  None really.
;
; COMMON BLOCKS:
;  None
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_PLOT_HISTOGRAM, Parent, Image
   base = WIDGET_BASE(GROUP_LEADER=Parent, TITLE="Image Histogram",$
                      TLB_FRAME_ATTR=1)
   junk = WIDGET_DRAW(base, XSIZE=512, YSIZE=512, RETAIN=2)

   WIDGET_CONTROL, Base, /REALIZE
   WIDGET_CONTROL, junk, get_value=wnum

   OLD = !D.WINDOW
   WSET,WNUM
   PLOT, HISTOGRAM(image)
   WSET,OLD

   XMANAGER,"XV_HIST",Base,/NO_BLOCK
END


;----------------------------------------------------------
; PURPOSE:
;  Creates a static image window and displays the current image.
;
; INPUTS:
;  Parent (actually the group leader), Image and ImageNumber
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  Static Image window
;
; SIDE EFFECTS:
;  None
;
; COMMON BLOCKS:
;  None
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_STATIC_IMAGE_VIEW, Parent, Image, ImageNum
   sz =  size(image)
   title = "Image " + STRTRIM(ImageNum,2)
   base = WIDGET_BASE(GROUP_LEADER=Parent, TITLE=title,$
                      TLB_FRAME_ATTR=1)
   junk = WIDGET_DRAW(base, XSIZE=sz(1), YSIZE=sz(2), RETAIN=2)


   WIDGET_CONTROL, Base, /REALIZE
   WIDGET_CONTROL, junk, GET_VALUE=winnum
   old =  !D.WINDOW
   wset,winnum

   TVImage =  Image

   IF( !D.TABLE_SIZE LT 256) THEN TVImage = FIX(TVImage * (FLOAT(!D.TABLE_SIZE) / 256.0))
   TV,TVImage,/order

   wset,old
   XMANAGER,"XV_STATIC_IMAGE",Base,/NO_BLOCK
END


;----------------------------------------------------------
; PURPOSE:
;  Event handler for the file_info window.  Basically
;  just destroys the window when the close button is
;  activated.
;
; INPUTS:
;  Event structure
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  None
;
; COMMON BLOCKS:
;  None
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_FILE_INFO_EVENT, event
   WIDGET_CONTROL,event.top,GET_UVALUE=control_button
   IF(event.id EQ control_button) THEN BEGIN
      WIDGET_CONTROL,event.top,/destroy
   END
END


;----------------------------------------------------------
; PURPOSE:
;  Creates and realizes the file_info window.  This displays
;  global file information embedded in the CDF file.
;
; INPUTS:
;  Event structure
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  None
;
; COMMON BLOCKS:
;  XV_WIDS
;  XV_DERIVED_DATA
;  XV_FLAGS
;  XV_RECORD_DATA
;  XV_FILE_DATA
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_CREATE_FILE_INFO_PANEL, Event
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort

   WIDGET_CONTROL, MainWid, GET_UVALUE=Wids

   isValid = WIDGET_INFO(Wids.FIWin,/VALID_ID)
   IF(isValid EQ 0) THEN BEGIN
      Wids.FIWin = WIDGET_BASE(GROUP_LEADER=event.top, /COLUMN, $
                               TITLE='File Attributes', TLB_FRAME_ATTR=1 )

      junk = WIDGET_TEXT(Wids.FIWin, VALUE=XV_GET_GATTRIBUTES(Fid),$
                         /scroll,ysize=30,Xsize=80)

      Close = WIDGET_BUTTON(Wids.FIWin,VALUE="Close")

      WIDGET_CONTROL, Wids.FIWin, /REALIZE, SET_UVALUE=Close
      WIDGET_CONTROL, MainWid, SET_UVALUE=Wids
      XMANAGER,"XV_FILE_INFO",Wids.FIwin,/NO_BLOCK
   END
END

;----------------------------------------------------------
; PURPOSE:
;  Event handler for the image_detail window
;
; INPUTS:
;  Event structure
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  None
;
; COMMON BLOCKS:
;  XV_DERIVED_DATA
;  XV_FLAGS
;  XV_RECORD_DATA
;  XV_WIDS
;  XV_DETAIL
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_IMAGE_DETAIL_EVENT, Event
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_DETAIL, Base, Table, Stat, Close, Options, State, Heading
   COMMON XV_CURSOR, Xsc, Ysc, Xim, Yim, Xcd, Ycd, Xlb, Ylb

   IF(TAG_NAMES(event,/STRUCTURE_NAME) EQ 'WIDGET_DRAW') THEN BEGIN
      IF(event.PRESS EQ 0 AND state.mode EQ 1) THEN return
   END

   CASE event.id OF
      CLOSE: BEGIN
         WIDGET_CONTROL,Event.top,/destroy
      END
      OPTIONS: BEGIN
         State = XV_DETAIL_DIALOG(Base,state)
         WIDGET_CONTROL,send_event=event,Base
      END
      Base: BEGIN
         MaskVal = state.mask
         IF(NOT MaskVal) THEN   BEGIN
            MaskVal = MaskVAl + 1
            WIDGET_CONTROL,Mask,SET_VALUE=MaskVal
         END

         pts = region(xim,yim,MaskVal/2,MaskVal/2,fill)
         negs = WHERE(pts LT 0, count)

         IF(state.unit EQ 0) THEN BEGIN
            WIDGET_CONTROL,Heading,SET_VALUE='Compressed Values'
         END ELSE WIDGET_CONTROL,Heading,SET_VALUE='UnCompressed Values'

         IF(state.unit EQ 0) THEN BEGIN
            poss = WHERE(pts GE 0, count2)
            Junk =  Image(pts(poss))
            avg = (MOMENT(junk,sdev=sdev))(0)
            median = FIX(median(junk))
            maxval =  FIX(max(junk))
            minval =  FIX(min(junk))
         END ELSE BEGIN
            poss = WHERE(pts GE 0, count2)
            Junk =  UNPACK(IMAGE(pts(Poss)))
            avg = (MOMENT(junk,sdev=sdev))(0)
            median = FIX(median(junk))
            maxval =  FIX(max(junk))
            minval =  FIX(min(junk))
         END

         Stats = STRARR(6)
         IF(state.unit EQ 1) THEN BEGIN
            Stats(0) = 'Avg: ' + STRTRIM(STRING(avg),2)
         END ELSE Stats(0) =  'Avg: *'
         Stats(1) = 'Min: ' + STRTRIM(STRING(minval),2)
         Stats(2) = 'Med: ' + STRTRIM(STRING(median),2)
         Stats(3) = 'Max: ' + STRTRIM(STRING(maxval),2)
         IF(state.unit EQ 1) THEN BEGIN
            Stats(4) = 'Dev: ' + STRTRIM(STRING(sdev),2)
         END ELSE Stats(4) = 'Dev: *'
         Stats(5) = 'Pos: ' + STRTRIM(STRING(Xlb,FORMAT='(I3)'),2) +$
          '  ' + STRTRIM(STRING(ylb),2)

         IF(state.unit EQ 0) THEN BEGIN
            pts = STRING(Image(pts),FORMAT='(I4)')
         END ELSE pts = STRING(UNPACK(IMAGE(pts)), FORMAT='(I5)')

         pts = REFORM(pts,MaskVal,MaskVal)
         IF(count GT 0) THEN BEGIN
            IF(State.unit EQ 0) THEN pts(negs) = "  * " ELSE pts(negs) =  "  *  "
         END
         dims = size(pts)

         Pts = Transpose(pts)
         newString=strarr(dims(1))
         FOR i=0,dims(1)-1 DO BEGIN
            newString(i) =  pts(dims(1)-i-1,0)
            FOR j=1,dims(2)-1 DO BEGIN
               newSTring(i) = newSTring(i) + pts(dims(1)-i-1,j)
            END
         END

         IF(State.unit EQ 0) THEN BEGIN
            WIDGET_CONTROL,Table,SET_VALUE=newstring,XSize=4*dims(1),YSize=dims(2)
            WIDGET_CONTROL,Stat,SET_VALUE=Stats,xsize = 4*dims(1)
         END ELSE BEGIN
            WIDGET_CONTROL,Table,SET_VALUE=newstring,XSize=6*dims(1),YSize=dims(2)
            WIDGET_CONTROL,Stat,SET_VALUE=Stats,xsize = 4*dims(1)
         END
      END
      ELSE: print,'detail event'
   END
END


;----------------------------------------------------------
; PURPOSE:
;  Creates and realizes an image_detail window.  This window
;  displays the pixel values in a specified region around
;  the current pixel.
;
; INPUTS:
;  Event structure
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  None
;
; COMMON BLOCKS:
;  XV_DERIVED_DATA
;  XV_FLAGS
;  XV_RECORD_DATA
;  XV_WIDS
;  XV_DETAIL
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_CREATE_IMAGE_DETAIL
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON XV_DETAIL, Base, Table, Stat, Close, Options, State, Heading

   IF XREGISTERED("XV_IMAGE_DETAIL") THEN RETURN

   state = {mask:9,mode:0,unit:1}
   Base = WIDGET_BASE(GROUP_LEADER=MainWid,/COLUMN,$
                      TITLE='Image Detail', TLB_FRAME_ATTR=1,$
                      Event_FUNC='XV_IMAGE_DETAIL_EVENT')

   Heading = WIDGET_LABEL(Base,/dynamic_resize,/align_center)
   Table = WIDGET_TEXT(Base,XSize = state.mask*4,ysize=state.mask)
   Stat = WIDGET_TEXT(Base,ysize=6)
   Options = WIDGET_BUTTON(Base,VALUE='Options')
   Close = WIDGET_BUTTON(Base,VALUE='Close')

   XV_REGISTER_VIEW_HANDLER, Base
   WIDGET_CONTROL, Base, /REALIZE
   XMANAGER,"XV_IMAGE_DETAIL",Base,/NO_BLOCK,CLEANUP='XV_CLEANUP'
   XV_IMAGE_DETAIL_EVENT,{id:Base,top:base,handler:0L}
END



;----------------------------------------------------------
; PURPOSE:
;  Event handler for the image_info window.  Basically
;  just destroys the window when the close button is
;  activated.
;
; INPUTS:
;  Event structure
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  None
;
; COMMON BLOCKS:
;  None
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_IMAGE_INFO_EVENT, event
   WIDGET_CONTROL,event.top,GET_UVALUE=wids

   IF(event.id EQ wids.close) THEN BEGIN
      WIDGET_CONTROL,event.top,/destroy
   END
END


;----------------------------------------------------------
; PURPOSE:
;  Creates and realizes an image_info window.  This window
;  displays information associated with the active image.
;
; INPUTS:
;  Event structure
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  None
;
; COMMON BLOCKS:
;  None
;
; PROCEDURE:
;  XV_DERIVED_DATA
;  XV_FLAGS
;  XV_RECORD_DATA
;  XV_WIDS
;  XV_FILE_DATA
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XV_CREATE_IMAGE_INFO
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount

   WIDGET_CONTROL, MainWid, GET_UVALUE=Wids

   isValid = WIDGET_INFO(Wids.IIWin,/VALID_ID)
   IF(isValid EQ 0) THEN BEGIN
      Wids.IIWin = WIDGET_BASE(GROUP_LEADER=MainWid,$
                               TITLE='Image Information', $
                               TLB_FRAME_ATTR=1,$
                               /COLUMN)
      text = WIDGET_TEXT(Wids.IIWin, VALUE=XV_GET_IMAGE_INFO(Fid,ImageNum),$
                         /scroll,ysize=50,xsize=60)

      close =  WIDGET_BUTTON(Wids.IIWIN, VALUE="Close")

      WIDGET_CONTROL, MainWid, SET_UVALUE=Wids
      WIDGET_CONTROL, Wids.IIWin, /REALIZE, SET_UVALUE={close:close, text:text}
      XMANAGER,"XV_IMAGE_INFO",Wids.IIwin,/NO_BLOCK
   END
END


PRO XV_UPDATE_IMAGE_INFO
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   WIDGET_CONTROL, MainWid, GET_UVALUE=MWids
   isValid = WIDGET_INFO(MWids.IIWin,/VALID_ID)
   IF(isValid NE 0) THEN BEGIN
      WIDGET_CONTROL, MWids.IIWin, GET_UVALUE=Wids
      WIDGET_CONTROL, Wids.text, update=0
      top_line =  WIDGET_INFO(Wids.text,/TEXT_TOP_LINE)
      WIDGET_CONTROL,Wids.text,SET_VALUE=XV_GET_IMAGE_INFO(Fid,ImageNum)
      widget_control,wids.text,update=1
   END
END

;----------------------------------------------------------
; PURPOSE:
;  Event handler for the XVIs application.  Primarily dispatches
;  various functions that are invoked via the pulldown menu.
;
; INPUTS:
;  Event structure
;
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  None
;
; COMMON BLOCKS:
;  None
;
; PROCEDURE:
;  XV_DERIVED_DATA
;  XV_FLAGS
;  XV_RECORD_DATA
;  XV_WIDS
;  XV_FILE_DATA
;
; MODIFICATION HISTORY:
;
;----------------------------------------------------------
PRO XVIS_EVENT, Event
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount

   WIDGET_CONTROL, GET_UVALUE = Wids, Event.top

   CASE event.id OF
      Wids.Open: XV_OPEN, Event
      Wids.Exit: XV_EXIT, Event
      Wids.Gif: BEGIN
         default_file = STRTRIM((str_sep(filename,"."))(0) + ".gif",2)
         giffile = dialog_pickfile(FILE=default_file, /WRITE)
         IF(giffile NE "") THEN BEGIN
            tvlct,r,g,b,/get
            WRITE_GIF, giffile, transpose(rotate(Image,1)), R,G,B
         END
      END
      Wids.BMP: BEGIN
         ifilename =  dialog_pickfile()
         IF(ifilename NE "") THEN BEGIN
            tvlct,r,g,b,/get
            write_bmp, ifilename, transpose(rotate(image,1)), r,g,b
         END
      END
      Wids.IDL: BEGIN
         ifilename =  dialog_pickfile()
         IF(ifilename NE "") THEN BEGIN
            save,bin_image,filename=ifilename
         END
      END
      Wids.Pict: BEGIN
         ifilename =  dialog_pickfile()
         IF(ifilename NE "") THEN BEGIN
            tvlct,r,g,b,/get
            write_Pict, ifilename, transpose(rotate(image,1)), R,g,b
         END
      END
      Wids.PPM: BEGIN
         ifilename =  dialog_pickfile()
         IF(ifilename NE "") THEN BEGIN
            write_PPM, ifilename, transpose(rotate(image,1))
         END
      END
      Wids.PS: BEGIN
         WIDGET_CONTROL, Wids.Zoom1, GET_UVALUE=Z1
         IF(Z1 EQ 1) THEN dims = 256 ELSE dims = 512
         WRITE_PS, transpose(rotate(Image,1)), dims
      END
      Wids.EPS: BEGIN
         WIDGET_CONTROL, Wids.Zoom1, GET_UVALUE=Z1
         IF(Z1 EQ 1) THEN dims = 256 ELSE dims = 512
         WRITE_PS, transpose(rotate(Image,1)), dims,/ENCAPSULATED
      END
      Wids.Undo:BEGIN
         Image = LastImage
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.ScaleI:BEGIN
         Tmp = Image
         Changed = XV_SCALE_INTENSITY(event.top)
         IF(Changed EQ 1) THEN BEGIN
            LastImage =  Tmp
         END
      END
      Wids.Smooth: BEGIN
         WIDGET_CONTROL, /HOURGLASS, SENSITIVE=0, Wids.CWin
         LastImage = Image
         XV_SMOOTH, Image
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL, HOURGLASS=0, /SENSITIVE, Wids.CWin
      END
      Wids.FillZ: BEGIN
         Tmp =  Image
         Changed = XV_FILL_ZEROS_DIALOG(event.top)
         IF(Changed EQ 1) THEN BEGIN
            LastImage =  Tmp
         END
      END
      Wids.FILLB: BEGIN
         Tmp =  Image
         Changed = XV_FILL_BYTES_DIALOG(event.top)
         IF(Changed EQ 1) THEN BEGIN
            LastImage =  Tmp
         END
      END
      Wids.Histogram: BEGIN
         LastImage = Image
         Image= Hist_EQUAl(Image)
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.Median: BEGIN
         Image=MEDIAN(Image,3)
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.Color: BEGIN
         XV_COLORS, GROUP=Event.Top, Range = CURR_LIMIT, $
          NotifyID=[DrawWid,event.top], NColors= !D.table_Size
      END
      Wids.Redraw: XV_UPDATE_VIEW_WINDOW
      Wids.SubCRay: BEGIN
         tmp =  Image
         changed =  XV_SUB_COSMIC_DIALOG(Event.top)
         IF(changed = 1) THEN BEGIN
            LastImage =  tmp
         END
      END
      Wids.SubDG:BEGIN
         LastImage =  Image
         WIDGET_CONTROL, /HOURGLASS, SENSITIVE=0, Wids.CWin
         XV_DAYGLOW_SUBTRACT, Image, Record, LookVector
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL, HOURGLASS=0, /SENSITIVE, Wids.CWin
      END
      Wids.SubSlope: BEGIN
         XV_SLOPE_SUB_DIALOG,MainWid
      END
      Wids.Trans: BEGIN
         LastImage = Image
         Image = Transpose(Image)
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.FlipV: BEGIN
         LastImage = Image
         Image = transpose(rotate(image,1))
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.FlipH: BEGIN
         LastImage = Image
         Image = rotate(transpose(image),1)
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.Flatf: BEGIN
         params = XV_FLAT_FIELD_DIALOG(event.top)
         IF(Params.New EQ 1) THEN BEGIN
            WIDGET_CONTROL,/HOURGLASS, SENSITIVE=0, Wids.CWin
            LastImage = image
            XV_FLAT_FIELD,Image,Params.FF,Params.IBias,Params.Shift
            WIDGET_CONTROL,HOURGLASS=0,/SENSITIVE, Wids.CWin
            XV_UPDATE_VIEW_WINDOW
         END
      END
      Wids.RemWeave: BEGIN
         WIDGET_CONTROL,/HOURGLASS, SENSITIVE=0, Wids.CWin
         LastImage = Image
         XV_REMOVE_WEAVE,Image
         WIDGET_CONTROL,HOURGLASS=0,/SENSITIVE, Wids.CWin
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.BTape: BEGIN
         tmp =  Image
         Changed =  XV_BLACKTAPE_DIALOG(event.top)
         IF(Changed EQ 1) THEN BEGIN
            LastImage =  tmp
         END
      END
;      Wids.Date1Bid: BEGIN
;         WIDGET_CONTROL, Wids.Date1Bid, SET_UVALUE=1
;         WIDGET_CONTROL, Wids.Date2Bid, SET_UVALUE=0
;         StartTime = record.time_pb5
;         StartTime[2] = StartTime[2] - FIX(record.int_time_half) + 1000 ; add 1 second (1000 msec)
;         WIDGET_CONTROL, Wids.StartDateBid, SET_VALUE="Start : " + DateToString(StartTime,1)
;         WIDGET_CONTROL, Wids.CenterDateBid, SET_VALUE="Center: " + DateToString(record.time_pb5,1)
;      END
;      Wids.Date2Bid: BEGIN
;         WIDGET_CONTROL, Wids.Date1Bid, SET_UVALUE=0
;         WIDGET_CONTROL, Wids.Date2Bid, SET_UVALUE=1
;         StartTime = record.time_pb5
;         StartTime[2] = StartTime[2] - FIX(record.int_time_half) + 1000 ; add 1 second (1000 msec)
;         WIDGET_CONTROL, Wids.StartDateBid, SET_VALUE="Start : " + DateToString(StartTime,1)
;         WIDGET_CONTROL, Wids.CenterDateBid, SET_VALUE="Center: " + DateToString(record.time_pb5,1)
;      END
      Wids.Zoom1: BEGIN
         WIDGET_CONTROL,Wids.Zoom1,SET_UVALUE=1
         WIDGET_CONTROL,Wids.Zoom2,SET_UVALUE=0
         WIDGET_CONTROL, ViewWid, XSIZE=256, YSIZE=256
         WIDGET_CONTROL, DrawWid, XSIZE=256, YSIZE=256
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.Zoom2: BEGIN
         WIDGET_CONTROL,Wids.Zoom2,SET_UVALUE=1
         WIDGET_CONTROL,Wids.Zoom1,SET_UVALUE=0
         WIDGET_CONTROL, ViewWid, XSIZE=512, YSIZE=512
         WIDGET_CONTROL, DrawWid ,XSIZE=512, YSIZE=512
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.Zoom3: BEGIN
         WIDGET_CONTROL, Wids.Zoom1, SET_UVALUE=0
         WIDGET_CONTROL, Wids.Zoom2, SET_UVALUE=0
         WIDGET_CONTROL, Wids.Zoom3, SET_UVALUE=1
         WIDGET_CONTROL, ViewWid, XSIZE=768, YSIZE=768
         WIDGET_CONTROL, DrawWid, XSIZE=768, YSIZE=768
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.FINFO: BEGIN
         XV_CREATE_FILE_INFO_PANEL,Event
      END
      Wids.SurveyBid: BEGIN
         XV_CREATE_SURVEY, Event.top
      END
      Wids.ZWin: BEGIN
         XV_ZOOMER,Event.top
      END
      Wids.SurfWin:BEGIN
         XV_SURFER,Event.top
      END
      Wids.RCBid: BEGIN
         XV_RC,event.top,Image
      END
      Wids.Detail: BEGIN
         XV_CREATE_IMAGE_DETAIL
      END
      Wids.IINFO: BEGIN
         XV_CREATE_IMAGE_INFO
      END
      Wids.HIST: BEGIN
         XV_PLOT_HISTOGRAM, Event.top, Image
      END
      Wids.SolarZ: BEGIN
         Tmp =  Image
         Changed =  XV_SOLAR_ZENITH_DIALOG(event.top)
         IF(Changed EQ 1) THEN BEGIN
            LastImage = Tmp
         END
      END
      Wids.Coord: BEGIN
         XV_CRD, event.top
      END
      Wids.STATIC: BEGIN
         XV_STATIC_IMAGE_VIEW, MainWid, Image, ImageNum
      END
      Wids.StackBid: BEGIN
         XV_CREATE_STACK_WINDOW, event.top
      END
      Wids.XPand: BEGIN
         WIDGET_CONTROL, Wids.XPAND, GET_UVALUE=XPand
         IF(XPand EQ 0) THEN BEGIN
            Flags.XPand =  1
            newValue =  "View Compressed Values"
         END ELSE BEGIN
            Flags.XPand = 0
            newVAlue =  "View Uncompressed Values"
         END
         WIDGET_CONTROL, Wids.XPAND, SET_UVALUE=FLags.XPand, SET_VALUE=newValue
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.PolarBid: BEGIN
         WIDGET_CONTROL, /HOURGLASS, SENSITIVE=0, Event.top
         LastImage =  Image
         Image =  MapToPolar()
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL, HOURGLASS=0, /SENSITIVE, Event.top
      END
      Wids.InvBid:BEGIN
         LastImage =  Image
         Image =  abs(Image-255)
         XV_UPDATE_VIEW_WINDOW
      END
      Wids.SubHL: BEGIN
         WIDGET_CONTROL, /HOURGLASS, SENSITIVE=0, Wids.CWin
         LastImage =  Image
         XV_HORIZ_SMOOTH, Image
         XV_UPDATE_VIEW_WINDOW
         WIDGET_CONTROL, HOURGLASS=0, /SENSITIVE, Wids.CWin
      END
      ELSE: BEGIN
         WIDGET_CONTROL, Event.id, GET_VALUE=value
         print,'XVIS_EVENT::Unimplemented Option: ',$
          tag_names(event,/structure_name),value
      END
   END
END

;----------------------------------------------------------
; PURPOSE:
;  Initializes the XVIS application.
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;  ALL_COLORS	        == If set, XVIS attempts to enforce
;                          the use of a 256 entry color table.  If not
;                          set, XVIS uses only available colors.
;  FONT                 == if NOT set XVIS attempts to find a
;                          courier font.  Set FONT to the name of
;                          the desired font for use by XVIS.  Note
;                          that fixed-width fonts work better since
;                          tables only line up correctly with fixed
;                          width fonts.
;
; OUTPUTS:
;  None
;
; SIDE EFFECTS:
;  None
;
; COMMON BLOCKS:
;  None
;
; PROCEDURE:
;  XV_DERIVED_DATA
;  XV_FLAGS
;  XV_RECORD_DATA
;  XV_WIDS
;  XV_FILE_DATA
;
; MODIFICATION HISTORY:
;       18-AUG-1999 RLD Had to add a lone "WDelete, 0" at the end of this
;                       function because the font calls were apparently
;                       generating an open window call...
;                       If the font calls are removed, take the delete too
;
;----------------------------------------------------------
PRO INITIALIZE_XVIS, ALL_COLORS=all_colors, Font=font
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount
   COMMON COLORS, rr,gg,bb,rc,gc,bc
   COMMON XV_CURSOR, Xsc, Ysc, Xim, Yim, Xcd, Ycd, Xlb, Ylb

   IF(N_ELEMENTS(FULL_COLOR) EQ 0) THEN FULL_COLOR = 0

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Initialize some COMMON block variables
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   LastImage = BYTARR(256,256)
   ImageNum = 0
   ROI = [-1]
   Handlers = LONARR(10)
   HCount = 0
   Xsc = 0
   Ysc = 0
   Filename = ''
   MaxRecs = 1
   ViewWid = 0L
   DrawWid = 0L

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;; Only way I can figure how to get the current path
   ;;; change to Login directory and change back
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   cd,"",current=path
   CD,PATH
   FLAGS = { loaded:0,$
             LV:0,$
             ALT:0,$
             ALTLS:0,$
             PHI:0,$
             SZA:0,$
             LOC:0,$
             GLAT:0,$
             GLON:0,$
             XPAND:0,$
             CDF_COLOR:1,$
             DIST:0}

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Setup the number of colors in the color table.
   ;; If ALL_COLORS is set then ensure 256 colors;
   ;; otherwise, possibly reduce the colors.
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   IF Keyword_SET(ALL_COLORS) THEN BEGIN
      Window, /Free, /Pixmap, Colors=256, XSize=1, YSize=1
      IF(!D.TABLE_SIZE LT 256) THEN BEGIN
         msg =  ['XVIS: 256 colors have been requested but',$
                 'IDL has already been initialized to use', $
                 'less than 256 colors.  Exit IDL and', $
                 'restart XVIS to ensure the use of 256', $
                 'colors in the color table']
         junk = dialog_message(msg,/error)
      END
      WDelete, !D.Window
   END ELSE BEGIN
      Window, /Free, /Pixmap, XSize=1, YSize=1
      WDelete, !D.Window
      IF(!D.TABLE_SIZE NE 256) THEN BEGIN
         msg =  'XVIS: Using ' + STRING(!D.TABLE_SIZE) + ' colors.'
         print,msg
      END
   END

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Initialize the radius function.  Table lookup is for speed.
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   INITIALIZE_EARTH_RADIUS

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Initialize the color table
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   tvlct,rr,gg,bb,/GET
   rc = rr
   gc = gg
   bc = bb
   tsize = n_elements(rr)
   Curr_Limit =  [0,tsize-1]

;  18-AUG-1999 RLD
;  Apparently this code now generates an empty window that is orphaned...
;  Added a "wdelete, 0" to delete the window.
;  All font code now commented out since the font change is never used anyway...
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Set the default font -- looks for a courier font
   ;; cause it's fixed-width and tables line up only when a
   ;; fixed-width font is used.
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   IF(NOT KEYWORD_SET(FONT)) THEN FONT = GET_COURIER_FONT()
;   widget_control,default_font= font
;   WDelete, 0

END


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; NAME:
;       XVIS
;
; PURPOSE:
;  This is the main driver for viewing/modifying VIS data
;
; CALLING SEQUENCE:
;  XVIS
;
; INPUTS:
;  None
;
; KEYWORD PARAMETERS:
;   ALL_COLORS		 == use a full 256 entry color table if set,
;                            use only the colors available otherwise.
;   FONT                 == specify a font to use in the application.
;                           fixed-width fonts are preferable.
;
; OUTPUTS:
;  None
;
; COMMON BLOCKS:
;
; MODIFICATION HISTORY:
;       Written by:     Kenny Hunt 7/8/97
;       Modified:   18-AUG-1999 RLD Added support for 24- and 8-bit
;                                   displays at the same time and updated
;                                   version to v1.6
;		    27-MAR-2001 MRD made using available colors the default; 
;				    changed color option keyword from 
;				    "USE_AVAILABLE_COLORS" to "ALL_COLORS";
;				    updated version to v1.7
;		    18-FEB-2005 MRD implemented REMOVE_WEAVE option,
;                                   changed COSMIC_RAY_SUBTRACT threshold
;                                   to 40, and updated version to v1.8 
;		    04-MAY-2005 MRD changed to get the look vector array from
;                                   file LV.DAT if available and to calculate
;                                   the rotation matrix instead of using the
;                                   CDF variable; updated version to v1.9 
;
;-------------------------------------------------------------
PRO XVIS, ALL_COLORS=all_colors, FONT=font
   COMMON XV_DERIVED_DATA, LookV_GCI, ALTLS, Alts, Phis, SZAs, Locs, Glats, Glons
   COMMON XV_FLAGS, Flags
   COMMON XV_RECORD_DATA, Image, Record, ROI, LastImage, Curr_Limit, Record2
   COMMON XV_FILE_DATA, Path, Filename, Fid, MaxRecs, ImageNum, LookVector, Header, UnDistort
   COMMON XV_WIDS, MainWid, ViewWid, DrawWid, Handlers, HCount

;RLD 18-AUG-1999    Added this line to allow operation on XWindow
;                   TrueColor & PseudoColor Displays
   Device, Decomposed = 0
   IF XREGISTERED("XVIS") THEN RETURN

   MainWid = WIDGET_BASE(TITLE="XVIS v1.9 (04-MAY-2005)", /ROW, MBAR=MainMenu,$
                         TLB_FRAME_ATTR=1,RESOURCE_NAME='xvis')

   Initialize_XVIS, ALL_COLORS=all_colors, Font=font
;   WDelete, 0

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Create Main Menu PullDowns
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   FileMenu = WIDGET_BUTTON(MainMenu, VALUE="File", /MENU)
   EditMenu = WIDGET_BUTTON(MainMenu, VALUE="Edit", /MENU)
   ViewMenu = WIDGET_BUTTON(MainMenu, VALUE="View", /MENU)
   WindowsMenu = WIDGET_BUTTON(MainMenu, VALUE="Windows", /MENU)

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Create 'FILE' SubMenu
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   OpenBid  = WIDGET_BUTTON(FileMenu,VALUE="Open...")
   SaveAsBid = WIDGET_BUTTON(FileMenu,/SEPARATOR,/MENU,VALUE="Save As ...")
   ExitBid  = WIDGET_BUTTON(FileMenu,/SEPARATOR,VALUE="Exit")

   BMPBid =  WIDGET_BUTTON(SaveAsBid,VALUE="BMP")
   GifBid = WIDGET_BUTTON(SaveAsBid,VALUE="GIF")
   IDLBid =  WIDGET_BUTTON(SaveAsBid,VALUE="IDL Binary")
   PictBid =  WIDGET_BUTTON(SaveAsBid,VALUE="Pict")
   PSBid = WIDGET_BUTTON(SaveAsBid,VALUE="Postscript")
   PPMBid =  WIDGET_BUTTON(SaveAsBid, VALUE="PPM")
   EPSBid = WIDGET_BUTTON(SaveAsBid,VALUE="Encapsulated PS")

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Create 'EDIT' SubMenu
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   UndoBid = WIDGET_BUTTON(EditMenu, VALUE="Undo Last Filter",UVALUE=0)
   BTapeBid = WIDGET_BUTTON(EditMenu, /SEPARATOR,VALUE="BlackTape")
   FillZBid = WIDGET_BUTTON(EditMenu, VALUE="Fill Zeros")
   FillBBid = WIDGET_BUTTON(EditMenu, VALUE="Fill Bytes")
   FlatFBid = WIDGET_BUTTON(EditMenu, VALUE="Flat Field")
   HistBid = WIDGET_BUTTON(EditMenu, VALUE="Histogram Equalize")
   MedianBid = WIDGET_BUTTON(EditMenu, VALUE="Median")
   ScaleIBid = WIDGET_BUTTON(EditMenu, VALUE="Scale Intensity")
   SmoothBid = WIDGET_BUTTON(EditMenu, VALUE="Smooth")
   SolarZBid = WIDGET_BUTTON(EditMenu, VALUE="Solar Zenith")
   SubCRayBid = WIDGET_BUTTON(EditMenu, VALUE="Subtract Cosmic Ray")
   SubDGBid = WIDGET_BUTTON(EditMenu, VALUE="Subtract DayGlow")
   SubHLBid = WIDGET_BUTTON(EditMenu, VALUE="Smooth Horizontal Lines")
   SubSlopeBid = WIDGET_BUTTON(EditMenu, VALUE="Subtract Slope")
   RemWeaveBid = WIDGET_BUTTON(EditMenu, VALUE="Remove Weave")


   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Create 'VIEW' SubMenu
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   SizeBid = WIDGET_BUTTON(ViewMenu, VALUE="Zoom",/MENU)
   ColorBid = WIDGET_BUTTON(ViewMenu, VALUE="Edit ColorBar",/SEPARATOR)
   XPandBid = WIDGET_BUTTON(ViewMenu, VALUE="View Uncompressed Values", /SEPARATOR, UVALUE=Flags.XPand)
;   DateBid =  WIDGET_BUTTON(ViewMenu, VALUE="Date Format", /SEPARATOR,/MENU)
   PolarBid =  WIDGET_BUTTON(ViewMenu, VALUE="Create Polar View",/SEPARATOR)
   TransposeBid = WIDGET_BUTTON(ViewMenu, VALUE="Transpose",/SEPARATOR)
   FlipVBid = WIDGET_BUTTON(ViewMenu, VALUE="Flip Vertical")
   FlipHBid = WIDGET_BUTTON(ViewMEnu, VALUE="Flip Horizonal")
   InvBid =  WIDGET_BUTTON(ViewMEnu, VALUE="Invert Values")
   RedrawBid = WIDGET_BUTTON(ViewMenu, VALUE="Redraw", /SEPARATOR)

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Create 'VIEW.SIZE' SubMenu
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   Zoom1Bid = WIDGET_BUTTON(SizeBid, VALUE='1X', UVALUE=1)
   Zoom2Bid = WIDGET_BUTTON(SizeBid, VALUE='2X', UVALUE=0)
   Zoom3Bid = WIDGET_BUTTON(SizeBid, VALUE='3X', UVALUE=0)

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Create 'VIEW.DATE' SubMenu
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Date1Bid = WIDGET_BUTTON(DateBid, VALUE="MONTH DAY YEAR", UVALUE=0)
;   Date2Bid = WIDGET_BUTTON(DateBid, VALUE="YEAR DOY", UVALUE=1)

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Create 'WINDOWS' SubMenu
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   CoordBid =  WIDGET_BUTTON(WindowsMenu, VALUE="Coordinate Info")
   FInfoBid = WIDGET_BUTTON(WindowsMenu, VALUE="File Info")
   HistogramBid = WIDGET_BUTTON(WindowsMenu, VALUE="Histogram")
   DetailBid = WIDGET_BUTTON(WindowsMenu, VALUE="Image Detail")
   IInfoBid = WIDGET_BUTTON(WindowsMenu, VALUE="Image Info")
   RCBid = WIDGET_BUTTON(WindowsMenu, VALUE="Row/Col Plots")
   StackBid =  WIDGET_BUTTON(WindowsMenu, VALUE="Multi-Image ops")
   StaticImageBid = WIDGET_BUTTON(WindowsMenu, VALUE="Static Image")
   SurfWBid =  WIDGET_BUTTON(WindowsMenu, VALUE="Surface Detail")
   SurveyBid =  WIDGET_BUTTON(WindowsMenu, VALUE="Survey Window")
   ZWin = WIDGET_BUTTON(WindowsMenu, VALUE="Zoomer")

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Create control panel
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   OpFrame = WIDGET_BASE(MainWid,/COLUMN)

   ControlPanel = XV_CREATE_CONTROL_PANEL(OpFrame)

   StartDateBid =  WIDGET_LABEL(OpFrame, Frame=3, /dynamic_resize, /align_left,$
                                VALUE="Start  Time")
   CenterDateBid = WIDGET_LABEL(OpFrame, Frame=3, /dynamic_resize, /align_left,$
                                VALUE="Center Time")

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Create the row_col position
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   RowCol = WIDGET_LABEL(OpFrame,FRAME=3,xsize=300,/align_left,$
                         VALUE="(NULL, NULL)")

   Wids = { Open:OpenBid,$
            Exit:ExitBid,$
            CWin:ControlPanel,$
            RowCol:RowCol,$
            StartDateBid:StartDateBid,$
            CenterDateBid:CenterDateBid,$
            RCBid:RCBid,$
            StackBid:StackBid,$
            IIWin:0L,$
            FIWin:0L,$
            Coord:CoordBid,$
            Detail:DetailBid,$
            BMP:BMPBid,$
            Gif:GifBid,$
            Idl:IdlBid,$
            Pict:PictBid,$
            PS:PSBid,$
            PPM:PPMBid,$
            Color:ColorBid,$
            Undo:UndoBid,$
            EPS:EPSBid,$
            BTape:BTapeBid,$
            FillZ:FillZBid,$
            FillB:FillBBid,$
            FlatF:FlatFBid,$
	    RemWeave:RemWeaveBid,$
            Histogram:HistBid,$
            Median:MedianBid,$
            ScaleI:ScaleIBid,$
            Smooth:SmoothBid,$
            SolarZ:SolarZBid,$
            SubCRay:SubCRayBid,$
            SubDG:SubDGBid,$
            SubHL:SubHLBid,$
            Trans:TransposeBid,$
            FlipH:FlipHBid,$
            FlipV:FlipVBid,$
            InvBid:InvBid,$
            SubSlope:SubSlopeBid,$
            Zoom1:Zoom1Bid,$
            Zoom2:Zoom2Bid,$
            Zoom3:Zoom3Bid,$
            Redraw:RedrawBid,$
            FInfo:FInfoBid,$
            IInfo:IInfoBid,$
            Hist:HistogramBid,$
            HWin:0L,$
            EMenu:EditMenu,$
            VMenu:ViewMEnu,$
            WMenu:WindowsMenu,$
            ZWin:ZWin,$
            SurfWin:SurfWBid,$
            SurveyBid:SurveyBid,$
            XPand:XPandBid,$
;            date1bid:date1bid,$
;            date2bid:date2bid,$
            PolarBid:PolarBid,$
            Static:StaticImageBid}

   WIDGET_CONTROL, MainWid, /REALIZE, SET_UVALUE= Wids
   WIDGET_CONTROL, EditMenu, SENSITIVE=0
   WIDGET_CONTROL, ViewMenu, SENSITIVE=0
   WIDGET_CONTROL, WindowsMenu, SENSITIVE=0

   XManager, "XVIS", MainWid, /NO_BLOCK
END


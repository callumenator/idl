Pro Tvcircle, radius, xc, yc, color, COLOR = TheColor, $
          THICK = thick, DATA= data
;+
; NAME:
;	TVCIRCLE
; PURPOSE:
;	Draw a circle or circles of specified radius centered on the cursor, or 
;	at specified position
;
; CALLING SEQUENCE:
;	TVCIRCLE, rad, x, y, color, [ COLOR = , THICK =, /DATA ]         
;
; INPUTS:
;	RAD - radius of circle(s) to be drawn, scalar
;
; OPTIONAL INPUT:
;	X - x position for circle center, vector or scalar, device coordinates
;	Y - y position for circle center, vector or scalar
;		If X and Y are not specified then program will draw circle at
;		at the current cursor position
;	COLOR - intensity value (0-255) used to draw the circle, Default =
;		!P.COLOR.   User can specify color using either this parameter
;		 or the COLOR keyword.  
;
; OPTIONAL KEYWORD INPUTS:
;	THICK - thickness of the drawn circle,  default = !P.THICK (=1)
;	DATA - if this keyword is set and non-zero, then the box width and
;		X,Y position center are interpreted as being in DATA 
;		coordinates.   Note that data coordinates must be previously
;		defined (with a PLOT or CONTOUR call).
;	COLOR - Intensity value used to draw the circle.  Default = !P.COLOR
;
; OUTPUTS:
;	None
;
; RESTRICTIONS:
;	(1) TVCIRCLE does not check whether it writes off of the edge of the 
;		display
;	(2) Some round-off error may occur when non-integral values are 
;		supplied for both the radius and the center coordinates
;
; METHOD:
;	The method used is that of Michener's, modified to take into account
;	the fact that IDL plots arrays faster than single points.   See
;	"Fundamental of Interactive Computer Graphics" by Foley and Van Dam"
;	p. 445 for the algorithm.
;
; REVISON HISTORY:
;	Original version   written by B. Pfarr  STX   10-88 
;	Major rewrite adapted from CIRCLE by Allyn Saroyan   LNLL
;		Wayne Landsman   STX     Sep. 91
;	Added DATA keyword   Wayne Landsman  HSTX    June 1993
;-

   On_Error, 2   ; Return to caller

   if N_params() LT 1 then begin
         print, $
         'Syntax - tvcircle, rad, [ xc, yc, color, COLOR = ,THICK =, /DATA ]'
         return
   endif

   if N_elements(radius) NE 1 then message, $
          'ERROR - Circle radius (first parameter) must be a scalar'
   irad = fix(radius + 0.5)

   x = 0
   y = irad 
   d = 3 - 2 * irad

   if not keyword_set(TheColor) then begin
      IF N_Elements( Color ) eq 0 THEN Color = !P.COLOR
   endif else color = TheColor

   if not keyword_set(THICK) then thick = !P.THICK
   
  if N_params() LT 3 then begin
     cursor, xcen, ycen, /DEVICE, /NOWAIT
     if (xcen LT 0) or (ycen LT 0) then begin
       message,'Position cursor in window ' + strtrim(!D.WINDOW,2) + $
              ' -- then hit mouse button',/INF
         cursor, xcen, ycen, /DEVICE, /WAIT
         message,'Circle is centered at (' + strtrim(xcen,2) + ',' + $
		strtrim(ycen,2) + ')',/INF
     endif
     N_circle = 1

  endif else begin

      N_circle = min( [ N_elements(xc), N_elements(yc) ] )
      xcen = fix(xc + 0.5)  & ycen = fix(yc+0.5)

  endelse

   ; Find the x and y coordinates for one eighth of a circle.
   ; The maximum number of these coordinates is the radius of the circle.

   xHalfQuad = Make_Array( irad + 1, /Int, /NoZero )
   yHalfQuad = xHalfQuad

   path = 0

   WHILE x lt y $
   DO BEGIN

      xHalfQuad(path) = x
      yHalfQuad(path) = y

      path = path + 1

      IF d lt 0 $
      THEN d = d + (4*x) + 6 $
      ELSE BEGIN

           d = d + (4*(x-y)) + 10
           y = y - 1

           END

      x = x + 1

      END

   IF x eq y $
   THEN BEGIN ; Fill in last point

        xHalfQuad(path) = x
        yHalfQuad(path) = y

        path = path + 1

        END ; Filling in last point

   ; Shrink the arrays to their correct size

   xHalfQuad = xHalfQuad( 0:path-1 )
   yHalfQuad = yHalfQuad( 0:path-1 )

   ; Convert the eighth circle into a quadrant

   xQuad = [ xHalfQuad, Rotate(yHalfQuad, 5) ]
   yQuad = [ yHalfQuad, Rotate(xHalfQuad, 5) ]

   ; Prepare for converting the quadrants into a full circle

   xQuadRev = Rotate( xQuad(0:2*path-2), 5 )
   yQuadRev = Rotate( yQuad(0:2*path-2), 5 )

   ; Create full-circle coordinates

   x = [ xQuad, xQuadRev, -xQuad(1:*), -xQuadRev ]
   y = [ yQuad, -yQuadRev, -yQuad(1:*), yQuadRev ]

   ; Plot the coordinates about the given center

   for i = 0, N_circle-1 do begin

    if keyword_set(DATA) then $ 
      PlotS, x + xcen(i), y+ ycen(i) , COLOR = Color, /DATA, THICK = thick $
    else $
      PlotS, x + xcen(i), y+ ycen(i) , COLOR = Color, /DEV, THICK = thick

   endfor
   Return

End; TVcircle

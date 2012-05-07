;+
; NAME:
;  PSWINDOW
;
; PURPOSE:
;  This function is used to calculate the size of a PostScript
;  window that has the same aspect ratio (ratio of height to
;  width) as the current display graphics window. It creates
;  the largest possible PostScript output window with the
;  desired aspect ratio. This assures that graphics output
;  looks similar, if not identical, to PostScript output.
;
; CATEGORY:
;  Graphics.
;
; CALLING SEQUENCE:
;
;  pageInfo = PSWINDOW()
;
; INPUTS:
;  None.
;
; KEYWORD PARAMETERS:
;  CM: Normally the structure value that is returned from this
;  function reports its values in inches. Setting this keyword
;  causes the return values to be in units of centimeters.
;
;  LANDSCAPE: Normally this function assumes a PostScript window
;  in Portrait mode. Setting this keyword assumes you want
;  the graphic in Landscape mode.
;
;  MARGIN: Normally this function creates the largest possible
;  PostScript window of the specified aspect ratio that can fit
;  on an 8.5 x 11 inch PostScript page. The margin is an amount
;  subtracted from the page size before the output window is sized.
;  A default margin of 0.5 is used to assure that the page can be
;  printed on most PostScript printers. The value should be
;  specified in the same units the function returns.
;
; OUTPUTS:
;  pageInfo: The output value is a named structure defined like
;  this:
;
;     pageInfo = {PSWINDOW_STRUCT, XSIZE:0.0, YSIZE:0.0, $
;        XOFSET:0.0, YOFFSET:0.0, INCHES:0, PORTRAIT:0, LANDSCAPE:0}
;
;  The units of the four size fields are inches unless the CM
;  keyword is set.
;
; RESTRICTIONS:
;  The aspect ratio of the current graphics window is calculated
;  like this:
;
;     aspectRatio = FLOAT(!D.Y_VSIZE) / !D.X_VSIZE
;
;  A PostScript page of 8.5 x 11.0 inches is assumed.
;
; EXAMPLE:
;  To create a PostScript output window with the same aspect
;  ratio as the curently active display window, type:
;
;     sizes = PSWINDOW()
;     SET_PLOT, 'PS'
;     DEVICE, XSIZE=sizes.xsize, YSIZE=sizes.ysize, $
;         XOFFSET=sizes.xoffset, YOFFSET=sizes.yoffset, INCHES=sizes.inches
;
; MODIFICATION HISTORY:
;  Written by: David Fanning, November 1996.
;       Fixed a bug in which the YOFFSET was calculated incorrectly
;          in Landscape mode. 12 Feb 97.
;       Took out a line of code that wasn't being used. 14 Mar 97.
;       Added correct units keyword to return structure. 29 JUN 98. DWF
;       Fixed a bug in how landscape offsets were calculated. 19 JUL 99. DWF.
;       Fixed a bug in the way margins were used to conform to my
;          original conception of the program. 19 JUL 99. DWF.
;       Added Landscape and Portrait fields to the return structure. 19 JUL 99. DWF.
;-

FUNCTION PSWINDOW, LANDSCAPE=landscape, CM=cm, MARGIN=margin

   ; Get the page sizes.

IF KEYWORD_SET(landscape) THEN BEGIN
   IF KEYWORD_SET(cm) THEN BEGIN
      pageXsize = 11.0 * 2.54
      pageYsize = 8.5 * 2.54
      inches = 0
   ENDIF ELSE BEGIN
      pageXsize = 11.0
      pageYsize = 8.5
      inches = 1
   ENDELSE
   landscape = 1
   portrait = 0
ENDIF ELSE BEGIN
   IF KEYWORD_SET(cm) THEN BEGIN
      pageXsize = 8.5 * 2.54
      pageYsize=11.0 * 2.54
      inches = 0
   ENDIF ELSE BEGIN
      pageXsize = 8.5
      pageYsize=11.0
      inches = 1
   ENDELSE
   landscape = 0
   portrait = 1
ENDELSE

   ; Determine the margin of the window.

IF N_ELEMENTS(margin) EQ 0 THEN $
   IF KEYWORD_SET(cm) THEN margin = 0.5 * 2.54 ELSE margin = 0.5 $
   ELSE IF margin LT 0.5 OR margin GE (pageXsize > pageYsize) THEN $
   IF KEYWORD_SET(cm) THEN margin = 0.5 * 2.54 ELSE margin = 0.5

   ; Get the aspect ratio of the current display window.

aspectRatio = FLOAT(!D.Y_VSIZE) / !D.X_VSIZE

   ; Fit to the largest plot possible.

xsize = pageXsize - (2 * margin)
ysize = xsize * aspectRatio
IF ysize GT pageYsize THEN BEGIN
   ysize = pageYsize - (2 * margin)
   xsize = ysize / aspectRatio
ENDIF

   ; Calculate the offsets.

IF KEYWORD_SET(landscape) THEN BEGIN
   xoffset = (pageYsize - ysize) / 2.0
   yoffset = pageXsize - ((pageXsize - xsize) / 2.0)
ENDIF ELSE BEGIN
   xoffset = (pageXsize - xsize) / 2.0
   yoffset = (pageYsize - ysize) / 2.0
ENDELSE

RETURN, {PSWINDOW_STRUCT, XSIZE:xsize, YSIZE:ysize, $
   XOFFSET:xoffset, YOFFSET:yoffset, INCHES:inches, $
   PORTRAIT:portrait, LANDSCAPE:landscape}

END

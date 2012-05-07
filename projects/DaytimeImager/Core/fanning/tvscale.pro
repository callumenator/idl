;+
; NAME:
;     TVSCALE
;
; PURPOSE:
;     This purpose of TVSCALE is to allow you to display an image
;     on the display or in a PostScript file in a particular position.
;     The position is specified by means of the POSITION keyword. In
;     this respect, TVSCALE works like other IDL graphics commands.
;     Moreover, the TVSCALE command works identically on the display
;     and in a PostScript file. You don't have to worry about how to
;     "size" the image in PostScript. The output on your display and
;     in the PostScript file will be identical. The major advantage of
;     TVSCALE is that it can be used in a natural way with other IDL
;     graphics commands in resizeable IDL graphics windows. TVSCALE
;     is a replacement for TVSCL. In addition, you can use the TOP
;     and BOTTOM keywords to define a particular set of number to
;     scale the data to. The algorithm used is this:
;
;         TV. BytScl(image, TOP=top-bottom) + bottom
;
;     Note that if you scale the image between 100 and 200, that
;     there are 101 possible pixel values. So the proper way to
;     load colors would be like this:
;
;       LoadCT, NColors=101, Bottom=100
;       TVSCALE, image, Top=200, Bottom=100
;
;     Alternatively, you could use the NCOLORS keyword:
;
;       LoadCT, NColors=100, Bottom=100
;       TVSCALE, image, NColors=100, Bottom=100
;
; AUTHOR:
;       FANNING SOFTWARE CONSULTING:
;       David Fanning, Ph.D.
;       2642 Bradbury Court
;       Fort Collins, CO 80521 USA
;       Phone: 970-221-0438
;       E-mail: davidf@dfanning.com
;       Coyote's Guide to IDL Programming: http://www.dfanning.com
;
; CATEGORY:
;     Graphics display.
;
; CALLING SEQUENCE:
;
;     TVSCALE, image
;
; INPUTS:
;     image:    A 2D or 3D image array. It does not have to be byte data.
;
;       x  :    The X position of the lower-left corner of the image.
;               This parameter is only recognized if the TVSCL keyword is set.
;
;       y  :    The Y position of the lower-left corner of the image.
;               This parameter is only recognized if the TVSCL keyword is set.
;
; KEYWORD PARAMETERS:
;     BOTTOM:   The image is scaled so that all displayed pixels have values
;               greater than or equal to BOTTOM and less than or equal to TOP.
;               The value of BOTTOM is 0 by default.
;
;     ERASE:    If this keyword is set an ERASE command is issued
;               before the image is displayed. Note that the ERASE
;               command puts the image on a new page in PostScript
;               output.
;
;     _EXTRA:   This keyword picks up any TV keywords you wish to use.
;
;     KEEP_ASPECT_RATIO: Normally, the image will be resized to fit the
;               specified position in the window. If you prefer, you can
;               force the image to maintain its aspect ratio in the window
;               (although not its natural size) by setting this keyword.
;               The image width is fitted first. If, after setting the
;               image width, the image height is too big for the window,
;               then the image height is fitted into the window. The
;               appropriate values of the POSITION keyword are honored
;               during this fitting process. Once a fit is made, the
;               POSITION coordiates are re-calculated to center the image
;               in the window. You can recover these new position coordinates
;               as the output from the POSITION keyword.
;
;     MARGIN:   A single value, expressed as a normalized coordinate, that
;               can easily be used to calculate a position in the window.
;               The margin is used to calculate a POSITION that gives
;               the image an equal margin around the edge of the window.
;               The margin must be a number in the range 0.0 to 0.333. This
;               keyword is ignored if the POSITION keyword is used.
;
;     MAX:      The data is linearly scaled between the MIN and MAX values,
;               if they are provided. MAX is set to MAX(image) by default.
;
;     MIN:      The data is linearly scaled between the MIN and MAX values,
;               if they are provided. MIN is set to MIN(image) by default.
;
;     MINUS_ONE: The value of this keyword is passed along to the CONGRID
;               command. It prevents CONGRID from adding an extra row and
;               column to the resulting array, which can be a problem with
;               small image arrays.
;
;     MULTI:    If this keyword is set, the image output honors the
;               !P.MULTI system variable.
;
;     NCOLORS:  If this keyword is supplied, the TOP keyword is ignored and
;               the TOP keyword is set equal to BOTTOM + NCOLORS - 1. This
;               keyword is provided to make TVSCALE easier to use with the
;               color-loading programs such as LOADCT:
;
;                  LoadCT, 5, NColors=100, Bottom=100
;                  TVScale, image, NColors=100, Bottom=100
;
;     NORMAL:   Setting this keyword means image position coordinates x and y
;               are interpreted as being in normalized coordinates. This keyword
;               is only valid if the TVSCL keyword is set.
;
;     POSITION: The location of the image in the output window. This is
;               a four-element floating array of normalized coordinates of
;               the type given by !P.POSITION or the POSITION keyword to
;               other IDL graphics commands. The form is [x0, y0, x1, y1].
;               The default is [0.0, 0.0, 1.0, 1.0]. Note that this can
;               be an output parameter if the KEEP_ASPECT_RATIO keyword is
;               used.
;
;     TOP:      The image is scaled so that all displayed pixels have values
;               greater than or equal to BOTTOM and less than or equal to TOP.
;               The value of TOP is !D.Table_Size by default.
;
;     TVSCL:    Setting this keyword makes the TVIMAGE command work much
;               like the TVSCL command, although better. That is to say, it
;               will still set the correct DECOMPOSED state depending upon
;               the kind of image to be displayed (8-bit or 24-bit). It will
;               also allow the image to be "positioned" in the window by
;               specifying the coordinates of the lower-left corner of the
;               image. The NORMAL keyword is activated when the TV keyword
;               is set, which will indicate that the position coordinates
;               are given in normalized coordinates rather than device
;               coordinates.
;
;               Setting this keyword will ensure that the keywords
;               KEEP_ASPECT_RATIO, MARGIN, MINUS_ONE, MULTI, and POSITION
;               are ignored.
;
; OUTPUTS:
;     None.
;
; SIDE EFFECTS:
;     Unless the KEEP_ASPECT_RATIO keyword is set, the displayed image
;     may not have the same aspect ratio as the input data set.
;
; RESTRICTIONS:
;     If the POSITION keyword and the KEEP_ASPECT_RATIO keyword are
;     used together, there is an excellent chance the POSITION
;     parameters will change. If the POSITION is passed in as a
;     variable, the new positions will be returned as an output parameter.
;
;     If the image is 2D then color decomposition is turned OFF
;     for the current graphics device (i.e., DEVICE, DECOMPOSED=0).
;
;     If outputting to the PRINTER device, the aspect ratio of the image
;     is always maintained and the POSITION coordinates are ignored.
;     The image always printed in portrait mode.
;
; EXAMPLE:
;     To display an image with a contour plot on top of it, type:
;
;        filename = FILEPATH(SUBDIR=['examples','data'], 'worldelv.dat')
;        image = BYTARR(360,360)
;        OPENR, lun, filename, /GET_LUN
;        READU, image
;        FREE_LUN, lun
;
;        thisPosition = [0.1, 0.1, 0.9, 0.9]
;        TVSCALE, image, POSITION=thisPosition, /KEEP_ASPECT_RATIO
;        CONTOUR, image, POSITION=thisPosition, /NOERASE, XSTYLE=1, $
;            YSTYLE=1, XRANGE=[0,360], YRANGE=[0,360], NLEVELS=10
;
; MODIFICATION HISTORY:
;      Written by:     David Fanning, 27 May 1999 from TVIMAGE code.
;      Added MIN, MAX, and NCOLORS keywords 28 May 1999. DWF.
;-

PRO TVSCALE, image, x, y, KEEP_ASPECT_RATIO=keep, POSITION=position, $
   MARGIN=margin, MINUS_ONE=minusOne, _EXTRA=extra, ERASE=eraseit, $
   MULTI=multi, TVSCL=tvscl, NORMAL=normal, TOP=top, BOTTOM=bottom, $
   NCOLORS=ncolors, MAX=max, MIN=min

ON_ERROR, 1

   ; Check for image parameter.

IF N_Elements(image) EQ 0 THEN MESSAGE, 'You must pass a valid image argument.'

   ; Check image size.

s = SIZE(image)
IF s(0) LT 2 OR s(0) GT 3 THEN $
   MESSAGE, 'Argument does not appear to be an image. Returning...'

   ; Check for TOP and BOTTOM keywords.

IF N_Elements(top) EQ 0 THEN top = !D.Table_Size
IF N_Elements(bottom) EQ 0 THEN bottom = 0B
IF N_Elements(ncolors) NE 0 THEN top = (bottom + ncolors - 1) < 255
IF N_Elements(max) EQ 0 THEN max = Max(image)
IF N_Elements(min) EQ 0 THEN min = Min(image)

   ; Which release of IDL is this?

thisRelease = Float(!Version.Release)

   ; 2D image.

IF s(0) EQ 2 THEN BEGIN
   imgXsize = FLOAT(s(1))
   imgYsize = FLOAT(s(2))
   true = 0

        ; Decomposed color off if device supports it.

   CASE  StrUpCase(!D.NAME) OF
        'X': BEGIN
            IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
            Device, Decomposed=0
            ENDCASE
        'WIN': BEGIN
            IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
            Device, Decomposed=0
            ENDCASE
        'MAC': BEGIN
            IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
            Device, Decomposed=0
            ENDCASE
        ELSE:
   ENDCASE
ENDIF

   ; 3D image.

IF s(0) EQ 3 THEN BEGIN
IF (s(1) NE 3L) AND (s(2) NE 3L) AND (s(3) NE 3L) THEN $
   MESSAGE, 'Argument does not appear to be a 24-bit image. Returning...'
   IF s(1) EQ 3 THEN true = 1 ; Pixel interleaved
   IF s(2) EQ 3 THEN true = 2 ; Row interleaved
   IF s(3) EQ 3 THEN true = 3 ; Band interleaved

        ; Decomposed color on if device supports it.


   CASE StrUpCase(!D.NAME) OF
        'X': BEGIN
            Device, Get_Visual_Depth=thisDepth
            IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
            IF thisDepth GT 8 THEN Device, Decomposed=1
            ENDCASE
        'WIN': BEGIN
            Device, Get_Visual_Depth=thisDepth
            IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
            IF thisDepth GT 8 THEN Device, Decomposed=1
            ENDCASE
        'MAC': BEGIN
            Device, Get_Visual_Depth=thisDepth
            IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
            IF thisDepth GT 8 THEN Device, Decomposed=1
            ENDCASE
        ELSE:
   ENDCASE
   CASE true OF
      1: BEGIN
         imgXsize = FLOAT(s(2))
         imgYsize = FLOAT(s(3))
         END
      2: BEGIN
         imgXsize = FLOAT(s(1))
         imgYsize = FLOAT(s(3))
         END
      3: BEGIN
         imgXsize = FLOAT(s(1))
         imgYsize = FLOAT(s(2))
         END
   ENDCASE
ENDIF

   ; Check for TVSCL keyword. If present, then act like a TVSCL command.

IF Keyword_Set(tvscl) THEN BEGIN
   IF Keyword_Set(eraseit) THEN Erase
   IF N_Elements(x) EQ 0 THEN x = 0
   IF N_Elements(y) EQ 0 THEN y = 0
   IF Keyword_Set(normal) THEN $
      TV, BytScl(image,Top=!D.Table_Size-1, Max=max, Min=min), x, y, True=true, _Extra=extra, /Normal ELSE $
      TV, BytScl(image,Top=!D.Table_Size-1, Max=max, Min=min), x, y, True=true, _Extra=extra, /Device
   GoTo, restoreDecomposed
ENDIF

   ; Check for keywords.

IF N_ELEMENTS(position) EQ 0 THEN BEGIN
   IF Keyword_Set(multi) THEN BEGIN
      Plot, Findgen(11), XStyle=4, YStyle=4, /NoData
      position = [!X.Window[0], !Y.Window[0], !X.Window[1], !Y.Window[1]]
   ENDIF ELSE BEGIN
      position = [0.0, 0.0, 1.0, 1.0]
   ENDELSE
ENDIF ELSE BEGIN
   IF Keyword_Set(multi) THEN BEGIN
      Plot, Findgen(11), XStyle=4, YStyle=4, /NoData
      position = [!X.Window[0], !Y.Window[0], !X.Window[1], !Y.Window[1]]
   ENDIF ELSE BEGIN
      position = Float(position)
   ENDELSE
ENDELSE


IF N_Elements(margin) NE 0 THEN BEGIN
        margin = 0.0 > margin < 0.33
        position = [position[0] + margin, position[1] + margin, $
                    position[2] - margin, position[3] - margin]
ENDIF

minusOne = Keyword_Set(minusOne)
IF Keyword_Set(eraseit) THEN Erase

   ; Maintain aspect ratio (ratio of height to width)?

IF KEYWORD_SET(keep) THEN BEGIN

      ; Find aspect ratio of image.

   ratio = FLOAT(imgYsize) / imgXSize

      ; Find the proposed size of the image in pixels without aspect
      ; considerations.

   xpixSize = (position(2) - position(0)) * !D.X_VSize
   ypixSize = (position(3) - position(1)) * !D.Y_VSize

      ; Try to fit the image width. If you can't maintain
      ; the aspect ratio, fit the image height.

   trialX = xpixSize
   trialY = trialX * ratio
   IF trialY GT ypixSize THEN BEGIN
      trialY = ypixSize
      trialX = trialY / ratio
   ENDIF

      ; Recalculate the position of the image in the window.

   position(0) = (((xpixSize - trialX) / 2.0) / !D.X_VSize) + position(0)
   position(2) = position(0) + (trialX/FLOAT(!D.X_VSize))
   position(1) = (((ypixSize - trialY) / 2.0) / !D.Y_VSize)  + position(1)
   position(3) = position(1) + (trialY/FLOAT(!D.Y_VSize))

ENDIF

   ; Calculate the image size and start locations.

xsize = (position(2) - position(0)) * !D.X_VSIZE
ysize = (position(3) - position(1)) * !D.Y_VSIZE
xstart = position(0) * !D.X_VSIZE
ystart = position(1) * !D.Y_VSIZE

   ; Display the image. Sizing different for PS device.

IF (!D.NAME EQ 'PS') THEN BEGIN

      ; Need a gray-scale color table if this is a true
      ; color image.

   IF true GT 0 THEN LOADCT, 0, /Silent
   TV, BytScl(image, Top=(top-bottom), Max=max, Min=min) + bottom, xstart, $
      ystart, XSIZE=xsize, YSIZE=ysize, _EXTRA=extra, True=true

ENDIF ELSE $

IF (!D.NAME EQ 'PRINTER') THEN BEGIN

      ; Reset the PRINTER for proper calculations.

   Device, Scale_Factor=1, Portrait=1

      ; Get the sizes of the PRINTER device.

   pxsize = !D.X_Size
   pysize = !D.Y_Size

      ; Calculate a scale factor for the printer.

   scalefactor = 1.0 / ((Float(imgXsize)/pxsize) > (Float(imgYsize)/pysize))
   xoffset = Fix((Float(pxsize)/scalefactor - imgXsize)/2.0)
   yoffset = Fix((Float(pysize)/scalefactor - imgYsize)/2.0)

      ; Print it.

   Device, Portrait=1, Scale_Factor=scalefactor
   TV, BytScl(image, Top=(top-bottom), Max=max, Min=min) + bottom, $
      xoffset, yoffset, /Device, True=true
   Device, /Close_Document

ENDIF ELSE BEGIN ; All other devices.
   CASE true OF
      0: TV, BytScl(CONGRID(image, CEIL(xsize), CEIL(ysize), /INTERP, $
            MINUS_ONE=minusOne), Top=top-bottom, Max=max, Min=min) + bottom, $
            xstart, ystart, _EXTRA=extra
      1: TV, BytScl(CONGRID(image, 3, CEIL(xsize), CEIL(ysize), /INTERP, $
            MINUS_ONE=minusOne), Top=top-bottom, Max=max, Min=min) + bottom, $
            xstart, ystart, _EXTRA=extra, True=1
      2: TV, BytScl(CONGRID(image, CEIL(xsize), 3, CEIL(ysize), /INTERP, $
            MINUS_ONE=minusOne), Top=top-bottom, Max=max, Min=min) + bottom, $
            xstart, ystart, _EXTRA=extra, True=2
      3: TV, BytScl(CONGRID(image, CEIL(xsize), CEIL(ysize), 3, /INTERP, $
            MINUS_ONE=minusOne), Top=top-bottom, Max=max, Min=min) + bottom, $
            xstart, ystart, _EXTRA=extra, True=3
  ENDCASE
ENDELSE

   ; Restore Decomposed state if necessary.

RestoreDecomposed:

CASE StrUpCase(!D.NAME) OF
   'X': BEGIN
      IF thisRelease GE 5.2 THEN Device, Decomposed=thisDecomposed
      ENDCASE
   'WIN': BEGIN
      IF thisRelease GE 5.2 THEN Device, Decomposed=thisDecomposed
      ENDCASE
   'MAC': BEGIN
      IF thisRelease GE 5.2 THEN Device, Decomposed=thisDecomposed
      ENDCASE
   ELSE:
ENDCASE

END
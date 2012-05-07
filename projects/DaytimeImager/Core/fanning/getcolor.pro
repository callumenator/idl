;+
; NAME:
;       GETCOLOR
;
; PURPOSE:
;       The original purpose of this function was to enable the
;       user to specify one of the 16 colors supported by the
;       McIDAS color map by name. Over time, however, the function
;       has become a general purpose function for handling and
;       supporting drawing colors in a device-independent way.
;       In particular, I have been looking for ways to write color
;       handling code that will work transparently on both 8-bit and
;       24-bit machines. On 24-bit machines, the code should work the
;       same where color decomposition is turned on or off.
;
;       (The 16 supported colors in GETCOLOR come from the McIDAS color
;       table offered on the IDL newsgroup by Liam Gumley.)
;
; CATEGORY:
;       Graphics, Color Specification.
;
; CALLING SEQUENCE:
;       result = GETCOLOR(color)
;
; OPTIONAL INPUT PARAMETERS:
;       COLOR: A string with the "name" of the color. Valid names are:
;           black
;           magenta
;           cyan
;           yellow
;           green
;           red
;           blue
;           navy
;           gold
;           pink
;           aqua
;           orchid
;           gray
;           sky
;           beige
;           white
;
;           The color YELLOW is returned if the color name can't be resolved.
;           Case is unimportant.
;
;           If the function is called with just this single input parameter,
;           the return value is either a 1-by-3 array containing the RGB values of
;           that particular color, or a 24-bit integer that can be "decomposed" into
;           that particular color, depending upon the state of the TRUE keyword and
;           upon whether color decomposition is turned on or off. The state of color
;           decomposition can ONLY be determined if the program is being run in
;           IDL 5.2 or higher.
;
;       INDEX: The color table index where the specified color should be loaded.
;           If this parameter is passed, then the return value of the function is the
;           index number and not the color triple. (If color decomposition is turned
;           on AND the user specifies an index parameter, the color is loaded in the
;           color table at the proper index, but a 24-bit value is returned to the
;           user in IDL 5.2 and higher.)
;
;       If no positional parameter is present, then the return value is either a 16-by-3
;       byte array containing the RGB values of all 16 colors or it is a 16-element
;       long integer array containing color values that can be decomposed into colors.
;       The 16-by-3 array is appropriate for loading color tables with the TVLCT command:
;
;           Device, Decomposed=0
;           colors = GetColor()
;           TVLCT, colors, 100
;
;
; INPUT KEYWORD PARAMETERS:
;
;       NAMES: If this keyword is set, the return value of the function is
;              a 16-element string array containing the names of the colors.
;              These names would be appropriate, for example, in building
;              a list widget with the names of the colors. If the NAMES
;              keyword is set, the COLOR and INDEX parameters are ignored.
;
;                 listID = Widget_List(baseID, Value=GetColor(/Names), YSize=16)
;
;       LOAD:  If this keyword is set, all 16 colors are automatically loaded
;              starting at the color index specified by the START keyword.
;              Note that setting this keyword means that the return value of the
;              function will be a structure, with each field of the structure
;              corresponding to a color name. The value of each field will be
;              an index number (set by the START keyword) corresponding to the
;              associated color, or a 24-bit long integer value that creates the
;              color on a true-color device. What you have as the field values is
;              determined by the TRUE keyword or whether color decomposition is on
;              or off in the absense of the TRUE keyword. It will either be a 1-by-3
;              byte array or a long integer value.
;
;       START: The starting color index number if the LOAD keyword is set. This keyword
;              value is ignored unless the LOAD keyword is also set. The keyword is also
;              ignored if the TRUE keyword is set or if color decomposition in on in
;              IDL 5.2 and higher. The default value for the START keyword is
;              !D.TABLE_SIZE - 17.
;
;       TRUE:  If this keyword is set, the specified color triple is returned
;              as a 24-bit integer equivalent. The lowest 8 bits correspond to
;              the red value; the middle 8 bits to the green value; and the
;              highest 8 bits correspond to the blue value. In IDL 5.2 and higher,
;              if color decomposition is turned on, it is as though this keyword
;              were set.
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       The TRUE keyword causes the START keyword to be ignored.
;       The NAMES keyword causes the COLOR, INDEX, START, and TRUE parameters to be ignored.
;       The COLOR parameter is ignored if the LOAD keyword is used.
;       On systems where it is possible to tell the state of color decomposition
;       (i.e., IDL 5.2 and higher), a 24-bit value (or values) is automatically
;       returned if color decomposition is ON.
;
; EXAMPLE:
;       To load a yellow color in color index 100 and plot in yellow, type:
;
;          yellow = GETCOLOR('yellow', 100)
;          PLOT, data, COLOR=yellow
;
;       or,
;
;          PLOT, data, COLOR=GETCOLOR('yellow', 100)
;
;       To do the same thing on a 24-bit color system with decomposed color on, type:
;
;          PLOT, data, COLOR=GETCOLOR('yellow', /TRUE)
;
;       or in IDL 5.2 and higher,
;
;          DEVICE, Decomposed=1
;          PLOT, data, COLOR=GETCOLOR('yellow')
;
;       To load all 16 colors into the current color table, starting at
;       color index 200, type:
;
;          TVLCT, GETCOLOR(), 200
;
;       To add the color names to a list widget:
;
;           listID = Widget_List(baseID, Value=GetColor(/Names), YSize=16)
;
;       To load all 16 colors and have the color indices returned in a structure:
;
;           DEVICE, Decomposed=0
;           colors = GetColor(/Load, Start=1)
;           HELP, colors, /Structure
;           PLOT, data, COLOR=colors.yellow
;
;       To get the direct color values as 24-bit integers in color structure fields:
;
;           DEVICE, Decomposed=1
;           colors = GetColor(/Load)
;           PLOT, data, COLOR=colors.yellow
;
;       Note that the START keyword value is ignored if on a 24-bit device,
;       so it is possible to write completely device-independent code by
;       writing code like this:
;
;           colors = GetColor(/Load)
;           PLOT, data, Color=colors.yellow
;
; MODIFICATION HISTORY:
;       Written by: David Fanning, 10 February 96.
;       Fixed a bug in which N_ELEMENTS was spelled wrong. 7 Dec 96. DWF
;       Added the McIDAS colors to the program. 24 Feb 99. DWF
;       Added the INDEX parameter to the program 8 Mar 99. DWF
;       Added the NAMES keyword at insistence of Martin Schultz. 10 Mar 99. DWF
;       Reorderd the colors so black is first and white is last. 7 June 99. DWF
;       Added automatic recognition of DECOMPOSED=1 state. 7 June 99. DWF
;       Added LOAD AND START keywords. 7 June 99. DWF.
;-



FUNCTION COLOR24, number

   ; This FUNCTION accepts a [red, green, blue] triple that
   ; describes a particular color and returns a 24-bit long
   ; integer that is equivalent to that color. The color is
   ; described in terms of a hexidecimal number (e.g., FF206A)
   ; where the left two digits represent the blue color, the
   ; middle two digits represent the green color, and the right
   ; two digits represent the red color.
   ;
   ; The triple can be either a row or column vector of 3 elements.

ON_ERROR, 1

IF N_ELEMENTS(number) NE 3 THEN $
   MESSAGE, 'Augument must be a three-element vector.'

IF MAX(number) GT 255 OR MIN(number) LT 0 THEN $
   MESSAGE, 'Argument values must be in range of 0-255'

base16 = [[1L, 16L], [256L, 4096L], [65536L, 1048576L]]

num24bit = 0L

FOR j=0,2 DO num24bit = num24bit + ((number(j) MOD 16) * base16(0,j)) + $
   (Fix(number(j)/16) * base16(1,j))

RETURN, num24bit
END ; ************************  of COLOR24  ******************************



FUNCTION GETCOLOR, thisColor, index, TRUE=truecolor, $
   NAMES=colornames, LOAD=load, START=start

   ; Set up the color vectors.

names  = ['Black', 'Magenta', 'Cyan', 'Yellow', 'Green']
rvalue = [  0,        255,       0,      255,       0  ]
gvalue = [  0,          0,     255,      255,     255  ]
bvalue = [  0,        255,     255,        0,       0  ]
names  = [names,  'Red', 'Blue', 'Navy', 'Gold', 'Pink']
rvalue = [rvalue,  255,     0,      0,    255,    255  ]
gvalue = [gvalue,    0,     0,      0,    187,    127  ]
bvalue = [bvalue,    0,   255,    115,      0,    127  ]
names  = [names,  'Aqua', 'Orchid', 'Gray', 'Sky', 'Beige', 'White']
rvalue = [rvalue,   112,     219,     127,    0,     255,     255  ]
gvalue = [gvalue,   219,     112,     127,  163,     171,     255  ]
bvalue = [bvalue,   147,     219,     127,  255,     127,     255  ]

   ; Did the user ask for a specific color? If not, return
   ; all the colors. If the user asked for a specific color,
   ; find out if a 24-bit value is required. Return to main
   ; IDL level if an error occurs.

ON_Error, 1
np = N_Params()
IF Keyword_Set(start) EQ 0 THEN start = !D.TABLE_SIZE - 17

   ; User ask for the color names?

IF Keyword_Set(colornames) THEN RETURN, names ELSE names = StrUpCase(names)

   ; If no positional parameter, return all colors.

IF np EQ 0 THEN BEGIN

   ; Did the user want a 24-bit value? If so, call COLOR24.

   IF Keyword_Set(trueColor) THEN BEGIN
      returnColor = LonArr(16)
      FOR j=0,15 DO returnColor[j] = Color24([rvalue[j], gvalue[j], bvalue[j]])

         ; If LOAD keyword set, return a color structure.

      IF Keyword_Set(load) THEN BEGIN
         returnValue = Create_Struct('black', returnColor[0])
         FOR j=1,15 DO returnValue = Create_Struct(returnValue, names[j], returnColor[j])
         returnColor = returnValue
      ENDIF

      RETURN, returnColor
   ENDIF

   ; If color decomposition is ON, return 24-bit values.

   IF Float(!Version.Release) GE 5.2 THEN BEGIN
      IF (!D.Name EQ 'X' OR !D.Name EQ 'WIN' OR !D.Name EQ 'MAC') THEN BEGIN
         Device, Get_Decomposed=decomposedState
      ENDIF ELSE decomposedState = 0
      IF decomposedState EQ 1 THEN BEGIN
         returnColor = LonArr(16)
         FOR j=0,15 DO returnColor[j] = Color24([rvalue[j], gvalue[j], bvalue[j]])
         IF Keyword_Set(load) THEN BEGIN
            returnValue = Create_Struct('black', returnColor[0])
            FOR j=1,15 DO returnValue = Create_Struct(returnValue, names[j], returnColor[j])
            RETURN, returnValue
         ENDIF
         RETURN, returnColor
      ENDIF

      IF Keyword_Set(load) THEN BEGIN
         TVLCT, Reform([rvalue, gvalue, bvalue], 16, 3), start
         returnValue = Create_Struct('black', start)
         FOR j=1,15 DO returnValue = Create_Struct(returnValue, names[j], start+j)
         RETURN, returnValue
      ENDIF

      returnColor = REFORM([rvalue, gvalue, bvalue], 16, 3)
      RETURN, returnColor

   ENDIF

   IF Keyword_Set(load) THEN BEGIN
      TVLCT, Reform([rvalue, gvalue, bvalue], 16, 3), start
      returnValue = Create_Struct('black', start)
      FOR j=1,15 DO returnValue = Create_Struct(returnValue, names[j], start+j)
      RETURN, returnValue
   ENDIF

   returnColor = REFORM([rvalue, gvalue, bvalue], 16, 3)
   RETURN, returnColor

ENDIF

   ; Check synonyms of colors.

IF StrUpCase(thisColor) EQ 'GREY' THEN thisColor = 'GRAY'
IF StrUpCase(thisColor) EQ 'CHARCOAL' THEN thisColor = 'GRAY'
IF StrUpCase(thisColor) EQ 'AQUAMARINE' THEN thisColor = 'AQUA'
IF StrUpCase(thisColor) EQ 'SKYBLUE' THEN thisColor = 'SKY'

   ; Make sure the parameter is an uppercase string.

varInfo = SIZE(thisColor)
IF varInfo(varInfo(0) + 1) NE 7 THEN $
   MESSAGE, 'The color name must be a string.'
thisColor = STRUPCASE(thisColor)

   ; Get the color triple for this color.

colorIndex = WHERE(names EQ thisColor)

   ; If you can't find it. Issue an infomational message,
   ; set the index to a YELLOW color, and continue.

IF colorIndex(0) LT 0 THEN BEGIN
   MESSAGE, "Can't find color. Returning YELLOW.", /INFORMATIONAL
   colorIndex = 3
ENDIF

   ; Get the color triple.

r = rvalue(colorIndex)
g = gvalue(colorIndex)
b = bvalue(colorIndex)
returnColor = REFORM([r, g, b], 1, 3)

   ; Did the user want a 24-bit value? If so, call COLOR24.

IF KEYWORD_SET(trueColor) THEN BEGIN
   returnColor = COLOR24(returnColor)
   RETURN, returnColor
ENDIF

   ; If color decomposition is ON, return 24-bit value.

IF Float(!Version.Release) GE 5.2 THEN BEGIN

      IF (!D.Name EQ 'X' OR !D.Name EQ 'WIN' OR !D.Name EQ 'MAC') THEN BEGIN
         Device, Get_Decomposed=decomposedState
      ENDIF ELSE decomposedState = 0

   IF decomposedState EQ 1 THEN BEGIN

         ; Before you change return color, load index if requested.

      IF N_Elements(index) NE 0 THEN BEGIN
         index = 0 > index < (!D.Table_Size-1)
         TVLCT, returnColor, index
      ENDIF

      returnColor = COLOR24(returnColor)
      RETURN, returnColor
   ENDIF
ENDIF

   ; Did the user specify a color index? If so, load it.

IF N_Elements(index) NE 0 THEN BEGIN
   index = 0 > index < (!D.Table_Size-1)
   TVLCT, returnColor, index
   returnColor = index
ENDIF

RETURN, returnColor
END

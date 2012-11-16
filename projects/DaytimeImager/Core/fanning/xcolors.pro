;+
; NAME:
;       XCOLORS
;
; PURPOSE:
;       The purpose of this routine is to interactively change color tables
;       in a manner similar to XLOADCT. No common blocks are used so
;       multiple copies of XCOLORS can be on the display at the same
;       time (if each has a different TITLE). XCOLORS has the ability
;       to notify a widget event handler or an object method if and when
;       a new color table has been loaded. The event handler or object method
;       is then responsibe for updating the program's display on 16- or
;       24-bit display systems.
;
; AUTHOR:
;       FANNING SOFTWARE CONSULTING
;       David Fanning, Ph.D.
;       2642 Bradbury Court
;       Fort Collins, CO 80521 USA
;       Phone: 970-221-0438
;       E-mail: davidf@dfanning.com
;       Coyote's Guide to IDL Programming: http://www.dfanning.com
;
; CATEGORY:
;       Widgets.
;
; CALLING SEQUENCE:
;       XCOLORS
;
; INPUTS:
;       None.
;
; KEYWORD PARAMETERS:
;       BOTTOM: The lowest color index of the colors to be changed.
;
;       DRAG: Set this keyword if you want colors loaded as you drag
;       the sliders. Default is to update colors only when you release
;       the sliders.
;
;       FILE: A string variable pointing to a file that holds the
;       color tables to load. The normal colors1.tbl file is used by default.
;
;       GROUP_LEADER: The group leader for this program. When the group
;       leader is destroyed, this program will be destroyed.
;
;       NCOLORS: This is the number of colors to load when a color table
;       is selected.
;
;       NOTIFYID: A 2-column by n-row array that contains the IDs of widgets
;       that should be notified when XCOLORS loads a color table. The first
;       column of the array is the widgets that should be notified. The
;       second column contains IDs of widgets that are at the top of the
;       hierarchy in which the corresponding widgets in the first column
;       are located. (The purpose of the top widget IDs is to make it
;       possible for the widget in the first column to get the "info"
;       structure of the widget program.) An XCOLORS_LOAD event will be
;       sent to the widget identified in the first column. The event
;       structure is defined like this:
;
;       event = {XCOLORS_LOAD, ID:0L, TOP:0L, HANDLER:0L, $
;          R:BytArr(!D.N_COLORS < 256), G:BytArr(!D.N_COLORS < 256), $
;          B:BytArr(!D.N_COLORS < 256), INDEX:0}
;
;       The ID field will be filled out with NOTIFYID[0, n] and the TOP
;       field will be filled out with NOTIFYID[1, n]. The R, G, and B
;       fields will have the current color table vectors, obtained by
;       exectuing the command TVLCT, r, g, b, /Get. The INDEX field will
;       have the index number of the just-loaded color table.
;
;       Note that XCOLORS can't initially tell *which* color table is
;       loaded, since it just uses whatever colors are available when it
;       is called. Thus, it stores a -1 in the INDEX field to indicate
;       this "default" value. Programs that rely on the INDEX field of
;       the event structure should normally do nothing if the value is
;       set to -1. This value is also set to -1 if the user hits the
;       CANCEL button.
;
;       Typically the XCOLORS button will be defined like this:
;
;           xcolorsID = Widget_Button(parentID, Value='Load New Color Table...', $
;               Event_Pro='Program_Change_Colors_Event')
;
;       The event handler will be written something like this:
;
;           PRO Program_Change_Colors_Event, event
;
;              ; Handles color table loading events. Allows colors be to changed.
;
;           Widget_Control, event.top, Get_UValue=info, /No_Copy
;           thisEvent = Tag_Names(event, /Structure_Name)
;           CASE thisEvent OF
;
;              'WIDGET_BUTTON': BEGIN
;
;                    ; Color table tool.
;
;                 XColors, NColors=info.ncolors, Bottom=info.bottom, $
;                    Group_Leader=event.top, NotifyID=[event.id, event.top]
;                 ENDCASE
;
;              'XCOLORS_LOAD': BEGIN
;
;                    ; Update the display for 24-bit displays.
;
;                 Device, Get_Visual_Depth=thisDepth
;                 IF thisDepth GT 8 THEN BEGIN
;                    WSet, info.wid
;
;                    ...Whatever display commands are required go here. For example...
;
;                    TV, info.image
;
;                 ENDIF
;                 ENDCASE
;
;           ENDCASE
;
;           Widget_Control, event.top, Set_UValue=info, /No_Copy
;           END
;
;       NOTIFYOBJ: A vector of structures (or a single structure), with
;       each element of the vector defined as follows:
;
;          struct = {XCOLORS_NOTIFYOBJ, object:Obj_New(), method:'', wid:0}
;
;       where the "object" is an object reference, "method" is the object
;       method that should be called when XCOLORS loads its color tables,
;       and "wid" is the window index number of the window where the object
;       output should be displayed. Note that the current graphics window
;       will be set to struct.wid before the object method is called.
;
;           ainfo = {XCOLORS_NOTIFYOBJ, a, 'Draw', 0}
;           binfo = {XCOLORS_NOTIFYOBJ, b, 'Display', 3}
;           XColors, NotifyObj=[ainfo, binfo]
;
;       Note that the XColors program must be compiled before these structures
;       are used. Alternatively, you can put this program, named
;       "xcolors_notifyobj__define.pro" (*three* underscore characters in this
;       name!) in your PATH:
;
;           PRO XCOLORS_NOTIFYOBJ__DEFINE
;              struct = {XCOLORS_NOTIFYOBJ, OBJECT:Obj_New(), METHOD:'', WID:0}
;           END
;
;       TITLE: This is the window title. It is "Load Color Tables" by
;       default. The program is registered with the name 'XCOLORS:' plus
;       the TITLE string. The "register name" is checked before the widgets
;       are defined. If a program with that name has already been registered
;       you cannot register another with that name. This means that you can
;       have several versions of XCOLORS open simultaneously as long as each
;       has a unique title or name. For example, like this:
;
;         IDL> XColors, NColors=100, Bottom=0, Title='First 100 Colors'
;         IDL> XColors, NColors=100, Bottom=100, Title='Second 100 Colors'
;
;       XOFFSET: This is the X offset of the program on the display. The
;       program will be placed approximately in the middle of the display
;       by default.
;
;       YOFFSET: This is the Y offset of the program on the display. The
;       program will be placed approximately in the middle of the display
;       by default.
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       Colors are changed. Events are sent to widgets if the NOTIFYID
;       keyword is used. Object methods are called if the NOTIFYOBJ keyword
;       is used. This program is a non-blocking widget.
;
; RESTRICTIONS:
;       None.
;
; EXAMPLE:
;       To load a color table into 100 colors, starting at color index
;       50 and send an event to the widget identified at info.drawID
;       in the widget heirarchy of the top-level base event.top, type:
;
;       XCOLORS, NCOLORS=100, BOTTOM=50, NOTIFYID=[info.drawID, event.top]
;
; MODIFICATION HISTORY:
;       Written by:     David Fanning, 15 April 97. Extensive modification
;         of an older XCOLORS program with excellent suggestions for
;         improvement by Liam Gumley. Now works on 8-bit and 24-bit
;         systems. Subroutines renamed to avoid ambiguity. Cancel
;         button restores original color table.
;       23 April 97, added color protection for the program. DWF
;       24 April 97, fixed a window initialization bug. DWF
;       18 June 97, fixed a bug with the color protection handler. DWF
;       18 June 97, Turned tracking on for draw widget to fix a bug
;         in TLB Tracking Events for WindowsNT machines in IDL 5.0. DWF
;       20 Oct 97, Changed GROUP keyword to GROUP_LEADER. DWF
;       19 Dec 97, Fixed bug with TOP/BOTTOM reversals and CANCEL. DWF.
;        9 Jun 98, Fixed bug when using BOTTOM keyword on 24-bit devices. DWF
;        9 Jun 98, Added Device, Decomposed=0 for TrueColor visual classes. DWF
;        9 Jun 98, Removed all IDL 4 compatibility.
;       21 Oct 98, Fixed problem with gamma not being reset on CANCEL. DWF
;        5 Nov 98. Added the NotifyObj keyword, so that XCOLORS would work
;         interactively with objects. DWF.
;        9 Nov 98. Made slider reporting only at the end of the drag. If you
;         want continuous updating, set the DRAG keyword. DWF.
;        9 Nov 98. Fixed problem with TOP and BOTTOM sliders not being reset
;         on CANCEL. DWF.
;       10 Nov 98. Fixed fixes. Sigh... DWF.
;        5 Dec 98. Added INDEX field to the XCOLORS_LOAD event structure. This
;         field holds the current color table index number. DWF.
;        5 Dec 98. Modified the way the colorbar image was created. Results in
;         greatly improved display for low number of colors. DWF.
;        6 Dec 98. Added the ability to notify an unlimited number of objects. DWF.
;       12 Dec 98. Removed obsolete Just_Reg keyword and improved documetation. DWF.
;       30 Dec 98. Fixed the way the color table index was working. DWF.
;        4 Jan 99. Added slightly modified CONGRID program to fix floating divide
;          by zero problem. DWF
;        2 May 99. Added code to work around a Macintosh bug in IDL through version
;          5.2 that tries to redraw the graphics window after a TVLCT command. DWF.
;        5 May 99. Restore the current window index number after drawing graphics.
;          Not supported on Macs. DWF.
;        9 Jul 99. Fixed a couple of bugs I introduced with the 5 May changes. Sigh... DWF.
;       13 Jul 99. Scheesh! That May 5th change was a BAD idea! Fixed more bugs. DWF.
;       31 Jul 99. Substituted !D.Table_Size for !D.N_Colors. DWF.
;        1 Sep 99. Got rid of the May 5th fixes and replaced with something MUCH simpler. DWF.
;-

; $Id: congrid.pro,v 1.7 1998/01/15 18:41:15 scottm Exp $
;
; Copyright (c) 1988-1998, Research Systems, Inc.  All rights reserved.
;  Unauthorized reproduction prohibited.
;
;
; NAME:
;  CONGRID
;
; PURPOSE:
;       Shrink or expand the size of an array by an arbitrary amount.
;       This IDL procedure simulates the action of the VAX/VMS
;       CONGRID/CONGRIDI function.
;
;  This function is similar to "REBIN" in that it can resize a
;       one, two, or three dimensional array.   "REBIN", however,
;       requires that the new array size must be an integer multiple
;       of the original size.   CONGRID will resize an array to any
;       arbitrary size (REBIN is somewhat faster, however).
;       REBIN averages multiple points when shrinking an array,
;       while CONGRID just resamples the array.
;
; CATEGORY:
;       Array Manipulation.
;
; CALLING SEQUENCE:
;  array = CONGRID(array, x, y, z)
;
; INPUTS:
;       array:  A 1, 2, or 3 dimensional array to resize.
;               Data Type : Any type except string or structure.
;
;       x:      The new X dimension of the resized array.
;               Data Type : Int or Long (greater than or equal to 2).
;
; OPTIONAL INPUTS:
;       y:      The new Y dimension of the resized array.   If the original
;               array has only 1 dimension then y is ignored.   If the
;               original array has 2 or 3 dimensions then y MUST be present.
;
;       z:      The new Z dimension of the resized array.   If the original
;               array has only 1 or 2 dimensions then z is ignored.   If the
;               original array has 3 dimensions then z MUST be present.
;
; KEYWORD PARAMETERS:
;       INTERP: If set, causes linear interpolation to be used.
;               Otherwise, the nearest-neighbor method is used.
;
;  CUBIC:   If specified and non-zero, "Cubic convolution"
;     interpolation is used.  This is a more
;     accurate, but more time-consuming, form of interpolation.
;     CUBIC has no effect when used with 3 dimensional arrays.
;     If this parameter is negative and non-zero, it specifies the
;     value of the cubic interpolation parameter as described
;     in the INTERPOLATE function.  Valid ranges are -1 <= Cubic < 0.
;     Positive non-zero values of CUBIC (e.g. specifying /CUBIC)
;     produce the default value of the interpolation parameter
;     which is -1.0.
;
;       MINUS_ONE:
;               If set, will prevent CONGRID from extrapolating one row or
;               column beyond the bounds of the input array.   For example,
;               If the input array has the dimensions (i, j) and the
;               output array has the dimensions (x, y), then by
;               default the array is resampled by a factor of (i/x)
;               in the X direction and (j/y) in the Y direction.
;               If MINUS_ONE is present (AND IS NON-ZERO) then the array
;               will be resampled by the factors (i-1)/(x-1) and (j-1)/(y-1).
;
; OUTPUTS:
;  The returned array has the same number of dimensions as the original
;       array and is of the same data type.   The returned array will have
;       the dimensions (x), (x, y), or (x, y, z) depending on how many
;       dimensions the input array had.
;
; PROCEDURE:
;       IF the input array has three dimensions, or if INTERP is set,
;       then the IDL interpolate function is used to interpolate the
;       data values.
;       If the input array has two dimensions, and INTERP is NOT set,
;       then the IDL POLY_2D function is used for nearest neighbor sampling.
;       If the input array has one dimension, and INTERP is NOT set,
;       then nearest neighbor sampling is used.
;
; EXAMPLE:
;       ; vol is a 3-D array with the dimensions (80, 100, 57)
;       ; Resize vol to be a (90, 90, 80) array
;       vol = CONGRID(vol, 90, 90, 80)
;
; MODIFICATION HISTORY:
;       DMS, Sept. 1988.
;       DMS, Added the MINUS_ONE keyword, Sept. 1992.
;  Daniel Carr. Re-wrote to handle one and three dimensional arrays
;                    using INTERPOLATE function.
;  DMS, RSI, Nov, 1993.  Added CUBIC keyword.
;       SJL, Nov, 1997.  Formatting, conform to IDL style guide.
;       DWF, Jan, 1999. Added error checking to look for divide by zero.
;

function CONGRID, arr, x, y, z, INTERP=int, MINUS_ONE=m1, CUBIC = cubic

    ON_ERROR, 2      ;Return to caller if error
    s = Size(arr)

    if ((s[0] eq 0) or (s[0] gt 3)) then $
      Message, 'Array must have 1, 2, or 3 dimensions.'

    ;;  Supply defaults = no interpolate, and no minus_one.
    if (N_ELEMENTS(int) le 0) then int = 0 else int = KEYWORD_SET(int)
    if (N_ELEMENTS(m1) le 0) then m1 = 0 else m1 = KEYWORD_SET(m1)
    if (N_ELEMENTS(cubic) eq 0) then cubic = 0
    if (cubic ne 0) then int = 1 ;Cubic implies interpolate


    case s[0] of
        1: begin                ; *** ONE DIMENSIONAL ARRAY
            ; DWF modified: Check divide by zero.
            srx = float(s[1] - m1)/((x-m1) > 1e-6) * findgen(x) ;subscripts
            if (int) then $
              return, INTERPOLATE(arr, srx, CUBIC = cubic) else $
              return, arr[ROUND(srx)]
        endcase
        2: begin                ; *** TWO DIMENSIONAL ARRAY
            if (int) then begin
                srx = float(s[1] - m1) / ((x-m1) > 1e-6) * findgen(x)
                sry = float(s[2] - m1) / ((y-m1) > 1e-6) * findgen(y)
                return, INTERPOLATE(arr, srx, sry, /GRID, CUBIC=cubic)
            endif else $
              return, POLY_2D(arr, $
                              [[0,0],[(s[1]-m1)/(float(x-m1) > 1e-6),0]], $ ;Use poly_2d
                              [[0,(s[2]-m1)/(float(y-m1) > 1e-6)],[0,0]],int,x,y)

        endcase
        3: begin                ; *** THREE DIMENSIONAL ARRAY
            srx = float(s[1] - m1) / ((x-m1) > 1e-6) * findgen(x)
            sry = float(s[2] - m1) / ((y-m1) > 1e-6) * findgen(y)
            srz = float(s[3] - m1) / ((z-m1) > 1e-6) * findgen(z)
            return, interpolate(arr, srx, sry, srz, /GRID)
        endcase
    endcase

    return, arr_r
end  ; ***************************************************************


PRO XColors_NotifyObj__Define

   ; Structure definition module for object notification.

struct = {  XColors_NotifyObj, $  ; The structure name.
            object:Obj_New(), $   ; The object to notify.
            method:'', $          ; The object method to call.
            wid:0 }               ; The window index number where object is displayed.

END ; ***************************************************************



PRO XColors_Set, info

TVLCT, r, g, b, /Get

   ; Make sure the current bottom index is less than the current top index.

IF info.currentbottom GE info.currenttop THEN BEGIN
   temp = info.currentbottom
   info.currentbottom = info.currenttop
   info.currenttop = temp
ENDIF

r(info.bottom:info.currentbottom) = info.bottomcolor(0)
g(info.bottom:info.currentbottom) = info.bottomcolor(1)
b(info.bottom:info.currentbottom) = info.bottomcolor(2)
r(info.currenttop:info.top) = info.topcolor(0)
g(info.currenttop:info.top) = info.topcolor(1)
b(info.currenttop:info.top) = info.topcolor(2)

red = info.r
green = info.g
blue = info.b
number = ABS((info.currenttop-info.currentbottom) + 1)

gamma = info.gamma
index = Findgen(info.ncolors)
distribution = index^gamma > 10e-6
index = Round(distribution * (info.ncolors-1) / (Max(distribution) > 10e-6))

IF info.currentbottom GE info.currenttop THEN BEGIN
   temp = info.currentbottom
   info.currentbottom = info.currenttop
   info.currenttop = temp
ENDIF

IF info.reverse EQ 0 THEN BEGIN
   r(info.currentbottom:info.currenttop) = Congrid(red(index), number, /Minus_One)
   g(info.currentbottom:info.currenttop) = Congrid(green(index), number, /Minus_One)
   b(info.currentbottom:info.currenttop) = Congrid(blue(index), number, /Minus_One)
ENDIF ELSE BEGIN
   r(info.currentbottom:info.currenttop) = $
      Reverse(Congrid(red(index), number, /Minus_One))
   g(info.currentbottom:info.currenttop) = $
      Reverse(Congrid(green(index), number, /Minus_One))
   b(info.currentbottom:info.currenttop) = $
      Reverse(Congrid(blue(index), number, /Minus_One))
ENDELSE

TVLct, r, g, b
thisWindow = !D.Window
WSet, info.windowindex
TV, info.colorimage
IF thisWindow GE 0 THEN WSet, thisWindow

   ; Are there widgets to notify?

s = SIZE(info.notifyID)
IF s(0) EQ 1 THEN count = 0 ELSE count = s(2)-1
FOR j=0,count DO BEGIN
   colorEvent = { XCOLORS_LOAD, $            ;
                  ID:info.notifyID(0,j), $   ;
                  TOP:info.notifyID(1,j), $
                  HANDLER:0L, $
                  R:r, $
                  G:g, $
                  B:b, $
                  index:info.index }
   IF Widget_Info(info.notifyID(0,j), /Valid_ID) THEN $
      Widget_Control, info.notifyID(0,j), Send_Event=colorEvent
ENDFOR

   ; Is there an object to call?

nelements = SIZE(info.notifyobj, /N_Elements)
FOR j=0,nelements-1 DO BEGIN
   IF Obj_Valid((info.notifyobj)[j].object) THEN BEGIN
      WSet, (info.notifyobj)[j].wid
      Call_Method, (info.notifyobj)[j].method, (info.notifyobj)[j].object
      IF thisWindow GE 0 THEN WSet, thisWindow
   ENDIF
ENDFOR

END ; ***************************************************************



PRO XCOLORS_TOP_SLIDER, event

   ; Get the info structure from storage location.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Update the current top value of the slider.

currentTop = event.value
Widget_Control, info.botSlider, Get_Value=currentBottom
currentBottom = currentBottom + info.bottom
currentTop = currentTop + info.bottom

   ; Error handling. Is currentBottom = currentTop?

IF currentBottom EQ currentTop THEN BEGIN
   currentBottom = (currentTop - 1) > 0
   thisValue = (currentBottom-info.bottom)
   IF thisValue LT 0 THEN BEGIN
      thisValue = 0
      currentBottom = info.bottom
   ENDIF
   Widget_Control, info.botSlider, Set_Value=thisValue
ENDIF

   ; Error handling. Is currentBottom > currentTop?

IF currentBottom GT currentTop THEN BEGIN

   bottom = currentTop
   top = currentBottom
   bottomcolor = info.topColor
   topcolor = info.bottomColor
   reverse = 1

ENDIF ELSE BEGIN

   bottom = currentBottom
   top = currentTop
   bottomcolor = info.bottomColor
   topcolor = info.topColor
   reverse = 0

ENDELSE

   ; Create a pseudo structure.

pseudo = {currenttop:top, currentbottom:bottom, reverse:reverse, $
   bottomcolor:bottomcolor, topcolor:topcolor, gamma:info.gamma, index:info.index, $
   top:info.top, bottom:info.bottom, ncolors:info.ncolors, r:info.r, $
   g:info.g, b:info.b, notifyID:info.notifyID, colorimage:info.colorimage, $
   windowindex:info.windowindex, from:'TOP', notifyObj:info.notifyObj, $
   thisWindow:info.thisWindow}

   ; Update the colors.

XColors_Set, pseudo

info.currentTop = currentTop

   ; Put the info structure back in storage location.

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ; ************************************************************************



PRO XCOLORS_BOTTOM_SLIDER, event

   ; Get the info structure from storage location.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Update the current bottom value of the slider.

currentBottom = event.value + info.bottom
Widget_Control, info.topSlider, Get_Value=currentTop
;currentBottom = currentBottom + info.bottom
currentTop = currentTop + info.bottom

   ; Error handling. Is currentBottom = currentTop?

IF currentBottom EQ currentTop THEN BEGIN
   currentBottom = currentTop
   Widget_Control, info.botSlider, Set_Value=(currentBottom-info.bottom)
ENDIF

   ; Error handling. Is currentBottom > currentTop?

IF currentBottom GT currentTop THEN BEGIN

   bottom = currentTop
   top = currentBottom
   bottomcolor = info.topColor
   topcolor = info.bottomColor
   reverse = 1

ENDIF ELSE BEGIN

   bottom = currentBottom
   top = currentTop
   bottomcolor = info.bottomColor
   topcolor = info.topColor
   reverse = 0

ENDELSE

   ; Create a pseudo structure.

pseudo = {currenttop:top, currentbottom:bottom, reverse:reverse, $
   bottomcolor:bottomcolor, topcolor:topcolor, gamma:info.gamma, index:info.index, $
   top:info.top, bottom:info.bottom, ncolors:info.ncolors, r:info.r, $
   g:info.g, b:info.b, notifyID:info.notifyID, colorimage:info.colorimage, $
   windowindex:info.windowindex, from:'BOTTOM', notifyObj:info.notifyObj, $
   thisWindow:info.thisWindow}

   ; Update the colors.

XColors_Set, pseudo

info.currentBottom = currentBottom

   ; Put the info structure back in storage location.

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ; ************************************************************************




PRO XCOLORS_GAMMA_SLIDER, event

   ; Get the info structure from storage location.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Get the gamma value from the slider.

Widget_Control, event.id, Get_Value=gamma
gamma = 10^((gamma/50.0) - 1)

   ; Update the gamma label.

Widget_Control, info.gammaID, Set_Value=String(gamma, Format='(F6.3)')

   ; Make a pseudo structure.

IF info.currentBottom GT info.currentTop THEN $
   pseudo = {currenttop:info.currentbottom, currentbottom:info.currenttop, $
      reverse:1, bottomcolor:info.topcolor, topcolor:info.bottomcolor, $
      gamma:gamma, top:info.top, bottom:info.bottom, index:info.index, $
      ncolors:info.ncolors, r:info.r, g:info.g, b:info.b, $
      notifyID:info.notifyID, colorimage:info.colorimage, $
      windowindex:info.windowindex, from:'SLIDER', notifyObj:info.notifyObj, $
      thisWindow:info.thisWindow} $
ELSE $
   pseudo = {currenttop:info.currenttop, currentbottom:info.currentbottom, $
      reverse:0, bottomcolor:info.bottomcolor, topcolor:info.topcolor, $
      gamma:gamma, top:info.top, bottom:info.bottom, index:info.index, $
      ncolors:info.ncolors, r:info.r, g:info.g, b:info.b, $
      notifyID:info.notifyID, colorimage:info.colorimage, $
      windowindex:info.windowindex, from:'SLIDER', notifyObj:info.notifyObj, $
      thisWindow:info.thisWindow}

   ; Load the colors.

XColors_Set, pseudo

info.gamma = gamma

   ; Put the info structure back in storage location.

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ; ************************************************************************



PRO XCOLORS_COLORTABLE, event

   ; Get the info structure from storage location.

Widget_Control, event.top, Get_UValue=info, /No_Copy

LoadCT, event.index, File=info.file, /Silent, $
   NColors=info.ncolors, Bottom=info.bottom

TVLct, r, g, b, /Get
info.r = r(info.bottom:info.top)
info.g = g(info.bottom:info.top)
info.b = b(info.bottom:info.top)
info.topcolor = [r(info.top), g(info.top), b(info.top)]
info.bottomcolor = [r(info.bottom), g(info.bottom), b(info.bottom)]

   ; Update the slider positions and values.

Widget_Control, info.botSlider, Set_Value=0
Widget_Control, info.topSlider, Set_Value=info.ncolors-1
Widget_Control, info.gammaSlider, Set_Value=50
Widget_Control, info.gammaID, Set_Value=String(1.0, Format='(F6.3)')
info.currentBottom = info.bottom
info.currentTop = info.top
info.gamma = 1.0
info.index = event.index

   ; Create a pseudo structure.

pseudo = {currenttop:info.currenttop, currentbottom:info.currentbottom, $
   reverse:info.reverse, windowindex:info.windowindex, index:event.index, $
   bottomcolor:info.bottomcolor, topcolor:info.topcolor, gamma:info.gamma, $
   top:info.top, bottom:info.bottom, ncolors:info.ncolors, r:info.r, $
   g:info.g, b:info.b, notifyID:info.notifyID, colorimage:info.colorimage, $
   from:'LIST', notifyObj:info.notifyObj, thisWindow:info.thisWindow}

   ; Update the colors.

XColors_Set, pseudo

   ; Put the info structure back in storage location.

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ; ************************************************************************



PRO XCOLORS_PROTECT_COLORS, event

   ; Get the info structure from storage location.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Create a pseudo structure.

pseudo = {currenttop:info.currenttop, currentbottom:info.currentbottom, $
   reverse:info.reverse, $
   bottomcolor:info.bottomcolor, topcolor:info.topcolor, gamma:info.gamma, $
   top:info.top, bottom:info.bottom, ncolors:info.ncolors, r:info.r, index:info.index, $
   g:info.g, b:info.b, notifyID:info.notifyID, colorimage:info.colorimage, $
   windowindex:info.windowindex, from:'PROTECT', notifyObj:info.notifyObj, $
   thisWindow:info.thisWindow}

   ; Update the colors.

XColors_Set, pseudo

   ; Put the info structure back in storage location.

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ; ************************************************************************



PRO XCOLORS_CANCEL, event
Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Create a pseudo structure.

pseudo = {currenttop:info.currenttop, currentbottom:info.currentbottom, $
   reverse:info.reverse, windowindex:info.windowindex, $
   bottomcolor:info.bottomcolor, topcolor:info.topcolor, gamma:info.gamma, $
   top:info.top, bottom:info.bottom, ncolors:info.ncolors, r:info.rstart, $
   g:info.gstart, b:info.bstart, notifyID:info.notifyID, index:info.oindex, $
   colorimage:info.colorimage,from:'CANCEL', notifyObj:info.notifyObj, $
   thisWindow:info.thisWindow}

   ; Update the colors.

XColors_Set, pseudo
Widget_Control, event.top, /Destroy
END ; ************************************************************************



PRO XCOLORS_DISMISS, event
Widget_Control, event.top, /Destroy
END ; ************************************************************************



PRO XCOLORS, NColors=ncolors, Bottom=bottom, Title=title, File=file, $
   Group_Leader=group, XOffset=xoffset, YOffset=yoffset, $
   NotifyID=notifyID, NotifyObj=notifyObj, Drag=drag

   ; This is a procedure to load color tables into a
   ; restricted color range of the physical color table.
   ; It is a highly simplified version of XLoadCT.

On_Error, 1

   ; Current graphics window.

thisWindow = !D.Window

   ; Check keyword parameters. Define defaults.

IF N_Elements(bottom) EQ 0 THEN bottom = 0
IF N_Elements(ncolors) EQ 0 THEN ncolors = (256 < !D.Table_Size) - bottom
IF (ncolors + bottom) GT 256 THEN ncolors = 256 - bottom

IF N_Elements(title) EQ 0 THEN title = 'Load Color Tables'
IF N_Elements(drag) EQ 0 THEN drag = 0
IF N_ELements(file) EQ 0 THEN $
   file = Filepath(SubDir=['resource','colors'], 'colors1.tbl')
IF N_Elements(notifyID) EQ 0 THEN notifyID = [-1L, -1L]
IF N_Elements(notifyObj) EQ 0 THEN BEGIN
   notifyObj = {object:Obj_New(), method:'', wid:-1}
ENDIF
IF Size(notifyObj, /Type) NE 8 THEN BEGIN
   ok = Dialog_Message(['Arguments to the NotifyObj keyword must', $
      'be structures. Returning...'])
   RETURN
END
nelements = Size(notifyObj, /N_Elements)
FOR j=0,nelements-1 DO BEGIN
   tags = Tag_Names(notifyObj[j])
   check = Where(tags EQ 'OBJECT', count1)
   check = Where(tags EQ 'METHOD', count2)
   check = Where(tags EQ 'WID', count3)
   IF (count1 + count2 + count3) NE 3 THEN BEGIN
      ok = Dialog_Message('NotifyObj keyword has incorrect fields. Returning...')
   RETURN
   ENDIF
ENDFOR

   ; Calculate top parameter.

top = ncolors + bottom - 1

   ; Find the center of the display.

DEVICE, GET_SCREEN_SIZE=screenSize
xCenter = FIX(screenSize(0) / 2.0)
yCenter = FIX(screenSize(1) / 2.0)

IF N_ELEMENTS(xoffset) EQ 0 THEN xoffset = xCenter - 150
IF N_ELEMENTS(yoffset) EQ 0 THEN yoffset = yCenter - 200

registerName = 'XCOLORS:' + title

   ; Only one XCOLORS with this title.

IF XRegistered(registerName) THEN RETURN

   ; Create the top-level base. No resizing.

tlb = Widget_Base(Column=1, Title=title, TLB_Frame_Attr=1, $
   XOffSet=xoffset, YOffSet=yoffset, Base_Align_Center=1)

   ; Create a draw widget to display the current colors.

IF !D.NAME NE 'MAC' THEN BEGIN
   draw = Widget_Draw(tlb, XSize=256, YSize=40, Expose_Events=0, $
      Retain=0, Event_Pro='XCOLORS_PROTECT_COLORS')
ENDIF ELSE BEGIN
   draw = Widget_Draw(tlb, XSize=256, YSize=40, Retain=1)
ENDELSE

   ; Create sliders to control stretchs and gamma correction.

sliderbase = Widget_Base(tlb, Column=1, Frame=1)
botSlider = Widget_Slider(sliderbase, Value=0, Min=0, $
   Max=ncolors-1, XSize=256,Event_Pro='XColors_Bottom_Slider', $
   Title='Stretch Bottom', Drag=drag)
topSlider = Widget_Slider(sliderbase, Value=ncolors-1, Min=0, $
   Max=ncolors-1, XSize=256, Event_Pro='XColors_Top_Slider', $
   Title='Stretch Top', Drag=drag)
gammaID = Widget_Label(sliderbase, Value=String(1.0, Format='(F6.3)'))
gammaSlider = Widget_Slider(sliderbase, Value=50.0, Min=0, Max=100, $
   Drag=drag, XSize=256, /Suppress_Value, Event_Pro='XColors_Gamma_Slider', $
   Title='Gamma Correction')

   ; Get the colortable names for the list widget.

colorNames=''
LoadCt, Get_Names=colorNames
FOR j=0,N_Elements(colorNames)-1 DO $
   colorNames(j) = StrTrim(j,2) + ' - ' + colorNames(j)
filebase = Widget_Base(tlb, Column=1, /Frame)
listlabel = Widget_Label(filebase, Value='Select Color Table...')
list = Widget_List(filebase, Value=colorNames, YSize=8, Scr_XSize=256, $
   Event_Pro='XColors_ColorTable')

   ; Dialog Buttons

dialogbase = WIDGET_BASE(tlb, Row=1)
cancel = Widget_Button(dialogbase, Value='Cancel', $
   Event_Pro='XColors_Cancel', UVALUE='CANCEL')
dismiss = Widget_Button(dialogbase, Value='Accept', $
   Event_Pro='XColors_Dismiss', UVALUE='ACCEPT')
Widget_Control, tlb, /Realize

   ; Get window index number of the draw widget.

Widget_Control, draw, Get_Value=windowIndex

   ; Is this a 24-bit TrueColor device? If so, turn
   ; color decomposition OFF.

thisRelease = Float(!Version.Release)
IF thisRelease GE 5.1 THEN BEGIN
   Device, Get_Visual_Name=thisVisual
   IF thisVisual EQ 'TrueColor' THEN Device, Decomposed=0
ENDIF ELSE Device, Decomposed=0

   ; Put a picture of the color table in the window.

bar = BINDGEN(ncolors) # REPLICATE(1B, 10)
bar = BYTSCL(bar, TOP=ncolors-1) + bottom
bar = CONGRID(bar, 256, 40, /INTERP)
WSet, windowIndex
TV, bar

   ; Get the colors that make up the current color table
   ; in the range that this program deals with.

TVLCT, rr, gg, bb, /Get
r = rr(bottom:top)
g = gg(bottom:top)
b = bb(bottom:top)

topColor = [rr(top), gg(top), bb(top)]
bottomColor = [rr(bottom), gg(bottom), bb(bottom)]

   ; Create an info structure to hold information to run the program.

info = {  windowIndex:windowIndex, $   ; The WID of the draw widget.
          botSlider:botSlider, $       ; The widget ID of the bottom slider.
          currentBottom:bottom, $      ; The current bottom slider value.
          currentTop:top, $            ; The current top slider value.
          topSlider:topSlider, $       ; The widget ID of the top slider.
          gammaSlider:gammaSlider, $   ; The widget ID of the gamma slider.
          gammaID:gammaID, $           ; The widget ID of the gamma label
          ncolors:ncolors, $           ; The number of colors we are using.
          gamma:1.0, $                 ; The current gamma value.
          file:file, $                 ; The name of the color table file.
          bottom:bottom, $             ; The bottom color index.
          top:top, $                   ; The top color index.
          topcolor:topColor, $         ; The top color in this color table.
          bottomcolor:bottomColor, $   ; The bottom color in this color table.
          reverse:0, $                 ; A reverse color table flag.
          notifyID:notifyID, $         ; Notification widget IDs.
          notifyObj:notifyObj, $       ; An vector of structures containng info about objects to notify.
          r:r, $                       ; The red color vector.
          g:g, $                       ; The green color vector.
          b:b, $                       ; The blue color vector.
          oindex:-1, $                 ; The original color table number.
          index:-1, $                  ; The current color table number.
          thisWindow:thisWindow, $     ; The current graphics window when this program is called.
          rstart:r, $                  ; The original red color vector.
          gstart:g, $                  ; The original green color vector.
          bstart:b, $                  ; The original blue color vector.
          colorimage:bar }             ; The color table image.

   ; Turn color protection on.

IF !D.NAME NE 'MAC' THEN Widget_Control, draw, Draw_Expose_Events=1

   ; Store the info structure in the user value of the top-level base.

Widget_Control, tlb, Set_UValue=info, /No_Copy
WSet, thisWindow
XManager, registerName, tlb, Group=group, /No_Block
END ; ************************************************************************

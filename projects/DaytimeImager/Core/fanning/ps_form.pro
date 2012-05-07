;+
; NAME:
;   PS_FORM
;
; PURPOSE:
;
;   This function displays a form the user can interactively manipulate
;   to configure the PostScript device driver (PS) setup. The function returns
;   a structure of keywords that can be sent directly to the DEVICE command
;   via its _EXTRA keyword
;
; AUTHOR:
;
;   FANNING SOFTWARE CONSULTING
;   David Fanning, Ph.D.
;   2642 Bradbury Court
;   Fort Collins, CO 80521 USA
;   Phone: 970-221-0438
;   E-mail: davidf@dfanning.com
;   Coyote's Guide to IDL Programming: http://www.dfanning.com
;
; MAJOR TOPICS:
;
;   Device Drivers, Hardcopy Output, PostScript Output
;
; PROCEDURE:
;
;   This is a pop-up form widget. It is a modal or blocking widget.
;   Keywords appropriate for the PostScript (PS) DEVICE command are returned.
;   The yellow box in the upper right hand corner of the form represents the
;   PostScript page. The green box represents the "window" on the PostScript
;   page where the graphics will be drawn.
;
;   Use your LEFT mouse button to move the plot "window" around the page.
;   Use your RIGHT mouse button to draw your own plot window on the page.
;
;   The CREATE FILE and ACCEPT buttons are meant to indicate slightly
;   different operations, although this is sometimes confusing. My idea
;   is that PS_FORM is a *configuration* dialog, something the user displays
;   if he or she wants to change the way the PostScript device is configured.
;   Thus, in many of my widget programs if the user clicks a "Write PostScript File"
;   button, I just go ahead and write a PostScript file without displaying the
;   form. (I can do this because I always keep a copy of the current device
;   configuration in my info structure.) To get to the form, the user must
;   select a "Configure PostScript Device" button.
;
;   At that time, the user might select the ACCEPT button to just change
;   the PostScript device configurations. Or the user can select the
;   CREATE FILE button, which both accepts the configuration *and* creates
;   a PostScript file. If you find the CREATE FILE button confusing, you
;   can just edit it out of the form and use the ACCEPT button for the
;   same purpose.
;
; HELP:
;
;   formInfo = PS_FORM(/Help)
;
; USAGE:
;
;  The calling procedure for this function in a widget program will look something
;  like this:
;
;     info.ps_config = PS_FORM(/Initialize)
;     ...
;     formInfo = PS_FORM(Cancel=canceled, Create=create, $
;                        Defaults=info.ps_config, Parent=event.top)
;
;     IF NOT canceled THEN BEGIN
;        IF create THEN BEGIN
;           thisDevice = !D.Name
;           Set_Plot, "PS"
;           Device, _Extra=formInfo
;
;           Enter Your Graphics Commands Here!
;
;           Device, /Close
;           Set_Plot, thisDevice
;        ENDIF
;        info.ps_config = formInfo
;     ENDIF
;
; OPTIONAL INPUT PARAMETERS:
;
;    XOFFSET -- Optional xoffset of the top-level base of PS_Form. Default is
;    to try to center the form on the display.
;
;    YOFFSET -- Optional yoffset of the top-level base of PS_Form. Default is
;    to try to center the form on the display.
;
; INPUT KEYWORD PARAMETERS:
;
;    BITS_PER_PIXEL -- The initial configuration of the bits per pixel button.
;
;    BLOCKING -- Set this keyword to make this a blocking widget under IDL 5.0.
;    (All widget programs block under IDL 4.0.)
;
;    COLOR -- The initial configuration of the color switch.
;
;    DEFAULTS -- A stucture variable of the same type and structure as the
;    RETURN VALUE of PS_FORM. It will set initial conditions. This makes
;    it possible to start PS_FORM up again with the same values it had the
;    last time it was called. For example:
;
;       mysetup = PS_FORM()
;       newsetup = PS_FORM(Defaults=mysetup)
;
;    NOTE: Using the DEFAULTS keyword will nullify any of the other
;    DEVICE-type keywords listed above (e.g., XSIZE, ENCAPSULATED, etc.)
;
;    ENCAPSULATED -- The initial configuration of the encapsulated switch.
;
;    FILENAME -- The initial filename to be used on the form.
;
;    HELP -- Prints a helpful message in the output log.
;
;    INCHES -- The initial configuration of the inches/cm switch.
;
;    INITIALIZE -- If this keyword is set, the program immediately returns the
;    "localdefaults" structure. This gives you the means to configue the
;    PostScript device without displaying the form to the user. I use this
;    to write a PostScript file directly and also to initialize my info
;    structure field that contains the current PostScript form setup. Passing
;    the setup structure into PS_FORM via the DEFAULTS keyword gives my PS_FORM
;    a program "memory".
;
;        info.ps_setup = PS_FORM(/Initialize)
;
;    LANDSCAPE -- The initial configuration of the landscape/portrait switch.
;
;    LOCALDEFAULTS -- A structure like the DEFAULTS structure. Used if the
;    "Local Defaults" button is pressed in the form. This gives you the
;    opportunity to have a "local" as well as "system" default setup.
;    If this keyword is not used, the procedure PS_Form_Set_Personal_Local_Defaults
;    is called. Use this procedure (see below) to define your own local
;    defaults.
;
;    XOFFSET -- The initial XOffSet of the PostScript window.
;
;    YOFFSET -- The initial YOffSet of the PostScript window.
;
;    XSIZE -- The initial XSize of the PostScript window.
;
;    YSIZE -- The initial YSize of the PostScript window.
;
; OUTPUT KEYWORD PARAMETERS
;
;    CANCEL -- This is an OUTPUT keyword. It is used to check if the user
;    selected the "Cancel" button on the form. Check this variable rather
;    than the return value of the function, since the return value is designed
;    to be sent directly to the DEVICE procedure. The varible is set to 1 if
;    the user selected the "Cancel" button. Otherwise, it is set to 0.
;
;    CREATE -- This output keyword can be used to determine if the user
;    selected the 'Create File' button rather than the 'Accept' button.
;    The value is 1 if selected, and 0 otherwise.
;
; RETURN VALUE:
;
;     formInfo = { PS_FORM_INFO, $
;                  xsize:0.0, $        ; The x size of the plot
;                  xoff:0.0, $         ; The x offset of the plot
;                  ysize:0.0, $        ; The y size of the plot
;                  yoff:0.0 $          ; The y offset of the plot
;                  filename:'', $      ; The name of the output file
;                  inches:0 $          ; Inches or centimeters?
;                  color:0, $          ; Color on or off?
;                  bits_per_pixel:0, $ ; How many bits per image pixel?
;                  encapsulated:0,$    ; Encapsulated or regular PostScript?
;                  landscape:0 }       ; Landscape or portrait mode?
;
; MAJOR FUNCTIONS and PROCEDURES:
;
;   None. Designed to work originally in conjunction with XWindow,
;   a resizable graphics window.
;
; MODIFICATION HISTORY:
;
;   Written by: David Fanning, RSI, March 1995.
;   Given to attendees of IDL training courses.
;
;   Modified to work when grapics device set to PostScript: 6 May 95.
;   Modified to configure initial conditions via keywords: 13 October 95.
;   Modified to load personal local defaults if LocalDefaults keyword not
;      used: 3 Nov 95.
;   Found and fixed bits_per_pixel error in Local Defaults setting
;     procedure: 3 Nov 95.
;   Modified to produce initial plot box with the same aspect ratio as
;      the current graphics window. (XSIZE or YSIZE keywords overrule this
;      behavior.) 22 Apr 96.
;   Fixed annoying behavior of going to default-sized plot box when selecting
;      the Landscape or Portrait option. Now keeps current plot box size.
;      22 Apr 96.
;   Made the size and offset text widgets a little bigger and changed the
;      size and offset formatting from F4.2 to F5.2 to accomodate larger plot
;      box sizes. 29 Apr 96.
;   Fixed a bug in the filename text widget that caused a crash when a CR
;      was hit. 3 Sept 96.
;   Added the Initialize keyword to immediately return the "localdefaults"
;      structure. 27 Oct 96.
;   Fixed another problem with the BITS_PER_PIXEL keyword. 27 Oct 96.
;   Made the return value a named structure of the name PS_FORM_INFO.
;      3 Nov 96.
;   Discovered and fixed a problem whereby YOFFSET was set incorrectly if
;      LOCALDEFAULTS was used instead of DEFAULTS keyword. 3 Nov 96.
;   Fixed bug in how Portrait mode was set using YSIZE and XSIZE keywords.
;      25 Nov 96.
;   Fixed a bug in how YOFFSET was calculated when in Landscape mode. 27 Nov 96.
;   Fixed a memory leak with the local defaults pointer. 25 Jan 97.
;   Added the CREATE keyword and modified the appearance of the form. 22 Apr 97.
;   Modifed subroutine names to avoid confusion. 22 Apr 97.
;   Fixed a bug I introduced when I added the CREATE keyword. 23 Apr 97.
;   Modified the program for IDL 5. 30 May 97, DWF.
;   Fixed Inches to CM exclusive button problem. 30 May 97, DWF.
;   Fixed a problem when the widget is killed with the mouse. 30 May 97. DWF
;   Added a Select Filename button. 12 Oct 97.
;   Modified program layout slightly. 12 Oct 97.
;   Added valid directory/file error checking for the filename. 12 Oct 97. DWF
;   Added further support for IDL 5 modal functionality. 20 Oct 97. DWF
;
;-

Pro PS_Form_Set_Personal_Local_Defaults, ptr

   ; If you don't use the LocalDefaults keyword, you can use
   ; this procedure to define local defaults for yourself.
   ; This procedure will be called if the keyword is not used.
   ; If you don't want to set local defaults, don't put anything
   ; in this procedure.

CD, Current=thisDirectory
filename = Filepath(Root_Dir=thisDirectory, 'idl.ps')
personalDefaults =  { PS_FORM_INFO, $
                    xsize:7.0, $             ; The x size of the plot
                    xoff:1.0, $              ; The x offset of the plot
                    ysize:5.0, $             ; The y size of the plot
                    yoff:3.0, $              ; The y offset of the plot
                    filename:filename, $     ; The name of the output file
                    inches:1, $              ; Inches on.
                    color:0, $               ; Color off.
                    bits_per_pixel:8, $      ; 8 bits per image pixel.
                    encapsulated:0,$         ; Encapsulated file off.
                    landscape:0 }            ; Portrait mode on.

Handle_Value, ptr, personalDefaults, /Set, /No_Copy

END ;*******************************************************************



Pro PS_FORM_Select_File, event

   ; Allows the user to select a filename for writing.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Start with the name in the filename widget.

Widget_Control, info.filename, Get_Value=initialFilename
initialFilename = initialFilename(0)
filename = Pickfile(/Write, File=initialFilename)
IF filename NE '' THEN $
   Widget_Control, info.filename, Set_Value=filename
Widget_Control, event.top, Set_UValue=info, /No_Copy
END ;*******************************************************************



Function PS_Form_PlotBox_Coords, xsize, ysize, xoff, yoff, inches

   ; This function converts sizes and offsets to appropriate
   ; Device coordinates for drawing the PLOT BOX on the PostScript
   ; page. The return value is a [2,5] array.

returnValue = IntArr(2,5)

IF inches EQ 0 THEN BEGIN
   xs = xsize * 10.0 / 2.54
   ys = ysize * 10.0 / 2.54
   xof = xoff * 10.0 / 2.54
   yof = yoff * 10.0 / 2.54
ENDIF ELSE BEGIN
   xs = xsize * 10.0
   ys = ysize * 10.0
   xof = xoff * 10.0
   yof = yoff * 10.0
ENDELSE

xcoords = Round([xof, xof+xs, xof+xs, xof, xof])
ycoords = Round([yof, yof, yof+ys, yof+ys, yof])

returnValue(0,*) = xcoords
returnValue(1,*) = ycoords

RETURN, returnValue
END ;*******************************************************************



Pro PS_Form_Set_Local_Defaults, event

   ; Define local variables

xsize = 0
ysize = 0
xoff = 0
yoff = 0
landscape = 0
encapsulated = 0
color = 0
filename = ''
bits_per_pixel = 0
inches = 0

   ; Get the info structure out of the TLB.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Are there local defaults loaded in the program?

check = Handle_Info(info.localDefaultPtr)
IF check EQ 0 THEN BEGIN
   ok = Widget_Message('No local defaults loaded in program.')
   Widget_Control, event.top, Set_UValue=info, /No_Copy
   RETURN
ENDIF

   ; Get the local defaults structure and process it.
   ; Special processing for YOffset.

Handle_Value, info.localDefaultPtr, defaults

yoff_flag = 0
names = Tag_Names(defaults)
yoff_test = Where(names EQ 'YOFF')
IF yoff_test(0) GT 0 THEN yoff_flag = 1 ELSE yoff_flag = 0
FOR j=0,N_Elements(names)-1 DO BEGIN
   IF names(j) NE 'YOFF' THEN BEGIN
      str = names(j) + '= defaults.' + names(j)
      dummy = Execute(str)
   ENDIF
ENDFOR

   ; Process YOffset if yoff_flag is set. (ASSUMING xoff is DEFINED
   ; and passed in with the DEFAULTS!!)

IF yoff_flag THEN BEGIN
   yof = Where(names EQ 'YOFF')
   IF landscape EQ 1 AND inches EQ 0 THEN BEGIN
      yoff = xoff
      str = 'xoff = 27.94 - defaults.' + names(yof)
   ENDIF
   IF landscape EQ 1 AND inches EQ 1 THEN BEGIN
      yoff = xoff
      str = 'xoff = 11.0 - defaults.' + names(yof)
   ENDIF
   IF landscape EQ 0 AND inches EQ 0 THEN $
      str = 'yoff = defaults.' + names(yof)
   IF landscape EQ 0 AND inches EQ 1 THEN $
      str = 'yoff = defaults.' + names(yof)
   dummy = Execute(str(0))
ENDIF

IF landscape EQ 1 THEN BEGIN

      ; Make the draw widget the current graphics window

   WSet, info.wid

      ; Erase the old window and draw the Landscape page outline
      ; and the default Landscape box outline

   Erase

      ; Make the draw widget have a charcoal background color.

   TV, Replicate(info.charcoal,114,114)
   PlotS, info.landbox_x, info.landbox_y, /Device, Color=info.pagecolor
   coords = PS_Form_PlotBox_Coords(xsize, ysize, xoff, yoff, inches)
   PlotS, coords(0,*), coords(1,*), Color=info.boxcolor, /Device

      ; Draw the Landscape page outline in the pixmap

   WSet, info.pixwid
   Erase

      ; Make the draw widget have a charcoal background color.

   TV, Replicate(info.charcoal,114,114)
   PlotS, info.landbox_x, info.landbox_y, /Device, Color=info.pagecolor

      ; Make the draw widget the current graphics window

   WSet, info.wid

      ; Change the labels to their default values

   xsizeStr = String(xsize, Format='(F5.2)')
   ysizeStr = String(ysize, Format='(F5.2)')
   xoffStr =  String(xoff, Format='(F5.2)')
   yoffStr =  String(yoff, Format='(F5.2)')

      ; Put the new default values into the appropriate boxes on the form

   Widget_Control, info.xsize, Set_Value=xsizeStr
   Widget_Control, info.ysize, Set_Value=ysizeStr
   Widget_Control, info.xoff, Set_Value=xoffStr
   Widget_Control, info.yoff, Set_Value=yoffStr

      ; Set up the landscape x and y default maximums and minimums

   info.lbox_xmax = Max(coords(0,*))
   info.lbox_ymax = Max(coords(1,*))
   info.lbox_xmin = Min(coords(0,*))
   info.lbox_ymin = Min(coords(1,*))

ENDIF ELSE BEGIN

      ; Make the draw widget the current graphics window

   WSet, info.wid

      ; Erase the old window and draw the Portrait page outline
      ; and the default Portrait box outline

   Erase
      ; Make the draw widget have a charcoal background color.

   TV, Replicate(info.charcoal,114,114)
   PlotS, info.portraitbox_x, info.portraitbox_y, /Device, Color=info.pagecolor
   coords = PS_Form_PlotBox_Coords(xsize, ysize, xoff, yoff, inches)
   PlotS, coords(0,*), coords(1,*), Color=info.boxcolor, /Device

      ; Draw the Portrait page outline on the pixmap and then reset the
      ; current graphics window

   WSet, info.pixwid
   Erase
      ; Make the draw widget have a charcoal background color.

   TV, Replicate(info.charcoal,114,114)
   PlotS, info.portraitbox_x, info.portraitbox_y, /Device, $
      Color=info.pagecolor
   WSet, info.wid

      ; Change the labels to their default values

   xsizeStr = String(xsize, Format='(F5.2)')
   ysizeStr = String(ysize, Format='(F5.2)')
   xoffStr =  String(xoff, Format='(F5.2)')
   yoffStr =  String(yoff, Format='(F5.2)')

      ; Put the new default values into the appropriate boxes on the form

   Widget_Control, info.xsize, Set_Value=xsizeStr
   Widget_Control, info.ysize, Set_Value=ysizeStr
   Widget_Control, info.xoff, Set_Value=xoffStr
   Widget_Control, info.yoff, Set_Value=yoffStr

      ; Set up the portrait x and y maximums and minimums

   info.pbox_xmax = Max(coords(0,*))
   info.pbox_ymax = Max(coords(1,*))
   info.pbox_xmin = Min(coords(0,*))
   info.pbox_ymin = Min(coords(1,*))

ENDELSE

   ; Set encapsulation buttons.

IF encapsulated EQ 0 THEN BEGIN
   Widget_Control, info.encap_on, Set_Button=0
   Widget_Control, info.encap_off, Set_Button=1
   info.encapsulated = encapsulated
ENDIF ELSE BEGIN
   Widget_Control, info.encap_on, Set_Button=1
   Widget_Control, info.encap_off, Set_Button=0
   info.encapsulated = encapsulated
ENDELSE


   ; Set color buttons.

IF color EQ 0 THEN BEGIN
   Widget_Control, info.col_on, Set_Button=0
   Widget_Control, info.col_off, Set_Button=1
   info.color = color
ENDIF ELSE BEGIN
   Widget_Control, info.col_on, Set_Button=1
   Widget_Control, info.col_off, Set_Button=0
   info.color = color
ENDELSE

   ; Set inch/cm buttons.

IF inches EQ 0 THEN BEGIN
   Widget_Control, info.inch, Set_Button=0
   Widget_Control, info.cm, Set_Button=1
   info.inches = inches
ENDIF ELSE BEGIN
   Widget_Control, info.inch, Set_Button=1
   Widget_Control, info.cm, Set_Button=0
   info.inches = inches
ENDELSE

   ; Set bits_per_pixel buttons.

CASE bits_per_pixel OF
   2: BEGIN
      Widget_Control, info.bit2, Set_Button=1
      Widget_Control, info.bit8, Set_Button=0
      Widget_Control, info.bit4, Set_Button=0
      info.bits_per_pixel = 2
      END
   4: BEGIN
      Widget_Control, info.bit2, Set_Button=0
      Widget_Control, info.bit4, Set_Button=1
      Widget_Control, info.bit8, Set_Button=0
      info.bits_per_pixel = 4
      END
   8: BEGIN
      Widget_Control, info.bit2, Set_Button=0
      Widget_Control, info.bit8, Set_Button=1
      Widget_Control, info.bit4, Set_Button=0
      info.bits_per_pixel = 8
      END
ENDCASE

   ; Set default filename.

Widget_Control, info.filename, Set_Value=filename

   ; Set protrait/landscape button.

IF landscape EQ 0 THEN BEGIN
   Widget_Control, info.land, Set_Button=0
   Widget_Control, info.port, Set_Button=1
   info.landscape = landscape
ENDIF ELSE BEGIN
   Widget_Control, info.land, Set_Button=1
   Widget_Control, info.port, Set_Button=0
   info.landscape = landscape
ENDELSE

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ;*******************************************************************



Pro PS_Form_Set_System_Defaults, event

   ; This event handler sets up the system default values. There will
   ; be different defaults based on whether the form is in landscape
   ; or portrait mode when the button is selected.

   ; Get the info stucture.

Widget_Control, event.top, Get_UValue=info, /No_Copy

IF info.landscape EQ 1 THEN BEGIN

      ; Make the draw widget the current graphics window

   WSet, info.wid

      ; Erase the old window and draw the Landscape page outline
      ; and the default Landscape box outline

   Erase
      ; Make the draw widget have a charcoal background color.

   TV, Replicate(info.charcoal,114,114)
   PlotS, info.landbox_x, info.landbox_y, /Device, Color=info.pagecolor
   PlotS, info.lplotbox_x, info.lplotbox_y, Color=info.boxcolor, /Device

      ; Draw the Landscape page outline in the pixmap

   WSet, info.pixwid
   Erase
      ; Make the draw widget have a charcoal background color.

   TV, Replicate(info.charcoal,114,114)
   PlotS, info.landbox_x, info.landbox_y, /Device, Color=info.pagecolor

      ; Make the draw widget the current graphics window

   WSet, info.wid

      ; Change the labels to their default values

   xsize = '24.13'
   ysize = '17.78'
   xoff = '1.91'
   yoff = '1.91'

      ; Put the new default values into the appropriate boxes on the form

   Widget_Control, info.xsize, Set_Value=xsize
   Widget_Control, info.ysize, Set_Value=ysize
   Widget_Control, info.xoff, Set_Value=xoff
   Widget_Control, info.yoff, Set_Value=yoff

      ; Set up the landscape x and y default maximums and minimums

   info.lbox_xmax = 106
   info.lbox_ymax = 82
   info.lbox_xmin = 8
   info.lbox_ymin = 8

ENDIF ELSE BEGIN

      ; Make the draw widget the current graphics window

   WSet, info.wid

      ; Erase the old window and draw the Portrait page outline
      ; and the default Portrait box outline

   Erase

      ; Make the draw widget have a charcoal background color.

   TV, Replicate(info.charcoal,114,114)
   PlotS, info.portraitbox_x, info.portraitbox_y, /Device, $
      Color=info.pagecolor
   PlotS, info.pplotbox_x, info.pplotbox_y, Color=info.boxcolor, /Device

      ; Draw the Portrait page outline on the pixmap and then reset the
      ; current graphics window

   WSet, info.pixwid
   Erase

      ; Make the draw widget have a charcoal background color.

   TV, Replicate(info.charcoal,114,114)
   PlotS, info.portraitbox_x, info.portraitbox_y, /Device, $
      Color=info.pagecolor
   WSet, info.wid

      ; Change the labels to their default values

   xsize = '17.78'
   ysize = '12.70'
   xoff = '1.91'
   yoff = '12.70'

      ; Put the new default values into the appropriate boxes on the form

   Widget_Control, info.xsize, Set_Value=xsize
   Widget_Control, info.ysize, Set_Value=ysize
   Widget_Control, info.xoff, Set_Value=xoff
   Widget_Control, info.yoff, Set_Value=yoff

      ; Set up the portrait x and y maximums and minimums

   info.pbox_xmax = 82
   info.pbox_ymax = 106
   info.pbox_xmin = 8
   info.pbox_ymin = 60

ENDELSE

   ; Set encapsulation buttons.

Widget_Control, info.encap_on, Set_Button=0
Widget_Control, info.encap_off, Set_Button=1
info.encapsulated = 0

   ; Set color buttons.

Widget_Control, info.col_on, Set_Button=0
Widget_Control, info.col_off, Set_Button=1
info.color = 0

   ; Set inch/cm buttons.

Widget_Control, info.inch, Set_Button=0
Widget_Control, info.cm, Set_Button=1
info.inches = 0

   ; Set bits_per_pixel buttons.

Widget_Control, info.bit2, Set_Button=0
Widget_Control, info.bit8, Set_Button=0
Widget_Control, info.bit4, Set_Button=1
info.bits_per_pixel = 4

   ; Set default filename.

filename = 'idl.ps'
Widget_Control, info.filename, Set_Value=filename

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ;*******************************************************************



Pro PS_Form_Null_Events, event
END ;*******************************************************************



Function PS_Form_What_Button_Type, event

   ; Checks event.type to find out what kind of button
   ; was clicked in a draw widget. This is NOT an event handler.

type = ['DOWN', 'UP', 'MOTION', 'SCROLL']
Return, type(event.type)
END ;*******************************************************************




Function PS_Form_What_Button_Pressed, event

   ; Checks event.press to find out what kind of button
   ; was pressed in a draw widget.  This is NOT an event handler.

button = ['NONE', 'LEFT', 'MIDDLE', 'NONE', 'RIGHT']
Return, button(event.press)
END ;*******************************************************************





Function PS_Form_What_Button_Released, event

   ; Checks event.release to find out what kind of button
   ; was released in a draw widget.  This is NOT an event handler.

button = ['NONE', 'LEFT', 'MIDDLE', 'NONE', 'RIGHT']
Return, button(event.release)
END ;*******************************************************************





Pro PS_Form_NumEvents, event

   ; If an event comes here, read the offsets and sizes from the
   ; form and draw the appropriately sized box in the draw widget.

Widget_Control, event.top, Get_UValue= info, /No_Copy

   ; Get current values for offset and sizes

Widget_Control, info.xsize, Get_Value=xsize
Widget_Control, info.ysize, Get_Value=ysize
Widget_Control, info.xoff, Get_Value=xoff
Widget_Control, info.yoff, Get_Value=yoff

xsize = xsize(0)
ysize = ysize(0)
xoff = xoff(0)
yoff = yoff(0)


   ; Don't let the user pick sizes that don't make sense
   ; Sizes must fit on page along with minimum offsets

IF info.inches EQ 1 THEN Begin ; Calculation in inches

   IF info.landscape EQ 0 THEN Begin    ; Portrait Mode

        xsize = 0.25 > xsize < 8.25
        ysize = 0.25 > ysize < 10.75
        IF xsize + xoff GT 8.25 THEN xoff = 8.5 - xsize
        IF ysize + yoff GT 10.75 THEN yoff = 11.0 - ysize

   ENDIF ELSE Begin                     ; Landscape Mode

        ysize = 0.25 > ysize < 8.25
        xsize = 0.25 > xsize < 10.75
        IF xsize + xoff GT 10.75 THEN xoff = 11.0 - xsize
        IF ysize + yoff GT 8.25 THEN yoff = 8.5 - ysize

   ENDELSE

ENDIF ELSE Begin              ; Calculation in centimeters

   IF info.landscape EQ 0 THEN Begin    ; Portrait Mode
        xsize = 1 > xsize < 20.95
        ysize = 1 > ysize < 27.30
        IF xsize + xoff GT 20.95 THEN xoff = 20.95 - xsize
        IF ysize + yoff GT 27.30 THEN yoff = 27.30 - ysize

   ENDIF ELSE Begin                     ; Landscape Mode

        ysize = 1 > ysize < 20.95
        xsize = 1 > xsize < 27.30
        IF xsize + xoff GT 27.30 THEN xoff = 27.30 - xsize
        IF ysize + yoff GT 20.95 THEN yoff = 20.95 - ysize

   ENDELSE

ENDELSE

   ; Put correct sizes back into the text fields

Widget_Control, info.xsize, $
   Set_Value=StrTrim(String(xsize, Format='(F5.2)'), 2)
Widget_Control, info.ysize, $
   Set_Value=StrTrim(String(ysize, Format='(F5.2)'), 2)
Widget_Control, info.xoff, Set_Value=StrTrim(String(xoff, Format='(F5.2)'), 2)
Widget_Control, info.yoff, Set_Value=StrTrim(String(yoff, Format='(F5.2)'), 2)

   ; Convert sizes to Device coordinates

IF info.inches EQ 1 THEN Begin     ; 1 inch equals 10 pixels

   xsize = xsize * 10.0
   xoff = xoff * 10.0
   ysize = ysize * 10.0
   yoff = yoff * 10.0

ENDIF ELSE Begin                   ; 2.54 cm equals 1 inch equals 10 pixels

   xsize = xsize * 10.0 / 2.54
   xoff = xoff * 10.0 / 2.54
   ysize = ysize * 10.0 / 2.54
   yoff = yoff * 10.0 / 2.54

ENDELSE

   ; Make the draw widget the current graphics window

WSet, info.wid

   ; Copy the page outline from the pixmap

Device, Copy=[0, 0, 114, 114, 0, 0, info.pixwid]

   ; Draw the appropriately sized box

PlotS, [xoff, xoff+xsize, xoff+xsize, xoff, xoff], Color=info.boxcolor, $
       [yoff, yoff, yoff+ysize, yoff+ysize, yoff], /Device

   ; Update the box parameters

IF info.landscape EQ 0 THEN Begin      ; Portrait mode

   info.pbox_xmax = (xoff + xsize)
   info.pbox_xmin = xoff
   info.pbox_ymax = (yoff + ysize)
   info.pbox_ymin = yoff

ENDIF ELSE Begin                       ; Landscape mode

   info.lbox_xmax = (xoff + xsize)
   info.lbox_xmin = xoff
   info.lbox_ymax = (yoff + ysize)
   info.lbox_ymin = yoff

 ENDELSE

    ; Put the info structure back into the top-level base

Widget_Control, event.top, Set_UValue=info, /No_Copy

END ;*******************************************************************




Pro PS_Form_MoveBox, event

   ; This is the event handler that allows the user to "move"
   ; the plot box around in the page window. It will set the
   ; event handler back to "PS_Form_Draw_Events" when it senses an
   ; "UP" draw button event and it will also turn PS_Form_Draw_Motion_Events
   ; OFF.

   ; Get the info structure out of the top-level base.

Widget_Control, event.top, Get_UValue=info, /No_Copy

whatButtonType = PS_Form_What_Button_Type(event)

IF whatButtonType EQ 'UP' THEN Begin

   Widget_Control, info.draw, Draw_Motion_Events=0, $ ; Motion events off
        Event_Pro='PS_Form_Draw_Events' ; Change to normal processing

      ; Copy page outline from the pixmap

   Device, Copy=[0, 0, 114, 114, 0, 0, info.pixwid]

      ; Draw the final box shape

Plots, [info.xmin, info.xmin, info.xmax, info.xmax, info.xmin], $
   Color=info.boxcolor, [info.ymin, info.ymax, info.ymax, info.ymin, $
   info.ymin], /Device

      ; Update new offsets

   IF info.inches EQ 0 THEN Begin      ; Offset in Centimeters

      xoff = (info.xmin/10.0) * 2.54
      yoff = (info.ymin/10.0) * 2.54

   ENDIF ELSE Begin                    ; Offset in Inches

      xoff = (info.xmin/10.0)
      yoff = (info.ymin/10.0)

   ENDELSE

      ; Update new offsets in the offset boxes on the form.

   Widget_Control, info.xoff, $
      Set_Value=StrTrim(String(xoff, Format='(F5.2)'), 2)
   Widget_Control, info.yoff, $
      Set_Value=StrTrim(String(yoff, Format='(F5.2)'), 2)

      ; Update the new box parameters in the info structure

   IF info.landscape EQ 0 THEN Begin      ; Portrait mode

      info.pbox_xmax = info.xmax
      info.pbox_xmin = info.xmin
      info.pbox_ymax = info.ymax
      info.pbox_ymin = info.ymin

   ENDIF ELSE Begin                       ; Landscape mode

      info.lbox_xmax = info.xmax
      info.lbox_xmin = info.xmin
      info.lbox_ymax = info.ymax
      info.lbox_ymin = info.ymin

    ENDELSE

      ; Put the info structure back in the top-level base and RETURN

   Widget_Control, event.top, Set_UValue=info, /No_Copy
   Return

ENDIF

   ; You come to this section of the code for all events except
   ; an UP button event. Most of the action in this event handler
   ; occurs here.

   ; Make the draw widget the current graphics window

WSet, info.wid

   ; Copy the page outline from the pixmap into the window, thus
   ; erasing the last box you drew.

Device, Copy=[0, 0, 114, 114, 0, 0, info.pixwid]

   ; Calculate the length of of the current box

xlength = info.xmax - info.xmin
ylength = info.ymax - info.ymin

   ; Calculate location of lower-left corner of box.
   ; Constrain the box to lie inside the page outline.

IF info.landscape EQ 0 THEN Begin    ; Portrait Mode

   test = info.xmin + event.x - info.mouse_x
   info.xmin = 2.5 > test
   info.xmin = info.xmin  < (86 - xlength)

   test = info.ymin + event.y - info.mouse_y
   info.ymin = 2.5 > test
   info.ymin = info.ymin < (111 - ylength)

ENDIF ELSE Begin                    ; Landscape Mode

   test = info.xmin + event.x - info.mouse_x
   info.xmin = 2.5 > test
   info.xmin = info.xmin  < (111 - xlength)

   test = info.ymin + event.y - info.mouse_y
   info.ymin = 2.5 > test
   info.ymin = info.ymin < (86 - ylength)

ENDELSE

   ; Calculate upper-right corners of the box

info.xmax = info.xmin + xlength
info.ymax = info.ymin + ylength

   ; Draw the new box on the display

Plots, [info.xmin, info.xmin, info.xmax, info.xmax, info.xmin], $
   Color=info.boxcolor, [info.ymin, info.ymax, info.ymax, info.ymin, $
   info.ymin], /Device

   ; Update the mouse pointer

info.mouse_x = event.x
info.mouse_y = event.y

   ; Put the info structure back into the top-level base.

Widget_Control, event.top, Set_UValue=info, /No_Copy

END ;*******************************************************************



Pro Ps_Form_DrawBox, event

   ; This event handler is summoned when a RIGHT button is clicked
   ; in the draw widget. It allows the user to draw the outline of a
   ; box with the mouse. It will continue drawing the new box shape
   ; until an UP event is detected. Then it will set the event handler
   ; back to PS_Form_Draw_Events and turn PS_Form_Draw_Motion_Events to OFF.

   ; Get the info structure out of the top-level base.

Widget_Control, event.top, Get_UValue=info, /No_Copy

whatButtonType = PS_Form_What_Button_Type(event)

IF whatButtonType EQ 'UP' THEN Begin

   Widget_Control, info.draw, Draw_Motion_Events=0, $ ; Motion events off
        Event_Pro='PS_Form_Draw_Events' ; Change to normal processing

      ; Make the draw widget the current graphics window

WSet, info.wid

      ; Copy the page outline from the pixmap

   Device, Copy=[0, 0, 114, 114, 0, 0, info.pixwid]

      ; Draw the final box shape

   PlotS, [info.xs, info.xs, info.xcur, info.xcur, info.xs], $
      Color=info.boxcolor, [info.ys, info.ycur, info.ycur, info.ys, info.ys],$
      /Device

      ; Update new box sizes and offsets

   xmax = (info.xs > info.xcur)
   xmin = (info.xs < info.xcur)
   ymax = (info.ys > info.ycur)
   ymin = (info.ys < info.ycur)

   IF info.inches EQ 0 THEN Begin    ; Values in Centimeters (10 pixels/inch)

      xoff = (xmin/10.0 * 2.54)
      yoff = ymin/10.0 * 2.54
      xsize = (xmax - xmin)/10.0 * 2.54
      ysize = (ymax - ymin)/10.0 * 2.54

   ENDIF ELSE Begin                  ; Values in Inches (10 pixels/inch)

      xoff = (xmin/10.0)
      yoff = (ymin/10.0)
      xsize = (xmax - xmin)/10.0
      ysize = (ymax - ymin)/10.0

   ENDELSE

      ; Update the new sizes in the size and offset boxes

   Widget_Control, info.xsize, $
      Set_Value=StrTrim(String(xsize, Format='(F5.2)'), 2)
   Widget_Control, info.ysize, $
      Set_Value=StrTrim(String(ysize, Format='(F5.2)'), 2)
   Widget_Control, info.xoff, $
      Set_Value=StrTrim(String(xoff, Format='(F5.2)'), 2)
   Widget_Control, info.yoff, $
      Set_Value=StrTrim(String(yoff, Format='(F5.2)'), 2)

      ; Update the box location

   IF info.landscape EQ 0 THEN Begin      ; Portrait mode

      info.pbox_xmax = info.xcur > info.xs
      info.pbox_xmin = info.xcur < info.xs
      info.pbox_ymax = info.ycur > info.ys
      info.pbox_ymin = info.ycur < info.ys

   ENDIF ELSE Begin                       ; Landscape mode

      info.lbox_xmax = info.xcur > info.xs
      info.lbox_xmin = info.xcur < info.xs
      info.lbox_ymax = info.ycur > info.ys
      info.lbox_ymin = info.ycur < info.ys

    ENDELSE

      ; Put the info structure back into the top-level base and RETURN

   Widget_Control, event.top, Set_UValue=info, /No_Copy
   Return

ENDIF

   ; This is the potion of the code that handles all events except for
   ; UP button events. The bulk of the work is done here. Basically,
   ; you need to erase the old box and draw a new box at the new
   ; location. Just keep doing this until you get an UP event.

   ; Make the draw widget be the current graphics window

WSet, info.wid

   ; Copy the page outline from the pixmap

Device, Copy=[0, 0, 114, 114, 0, 0, info.pixwid]

   ; Locate the current position of the cursor. Make sure it is
   ; located inside the page outline.

IF info.landscape EQ 0 THEN Begin ; Portrait mode

   info.xcur = 2.5 > event.x < 84.5
   info.ycur = 2.5 > event.y < 109.5

ENDIF ELSE Begin                  ; Landscape mode

   info.xcur = 2.5 > event.x < 109.5
   info.ycur = 2.5 > event.y < 84.5

ENDELSE

   ; Draw the new box on the display

Plots, [info.xs, info.xs, info.xcur, info.xcur, info.xs], $
   Color=info.boxcolor, [info.ys, info.ycur, info.ycur, info.ys, info.ys], $
   /Device

   ; Put the info structure back in the top-level base.

Widget_Control, event.top, Set_UValue=info, /No_Copy

END ;*******************************************************************




Pro PS_Form_Draw_Events, event

whatButtonType = PS_Form_What_Button_Type(event)

IF whatButtonType NE 'DOWN' THEN Return

   ; Get info structure out of TLB

Widget_Control, event.top, Get_UValue=info, /No_Copy

whatButtonPressed = PS_Form_What_Button_Pressed(event)
CASE whatButtonPressed OF

   'RIGHT': Begin

         ; Resize the plot box interactively. Change the event handler
         ; to PS_Form_DrawBox. All subsequent events will be handled by
         ; PS_Form_DrawBox until an UP event is detected. Then you will
         ; return to this event handler. Also, turn motion events ON.

      Widget_Control, event.id, Event_Pro='PS_Form_DrawBox', $
         Draw_Motion_Events=1

         ; Portrait mode or landscape mode? Set constraints accordingly

      IF info.landscape EQ 0 THEN Begin        ; Portrait mode

         info.xs = 2.5 > event.x < 85.0
         info.ys = 2.5 > event.y < 110.0
         info.xcur = 2.5 > event.x < 85.0
         info.ycur = 2.5 > event.y < 110.0

      ENDIF ELSE Begin                         ; Landscape mode

         info.xs = 2.5 > event.x < 110.0
         info.ys = 2.5 > event.y < 85.0
         info.xcur = 2.5 > event.x < 110.0
         info.ycur = 2.5 > event.y < 85.0

      ENDELSE

      Plots, [info.xs, info.xs, info.xcur, info.xcur, info.xs], $
          Color=info.boxcolor, $
          [info.ys, info.ycur, info.ycur, info.ys, info.ys], /Device

      End

   'LEFT': Begin

         ; Resize the plot box interactively. Change the event handler
         ; to PS_Form_MoveBox. All subsequent events will be handled by
         ; PS_Form_MoveBox until an UP event is detected. Then you will
         ; return to this  event handler. Also, turn motion events ON.

         ; Copy max and min values into the info structure from the
         ; current box size

      IF info.landscape EQ 0 THEN Begin    ; Portrait mode

         info.xmax = info.pbox_xmax
         info.xmin = info.pbox_xmin
         info.ymax = info.pbox_ymax
         info.ymin = info.pbox_ymin

      ENDIF ELSE Begin                     ; Landscape mode

         info.xmax = info.lbox_xmax
         info.xmin = info.lbox_xmin
         info.ymax = info.lbox_ymax
         info.ymin = info.lbox_ymin

      ENDELSE

         ; Only move the box if the cursor is inside the box.
         ;If it is NOT, then RETURN.

     IF event.x LT info.xmin OR event.x GT info.xmax OR event.y  $
         LT info.ymin OR event.y GT info.ymax THEN Begin
         Widget_Control, event.top, Set_UValue=info, /No_Copy
         Return
     ENDIF

          ; Relocate the event handler and turn motion events ON.

      Widget_Control, event.id, Event_Pro='PS_Form_MoveBox', $
         Draw_Motion_Events=1

        ; Locate the cursor point inside the box that will be moved

      info.mouse_x = event.x
      info.mouse_y = event.y

      End

   ELSE: ; Middle button ignored in this program

ENDCASE

   ; Put the info structure back into the top-level base

Widget_Control, event.top, Set_UValue=info, /No_Copy

END ;*******************************************************************




Pro PS_Form_Event, event

   ; This is the main event handler for PS_FORM. It handles
   ; the exclusive buttons on the form. Other events on the form
   ; will have their own event handlers.

   ; Get the name of the event structure

name = Tag_Names(event, /Structure_Name)

   ; If name is NOT "WIDGET_BUTTON" or this is not a button
   ; selection event, RETURN.

IF name NE 'WIDGET_BUTTON' OR event.select NE 1 THEN Return

   ; Get the info structure out of the top-level base

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Get the User Value of the Button

Widget_Control, event.id, Get_UValue=thisButton

   ; Respond appropriately to whatever button was selected

CASE thisButton OF

   'INCHES': Begin

         ; Get current centimeter values

      IF info.inches NE 1 THEN BEGIN
         Widget_Control, info.xsize, Get_Value=xsize
         Widget_Control, info.ysize, Get_Value=ysize
         Widget_Control, info.xoff, Get_Value=xoff
         Widget_Control, info.yoff, Get_Value=yoff

         ; Set values to inches and make a string

         xsize = StrTrim(String(Float(xsize) / 2.54, Format='(F5.2)'), 2)
         ysize = StrTrim(String(Float(ysize) / 2.54, Format='(F5.2)'), 2)
         xoff = StrTrim(String(Float(xoff) / 2.54, Format='(F5.2)'), 2)
         yoff = StrTrim(String(Float(yoff) / 2.54, Format='(F5.2)'), 2)

         ; Put inch values on the labels

         Widget_Control, info.xsize, Set_Value=xsize
         Widget_Control, info.ysize, Set_Value=ysize
         Widget_Control, info.xoff, Set_Value=xoff
         Widget_Control, info.yoff, Set_Value=yoff

         ; Update the info structure to indicate that current status is inches

         info.inches = 1
      EndIF
      End

   'CENTIMETERS': Begin

         ; Get current inch values

      IF info.inches NE 0 THEN Begin
         Widget_Control, info.xsize, Get_Value=xsize
          Widget_Control, info.ysize, Get_Value=ysize
         Widget_Control, info.xoff, Get_Value=xoff
         Widget_Control, info.yoff, Get_Value=yoff

         ; Set values to centimeters and make a string

         xsize = StrTrim(String(Float(xsize) * 2.54, Format='(F5.2)'), 2)
         ysize = StrTrim(String(Float(ysize) * 2.54, Format='(F5.2)'), 2)
         xoff = StrTrim(String(Float(xoff) * 2.54, Format='(F5.2)'), 2)
         yoff = StrTrim(String(Float(yoff) * 2.54, Format='(F5.2)'), 2)

         ; Put inch values on the labels

         Widget_Control, info.xsize, Set_Value=xsize
         Widget_Control, info.ysize, Set_Value=ysize
         Widget_Control, info.xoff, Set_Value=xoff
         Widget_Control, info.yoff, Set_Value=yoff

         ; Update the info structure to indicate that current
         ; status is centimeters

         info.inches = 0
      EndIF
      End

   'COLOR_ON': Begin

         ; Update the info structure to indicate that current status
         ; is COLOR ON

      info.color = 1

      End

   'COLOR_OFF': Begin

         ; Update the info structure to indicate that current status
         ; is COLOR OFF

      info.color = 0

      End

   'BITS2': Begin

         ; Update the info structure to indicate that current status is BITS=2

      info.bits_per_pixel = 2

      End

   'BITS4': Begin

         ; Update the info structure to indicate that current status is BITS=4

      info.bits_per_pixel = 4

      End

   'BITS8': Begin

         ; Update the info structure to indicate that current status is BITS=8

      info.bits_per_pixel = 8

      End

   'LANDSCAPE': Begin

          ; Going to landscape mode. Have to change the draw widget window.
          ; Make the draw widget the current graphics window

      WSet, info.wid

          ; Erase the old window and draw the Landscape page outline
          ; and the default Landscape box outline

      Erase

         ; Make the draw widget have a charcoal background color.

      TV, Replicate(info.charcoal,114,114)

         ; Get the curent sizes of the box.

      Widget_Control, info.xsize, Get_Value=xsize
      Widget_Control, info.ysize, Get_Value=ysize
      xsize = Float(xsize(0))
      ysize = Float(ysize(0))

     ; Calculate new offsets.

      IF info.inches EQ 1 THEN xoff = (11.0 - xsize) / 2.0
      IF info.inches EQ 0 THEN xoff = (27.95 - xsize) / 2.0
      IF info.inches EQ 1 THEN yoff = (8.5 - ysize) / 2.0
      IF info.inches EQ 0 THEN yoff = (21.60 - ysize) / 2.0

       ; Constrain user sizes and offsets to fit on the page.

      IF info.inches EQ 0 THEN BEGIN
         xsize = 0.64 > xsize < 27.3
         ysize = 0.64 > ysize < 20.95
         xoff = 0.64 > xoff < 27.3
         yoff = 0.64 > yoff < 20.95
      ENDIF
      IF info.inches EQ 1 THEN BEGIN
         xsize = 0.25 > xsize < 10.75
         ysize = 0.25 > ysize < 8.25
         xoff = 0.25 > xoff < 10.75
         yoff = 0.25 > yoff < 8.25
      ENDIF

         ; Get the box coordinates.

      box = PS_Form_PlotBox_Coords(xsize, ysize, xoff, yoff, info.inches)

      PlotS, info.landbox_x, info.landbox_y, /Device, Color=info.pagecolor
      PlotS, box, Color=info.boxcolor, /Device

          ; Draw the Landscape page outline in the pixmap

      WSet, info.pixwid
      Erase

         ; Make the draw widget have a charcoal background color.

      TV, Replicate(info.charcoal,114,114)
      PlotS, info.landbox_x, info.landbox_y, /Device, Color=info.pagecolor

          ; Make the draw widget the current graphics window

      WSet, info.wid

         ; Change the labels to their default values

       xsize = String(xsize, Format='(F5.2)')
       ysize = String(ysize, Format='(F5.2)')
       xoff = String(xoff, Format='(F5.2)')
       yoff = String(yoff, Format='(F5.2)')

         ; Put the new default values into the appropriate boxes on the form

      Widget_Control, info.xsize, Set_Value=xsize
      Widget_Control, info.ysize, Set_Value=ysize
      Widget_Control, info.xoff, Set_Value=xoff
      Widget_Control, info.yoff, Set_Value=yoff

         ; Set up the landscape x and y default maximums and minimums

      info.lbox_xmax = Max(box(0,*))
      info.lbox_ymax = Max(box(1,*))
      info.lbox_xmin = Min(box(0,*))
      info.lbox_ymin = Min(box(1,*))

         ; Set landscape mode

      info.landscape = 1

      End

   'PORTRAIT': Begin

          ; Going to landscape mode. Have to change the draw widget window.


          ; Make the draw widget the current graphics window

      WSet, info.wid

          ; Erase the old window and draw the Portrait page outline
          ; and the default Portrait box outline

      Erase

         ; Get the curent sizes of the box.

      Widget_Control, info.xsize, Get_Value=xsize
      Widget_Control, info.ysize, Get_Value=ysize
      xsize = Float(xsize(0))
      ysize = Float(ysize(0))

     ; Calculate new offsets.

      IF info.inches EQ 1 THEN xoff = (8.5 - xsize) / 2.0
      IF info.inches EQ 0 THEN xoff = (21.6 - xsize) / 2.0
      IF info.inches EQ 1 THEN yoff = (11.0 - ysize) / 2.0
      IF info.inches EQ 0 THEN yoff = (27.95 - ysize) / 2.0

       ; Constrain user sizes and offsets to fit on the page.

      IF info.inches EQ 0 THEN BEGIN
         xsize = 0.64 > xsize < 27.3
         ysize = 0.64 > ysize < 20.95
         xoff = 0.64 > xoff < 27.3
         yoff = 0.64 > yoff < 20.95
      ENDIF
      IF info.inches EQ 1 THEN BEGIN
         xsize = 0.25 > xsize < 10.75
         ysize = 0.25 > ysize < 8.25
         xoff = 0.25 > xoff < 10.75
         yoff = 0.25 > yoff < 8.25
      ENDIF

         ; Get the box coordinates.

      box = PS_Form_PlotBox_Coords(xsize, ysize, xoff, yoff, info.inches)

         ; Make the draw widget have a charcoal background color.

      TV, Replicate(info.charcoal,114,114)
      PlotS, info.portraitbox_x, info.portraitbox_y, /Device, $
         Color=info.pagecolor
      PlotS, box, Color=info.boxcolor, /Device

         ; Draw the Portrait page outline on the pixmap and then reset the
         ; current graphics window

      WSet, info.pixwid
      Erase

         ; Make the draw widget have a charcoal background color.

      TV, Replicate(info.charcoal,114,114)
      PlotS, info.portraitbox_x, info.portraitbox_y, /Device, $
        Color=info.pagecolor
      WSet, info.wid

         ; Change the labels to their default values

       xsize = String(xsize, Format='(F5.2)')
       ysize = String(ysize, Format='(F5.2)')
       xoff = String(xoff, Format='(F5.2)')
       yoff = String(yoff, Format='(F5.2)')

         ; Put the new default values into the appropriate boxes on the form

      Widget_Control, info.xsize, Set_Value=xsize
      Widget_Control, info.ysize, Set_Value=ysize
      Widget_Control, info.xoff, Set_Value=xoff
      Widget_Control, info.yoff, Set_Value=yoff

         ; Set up the portrait x and y maximums and minimums

      info.pbox_xmax = Max(box(0,*))
      info.pbox_ymax = Max(box(1,*))
      info.pbox_xmin = Min(box(0,*))
      info.pbox_ymin = Min(box(1,*))

         ; Set portrait mode

      info.landscape = 0

      End

   'ENCAPSULATED_ON': Begin

         ; Update the info structure to indicate that current status
         ; is ENCAPSULATED ON

      info.encapsulated = 1

      End

   'ENCAPSULATED_OFF': Begin

         ; Update the info structure to indicate that current status
         ; is ENCAPSULATED OFF

      info.encapsulated = 0

      End

   'ACCEPT': Begin

         ; The user wants to accept the information in the form.
         ; The procedure is to gather all the information from the
         ; form and then fill out a formInfo structure variable
         ; with the information. The formInfo structure is stored
         ; in a pointer. The reason for this is that we want the
         ; information to exist even after the form is destroyed.

         ; Gather the information from the form

      Widget_Control, info.filename, Get_Value=filename

   ; Is this a valid filename? Does the directory exist?
         ; Can you write the file?

      filename = filename(0)

         ; Extract the file path.

      CASE !Version.OS_Family OF
         'Windows'   : sep = '\' ; PCs
         'MacOS'  : sep = ':'    ; Macintoshes
         'vms'    : sep = ']'    ; VMS machines
      ELSE        : sep = '/'    ; Unix machines
      ENDCASE

        ; Find the last occurrance of a separator in a filename.

      loc = RStrPos(filename, sep)

        ; Extract the root name of the file

      shortfile = StrMid(filename, loc+1, StrLen(filename) - (loc+1))
      directory = StrMid(filename, 0, (StrLen(filename)-StrLen(shortfile))-1)

         ; Can you change to this directory?

      Catch, error
      IF error NE 0 THEN BEGIN
         ok = Widget_Message(['"' + directory +'"', $
            'does not seem to exist. Try again.'])
         Widget_Control, event.top, Set_UValue=info, /No_Copy
         RETURN
      ENDIF

      CD, Current=thisDirectory
      CD, directory

         ; Can you write to this directory? It appears that WindowsNT
         ; allows IDL to write to a non-writeable directory without
         ; causing an error, although no file is actually written.
         ; I'm looking into it.

      Catch, error
      IF error NE 0 THEN BEGIN
         ok = Widget_Message(['The directory or file does not', $
            'appear to be writable. Try again.'])
         Widget_Control, event.top, Set_UValue=info, /No_Copy
         RETURN
      ENDIF

      OpenW, lun, 'ps_form.tmp', /Get_Lun, /Delete
      variable = 1
      WriteU, lun, variable
      Free_Lun, lun

      CD, thisDirectory

      Widget_Control, info.xsize, Get_Value=xsize
      Widget_Control, info.ysize, Get_Value=ysize
      Widget_Control, info.xoff, Get_Value=xoff
      Widget_Control, info.yoff, Get_Value=yoff

        ; I am shielding the user from the strangeness of PostScript
        ; Landscape mode, in which the X and Y offsets are rotated
        ; 180 degrees. Thus, in the form, the offsets are calculated from
        ; the lower-left corner in both Landscape and Portrait mode.
        ; This means I have to monkey around to get the proper offsets
        ; if the form is in Landscape mode.

      IF info.landscape EQ 1 THEN Begin


          IF info.inches EQ 1 THEN pagesize = 11.0 ELSE pagesize = 11.0 * 2.54
          temp = yoff               ; Switch x and y offsets
          yoff = pagesize - xoff    ; Offset really calculated from right of page
          xoff = temp

      ENDIF

         ; Fill out the formInfo structure with the information

      formInfo = { cancel:0, $            ; The CANCEL flag
         create:0, $                      ; The CREATE flag
         xsize:Float(xsize(0)), $         ; The x size of the plot
         xoff:Float(xoff(0)), $           ; The x offset of the plot
         ysize:Float(ysize(0)), $         ; The y size of the plot
         yoff:Float(yoff(0)), $           ; The y offset of the plot
         filename:filename(0), $          ; The name of the file
         inches:info.inches, $            ; Inches or centimeters?
         color:info.color, $              ; Color on or off?
         bits_per_pixel:info.bits_per_pixel, $ ; How many bits per pixel?
         encapsulated:info.encapsulated,$ ; Encapsulated file?
         landscape:info.landscape }       ; Landscape or portrait mode?

         ; Put the formInfo structure into the location pointer
         ; to by the pointer

      Handle_Value, info.ptr, formInfo, /Set, /No_Copy

         ; Delete the pixmap window

      WDelete, info.pixwid

         ; Restore the user's color table

      TVLct, info.red, info.green, info.blue

         ; Destroy the PS_FORM widget program

      Widget_Control, event.top, /Destroy

      End

   'CREATE': Begin

         ; The user wants to accept the information in the form and
         ; create the file. The procedure is the same as ACCEPT above.

         ; Gather the information from the form

      Widget_Control, info.filename, Get_Value=filename
         ; Is this a valid filename? Does the directory exist?
         ; Can you write the file?

      filename = filename(0)

         ; Extract the file path.

      CASE !Version.OS_Family OF
         'Windows'   : sep = '\' ; PCs
         'MacOS'  : sep = ':'    ; Macintoshes
         'vms'    : sep = ']'    ; VMS machines
      ELSE        : sep = '/'    ; Unix machines
      ENDCASE

        ; Find the last occurrance of a separator in a filename.

      loc = RStrPos(filename, sep)

        ; Extract the root name of the file

      shortfile = StrMid(filename, loc+1, StrLen(filename) - (loc+1))
      directory = StrMid(filename, 0, (StrLen(filename)-StrLen(shortfile))-1)

         ; Can you change to this directory?

      Catch, error
      IF error NE 0 THEN BEGIN
         ok = Widget_Message(['"' + directory +'"', $
            'does not seem to exist. Try again.'])
         Widget_Control, event.top, Set_UValue=info, /No_Copy
         RETURN
      ENDIF

      CD, Current=thisDirectory
      CD, directory

         ; Can you write to this directory? It appears that WindowsNT
         ; allows IDL to write to a non-writeable directory without
         ; causing an error, although no file is actually written.
         ; I'm looking into it.

      Catch, error
      IF error NE 0 THEN BEGIN
         ok = Widget_Message(['The directory or file does not', $
            'appear to be writable. Try again.'])
         Widget_Control, event.top, Set_UValue=info, /No_Copy
         RETURN
      ENDIF

      OpenW, lun, 'ps_form.tmp', /Get_Lun, /Delete
      variable = 1
      WriteU, lun, variable
      Free_Lun, lun

      CD, thisDirectory

      Widget_Control, info.xsize, Get_Value=xsize
      Widget_Control, info.ysize, Get_Value=ysize
      Widget_Control, info.xoff, Get_Value=xoff
      Widget_Control, info.yoff, Get_Value=yoff

        ; I am shielding the user from the strangeness of PostScript
        ; Landscape mode, in which the X and Y offsets are rotated
        ; 180 degrees. Thus, in the form, the offsets are calculated from
        ; the lower-left corner in both Landscape and Portrait mode.
        ; This means I have to monkey around to get the proper offsets
        ; if the form is in Landscape mode.

      IF info.landscape EQ 1 THEN Begin


          IF info.inches EQ 1 THEN pagesize = 11.0 ELSE pagesize = 11.0 * 2.54
          temp = yoff               ; Switch x and y offsets
          yoff = pagesize - xoff    ; Offset really calculated from right of page
          xoff = temp

      ENDIF

         ; Fill out the formInfo structure with the information

      formInfo = { cancel:0, $            ; The CANCEL flag
         create:1, $                      ; The CREATE flag
         xsize:Float(xsize(0)), $         ; The x size of the plot
         xoff:Float(xoff(0)), $           ; The x offset of the plot
         ysize:Float(ysize(0)), $         ; The y size of the plot
         yoff:Float(yoff(0)), $           ; The y offset of the plot
         filename:filename(0), $          ; The name of the file
         inches:info.inches, $            ; Inches or centimeters?
         color:info.color, $              ; Color on or off?
         bits_per_pixel:info.bits_per_pixel, $ ; How many bits per pixel?
         encapsulated:info.encapsulated,$ ; Encapsulated file?
         landscape:info.landscape }       ; Landscape or portrait mode?

         ; Put the formInfo structure into the location pointer
         ; to by the pointer

      Handle_Value, info.ptr, formInfo, /Set, /No_Copy

         ; Delete the pixmap window

      WDelete, info.pixwid

         ; Restore the user's color table

      TVLct, info.red, info.green, info.blue

         ; Destroy the PS_FORM widget program

      Widget_Control, event.top, /Destroy

      End

   'CANCEL': Begin

         ; The user wants to cancel out of this form. We need a way to
         ; do that gracefully. Our method here is to set a "cancel"
         ; field in the formInfo structure.

      formInfo = {cancel:1, create:0}

         ; Put the formInfo structure into the location pointer to
         ; by the pointer

     Handle_Value, info.ptr, formInfo, /Set, /No_Copy

         ; Delete the pixmap window

      WDelete, info.pixwid

         ; Restore the user's color table

      TVLct, info.red, info.green, info.blue

         ; Destroy the PS_FORM widget program

      Widget_Control, event.top, /Destroy

      End

ENDCASE

   ; Put the info structure back into the top-level base if the
   ; base is still in existence.

If Widget_Info(event.top, /Valid) THEN $
   Widget_Control, event.top, Set_UValue=info, /No_Copy

END ;*******************************************************************



Function PS_Form, xoffset, yoffset, Cancel=cancelButton, Help=help, $
   XSize=xsize, YSize=ysize, XOffset=xoff, YOffset=yoff, $
   Inches=inches, Color=color, Bits_Per_Pixel=bits_per_pixel, $
   Encapsulated=encapsulated, Landscape=landscape, Filename=filename, $
   Defaults=defaults, LocalDefaults=localDefaults, Initialize=initialize, $
   Create=createButton, Parent=parent

   ; If the Help keyword is set, print some help information and return

IF Keyword_Set(help) THEN BEGIN
Doc_Library, 'PS_FORM'
RETURN, 0
ENDIF

   ; I want inches to be the default case.

IF N_ELEMENTS(inches) EQ 0 THEN inches = 1

   ; Check other keyword parameters.

IF N_Elements(localDefaults) EQ 0 THEN BEGIN
   localDefaultPtr = Handle_Create()
   PS_Form_Set_Personal_Local_Defaults, localDefaultPtr
   ENDIF ELSE localDefaultPtr = Handle_Create(Value=localDefaults)

IF Keyword_Set(initialize) THEN BEGIN

      ; Get the local defaults and return them without asking the user
      ; for input.

   Handle_Value, localDefaultPtr, localdefaults, /No_Copy
   Handle_Free, localDefaultPtr
   RETURN, localdefaults
ENDIF

  ; Special processing for YOffset.

yoff_flag = 0

IF N_Elements(localdefaults) NE 0 THEN BEGIN
   names = Tag_Names(localdefaults)
   yoff_test = Where(names EQ 'YOFF')
   IF yoff_test(0) GT 0 THEN yoff_flag = 1 ELSE yoff_flag = 0
   FOR j=0,N_Elements(names)-1 DO BEGIN
      IF names(j) NE 'YOFF' THEN BEGIN
         str = names(j) + '= localdefaults.' + names(j)
        dummy = Execute(str)
      ENDIF
   ENDFOR
ENDIF

IF N_Elements(defaults) NE 0 THEN BEGIN
   names = Tag_Names(defaults)
   yoff_test = Where(names EQ 'YOFF')
   IF yoff_test(0) GT 0 THEN yoff_flag = 1 ELSE yoff_flag = 0
   FOR j=0,N_Elements(names)-1 DO BEGIN
      IF names(j) NE 'YOFF' THEN BEGIN
         str = names(j) + '= defaults.' + names(j)
        dummy = Execute(str)
      ENDIF
   ENDFOR
ENDIF

landscape = Keyword_Set(landscape)
color = Keyword_Set(color)
encapsulated = Keyword_Set(encapsulated)
inches = Keyword_Set(inches)
IF N_Elements(bits_per_pixel) EQ 0 THEN bits_per_pixel = 8
IF NOT (bits_per_pixel NE 2 OR bits_per_pixel NE 4 $
   OR bits_per_pixel NE 8) THEN BEGIN
   ok = Widget_Message(['Bits_Per_Pixel keyword set with incorrect ' , $
      'value of ' + StrTrim(bits_per_pixel,2) + '.', '', $
       'Setting Bits_Per_Pixel = 8.'])
   bits_per_pixel = 8
ENDIF

IF N_ELements(filename) EQ 0 THEN BEGIN
   CD, Current=thisDir
   filename = Filepath(Root_Dir=thisDir, 'idl.ps')
ENDIF

   ; Process YOffset if yoff_flag is set. (ASSUMING xoff is DEFINED
   ; and passed in with the DEFAULTS or LOCALDEFAULTS!!)

IF yoff_flag THEN BEGIN
IF N_ELEMENTS(defaults) EQ 0 THEN defaults = localdefaults
   yof = Where(names EQ 'YOFF')
   IF landscape EQ 1 AND inches EQ 0 THEN BEGIN
      yoff = xoff
      str = 'xoff = 27.94 - defaults.' + names(yof)
   ENDIF
   IF landscape EQ 1 AND inches EQ 1 THEN BEGIN
      yoff = xoff
      str = 'xoff = 11.0 - defaults.' + names(yof)
   ENDIF
   IF landscape EQ 0 AND inches EQ 0 THEN $
      str = 'yoff = defaults.' + names(yof)
   IF landscape EQ 0 AND inches EQ 1 THEN $
      str = 'yoff = defaults.' + names(yof)
   dummy = Execute(str(0))
ENDIF

   ; Portrait mode

IF landscape EQ 0 THEN BEGIN

   ; Check for undefined sizes and offsets. Use current window
   ; aspect ratio if no XSIZE or YSIZE keywords are used.

   IF N_Elements(xsize) EQ 0 AND N_Elements(ysize) EQ 0 THEN BEGIN
      IF !D.Window NE -1 THEN $
      aspect = Float(!D.X_VSize) / !D.Y_VSize ELSE aspect = 1.0
      IF aspect GE 1 THEN BEGIN
         xsize = 7.0
         ysize = xsize / aspect
      ENDIF ELSE BEGIN
         ysize = 7.0
         xsize = ysize * aspect
      ENDELSE
      IF inches EQ 0 THEN BEGIN
         xsize = xsize * 2.54
         ysize = ysize * 2.54
      ENDIF
   ENDIF

   IF N_Elements(xsize) EQ 0 THEN BEGIN
      IF inches EQ 0 THEN xsize = 17.75
      IF inches EQ 1 THEN xsize = 17.75 / 2.54
   ENDIF
   IF N_Elements(ysize) EQ 0 THEN BEGIN
      IF inches EQ 0 THEN ysize = 12.70
      IF inches EQ 1 THEN ysize = 12.70 / 2.54
   ENDIF
   IF N_Elements(xoff) EQ 0 THEN BEGIN
      IF inches EQ 1 THEN xoff = (8.5 - xsize) / 2.0
      IF inches EQ 0 THEN xoff = (21.6 - xsize) / 2.0
   ENDIF
   IF N_Elements(yoff) EQ 0 THEN BEGIN
      IF inches EQ 1 THEN yoff = (11.0 - ysize) / 2.0
      IF inches EQ 0 THEN yoff = (27.95 - ysize) / 2.0
   ENDIF

   ; Constrain user sizes and offsets to fit on the page.

   IF inches EQ 0 THEN BEGIN
      xsize = 0.64 > xsize < 20.95
      ysize = 0.64 > ysize < 27.3
      xoff = 0.64 > xoff < 20.95
      yoff = 0.64 > yoff < 27.3
   ENDIF
   IF inches EQ 1 THEN BEGIN
      xsize = 0.25 > xsize < 8.25
      ysize = 0.25 > ysize < 10.75
      xoff = 0.25 > xoff < 8.25
      yoff = 0.25 > yoff < 10.75
   ENDIF

ENDIF

   ; Landscape mode

IF landscape EQ 1 THEN BEGIN

   ; Check for undefined sizes and offsets. Use current window
   ; aspect ratio if no XSIZE or YSIZE keywords are used.

   IF N_Elements(xsize) EQ 0 AND N_Elements(ysize) EQ 0 THEN BEGIN
      IF !D.Window NE -1 THEN $
      aspect = Float(!D.X_VSize) / !D.Y_VSize ELSE aspect = 1.0
      IF aspect GE 1 THEN BEGIN
         xsize = 7.0
         ysize = xsize / aspect
      ENDIF ELSE BEGIN
         ysize = 7.0
         xsize = ysize * aspect
      ENDELSE
      IF inches EQ 0 THEN BEGIN
         xsize = xsize * 2.54
         ysize = ysize * 2.54
      ENDIF
   ENDIF

   ; Check for undefined sizes and offsets

   IF N_Elements(xsize) EQ 0 THEN BEGIN
      IF inches EQ 1 THEN xsize = 9.5
      IF inches EQ 0 THEN xsize = 24.13
   ENDIF
   IF N_Elements(ysize) EQ 0 THEN BEGIN
      IF inches EQ 1 THEN ysize = 7.0
      IF inches EQ 0 THEN ysize = 17.78
   ENDIF
   IF N_Elements(xoff) EQ 0 THEN BEGIN
      IF inches EQ 1 THEN xoff = (11.0 - xsize) / 2.0
      IF inches EQ 0 THEN xoff = (27.94 - xsize) / 2.0
   ENDIF
   IF N_Elements(yoff) EQ 0 THEN BEGIN
      IF inches EQ 1 THEN yoff = (8.5 - ysize) / 2.0
      IF inches EQ 0 THEN yoff = (21.60 - ysize) / 2.0
   ENDIF

   ; Constrain user sizes and offsets to fit on the page.

   IF inches EQ 0 THEN BEGIN
      xsize = 0.64 > xsize < 27.3
      ysize = 0.64 > ysize < 20.95
      xoff = 0.64 > xoff < 27.3
      yoff = 0.64 > yoff < 20.95
   ENDIF
   IF inches EQ 1 THEN BEGIN
      xsize = 0.25 > xsize < 10.75
      ysize = 0.25 > ysize < 8.25
      xoff = 0.25 > xoff < 10.75
      yoff = 0.25 > yoff < 8.25
   ENDIF

ENDIF

   ; Put sizes and offsets into strings that can be placed in
   ; the text widgets.

sizeFormat = '(F5.2)'
xsize_str = String(xsize, Format=sizeFormat)
ysize_str = String(ysize, Format=sizeFormat)
xoff_str = String(xoff, Format=sizeFormat)
yoff_str = String(yoff, Format=sizeFormat)

   ; This program cannot work if the graphics device is already set
   ; to PostScript. So if it is, set it to the native OS graphics device.
   ; Remember to set it back later.

IF !D.Name EQ 'PS' THEN BEGIN

   oldName = 'PS'
   thisDevice = Byte(!Version.OS)
   thisDevice = StrUpCase( thisDevice(0:2) )
   IF thisDevice EQ 'MAC' OR thisDevice EQ 'WIN' THEN Set_Plot, thisDevice ELSE Set_Plot, 'X'

ENDIF ELSE oldName = !D.Name

   ; Check for optional offset parameters and give defaults if not passed

Device, Get_Screen_Size=screenSize
IF N_Elements(xoffset) EQ 0 THEN xoffset = (screenSize(0) - 600) / 2.
IF N_Elements(yoffset) EQ 0 THEN yoffset = (screenSize(1) - 400) / 2.

thisRelease = StrMid(!Version.Release, 0, 1)
IF thisRelease EQ '5' AND N_Elements(parent) EQ 0 THEN BEGIN
   Print, ''
   Print, '    Unless you are calling PS_FORM from the command line, the'
   Print, '    PARENT keyword MUST be used in IDL 5 for modal operation.'
   Print, '    Please modify your code if neccesary.'
ENDIF

   ; The TLB must be made modal in IDL 5. Requires, however, that
   ; the group leader be defined.

thisRelease = StrMid(!Version.Release, 0, 1)
IF thisRelease EQ '5' THEN BEGIN
   tlb = Widget_Base(Title='Configure PostScript Parameters', Column=1, $
      XOffset=xoffset, YOffset=yoffset, TLB_Frame_Attr=9, $
      Modal=Keyword_Set(parent), Group_Leader=parent)
ENDIF ELSE BEGIN
   tlb = Widget_Base(Title='Configure PostScript Parameters', Column=1, $
      XOffset=xoffset, YOffset=yoffset, TLB_Frame_Attr=9)
ENDELSE

   ; Sub-bases for layout

sizebase = Widget_Base(tlb, Row=1,  Align_Center=1)

   numbase = Widget_Base(sizebase, Column=1)

      numsub1 = Widget_Base(numbase, Row=1)

         junk = Widget_Label(numsub1, Value=' Units: ')
             junksub = Widget_Base(numsub1, Row=1, /Exclusive)
                inch = Widget_Button(junksub, Value='Inches', UValue='INCHES')
                cm = Widget_Button(junksub, Value='Centimeters', $
                   UValue='CENTIMETERS')
                IF inches EQ 1 THEN Widget_Control, inch, Set_Button=1 ELSE $
                   Widget_Control, cm, Set_Button=1

      numsub2 = Widget_Base(numbase, Row=1, Event_Pro='PS_Form_NumEvents')

         lab1base = Widget_Base(numsub2, Column=1, Base_Align_Center=1)
            junk = Widget_Label(lab1base, Value='XSize: ')
            junk = Widget_Label(lab1base, Value='XOffset: ')

         lab2base = Widget_Base(numsub2, Column=1, Base_Align_Center=1)
            xsizew = Widget_Text(lab2base, Scr_XSize=60, /Editable, $
               Value=xsize_str, UValue=xsize)
            xoffw = Widget_Text(lab2base, Scr_XSize=60, /Editable, $
               Value=xoff_str, UValue=xoff)

         lab3base = Widget_Base(numsub2, Column=1, Base_Align_Center=1)
            junk = Widget_Label(lab3base, Value='YSize: ')
            junk = Widget_Label(lab3base, Value='YOffset: ')

         lab2base = Widget_Base(numsub2, Column=1, Base_Align_Center=1)
            ysizew = Widget_Text(lab2base, Scr_XSize=60, /Editable, $
               Value=ysize_str, UValue=ysize)
            yoffw = Widget_Text(lab2base, Scr_XSize=60, /Editable, $
               Value=yoff_str, UValue=yoff)

drawbase = Widget_Base(sizebase, Row=1)

   draw = Widget_Draw(drawbase, XSize=114, YSize=114, $
     Event_Pro='PS_Form_Draw_Events', Button_Events=1)

colorbase = Widget_Base(tlb, Row=1, Align_Center=1)

   colorlabel = Widget_Label(colorbase, Value='Color:')

   coloron = Widget_Base(colorbase, Row=1, /Exclusive, Frame=1)

      col_on = Widget_Button(coloron, Value='On', UValue='COLOR_ON')
      col_off = Widget_Button(coloron, Value='Off', UValue='COLOR_OFF')
      IF color EQ 0 THEN Widget_Control, col_off, Set_Button=1 ELSE $
         Widget_Control, col_on, Set_Button=1

   bitslabel = Widget_Label(colorbase, Value='Bits')

   bitsw = Widget_Base(colorbase, Row=1, /Exclusive, /frame)

      bit2 = Widget_Button(bitsw, Value='2', UValue='BITS2')
      bit4 = Widget_Button(bitsw, Value='4', UValue='BITS4')
      bit8 = Widget_Button(bitsw, Value='8', UValue='BITS8')
      CASE bits_per_pixel OF
         2: Widget_Control, bit2, Set_Button=1
         4: Widget_Control, bit4, Set_Button=1
         8: Widget_Control, bit8, Set_Button=1
      ENDCASE

orientbase = Widget_Base(tlb, Row=1, Align_Center=1)

   junk = Widget_Label(orientbase, Value='Orientation: ')
      junkbase = Widget_Base(orientbase, Row=1, /Frame, /Exclusive)
         land = Widget_Button(junkbase, Value='Landscape', UValue='LANDSCAPE')
         port = Widget_Button(junkbase, Value='Portrait', UValue='PORTRAIT')
         IF landscape EQ 0 THEN Widget_Control, port, Set_Button=1 ELSE $
            Widget_Control, land, Set_Button=1

   junk = Widget_Label(orientbase, Value='Encapsulated: ')
      junkbase = Widget_Base(orientbase, Row=1, /Exclusive, /Frame)
         encap_on = Widget_Button(junkbase, Value='On', $
            UValue='ENCAPSULATED_ON')
         encap_off = Widget_Button(junkbase, Value='Off', $
            UValue='ENCAPSULATED_OFF')
         IF encapsulated EQ 0 THEN Widget_Control, encap_off, $
            Set_Button=1 ELSE Widget_Control, encap_on, Set_Button=1

filenamebase = Widget_Base(tlb, Column=1, Align_Center=1)
fbase = Widget_Base(filenamebase, Row=1)
   textlabel = Widget_Label(fbase, Value='Filename: ')

       ; Set up text widget with an event handler that ignores any event.

filenamew = Widget_Text(fbase, /Editable, Scr_XSize=250,  $
      Value=filename, Event_Pro='PS_Form_Null_Events')
filebutton = Widget_Button(fbase, Value='Select Filename', $
      Event_Pro='PS_FORM_Select_File')


buttonbase = Widget_Base(filenamebase, Align_Center=1, Column=1)
defbuttonbase = Widget_Base(buttonbase, Row=1)
   sysdefaults = Widget_Button(defbuttonbase, Value='System Defaults', $
      Event_Pro='PS_Form_Set_System_Defaults', UValue='SYSTEM')
   localdefs = Widget_Button(defbuttonbase, Value='Local Defaults', $
      Event_Pro='PS_Form_Set_Local_Defaults', UValue='LOCAL')
actionbuttonbase = Widget_Base(buttonbase, Row=1)
   cancel = Widget_Button(actionbuttonbase, Value='Cancel', UValue='CANCEL')
   create = Widget_Button(actionbuttonbase, Value='Create File', UValue='CREATE')
   accept = Widget_Button(actionbuttonbase, Value='Accept', UValue='ACCEPT')

Widget_Control, tlb, /Realize
Widget_Control, draw, Get_Value=wid
WSet, wid

   ; How big is the top-level base? Want to size the filename text widget
   ; the appropriate size.

;baseSize = Widget_Info(filenamebase, /Geometry)
;textlabelSize = Widget_Info(textlabel, /Geometry)
;Widget_Control, filenamew, $
;   Scr_XSize=(baseSize.XSize - textlabelSize.XSize - baseSize.XPad - $
;    textlabelSize.XPad)

   ; Ready to set up parameters to draw the boxes on the display.

portraitbox_x = [1,1,88,88,1]
portraitbox_y = [1, 112, 112, 1, 1]
landbox_x = [1, 112, 112, 1, 1]
landbox_y = [1, 1, 88, 88, 1]

   ;  Convert sizes and offsets to Device coordinates.

boxInfo = PS_Form_PlotBox_Coords(xsize, ysize, xoff, yoff, inches)

IF landscape EQ 0 THEN BEGIN
   pbox_xmax = Max(boxInfo(0,*))
   pbox_xmin = Min(boxInfo(0,*))
   pbox_ymax = Max(boxInfo(1,*))
   pbox_ymin = Min(boxInfo(1,*))
   lbox_xmax = 0
   lbox_xmin = 0
   lbox_ymax = 0
   lbox_ymin = 0
ENDIF ELSE BEGIN
   pbox_xmax = 0
   pbox_xmin = 0
   pbox_ymax = 0
   pbox_ymin = 0
   lbox_xmax = Max(boxInfo(0,*))
   lbox_xmin = Min(boxInfo(0,*))
   lbox_ymax = Max(boxInfo(1,*))
   lbox_ymin = Min(boxInfo(1,*))
ENDELSE

   ; Get the colors in the current color table

TVLct, r, g, b, /Get

   ; Modify color indices N_Colors-2, N_Colors-3 and N_Colors-4 for
   ; drawing colors

   ; The number of colors in the session can be less then the
   ; number of colors in the color vectors on PCs (and maybe other
   ; computers), so take the smaller value. (Bug fix?)

ncol = !D.N_Colors < N_Elements(r)
red = r
green = g
blue=b
red(ncol-4:ncol-2) = [70B, 0B, 255B]
green(ncol-4:ncol-2) = [70B, 255B, 255B]
blue(ncol-4:ncol-2) = [70B, 0B, 0B]

   ; Load the newly modified colortable

TVLct, red, green, blue

   ; Make the draw widget have a charcoal background color.

TV, Replicate(ncol-4,114,114)

   ; Draw a page box in the draw widget

IF landscape EQ 0 THEN PlotS, portraitbox_x, portraitbox_y, /Device, Color=ncol-2  ELSE $
   PlotS, landbox_x, landbox_y, /Device, Color=ncol-2

   ; Draw a plot box in the draw widget

PlotS, boxInfo(0,*), boxInfo(1,*), /Device, Color=ncol-3

   ; Create a pixmap and draw the page box on it

Window, /Free, XSize=114, YSize=114, /Pixmap
pixwid = !D.Window
WSet, pixwid
TV, Replicate(ncol-4,114,114)
IF landscape EQ 0 THEN PlotS, portraitbox_x, portraitbox_y, /Device, Color=ncol-2  ELSE $
   PlotS, landbox_x, landbox_y, /Device, Color=ncol-2
WSet, wid

   ; Create a pointer to store the formInfo structure from the form

ptr = Handle_Create()

   ; Create an info structure to store information required by the program

info = {draw:draw, $          ; The draw widget id
      pixwid:pixwid, $        ; The pixmap window id
      wid:wid, $              ; The draw widget window id
      xsize:xsizew, $         ; The widget id to get XSIZE
      ysize:ysizew, $         ; The widget id to get YSIZE
      xoff:xoffw, $           ; The widget id to get XOFFSET
      yoff:yoffw, $           ; The widget id to get YOFFSET
      filename:filenamew, $   ; The widget id to get FILENAME
      inch:inch, $            ; The widget id of inch button.
      cm:cm, $                ; The widget id of cm button.
      col_on:col_on, $        ; The widget id of color on button.
      col_off:col_off, $      ; The widget id of color off button.
      bit2:bit2, $            ; The widget id of bit=2 button.
      bit4:bit4, $            ; The widget id of bit=4 button.
      bit8:bit8, $            ; The widget id of bit=8 button.
      encap_on:encap_on, $    ; The widget id of encapsulate on button.
      encap_off:encap_off, $  ; The widget id of encapsulate off button.
      land:land, $            ; The widget id of the landscape button.
      port:port, $            ; The widget id of the portrait button.
      portraitbox_x:portraitbox_x, $   ; Portrait page outline x (default)
      portraitbox_y:portraitbox_y, $   ; Portrait page outline y (default)
      pplotbox_x:[8, 8, 82, 82, 8], $       ; Portrait box outline x (default)
      pplotbox_y:[60, 106, 106, 60, 60], $  ; Portrait box outline y (default)
      landbox_x:landbox_x, $           ; Landscape page outline x (default)
      landbox_y:landbox_y, $           ; Landscape page outline y (default)
      lplotbox_x:[8, 8, 106, 106, 8], $  ; Landscape box outline x (default)
      lplotbox_y:[8, 82, 82, 8, 8], $    ; Landscape box outline y (default)
      pbox_xmax:pbox_xmax, $  ; Current portrait box x maximum
      pbox_xmin:pbox_xmin, $  ; Current portrait box x minimum
      pbox_ymax:pbox_ymax, $  ; Current portrait box y maximum
      pbox_ymin:pbox_ymin, $  ; Current portrait box Y minimum
      lbox_xmax:lbox_xmax, $  ; Current landscape box x maximum
      lbox_xmin:lbox_xmin, $  ; Current landscape box x minimum
      lbox_ymax:lbox_ymax, $  ; Current landscape box y maximum
      lbox_ymin:lbox_ymin, $  ; Current landscape box y minimum
      inches:inches, $        ; Inches = 1, Centimeters = 0
      color:color, $          ; Color = 1, B&W = 0
      bits_per_pixel:bits_per_pixel, $  ; Number of bits per pixel
      landscape:landscape, $   ; Landscape mode = 1, Portrait mode = 0
      encapsulated:encapsulated, $ ; Encapsulated = 1, Non-encapsulated = 0
      pagecolor:ncol-2, $     ; Color to draw page outline (yellow)
      boxcolor:ncol-3, $      ; Color to draw plot box (green)
      charcoal:ncol-4, $      ; Color to put as background in the draw widget
      red:r, $                ; Old red color vector
      green:g, $              ; Old green color vector
      blue:b, $               ; Old blue color vector
      ptr:ptr, $              ; Pointer to store data from the form.
      localDefaultPtr:localDefaultPtr, $ ; Pointer to local default structure.
      xs:0.0, $               ; X value of static corner of box
      ys:0.0, $               ; Y value of static corner of box
      xcur:0.0, $             ; X value of moving corner of box
      ycur:0.0, $             ; Y value of moving corner of box
      mouse_x:0.0, $          ; X value of mouse in moving box
      mouse_y:0.0, $          ; Y value of mouse in moving box
      xmax:0.0, $             ; Temporary X max value of moving box
      ymax:0.0, $             ; Temporary Y max value of moving box
      xmin:0.0, $             ; Temporary X min value of moving box
      ymin:0.0 }              ; Temporary Y min value of moving box

   ; Store the info structure in the top-level base

Widget_Control, tlb, Set_UValue=info, /No_Copy

   ; Set this widget program up as a modal or blocking widget. What this means
   ; is that you will return to the line after this XManager call when the
   ; widget is destroyed.

thisRelease = StrMid(!Version.Release, 0, 1)
IF thisRelease EQ '5' THEN XManager, 'ps_form', tlb ELSE $
      XManager, 'ps_form', tlb, /Modal

   ; Get the formInfo structure from the pointer location.

Handle_Value, ptr, formInfo, /No_Copy

   ; Make sure the user didn't click a close button.

IF N_Elements(formInfo) EQ 0 THEN Begin
   Handle_Free, ptr
   cancelButton = 1
   createButton = 0
   RETURN, 0
EndIF

   ; Make sure you aren't running through the XManager call.

stillValid = Widget_Info(tlb, /Valid_ID)
IF N_Elements(formInfo) EQ 0 AND stillValid THEN Begin
   ok = Widget_Message(['The PARENT keyword MUST be used', $
      'in the PS_FORM call in IDL 5.', 'Please modify your code.'])
   cancelButton = 1
   createButton = 0
   RETURN, 0
EndIF

   ; Strip the CANCEL field out of the formInfo structure so the
   ; cancelButton flag can be returned via the CANCEL keyword and the
   ; formInfo structure is suitable for passing directly to the DEVICE
   ; procedure through its _Extra keyword.

cancelButton = formInfo.cancel
createButton = formInfo.create
IF NOT cancelButton THEN BEGIN

   formInfo = { PS_FORM_INFO, $
                xsize:formInfo.xsize, $
                xoff:formInfo.xoff, $
                ysize:formInfo.ysize, $
                yoff:formInfo.yoff, $
                filename:formInfo.filename, $
                inches:formInfo.inches, $
                color:formInfo.color, $
                bits_per_pixel:formInfo.bits_per_pixel, $
                encapsulated:formInfo.encapsulated, $
                landscape:formInfo.landscape }

ENDIF ELSE formInfo = 0 ; Return a throw-away value

   ; Free up the space allocated to the pointers and the data

Handle_Free, ptr
IF N_Elements(localDefaultPtr) NE 0 THEN Handle_Free, localDefaultPtr

   ; Restore graphics device.

Set_Plot, oldname

RETURN, formInfo
END ;*******************************************************************

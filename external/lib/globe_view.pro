;==========================================================================
;                              globe_view
;==========================================================================
;
; Draws the world as seen from a satellite passing over head.
; Default position is 65 deg. N. Lat and 150 deg. East Long. (over Alaska)
; sat_radius of 1.2 Earth Radii and no camera rotation or tilt.
;
; Inputs:
;          view:  structure of viewing perspective control parameters
;          view.lat = satellite position -90 to 90 degrees latitude
;          view.elon = satellite position -180 to 180 East Longitude
;          view.radius = satellite height from which the Earth is viewed
;          view.tilt = 0, default is looking straight down
;          view.azmurot=0, rotated view measured from looking North
;
;          echo - keyword switch to print values of the above listed variables
;
;          color_set - structure to control colors, see defaults below
;
;          limit - array of lat/lon values to define the corners of the
;                  globe.  None results in full globe view, see documentation
;                  below with limit defaults.
;
; Usage:
;       globe_view                            ; default over AK
;       globe_view,/echo                      ; show current values
;       globe_view,view=view  ; show pole centered by user controlled structure
;       globe_view,/echo,color_set=color_set  ; user definded color map
;                  etc.
;
Pro globe_view, view=view, limit=limit, echo=echo, color_set=color_set, noerase=noerase, hires=hires

; Assign default view of satellite located above Alaska.
IF NOT KEYWORD_SET(view) THEN $
view = {lat:     65.   ,$    ; North laltitude
    elon:    -150. ,$    ; From Greenwich Meridian, Longitude>0 is East
    radius:  1.3   ,$    ; View Height in Earth Radii
    tilt:    0     ,$    ; degrees tilted from straight downward
    azmurot: 0     ,$    ; degrees rotated from // to North
        north_rot: 0   }     ; 0==Put North at the top of the map,
                             ; 90==North points right.
; Use UT time *15 + any offset as view.elon to rotate globe under stationary oval!

; Optionally set plotting limits.  Alternating latitude, longitude values for
;the four corners of the view plot in order of lower-left, upper, right, lower
IF KEYWORD_SET(limit) THEN limit=[50, -174, 83, 4, 63, -97, 40,-117]

IF KEYWORD_SET(echo) THEN BEGIN
   PRINT, FORMAT = $
   '("As viewed from ",F4.2," Earth Radii directly over",F7.2," Deg. N",F8.2,"Deg. E. of GM")', $
         view.radius,view.lat,view.elon
   PRINT,'Looking',view.tilt,' Deg. from straight down and North rotated', $
         view. north_rot, 'Deg. from the Top of the Page'
END

; create a default color_set.  Structure has 6 tags.
IF NOT KEYWORD_SET(color_set) THEN $
   color_set  = {background: 0, $          ; draw against black background
             fill:       255, $        ; fill continents
             ocean:      50, $
             borders:   0, $        ; color for country borders
                 equitoval:  25, $         ; color for equatorward edge of oval
                 polaroval:  25, $         ; color for poleward edge if oval
                 text:       255 }         ; color for labels

if not(keyword_set(noerase)) then erase,color_set.background       ; clear screen and set the background

; Define mapping as SATELLITE perspective hanging over lat deg. N. Lat and
; Elon deg. East Long. with SAT_P of radius Earth Radii and camera rotation or
; tilt.  Draw the HORIZON to provide the appearance of a globe and make it
; a proportional plot (ISOTROPIC)
MAP_SET,view.lat,view.elon,view.north_rot,/SATELLITE,  $
        SAT_P=[view.radius,view.tilt, view.azmurot],$
        /HORIZON,/ISOTROPIC,LIMIT=limit,/NOBORDER, /noerase, e_horizon={fill:1, color:color_set.ocean}

; This next line draws the CONTINENTS,and FILLS the continents with color.
MAP_CONTINENTS,/FILL_CONTINENTS,COLOR=color_set.fill, /horizon

; This draws the COASTLINES, COUNTRY and USA boarder lines in either high
;resolution or not
IF KEYWORD_SET(hires) THEN $
     MAP_CONTINENTS,/COUNTRIES,/USA,/HIRES,COLOR=color_set.borders $
     ELSE MAP_CONTINENTS,/COASTS,/COUNTRIES,COLOR=color_set.borders, /horizon

; draws the grid lines.  May want color control of this, too
MAP_GRID,LATDEL=20,LONDEL=30, color=color_set.text

RETURN
END


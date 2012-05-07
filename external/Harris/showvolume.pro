;+
; NAME:		 ShowVolume
;
; PURPOSE:	To display a contour surface of a volume density.
;		Based on the example in the RSI IDL manual. 
;		Uses SURFACE, SHADE_VOLUME, POLYSHADE and TVSCL to produce 
;		a surface in 3-D coords.
;
; CATEGORY:
;
; CALLING SEQUENCE:
;		ShowVolume, volume, thresh, LOW = low, VERTICES=v, POLYGONS=p
;
; INPUTS:
;		volume	= 3-d array specifying a volume density function
;		thresh	= the value of the density function at which 
;			  to form a surface
;	KEYWORDS:
;		LOW	= If set then the surface will enclose the higher 
;			  valued data (the LOW side of the surface is shown) 
;			  othewrwise the HIGH side of the sirface will be 
;			  shown which encloses the lower valued data.
;			  (passed directly to the SHADE_VOLUME routine)
;
;
; OUTPUTS:
;	KEYWORDS:
;		VERTICES= the vertices defining the contour surface 
;			(direct from SHADE_VOLUME)
;		POLYGONS= the polygons defining the contour surface 
;			(direct from SHADE_VOLUME)
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:		draws on the current graphics device
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1992.
;
;-
              ; Display the contour surface of a volume.
              Pro ShowVolume, vol, thresh, LOW = low, vertices=v, polygons=p

	      if (n_params() lt 2) then begin
		print,'% SHOWVOLUME: need TWO parameters, the volume array,' $
			+'AND the contour level'
		return
	      end

              ; Get the dimensions of the volume.
              s = SIZE(vol)

              ; Error, must be a 3D array.
              IF s(0) NE 3 THEN begin
		print,'% SHOWVOLUME: array must be 3D to have a volume'
		return
	      ENDIF

              ; Use SURFACE to establish the 3D transformation and
              ; coordinate ranges.

              SURFACE,FLTARR(2,2),/NODATA,/SAVE,XRANGE=[0,s(1)-1], $
				YRANGE=[0,s(2)-1],ZRANGE=[0,s(3)-1]

              ; Default = view high side of contour surface.
              IF N_ELEMENTS(low) EQ 0 THEN low = 0

              ; Produce vertices and polygons.
              SHADE_VOLUME, vol, thresh, v, p, LOW = low

              ; Produce image of surface and display.
              TVSCL, POLYSHADE(v,p,/T3D)
              END




	function ellipsoid,s,aspect=aspect,steps=steps
;+
; NAME:			ELLIPSOID
;
; PURPOSE:		create an ellipsoidal gaussian volume density function
;
; CATEGORY:		Signal Processing.
;
; CALLING SEQUENCE:	
;			result = ELLIPSOID(n)
;			result = ELLIPSOID(n,aspect=aspect)
;
; INPUTS:
;			
;		n 	= size of result. (default = 50)
;	KEYWORDS:
		ASPECT	= aspect ratio of the ellipse  (default = 0.75)
;		STEPS	= number of steps to create (default = 0)
; OUTPUTS:
;	Result = (N,N,N) floating array in which each 2-d layer is created 
;		 by the ellipse generating function DIST4
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

	;create an ellipsoidal gaussian volume density function

	if (n_elements(s) le 0) then dim = 50. else dim = float(s(0)) 
	if (not keyword_set(aspect)) then aspect = 0.75

	volume = fltarr(dim,dim,dim)

	;use dist4 with different major and minor axes and "steps" steps

	area = dist4(dim,1,aspect,steps=steps)
	;;;;dont want cosine wiggles !!
	;;;;area = cos(area*2.*!pi/max(area))

	;for i=0,dim-1 do volume(0,0,i) = (max(area)-area)*i*(dim-i)/dim
         
	;for i=0,dim-1 do volume(0,0,i) = (max(area)-area) $
	;					*exp(-((i-(dim-1)*0.5)/dim)^2)
        
	for i=0,dim-1 do volume(0,0,i) = (max(area)-area) $
				*sqrt(1-(2.*(i-(dim-1)*0.5)/(dim-1))^2)
       
	return,volume
	end
	
	

;*********************************************************************
FUNCTION INTERPOL, V, X, U
;+
; NAME:
;	INTERPOL
; PURPOSE:
;	Linear interpolation for vectors.
;	Regular or irregular grid.
; CATEGORY:
;	E1 - Interpolation
; CALLING SEQUENCE:
;	Result = INTERPOL( V, X, U)	;Irregular grids
;	Result = INTERPOL( V, N)	;Regular grids
; INPUTS:
;	V = input vector, should be one dimensional,
;		any type except string.
;
;	Regular grids:
;	N = Number of points of result, both input and
;		output grids are regular.  Output grid
;		absicissa value = float(i)/N_elements(V),
;		for i=0,n-1.
;
;	Irregular grids:
;	X = Absicissae values for V. Must have same # of
;		elements as V. MUST be monotonic, either
;		ascending or descending.
;	U = Absicissae values for result.  Result will
;		have same number of elements as U.  U need
;		not be monotonic.
;	
; OPTIONAL INPUT PARAMETERS:
;	None.
; OUTPUTS:
;	Result = Floating vector of N points determined
;		from linearly interpolating input vector.
;		If V is double or complex, result is double
;		or complex.
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	None.
; RESTRICTIONS:
;	None.
; PROCEDURE:
;	Result(i) = V(x) + (x-FIX(x))*(V(x+1)-V(x))
;		where x = i*(m-1)/(N-1) for regular grids.
;		m = # of elements in V, i=0 to N-1.
;		For irregular grids, x = U(i).
;		m = number of points of input vector.
;
; MODIFICATION HISTORY:
;	Written, DMS, October, 1982.
;
;       Modified, Terry J. Armitage and Janet Ferguson, March 1989. Modified
;       counters ix and i to handle vectors larger than 32767.
;-
;
	m = N_elements(v)	;# of input pnts
	if N_params(0) eq 2 then begin	;Regular?
		r = findgen(x)*(m-1)/(x-1>1) ;Grid points in V
		rl = long(r)		;Cvt to integer
		dif = v(1:*)-v		;V(i+1)-v(i)
		return, V(rl) + (r-rl)*dif(rl) ;interpolate
		endif
;
	if n_elements(x) ne m then $ 
		stop,'INTERPOL - V and X must have same # of elements'
	n= n_elements(u)	;# of output points
	m2=m-2			;last subs in v and x
	r= fltarr(n)+V(0)	;floating point result
	if x(1) - x(0) ge 0 then s1 = 1 else s1=-1 ;Incr or Decr X
;
	ix = 0L			;current point
	for i=0L,n-1 do begin	;point loop
		d = s1 * (u(i)-x(ix))	;difference
		if d eq 0. then r(i)=v(ix) else begin  ;at point
		  if d gt 0 then while (s1*(u(i)-x(ix+1)) gt 0) and $
			(ix lt m2) do ix=ix+1 else $
			while (s1*(u(i)-x(ix)) lt 0) and (ix gt 0) do $
			  ix=ix-1
		  r(i) = v(ix) + (u(i)-x(ix))*(v(ix+1)-v(ix))/(x(ix+1)-x(ix))
		  endelse
	endfor
	return,r
end


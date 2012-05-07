;****************************************************************************
function xindex,xarr,x
; modification of TABINV
;
; REVISION HISTORY:
;   Adapted from the IUE RDAF                     January, 1988         
;   More elegant code  W. Landsman                August, 1989
;   Adapted for ICUR, ISARRAY removed  FMW  8/91
;-               
IF N_PARAMS(0) LT 2 THEN BEGIN
   PRINT,STRING(7B),'CALLING SEQUENCE- i=XINDEX(xarr,x)
   RETURN,-1
   ENDIF
NPOINTS = N_ELEMENTS(XARR)
if npoints eq 1 then begin
   if n_elements(x) gt 1 then begin
      t=xarr & xarr=x & x=t    ;swap
      iswap=1
      endif
   endif
NPT= NPOINTS - 1

;
; Initialize binary search area and compute number of divisions needed
;
ILEFT = INTARR( N_ELEMENTS(X) ) & IRIGHT = ILEFT
NDIVISIONS = FIX( ALOG10(NPOINTS)/ALOG10(2.0)+1.0 )
;
; Test for monotonicity 
;
I = XARR - SHIFT(XARR,1)
A = WHERE(I GE 0)
IF (!ERR EQ NPT) THEN $ ; Increasing array ?
    IRIGHT = IRIGHT + NPT $
ELSE BEGIN
     A = WHERE(I LE 0)  ; Test for decreasing array
     IF (!ERR EQ NPT) THEN ILEFT = ILEFT + NPT $
     ELSE BEGIN
           PRINT,STRING(7B)+ $ 
           'XINDEX: ERROR - First parameter must be a monotonic vector' 
           RETURN,-1
           END 
END          
;
; Perform binary search by dividing search interval in
; half NDIVISIONS times
;
FOR I=1,NDIVISIONS DO BEGIN
    IDIV = (ILEFT+IRIGHT)/2      ;Split interval in half
    XVAL = XARR(IDIV)            ;Find function values at center
    GREATER= FIX(X GT XVAL)      ;Determine which side X is on
    LESS   = FIX(X LE XVAL)  
    ILEFT =  ILEFT*LESS + IDIV*GREATER ;Compute new search area
    IRIGHT = IRIGHT*GREATER + IDIV*LESS
ENDFOR
;
; Interpolate between interval of width = 1
;
XLEFT =  XARR(ILEFT)              ;Value on left side
XRIGHT = XARR(IRIGHT)             ;Value on right side
IEFF = (XRIGHT-X)*ILEFT + (X-XLEFT)*IRIGHT + ILEFT*(XRIGHT EQ XLEFT)
IEFF = IEFF/FLOAT(XRIGHT-XLEFT+(XRIGHT EQ XLEFT)) ;Interpolate
IEFF = IEFF > 0.0 < NPT        ;Do not allow extrapolation beyond ends
s=size(x)
if s(0) eq 0 then IEFF = IEFF(0)  ;Make scalar if X was scalar
RETURN,ieff
END

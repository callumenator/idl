function chaplayr, z, z0, H, d, true_height = true_height

;-------------------------------------------------------------
;
;   This program returns a normalized fuction describing a 
;   Chapman layer.  
;
;   Inputs: 
;
;   z:  An array describing the heights at which to evaluate the function
;   z0: The desired peak height (see the "true_height" keyword below)
;   H:  The atmospheric density scale height
;   d:  The atmospheric "optical depth" seen by the exciting flux
;       at the layer height.
;
;   Return value: The layer density function, normalized to one at 
;                 its peak height.
;
;   Keywords:
;
;   true_height: The routine first uses an approximate technique to place the
;                layer peak at the requested z0.  If true_height is NOT
;                set, it then finds the actual peak height of the curve
;                that it generated on this first attempt.  Then, z0 is adjusted
;                so that the generated curve actually does peak at the 
;                requested z0.  This means that after the routine returns,
;                z0 WILL HAVE a NEW VALUE, which is the value you need to
;                supply to make the curve peak at the requested height
;                on its first guess.  Now, to speed up subsequent calls, 
;                you can supply this value and set the "true_height" 
;                keyword.  In this case, the routine will return after its
;                first attempt at generating the curve, without adjusting
;                z0.
;
;   Mark Conde, Fairbanks, September 1999.

;---Return -1 if no heights were passed in:
    if n_elements(z)     lt 1 then return, -1
    
;---Compute the density function:
    delz = z - z0
    dens = exp(-(delz)/h)

;---Compute the flux function:
    block = exp(-(delz)/d)
    flux  = exp(-block)
    
;---Compute the layer density function:
    layer = flux*dens

    if not(keyword_set(true_height)) then begin    
;------Adjust the peak height:
       pkht  = z(where(layer eq max(layer)))
       z0    = 2*z0 - pkht(0)

;------Compute the density function:
       delz = z - z0
       dens = exp(-(delz)/h)

;------Compute the flux function:
       block = exp(-(delz)/d)
       flux  = exp(-block)

;------Compute the layer density function:
       layer = flux*dens
    endif
    
    return, layer/max(layer)
end
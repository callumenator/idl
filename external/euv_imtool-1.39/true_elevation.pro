
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; true_elevation - calculate the true elevation
;                  from the pixel number in the
;                  combined frame.
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; 
; INPUTS:
;
; pixel        pixel number in the combined frame (float)
;
; n_overlap    number of pixels overlapped in the combined
;              frame
;
;
; OUTPUTS:
;
; elevation    corrected elevation angle
; 
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 25-Jul-2003

function true_elevation, pixel, n_overlap

forward_function camera_pixel

; ------------------------------------------------------
; determine which camera and pixel within the
; camera corresponds to this pixel in the combined frame
; ------------------------------------------------------
camera_pixel, pixel, n_overlap, camera, c_pixel

; ----------------------------------------------
; define the regression coefficients and offsets
; ----------------------------------------------
ac0 = [-1.74556,-1.64623,-1.02636]

ac1 = [0.996648, 1.03942, 1.02954]

off = [27.0, 0.0, -27.0]

; -----------------------
; calculate the elevation
; -----------------------
elevation=(0.6*(24.5 - c_pixel) + off[camera] - ac0[camera] ) / ac1[camera]

return, elevation
end

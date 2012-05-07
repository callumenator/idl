
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; camera_pixel - return the pixel number within
;                a camera and the camera number
;                from the pixel number in the
;                 combined frame.
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; 
; INPUTS:
;
; pixel        pixel number in the combined frame
;
; n_overlap    the number of pixels overlapped in
;              the combined frame
;
;
; OUTPUTS:
;
; camera       original camera number
; 
; c_pixel      pixel within the camera
;
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 25-Jul-2003

pro camera_pixel, pixel, n_overlap, camera, c_pixel

pixel = pixel + 1.0

n_combined = 150 - 2*n_overlap ; pixels in the combined frame
nc2        = n_combined / 2    ; half width of combined frame
nov2       = n_overlap / 2     ; half of the overlap (truncated)

; ----------------------------------------------------------
; calculate a pseudo-pixel for determining the camera number
; ----------------------------------------------------------
npixel = fix(pixel)
if(npixel gt nc2) then npixel = npixel + nov2 + (n_overlap mod 2)

; -------------------------------------
; calculate the camera and pixel number
; -------------------------------------
camera = npixel / (50 -nov2)
c_pixel = pixel + float(camera * (n_overlap - 50))

end

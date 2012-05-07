
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; write a JPEG image
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified:  8-May-2003

pro write_jpeg_image, out

@euv_imtool-commons

; -----------------------------------
; create the Z-buffer graphics object
; -----------------------------------
zbuf = OBJ_NEW('IDLgrBuffer')
zbuf -> SetProperty, dimensions=[xdim2,ydim2]

; -----------------------
; first, erase the buffer
; -----------------------
zbuf -> Erase

; ------------------------------------------------------
; draw the view containing the EUV image to the buffer
; ------------------------------------------------------
zbuf -> Draw, imview

; --------------------------------------------------------
; retrieve the RGB image data and write it to a JPEG image
; --------------------------------------------------------
zbuf -> GetProperty, image_data=im_rgb

; ------------------------------
; get rid of the Z-buffer object
; ------------------------------
OBJ_DESTROY, zbuf

; ------------------------------
; write out the JPEG image
; ------------------------------
write_jpeg, out, im_rgb, true=1

end
